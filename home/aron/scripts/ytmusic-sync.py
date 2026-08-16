#!/usr/bin/env python3
"""ytmusic-sync — mirror public YouTube Music playlists into a local Strawberry collection.

Re-runnable. Every run recomputes the remote playlist state, diffs it against the
last recorded state, and reports what changed. Downloads are incremental (yt-dlp
--download-archive); .m3u8 files are regenerated in full, so track reorders and
removals inside a playlist need no special handling.

Destructive work is opt-in:
  (default)   discover + download new tracks + regenerate .m3u8
  --prune     move orphaned audio files to a trash dir (recoverable, not deleted)
  --relink    rebuild the Strawberry DB playlist rows (requires Strawberry closed)
  --dry-run   report the diff, touch nothing
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import time
from pathlib import Path
from typing import NoReturn

HOME = Path.home()
MUSIC_DIR = Path(os.environ.get("YTMUSIC_SYNC_MUSIC_DIR", HOME / "Music/YouTubeMusic"))
PLAYLIST_DIR = Path(os.environ.get("YTMUSIC_SYNC_PLAYLIST_DIR", HOME / "Music/Playlists"))
STATE_DIR = Path(os.environ.get("YTMUSIC_SYNC_STATE_DIR", HOME / ".local/share/ytmusic-sync"))
STRAWBERRY_DB = Path(
    os.environ.get(
        "YTMUSIC_SYNC_STRAWBERRY_DB",
        HOME / ".local/share/strawberry/strawberry/strawberry.db",
    )
)

STATE_FILE = STATE_DIR / "state.json"
ARCHIVE_FILE = STATE_DIR / "archive.txt"
TRASH_DIR = STATE_DIR / "trash"

# YouTube enforces PO tokens on most player clients; web_embedded is currently the
# only one that serves media without a token or cookies. If this breaks, the
# durable fix is the bgutil PO token provider (python3Packages.bgutil-ytdlp-pot-provider).
PLAYER_CLIENT = os.environ.get("YTMUSIC_SYNC_PLAYER_CLIENT", "web_embedded")
EXTRACTOR_ARGS = f"youtube:player_client={PLAYER_CLIENT}"

OUTPUT_TEMPLATE = (
    "%(album_artist,artist,uploader|Unknown Artist)s/"
    "%(album|Unknown Album)s/"
    "%(title)s [%(id)s].%(ext)s"
)

ID_IN_NAME = re.compile(r"\[([A-Za-z0-9_-]{11})\]\.opus$")


def log(msg: str) -> None:
    print(msg, flush=True)


def die(msg: str) -> NoReturn:
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


# --------------------------------------------------------------------------
# remote discovery
# --------------------------------------------------------------------------


def resolve_channel_id(handle: str) -> str:
    """Resolve an @handle to a UC… channel id via yt-dlp."""
    if handle.startswith("UC"):
        return handle
    url = f"https://www.youtube.com/@{handle.lstrip('@')}/playlists"
    out = run_json(["yt-dlp", "--flat-playlist", "--playlist-items", "0", "--dump-single-json", url])
    channel_id = out.get("channel_id")
    if not channel_id:
        die(f"could not resolve channel id for {handle}")
    return channel_id


def fetch_music_playlists(channel_id: str) -> list[dict]:
    """List the channel's YouTube *Music* playlists.

    ytmusicapi is what separates music playlists from ordinary video playlists on
    the same channel — the YouTube /playlists page shows both mixed together.
    """
    from ytmusicapi import YTMusic

    yt = YTMusic()
    user = yt.get_user(channel_id)
    section = user.get("playlists") or {}
    results = section.get("results", [])
    if section.get("params"):
        try:
            results = yt.get_user_playlists(channel_id, section["params"])
        except Exception as exc:  # noqa: BLE001 - fall back to the truncated shelf
            log(f"warn: could not expand playlist shelf ({exc}); using first {len(results)}")
    playlists = []
    for entry in results:
        pid, title = entry.get("playlistId"), entry.get("title")
        if pid and title:
            playlists.append({"id": pid, "title": title})
    return playlists


def fetch_playlist_tracks(playlist_id: str) -> list[str]:
    """Ordered video ids for a playlist (flat, no per-video extraction)."""
    proc = subprocess.run(
        [
            "yt-dlp",
            "--flat-playlist",
            "--ignore-errors",
            "--print",
            "%(id)s",
            f"https://www.youtube.com/playlist?list={playlist_id}",
        ],
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in proc.stdout.splitlines() if line.strip()]


def run_json(cmd: list[str]) -> dict:
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0 and not proc.stdout.strip():
        die(f"{cmd[0]} failed: {proc.stderr.strip()[:400]}")
    return json.loads(proc.stdout)


# --------------------------------------------------------------------------
# local index
# --------------------------------------------------------------------------


def index_files() -> dict[str, Path]:
    """Map video id -> audio file, keyed off the [id] suffix in each filename."""
    index: dict[str, Path] = {}
    if not MUSIC_DIR.exists():
        return index
    for path in MUSIC_DIR.rglob("*.opus"):
        match = ID_IN_NAME.search(path.name)
        if match:
            index[match.group(1)] = path
    return index


def load_state() -> dict:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except json.JSONDecodeError:
            log("warn: state file unreadable, treating this run as a first sync")
    return {"playlists": {}}


def save_state(playlists: dict[str, dict]) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(
        json.dumps({"synced_at": int(time.time()), "playlists": playlists}, indent=2, ensure_ascii=False)
    )


# --------------------------------------------------------------------------
# diffing
# --------------------------------------------------------------------------


def diff_playlists(old: dict, new: dict) -> dict:
    old_pl, new_pl = old.get("playlists", {}), new
    added = [p for p in new_pl if p not in old_pl]
    removed = [p for p in old_pl if p not in new_pl]
    changed = {}
    for pid in new_pl:
        if pid not in old_pl:
            continue
        before = set(old_pl[pid].get("tracks", []))
        after = set(new_pl[pid]["tracks"])
        gained, lost = after - before, before - after
        renamed = old_pl[pid].get("title") != new_pl[pid]["title"]
        if gained or lost or renamed:
            changed[pid] = {"added": sorted(gained), "removed": sorted(lost), "renamed": renamed}
    return {"added": added, "removed": removed, "changed": changed}


def report_diff(delta: dict, new: dict, old: dict, missing: set[str], orphans: dict) -> None:
    log("\n── diff vs last sync ──")
    for pid in delta["added"]:
        log(f"  + playlist  {new[pid]['title']} ({len(new[pid]['tracks'])} tracks)")
    for pid in delta["removed"]:
        log(f"  - playlist  {old['playlists'][pid].get('title', pid)}")
    for pid, info in delta["changed"].items():
        title = new[pid]["title"]
        if info["renamed"]:
            log(f"  ~ renamed   {old['playlists'][pid].get('title', pid)} -> {title}")
        if info["added"]:
            log(f"  + {len(info['added'])} track(s) in {title}")
        if info["removed"]:
            log(f"  - {len(info['removed'])} track(s) in {title}")
    if not (delta["added"] or delta["removed"] or delta["changed"]):
        log("  (no playlist changes)")
    log(f"\n  {len(missing)} track(s) to download, {len(orphans)} orphaned file(s) on disk")


# --------------------------------------------------------------------------
# download / playlist generation
# --------------------------------------------------------------------------


def download(ids: list[str]) -> None:
    MUSIC_DIR.mkdir(parents=True, exist_ok=True)
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    cmd = [
        "yt-dlp",
        "--extractor-args", EXTRACTOR_ARGS,
        "-f", "bestaudio",
        "-x", "--audio-format", "opus", "--audio-quality", "0",
        "--embed-thumbnail", "--embed-metadata",
        "--download-archive", str(ARCHIVE_FILE),
        "--ignore-errors",
        "--no-overwrites",
        # 400ish sequential requests will trip rate limiting without these.
        "--sleep-requests", "1", "--sleep-interval", "2", "--max-sleep-interval", "5",
        "--paths", str(MUSIC_DIR),
        "-o", OUTPUT_TEMPLATE,
        *[f"https://www.youtube.com/watch?v={vid}" for vid in ids],
    ]
    log(f"\n── downloading {len(ids)} track(s) ──")
    subprocess.run(cmd, check=False)


def write_m3u(playlists: dict[str, dict], index: dict[str, Path]) -> list[str]:
    PLAYLIST_DIR.mkdir(parents=True, exist_ok=True)
    written = []
    for pid, meta in playlists.items():
        name = safe_filename(meta["title"])
        target = PLAYLIST_DIR / f"{name}.m3u8"
        lines = ["#EXTM3U"]
        gaps = 0
        for vid in meta["tracks"]:
            path = index.get(vid)
            if path is None:
                gaps += 1
                continue
            lines.append(f"#EXTINF:-1,{display_name(path)}")
            lines.append(str(path))
        target.write_text("\n".join(lines) + "\n")
        written.append(meta["title"])
        suffix = f" ({gaps} missing)" if gaps else ""
        log(f"  wrote {target.name}: {len(meta['tracks']) - gaps} track(s){suffix}")
    return written


def prune_stale_m3u(playlists: dict[str, dict]) -> None:
    if not PLAYLIST_DIR.exists():
        return
    keep = {safe_filename(m["title"]) + ".m3u8" for m in playlists.values()}
    for path in PLAYLIST_DIR.glob("*.m3u8"):
        if path.name not in keep:
            path.unlink()
            log(f"  removed stale playlist file {path.name}")


def safe_filename(name: str) -> str:
    return re.sub(r"[/\\\x00]", "_", name).strip() or "untitled"


def display_name(path: Path) -> str:
    """'Artist - Title' for the #EXTINF line, derived from the Artist/Album/ layout."""
    title = re.sub(r"\s*\[[A-Za-z0-9_-]{11}\]$", "", path.stem)
    artist = path.parent.parent.name
    return f"{artist} - {title}" if artist and path.parent.parent != MUSIC_DIR else title


def prune_orphans(orphans: dict[str, Path]) -> None:
    """Move orphaned files to a trash dir and drop them from the download archive.

    Moved rather than deleted so a mistaken prune is recoverable. The archive entry
    must go too, otherwise re-adding the track to a playlist would never re-download it.
    """
    TRASH_DIR.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    batch = TRASH_DIR / stamp
    batch.mkdir(parents=True, exist_ok=True)
    for vid, path in orphans.items():
        dest = batch / path.name
        shutil.move(str(path), str(dest))
        log(f"  trashed {path.name}")
    drop_from_archive(set(orphans))
    prune_empty_dirs()
    log(f"  {len(orphans)} file(s) moved to {batch}")


def drop_from_archive(ids: set[str]) -> None:
    if not ARCHIVE_FILE.exists():
        return
    kept = [
        line
        for line in ARCHIVE_FILE.read_text().splitlines()
        if line.strip().split(" ")[-1] not in ids
    ]
    ARCHIVE_FILE.write_text("\n".join(kept) + ("\n" if kept else ""))


def prune_empty_dirs() -> None:
    if not MUSIC_DIR.exists():
        return
    for path in sorted(MUSIC_DIR.rglob("*"), key=lambda p: len(p.parts), reverse=True):
        if path.is_dir() and not any(path.iterdir()):
            path.rmdir()


# --------------------------------------------------------------------------
# strawberry linking
# --------------------------------------------------------------------------


def strawberry_running() -> bool:
    return subprocess.run(["pgrep", "-x", "strawberry"], capture_output=True).returncode == 0


def relink_strawberry(playlists: dict[str, dict]) -> None:
    """Recreate the Strawberry playlist rows from the generated .m3u8 files.

    `strawberry -c` appends a *new* playlist on every call, so re-running without
    clearing the old rows first would duplicate every playlist tab. Strawberry must
    be closed: it holds the playlist state in memory and rewrites the DB on exit.
    """
    if strawberry_running():
        die("Strawberry is running — close it before --relink (it overwrites the DB on exit)")
    if not STRAWBERRY_DB.exists():
        die(f"Strawberry DB not found at {STRAWBERRY_DB}; launch Strawberry once first")

    backup = STRAWBERRY_DB.with_suffix(f".db.ytmusic-sync-{time.strftime('%Y%m%d-%H%M%S')}")
    shutil.copy2(STRAWBERRY_DB, backup)
    log(f"\n── relinking Strawberry (backup: {backup.name}) ──")

    titles = [meta["title"] for meta in playlists.values()]
    conn = sqlite3.connect(STRAWBERRY_DB)
    try:
        placeholders = ",".join("?" * len(titles))
        conn.execute(
            f"DELETE FROM playlist_items WHERE playlist IN "
            f"(SELECT rowid FROM playlists WHERE name IN ({placeholders}))",
            titles,
        )
        conn.execute(f"DELETE FROM playlists WHERE name IN ({placeholders})", titles)
        conn.commit()
    finally:
        conn.close()

    # The first -c launches Strawberry; later ones reach it over IPC. Playlist state
    # only reaches the DB when Strawberry exits, so this owns the whole lifecycle:
    # launch, feed, then shut it down cleanly and verify the rows landed.
    for meta in playlists.values():
        m3u = PLAYLIST_DIR / f"{safe_filename(meta['title'])}.m3u8"
        if not m3u.exists():
            continue
        subprocess.run(["strawberry", "-c", meta["title"], str(m3u)], check=False)
        time.sleep(2)

    log("  shutting Strawberry down to flush its playlist state")
    subprocess.run(["pkill", "-TERM", "-x", "strawberry"], check=False)
    for _ in range(30):
        if not strawberry_running():
            break
        time.sleep(1)
    else:
        die("Strawberry did not exit cleanly; playlists may not have been saved")

    conn = sqlite3.connect(STRAWBERRY_DB)
    try:
        placeholders = ",".join("?" * len(titles))
        linked = conn.execute(
            f"SELECT name, (SELECT COUNT(*) FROM playlist_items WHERE playlist = playlists.rowid) "
            f"FROM playlists WHERE name IN ({placeholders})",
            titles,
        ).fetchall()
    finally:
        conn.close()
    for name, count in linked:
        log(f"  linked {name}: {count} track(s)")
    if len(linked) != len(titles):
        log(f"  warn: {len(titles) - len(linked)} playlist(s) did not link")


def ensure_collection_dir() -> None:
    """Register the music dir as a Strawberry collection directory if it is missing.

    Collection roots live in the DB, not in strawberry.conf, so this is the only way
    to set one up without clicking through Settings. Strawberry scans the new root on
    its next start and builds the artist/album browser from the embedded tags.
    """
    if not STRAWBERRY_DB.exists():
        return
    conn = sqlite3.connect(STRAWBERRY_DB)
    try:
        rows = conn.execute("SELECT path FROM directories").fetchall()
        if any(Path(r[0]) == MUSIC_DIR for r in rows):
            return
        if strawberry_running():
            log(
                f"\nnote: {MUSIC_DIR} is not a Strawberry collection directory yet, and"
                f"\n      Strawberry is running. Close it and re-run to register it automatically."
            )
            return
        conn.execute("INSERT INTO directories (path, subdirs) VALUES (?, 1)", (str(MUSIC_DIR),))
        conn.commit()
        log(f"\nregistered {MUSIC_DIR} as a Strawberry collection directory (scans on next start)")
    finally:
        conn.close()


# --------------------------------------------------------------------------


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="ytmusic-sync",
        description="Sync public YouTube Music playlists into a local Strawberry collection.",
    )
    parser.add_argument(
        "--channel",
        default=os.environ.get("YTMUSIC_SYNC_CHANNEL", "arongomu4294"),
        help="channel @handle or UC… id (default: arongomu4294)",
    )
    parser.add_argument("--dry-run", action="store_true", help="report the diff, change nothing")
    parser.add_argument("--prune", action="store_true", help="move orphaned audio files to the trash dir")
    parser.add_argument("--relink", action="store_true", help="rebuild Strawberry playlists (Strawberry must be closed)")
    parser.add_argument("--no-download", action="store_true", help="skip downloading, only refresh playlists")
    args = parser.parse_args()

    channel_id = resolve_channel_id(args.channel)
    log(f"channel: {args.channel} ({channel_id})")

    remote = fetch_music_playlists(channel_id)
    if not remote:
        die("no public YouTube Music playlists found")
    log(f"found {len(remote)} music playlist(s)")

    new_state: dict[str, dict] = {}
    for entry in remote:
        tracks = fetch_playlist_tracks(entry["id"])
        new_state[entry["id"]] = {"title": entry["title"], "tracks": tracks}
        log(f"  {entry['title']}: {len(tracks)} track(s)")

    old_state = load_state()
    index = index_files()
    wanted = {vid for meta in new_state.values() for vid in meta["tracks"]}
    missing = wanted - set(index)
    orphans = {vid: path for vid, path in index.items() if vid not in wanted}

    delta = diff_playlists(old_state, new_state)
    report_diff(delta, new_state, old_state, missing, orphans)

    if args.dry_run:
        log("\ndry run — nothing changed")
        return

    if missing and not args.no_download:
        download(sorted(missing))
        index = index_files()
        still_missing = wanted - set(index)
        if still_missing:
            log(f"\nwarn: {len(still_missing)} track(s) could not be downloaded (unavailable or blocked)")

    log("\n── regenerating playlists ──")
    write_m3u(new_state, index)
    prune_stale_m3u(new_state)

    if orphans:
        if args.prune:
            log("\n── pruning orphans ──")
            prune_orphans(orphans)
        else:
            log(f"\n{len(orphans)} orphaned file(s) kept; re-run with --prune to move them to the trash dir")

    ensure_collection_dir()
    if args.relink:
        relink_strawberry(new_state)
    else:
        log("\nrun with --relink (Strawberry closed) to rebuild its playlist tabs")

    save_state(new_state)
    log("\ndone")


if __name__ == "__main__":
    main()
