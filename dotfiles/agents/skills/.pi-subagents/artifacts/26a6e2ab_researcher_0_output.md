# Research: GNOME Nautilus video file thumbnail previews (NixOS / Linux)

## Summary

Nautilus does **not** decode video itself. It uses **libgnome-desktop** `GnomeDesktopThumbnailFactory`, which discovers `*.thumbnailer` files under `$XDG_DATA_DIRS/thumbnailers` (and `~/.local/share/thumbnailers`), then runs the matching `Exec` (often sandboxed via bubblewrap). On modern NixOS GNOME, **Totem is no longer a core app** (replaced by Showtime, which does **not** ship a thumbnailer), so video thumbs are commonly missing until you install a thumbnailer package.

**Recommendation for NixOS Nautilus user:** install `ffmpegthumbnailer` system-wide (or via Home Manager). Prefer systemPackages so Nautilus (system GNOME session) sees `share/thumbnailers`. Clear `~/.cache/thumbnails` after install. Optional alternative: install `totem` for `totem-video-thumbnailer` + GStreamer stack. Do **not** need `nautilus-python` for video thumbs.

## Findings

### 1. What component generates video thumbnails for Nautilus?

1. **Nautilus → gnome-desktop thumbnail factory** — Nautilus depends on `gnome-desktop` and uses its thumbnail infrastructure; it does not embed a video decoder for icons. nixpkgs `nautilus` package lists `gnome-desktop` in `buildInputs` and only wraps image-loader-related `XDG_DATA_DIRS` (gdk-pixbuf, jxl, rsvg, webp, shared-mime-info), not a video thumbnailer. [nautilus package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/na/nautilus/package.nix)

2. **`GnomeDesktopThumbnailFactory` discovers and runs external thumbnailers** — Official gnome-desktop docs in source state:
   - Thumbnailers are programs that write a PNG to a given output path for a URI/path.
   - Chosen by scanning `.thumbnailer` files in `$PREFIX/share/thumbnailers` (actually: user + system data dirs).
   - Example called out in docs: **`totem-video-thumbnailer`** for video via GStreamer; `evince-thumbnailer` for PDFs.
   - Format keys: required `Exec`, required `MimeType`; placeholders `%u` URI, `%i` path, `%o` output, `%s` size, `%%` percent.
   - Cache under `$XDG_CACHE_HOME/thumbnails/{normal,large,...}`; failed thumbs under `.../fail/gnome-thumbnail-factory/`.
   - GSettings schema `org.gnome.desktop.thumbnailers` can disable all or specific MIME types.  
   Source: [gnome-desktop-thumbnail.c (GNOME 44 branch)](https://gitlab.gnome.org/GNOME/gnome-desktop/-/raw/gnome-44/libgnome-desktop/gnome-desktop-thumbnail.c)

3. **Discovery paths** — Factory loads from:
   - `$XDG_DATA_HOME/thumbnailers` (typically `~/.local/share/thumbnailers`)
   - each `g_get_system_data_dirs()` + `/thumbnailers`  
   Same source file: `init_thumbnailers_dirs()`.

4. **Sandbox execution** — Thumbnail scripts run through `gnome-desktop-thumbnail-script.c`, which supports bubblewrap/flatpak-style sandboxing and seccomp (and GStreamer registry cache under `~/.cache/gnome-desktop-thumbnailer/gstreamer-1.0`). [gnome-desktop-thumbnail-script.c](https://gitlab.gnome.org/GNOME/gnome-desktop/-/raw/master/libgnome-desktop/gnome-desktop-thumbnail-script.c)

5. **Nautilus runtime deps include Bubblewrap** — Upstream Nautilus README: Bubblewrap required “for security reasons” (thumbnail sandboxing is a major consumer). [GNOME/nautilus GitHub mirror README](https://github.com/GNOME/nautilus)

6. **Freedesktop Thumbnail Managing Standard** — Cache location `$XDG_CACHE_HOME/thumbnails` (else `~/.cache/thumbnails`); sizes normal/large/x-large/xx-large; fail dir for permanent failure markers; PNG + `Thumb::URI` / `Thumb::MTime` metadata. [Thumbnail Directory](https://specifications.freedesktop.org/thumbnail-spec/latest/directory.html), [Creation](https://specifications.freedesktop.org/thumbnail-spec/latest/creation.html), [Failures](https://specifications.freedesktop.org/thumbnail-spec/latest/failures.html)

### 2. What packages must be installed on NixOS / Home Manager?

| Package | Role | Needed? |
|--------|------|---------|
| **`ffmpegthumbnailer`** | Ships `bin/ffmpegthumbnailer` + `share/thumbnailers/ffmpegthumbnailer.thumbnailer`; nixpkgs **rewrites Exec to absolute store path** | **Yes (recommended)** |
| **`totem`** | Ships `totem-video-thumbnailer` + `.thumbnailer`; pulls GStreamer plugins incl. `gst-libav` | Alternative (heavier) |
| **`showtime`** | Current GNOME core video player on NixOS | **No** — player only; package has no thumbnailer install |
| **`gst-libav` / gst plugins alone** | Codecs for GStreamer-based tools | Only if using **totem** path; not sufficient alone |
| **`nautilus-python`** | Python extension API | **No** for video thumbs |
| **`bubblewrap`** | Sandbox for thumbnailers | Usually already present via GNOME/Nautilus |

**Evidence — ffmpegthumbnailer (nixpkgs):**
- Enables `-DENABLE_THUMBNAILER=ON`
- `postInstall` substitutes `Exec=` to `$out/bin/ffmpegthumbnailer` (critical on Nix where bare `TryExec=ffmpegthumbnailer` may not be on PATH inside sandbox the same way)
- Uses `ffmpeg-headless` (formats depend on ffmpeg build flags)  
[nixpkgs ffmpegthumbnailer/package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/ff/ffmpegthumbnailer/package.nix)

**Evidence — upstream ffmpegthumbnailer `.thumbnailer`:**
```
[Thumbnailer Entry]
TryExec=ffmpegthumbnailer
Exec=ffmpegthumbnailer -i %i -o %o -s %s -f
MimeType=video/mp4;video/webm;video/x-matroska;... (broad video/* list)
```
[dist/ffmpegthumbnailer.thumbnailer](https://raw.githubusercontent.com/dirkvdb/ffmpegthumbnailer/master/dist/ffmpegthumbnailer.thumbnailer)

**Evidence — totem thumbnailer:**
```
[Thumbnailer Entry]
TryExec=@BINDIR@/totem-video-thumbnailer
Exec=@BINDIR@/totem-video-thumbnailer -s %s %u %o
@MIME_TYPE@
```
[totem.thumbnailer.in (gnome-43)](https://gitlab.gnome.org/GNOME/totem/-/raw/gnome-43/data/totem.thumbnailer.in)

**Evidence — totem nixpkgs deps include full GStreamer stack:**
`gst-plugins-{base,good,bad,ugly}`, **`gst-libav`**, gstreamer. [totem/package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/to/totem/package.nix)

**Evidence — GNOME core apps on NixOS no longer include Totem:**
`services.gnome.core-apps` installs `showtime` (not `totem`) among others, plus `nautilus`. [gnome.nix module](https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/nixos/modules/services/desktop-managers/gnome.nix)

**Evidence — showtime has no thumbnailer:**
showtime package is a GTK4/libadwaita Python app with GStreamer plugins for playback; no `share/thumbnailers` handling in the derivation. [showtime/package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/sh/showtime/package.nix)

**Arch (secondary but consistent with primary model):** For GNOME Files, video thumbs via **totem**; **ffmpegthumbnailer** listed for general FMs; notes that video thumbs often need ffmpegthumbnailer + gst-libav + gst-plugins-ugly and clearing fail cache. [ArchWiki File manager functionality](https://wiki.archlinux.org/title/File_manager_functionality#Thumbnail_previews), [ArchWiki GNOME/Files#Thumbnails](https://wiki.archlinux.org/title/GNOME/Files#Thumbnails)

### 3. Exact Nix config snippets

#### Minimal recommended (NixOS system — preferred)

```nix
# configuration.nix / host module
{ pkgs, ... }:
{
  # GNOME + Nautilus already from:
  # services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer
    # optional: totem  # if you want GStreamer-based totem-video-thumbnailer instead/in addition
  ];
}
```

Why system-wide: GNOME session / system Nautilus reads `XDG_DATA_DIRS` including `/run/current-system/sw/share`. Module already enables `xdg.mime` and links `/share` into the system profile for GNOME. [gnome.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/nixos/modules/services/desktop-managers/gnome.nix)

#### Home Manager only

```nix
# home.nix
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ffmpegthumbnailer
  ];
}
```

Works if HM puts package share dirs on `XDG_DATA_DIRS` for the user session (default HM behavior). Prefer systemPackages when Nautilus is the system GNOME app and HM env is incomplete for GUI apps started from the session.

#### Optional: Totem path (GStreamer)

```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    totem
    # gst-libav is already a buildInput of totem in nixpkgs;
    # installing gst_all_1.gst-libav alone does NOT register a .thumbnailer
  ];
}
```

#### Optional: disable/enable thumbnailers via dconf (debug)

```nix
# Home Manager
{
  dconf.settings = {
    "org/gnome/desktop/thumbnailers" = {
      disable-all = false;
      # disable = [ "application/x-some-type" ];
    };
    "org/gnome/nautilus/preferences" = {
      # values vary by Nautilus version; check:
      # gsettings range org.gnome.nautilus.preferences show-image-thumbnails
      show-image-thumbnails = "always";
    };
  };
}
```

Schema names confirmed in gnome-desktop factory (`org.gnome.desktop.thumbnailers`). Nautilus preference key names should be verified live with `gsettings`.

#### Not required

```nix
# NOT needed for video thumbnails:
# pkgs.nautilus-python
# pkgs.gst_all_1.gst-libav alone
# programs.something special — there is no dedicated NixOS "enable video thumbnails" option
```

### 4. Common failure modes

| Failure | Severity | Cause | Fix |
|--------|----------|-------|-----|
| No video thumbs after GNOME 42+ / NixOS core-apps | **High** | Totem removed; Showtime has no `.thumbnailer` | Install `ffmpegthumbnailer` or `totem` |
| `.thumbnailer` not visible to Nautilus | **High** | Package only in nix-shell / wrong profile; not on `XDG_DATA_DIRS` | systemPackages or HM packages; re-login |
| Fail cache poisoned | **High** | Prior failures stored under `~/.cache/thumbnails/fail/gnome-thumbnail-factory/` | Delete fail cache (or whole thumbnails dir) |
| Missing codec / decode fail | **Med** | ffmpeg build lacks codec; or totem without needed gst plugins | ffmpegthumbnailer uses nixpkgs `ffmpeg-headless`; totem already pulls gst-libav+ugly etc. |
| Sandbox / bubblewrap | **Med** | bwrap missing or user namespaces restricted (hardened kernels) | Ensure `bubblewrap`; Arch notes hardened kernels need bwrap-suid or userns | 
| TryExec fails | **Med** | Binary name not on PATH inside lookup | nixpkgs patches ffmpegthumbnailer Exec to store path |
| MIME mismatch | **Med** | File MIME not in thumbnailer MimeType list | Check `file --mime-type` vs `.thumbnailer` MimeType |
| Thumbnails disabled in settings | **Low** | `org.gnome.desktop.thumbnailers disable-all=true` or Nautilus “never” | Reset gsettings |
| Remote/MTP FS | **Low** | File managers often skip or limit remote thumbs | Local copy or FM “always” setting |
| Flatpak Nautilus vs system | **Med** | Flatpak sandbox cannot see host `/nix/store` thumbnailers the same way; needs Flatpak permissions/portals or install thumbnailer **inside** Flatpak | Prefer system Nautilus on NixOS GNOME |
| File too large | **Low** | Thumbnailer timeout / size limits | Smaller sample file; check fail dir |
| Hash/mtime stale | **Low** | Cache entry invalid after edit | Touch file or clear cache |

Primary refs: gnome-desktop factory fail path + settings; freedesktop fail spec; Arch GNOME/Files sandbox note; nixpkgs path patch.

### 5. How to regenerate / clear thumbnails

Per freedesktop + gnome-desktop:

```bash
# Stop Nautilus (optional but cleaner)
nautilus -q

# Clear all cached thumbs + failure markers
rm -rf ~/.cache/thumbnails/*

# Optional: gstreamer registry used by sandboxed thumbnailers
rm -rf ~/.cache/gnome-desktop-thumbnailer

# Restart Files / re-open folder
nautilus &
```

Verify thumbnailer registration:

```bash
# Should list ffmpegthumbnailer.thumbnailer (and/or totem...)
ls /run/current-system/sw/share/thumbnailers/ 2>/dev/null
ls ~/.local/share/thumbnailers/ 2>/dev/null
# Also search full XDG data dirs:
echo "$XDG_DATA_DIRS" | tr ':' '\n' | while read -r d; do
  ls "$d/thumbnailers" 2>/dev/null
done
```

Manual smoke test (ffmpegthumbnailer):

```bash
ffmpegthumbnailer -i /path/to/video.mp4 -o /tmp/thumb.png -s 256
file /tmp/thumb.png
```

Manual smoke test (totem, if installed):

```bash
totem-video-thumbnailer -s 256 file:///path/to/video.mp4 /tmp/thumb.png
```

If manual works but Nautilus does not: almost always discovery (`XDG_DATA_DIRS`), fail-cache, or sandbox — not the decoder.

### 6. Is gst-libav / ffmpegthumbnailer / totem / gnome.totem / nautilus-python needed?

| Component | Needed for video thumbs? | Notes |
|-----------|--------------------------|-------|
| **ffmpegthumbnailer** | **Recommended yes** | Standalone; uses ffmpeg; registers `.thumbnailer`; nixpkgs patches absolute Exec |
| **totem** (`pkgs.totem`, historically `gnome.totem`) | Optional alternative | Provides `totem-video-thumbnailer`; classic GNOME path |
| **gst-libav** | Only with Totem/GStreamer path | Already pulled by `totem`/`showtime` derivations; alone does **not** create thumbs |
| **showtime** | No (for thumbs) | Playback only in current NixOS GNOME core-apps |
| **nautilus-python** | **No** | Extensions only; unrelated to thumbnail factory |
| **bubblewrap** | Indirect yes | Required by Nautilus/security sandboxing for thumbnailers |

## Summary recommendation for NixOS user running Nautilus

1. Add `pkgs.ffmpegthumbnailer` to `environment.systemPackages` (best) or `home.packages`.
2. Rebuild + re-login (or at least `nautilus -q`).
3. `rm -rf ~/.cache/thumbnails/*`.
4. Open a folder of local videos in Icons/Grid view; wait for generation.
5. If still broken: confirm `.thumbnailer` on `XDG_DATA_DIRS`; test CLI thumbnailer; inspect `~/.cache/thumbnails/fail/gnome-thumbnail-factory/`.
6. Only switch to/install `totem` if you specifically want GStreamer-based thumbnailing or already use Totem.

## Required packages

- **Minimum:** `ffmpegthumbnailer`
- **Already expected on GNOME NixOS:** `nautilus`, `gnome-desktop` (lib), `bubblewrap`, `shared-mime-info`, `xdg` mime enable
- **Optional alt:** `totem` (includes gst stack / gst-libav transitively)
- **Not required:** `nautilus-python`, bare `gst-libav`, `showtime` for thumbs

## Config

```nix
{ pkgs, ... }:
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  environment.systemPackages = with pkgs; [
    ffmpegthumbnailer
  ];
}
```

Home Manager variant:

```nix
{ pkgs, ... }:
{
  home.packages = [ pkgs.ffmpegthumbnailer ];
}
```

## Verify steps

1. `nixos-rebuild switch` (or `home-manager switch`).
2. `ls $(dirname $(readlink -f $(which ffmpegthumbnailer)))/../share/thumbnailers` or check `/run/current-system/sw/share/thumbnailers/ffmpegthumbnailer.thumbnailer`.
3. `ffmpegthumbnailer -i sample.mp4 -o /tmp/t.png -s 128 && file /tmp/t.png`
4. `rm -rf ~/.cache/thumbnails/*`
5. `nautilus -q`; open video directory; confirm PNG appears under `~/.cache/thumbnails/large/` or `normal/`.
6. If fail entries appear: open fail PNG metadata / re-run CLI; check sandbox/bwrap.

## Sources

### Kept (primary / authoritative)

- [Freedesktop Thumbnail Managing Standard — directory](https://specifications.freedesktop.org/thumbnail-spec/latest/directory.html) — cache paths and size dirs
- [Freedesktop Thumbnail Managing Standard — creation](https://specifications.freedesktop.org/thumbnail-spec/latest/creation.html) — PNG format, Thumb::* keys
- [Freedesktop Thumbnail Managing Standard — failures](https://specifications.freedesktop.org/thumbnail-spec/latest/failures.html) — fail repository semantics
- [gnome-desktop-thumbnail.c (GNOME 44)](https://gitlab.gnome.org/GNOME/gnome-desktop/-/raw/gnome-44/libgnome-desktop/gnome-desktop-thumbnail.c) — factory, `.thumbnailer` format, totem example, cache/fail paths, GSettings
- [gnome-desktop-thumbnail-script.c](https://gitlab.gnome.org/GNOME/gnome-desktop/-/raw/master/libgnome-desktop/gnome-desktop-thumbnail-script.c) — bwrap/sandbox + placeholder expansion
- [totem.thumbnailer.in](https://gitlab.gnome.org/GNOME/totem/-/raw/gnome-43/data/totem.thumbnailer.in) — official Totem video thumbnailer desktop entry
- [ffmpegthumbnailer upstream README + .thumbnailer](https://github.com/dirkvdb/ffmpegthumbnailer) / [dist file](https://raw.githubusercontent.com/dirkvdb/ffmpegthumbnailer/master/dist/ffmpegthumbnailer.thumbnailer)
- [nixpkgs ffmpegthumbnailer/package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/ff/ffmpegthumbnailer/package.nix) — ENABLE_THUMBNAILER + absolute Exec patch
- [nixpkgs totem/package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/to/totem/package.nix) — gst-libav and plugins
- [nixpkgs showtime/package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/sh/showtime/package.nix) — core player, no thumbnailer
- [nixpkgs nautilus/package.nix](https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/by-name/na/nautilus/package.nix) — gnome-desktop dep; image XDG wrap only
- [nixpkgs gnome.nix desktop module](https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/nixos/modules/services/desktop-managers/gnome.nix) — core-apps list (nautilus + showtime, no totem)
- [GNOME Nautilus README (runtime deps)](https://github.com/GNOME/nautilus) — bubblewrap requirement

### Kept (secondary corroboration)

- [ArchWiki File manager functionality § Thumbnail previews](https://wiki.archlinux.org/title/File_manager_functionality#Thumbnail_previews) — totem vs ffmpegthumbnailer roles
- [ArchWiki GNOME/Files § Thumbnails](https://wiki.archlinux.org/title/GNOME/Files#Thumbnails) — fail cache, bwrap/hardened, gst packages tip
- [NixOS Wiki GNOME](https://wiki.nixos.org/wiki/GNOME) — GNOME enablement patterns (no dedicated thumbnail option)

### Dropped

- Generic SEO blog posts / “fix GNOME thumbnails” listicles — non-primary
- Unrelated nixpkgs ffmpeg version bump PRs (#218309, #251494) — not about Nautilus thumbs
- Discourse search page with no useful hits
- gitlab.gnome.org HTML blob pages that returned bot challenges without source text

## Gaps

1. **Exact current Nautilus gsettings keys** for “show thumbnails” / max file size — version-dependent; verify with `gsettings list-keys org.gnome.nautilus.preferences` on the target system.
2. **Whether Showtime will ever ship a thumbnailer** — not present in showtime 50.0 nixpkgs package; future GNOME may change this.
3. **Flatpak Nautilus on NixOS** — not fully validated; expect host thumbnailers to be invisible without extra portal/Flatpak packaging work.
4. **MIME precedence** when both totem and ffmpegthumbnailer register the same video MIME — gnome-desktop registers first-seen MIME in hash table (load order = user dir then system data dirs order); not deeply tested here.
5. **Live end-to-end test on this host** — research only; not executed against desk-main.

## Supervisor coordination

None required. Research complete; artifact written to configured output path.