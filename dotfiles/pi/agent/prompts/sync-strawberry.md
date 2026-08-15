---
description: Sync public YouTube Music playlists into the local Strawberry collection via ytmusic-sync
argument-hint: "[--dry-run] [--prune] [--relink] [--no-download]"
---
Run the `ytmusic-sync` command (Nix-managed, defined in
`~/config/nix-aron/home/aron/packages.nix`, logic in
`~/config/nix-aron/home/aron/scripts/ytmusic-sync.py`).

It mirrors the public YouTube Music playlists of channel `@arongomu4294` into
`~/Music/YouTubeMusic` (Artist/Album folders, Opus), regenerates `~/Music/Playlists/*.m3u8`,
and can rebuild Strawberry's playlist tabs.

User arguments: $@

Behaviour:

- No arguments: run `ytmusic-sync --dry-run` first and show the diff, then ask whether to apply.
- Arguments given: pass them through verbatim.
- `--prune` moves orphaned audio to `~/.local/share/ytmusic-sync/trash/<timestamp>/` (recoverable, not deleted).
- `--relink` rewrites rows in Strawberry's DB and **requires Strawberry to be closed** — the
  script refuses otherwise, because Strawberry rewrites the DB from memory on exit. It backs
  the DB up first. If Strawberry is running, tell the user to quit it rather than killing it.

Report afterwards: playlists added/removed/renamed, tracks added/removed, tracks that failed to
download (usually deleted or region-blocked videos), and orphans left on disk.

If downloads start failing with `HTTP Error 403: Forbidden` across the board, the YouTube player
client workaround has been broken by an upstream change. The fix is either a different client via
`YTMUSIC_SYNC_PLAYER_CLIENT=...` or wiring in `python3Packages.bgutil-ytdlp-pot-provider`. Say so
rather than retrying blindly.
