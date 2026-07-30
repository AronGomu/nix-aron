# OpenWhispr pastes `v` or nothing on Hyprland

- **Date:** 2026-07-30
- **Status:** Solved, user-confirmed
- **Components:** OpenWhispr 1.7.6, Hyprland/Wayland, XWayland, `ydotool`, `ydotoold`, NixOS
- **Fix:** [`home/aron/packages.nix`](../../home/aron/packages.nix)

## Problem

OpenWhispr recorded audio, produced correct transcription, copied text to clipboard, then failed auto-paste:

- Initial symptom: target received bare `v`.
- Later symptom: target received nothing.
- Manual clipboard paste still worked.

Transcription pipeline worked. Failure existed only in simulated paste input.

## Env

- Session: Wayland
- Compositor: Hyprland via end-4 config
- OpenWhispr: AppImage wrapped by `pkgs.appimageTools.wrapAppImage`
- OpenWhispr display backend: X11/XWayland (`--ozone-platform=x11`)
- Input tools: `linux-fast-paste`, `wtype`, `ydotool`
- `ydotoold`: NixOS system svc, socket `/run/ydotoold/socket`

## Diagnostics

### 1. Confirm transcription + clipboard path

OpenWhispr history showed correct transcription. Bug scope reduced to paste simulation.

### 2. Inspect live session

```bash
printf 'XDG_SESSION_TYPE=%s\n' "$XDG_SESSION_TYPE"
printf 'WAYLAND_DISPLAY=%s\n' "$WAYLAND_DISPLAY"
printf 'DISPLAY=%s\n' "$DISPLAY"
printf 'XDG_CURRENT_DESKTOP=%s\n' "$XDG_CURRENT_DESKTOP"
```

Result: Wayland + Hyprland + XWayland.

### 3. Inspect daemon + socket

User svc initially caused confusion:

```bash
systemctl --user status ydotool.service
```

It was inactive. Correct NixOS svc was system-level:

```bash
systemctl status ydotoold.service
```

`ydotoold.service` was active. Socket used group `ydotool`:

```text
/run/ydotoold       root:ydotool 0750
/run/ydotoold/socket root:ydotool 0660
```

### 4. Compare configured groups vs live proc groups

Account DB contained new groups:

```bash
id aron
getent group ydotool
getent group uinput
```

Existing desktop session + OpenWhispr proc lacked group IDs for `ydotool`/`uinput`:

```bash
grep '^Groups:' /proc/$OPENWHISPR_PID/status
```

Direct socket test failed:

```text
failed to connect socket `/run/ydotoold/socket': Permission denied
Please check if the current user has sufficient permissions to access the socket file.
```

Reason: group membership changed after login. Existing compositor/app procs retained old supplementary groups.

### 5. Verify `ydotool` itself

Temporary `foot` window received clipboard token using exact OpenWhispr terminal key seq:

```bash
YDOTOOL_SOCKET=/run/ydotoold/socket \
  ydotool key 29:1 42:1 47:1 47:0 42:0 29:0
```

Keycodes:

- `29`: left Ctrl
- `42`: left Shift
- `47`: V

Expected token matched captured token. Persistent `ydotoold` input path worked.

### 6. Inspect bundled OpenWhispr code

Extracted `src/helpers/clipboard.js` from `resources/app.asar` using `asar`.

Important call order:

1. bundled `linux-fast-paste`
2. compositor-specific fallback list
3. `ydotool`/`wtype`/`xdotool`

Existing patch only moved `ydotool` before `wtype`. That change could not help while `linux-fast-paste` returned success first.

Bundled helper creates short-lived uinput dev per paste. Hyprland could miss modifier events while registering dev. Result: Ctrl lost → bare `v`; entire seq sometimes dropped → no input. `ydotoold` keeps virtual dev alive, avoiding registration race.

## Fixes tried

| Attempt | Result |
|---|---|
| Confirm clipboard text manually | Passed; transcription/copy path healthy |
| Move `ydotool` before `wtype` | Incomplete; bundled `linux-fast-paste` still ran first |
| Start package-provided user `ydotool.service` | Wrong svc for NixOS config; temporary svc later stopped |
| Use active system `ydotoold.service` | Correct backend; exposed stale group/socket access |
| Launch OpenWhispr with `sg ydotool` + `YDOTOOL_SOCKET` | Proved correct creds/socket; not yet persistent |
| Launch via transient user systemd svc | Failed: `setgroups: Operation not permitted` |
| Launch via old `hyprctl dispatch exec ...` syntax | Failed under end-4 Lua dispatcher |
| Launch via `hl.dsp.exec_cmd(...)` | Worked for temporary verification |
| Wrap with `${pkgs.shadow}/bin/sg` | Failed: `/nix/store` mounted `nosuid`; `sg` lacked setuid privilege |
| Build first new patch | Failed: `malformed patch`; corrected unified-diff hunk counts |
| Use `/run/wrappers/bin/sg` | Worked; NixOS setuid wrapper switched group correctly |
| Disable `linux-fast-paste` on Hyprland | Worked; paste routed through persistent `ydotoold` |

## Root causes

Two independent causes:

1. **Wrong input impl selected:** OpenWhispr preferred bundled short-lived uinput helper before patched fallback order. Hyprland dropped modifier/input events.
2. **Stale launch creds/env:** live desktop session lacked newly configured `ydotool` group + `YDOTOOL_SOCKET`. Normal app restart reintroduced socket failure until full relogin.

One Nix-specific implementation trap:

- Store binary `${pkgs.shadow}/bin/sg` cannot gain setuid privileges because `/nix/store` uses `nosuid`.
- NixOS security wrapper `/run/wrappers/bin/sg` must be used.

## Final solution

### 1. Skip bundled helper on Hyprland

OpenWhispr patch changes:

```js
const linuxFastPaste = isHyprland ? null : this.resolveLinuxFastPasteBinary();
```

Hyprland fallback order:

```js
candidates = [...ydotoolEntry, ...wtypeEntry, ...xdotoolEntry];
```

Result: persistent `ydotoold` handles paste first.

### 2. Harden every OpenWhispr launch

Nix wrapper:

```bash
export YDOTOOL_SOCKET=/run/ydotoold/socket
printf -v quoted_args ' %q' "$@"
exec /run/wrappers/bin/sg ydotool -c "exec OPENWHISPR_APP${quoted_args}"
```

Wrapper guarantees:

- explicit system socket
- fresh `ydotool` supplementary group from account DB
- safe arg forwarding via Bash `%q`
- no dependency on stale compositor env

### 3. Keep NixOS daemon/access config

Relevant system config enables:

- `programs.ydotool.enable = true`
- `hardware.uinput.enable = true`
- user membership in `ydotool` + `uinput`

## Verification

Build:

```bash
nix build --no-link \
  /home/aron/coding/nix-aron#nixosConfigurations.desk-main.config.system.build.toplevel
```

Runtime checks:

```bash
systemctl is-active ydotoold.service

grep '^Groups:' /proc/$OPENWHISPR_PID/status
tr '\0' '\n' </proc/$OPENWHISPR_PID/environ | grep '^YDOTOOL_SOCKET='

gdbus introspect --session \
  --dest com.openwhispr.App \
  --object-path /com/openwhispr/App
```

Expected:

- daemon: `active`
- OpenWhispr groups include `ydotool`
- env: `YDOTOOL_SOCKET=/run/ydotoold/socket`
- D-Bus methods include `Toggle()` + `Cancel()`
- dictation pastes full transcription

Final functional result: user confirmed fixed.

## Apply

```bash
sudo nixos-rebuild switch \
  --flake /home/aron/coding/nix-aron#desk-main
```

Full logout/login remains recommended after group changes. Wrapper makes OpenWhispr work before relogin.

## Rollback

Revert OpenWhispr patch/wrapper changes in `home/aron/packages.nix`, then rebuild:

```bash
sudo nixos-rebuild switch \
  --flake /home/aron/coding/nix-aron#desk-main
```
