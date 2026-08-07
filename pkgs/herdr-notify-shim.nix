{
  lib,
  writeShellApplication,
  libnotify,
  coreutils,
  jq,
  util-linux,
}:
writeShellApplication {
  name = "notify-send";
  runtimeInputs = [
    coreutils
    jq
    util-linux
  ];
  text = ''
    set -euo pipefail

    # herdr on Linux emits a bare `notify-send -- <title> <body>`: no D-Bus
    # actions, so a click on the toast has nothing to invoke. This shim sits
    # ahead of the real notify-send on herdr's PATH, re-emits the toast with a
    # "Focus" action, and on invoke jumps to the herdr workspace/tab that fired
    # it. Anything that is not a herdr agent toast passes through untouched.
    REAL=${libnotify}/bin/notify-send

    focus() {
      local ws_number="$1"
      local tab_label="$2"
      local herdr_bin hyprctl_bin ws_id tab_id

      herdr_bin="''${HERDR_BIN_PATH:-}"
      if [ ! -x "$herdr_bin" ]; then
        herdr_bin="$(command -v herdr || true)"
      fi
      [ -n "$herdr_bin" ] || return 0

      # focus takes ids, not numbers/labels, so resolve through the list APIs.
      ws_id="$("$herdr_bin" workspace list 2>/dev/null |
        jq -r --argjson n "$ws_number" \
          'first(.result.workspaces[] | select(.number == $n) | .workspace_id) // empty' ||
        true)"
      [ -n "$ws_id" ] || return 0
      "$herdr_bin" workspace focus "$ws_id" >/dev/null 2>&1 || true

      if [ -n "$tab_label" ]; then
        tab_id="$("$herdr_bin" tab list --workspace "$ws_id" 2>/dev/null |
          jq -r --arg l "$tab_label" \
            'first(.result.tabs[] | select(.label == $l) | .tab_id) // empty' ||
          true)"
        if [ -n "$tab_id" ]; then
          "$herdr_bin" tab focus "$tab_id" >/dev/null 2>&1 || true
        fi
      fi

      # herdr sets its own client window title, so the terminal hosting it is
      # addressable no matter which Hyprland workspace it currently sits on.
      hyprctl_bin="$(command -v hyprctl || true)"
      if [ -n "$hyprctl_bin" ]; then
        "$hyprctl_bin" dispatch focuswindow 'title:^herdr$' >/dev/null 2>&1 || true
      fi
    }

    # Detached second phase: `notify-send -A` implies --wait, and herdr blocks on
    # the child's exit status, so the actionable toast must outlive this call.
    if [ "''${1:-}" = "--herdr-await-action" ]; then
      chosen="$("$REAL" -a herdr -A default=Focus -- "$2" "$3" || true)"
      [ "$chosen" = "default" ] || exit 0
      focus "$4" "$5"
      exit 0
    fi

    if [ "$#" -ne 3 ] || [ "$1" != "--" ]; then
      exec "$REAL" "$@"
    fi

    # herdr agent toasts carry "<workspace label> · <workspace number>", plus
    # " · <tab label>" when that workspace has more than one tab. Anything else
    # (update banners, `herdr notification show`) is not addressable.
    body_re="^(.+) · ([0-9]+)( · (.+))?$"
    if [[ ! "$3" =~ $body_re ]]; then
      exec "$REAL" "$@"
    fi

    setsid -f "$0" --herdr-await-action "$2" "$3" \
      "''${BASH_REMATCH[2]}" "''${BASH_REMATCH[4]:-}" \
      </dev/null >/dev/null 2>&1
  '';
  meta = {
    description = "notify-send shim giving herdr toasts a click-to-focus action";
    license = lib.licenses.mit;
  };
}
