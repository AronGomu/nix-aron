# Fail loudly when bootloader entries land on the wrong disk's ESP.
#
# `nixos-rebuild boot` and `switch` both run the bootloader installer, and it
# writes into whatever is mounted at /boot. Build this host's *other* output
# from the running disk and the entries go to the RUNNING disk's ESP: the entry
# names the other disk's root while its `init=` points at a store path that
# exists only on this one. Booting it panics with no shell. That is the shape of
# the 2026-08-06 incident — see docs/migration/README.md.
#
# `switch` is not the only dangerous verb. `boot` moves no mounts, but it still
# installs bootloader entries, so it reaches the same broken end state.
#
# systemd-boot exposes no pre-install hook: extraInstallCommands runs AFTER the
# entries and loader.conf are written. This turns a silent brick into a loud
# failure with a printed recovery path. It cannot prevent the write.
{
  pkgs,
  expectedEspUuid,
  thisOutput,
}:
''
  esp_uuid="$(${pkgs.util-linux}/bin/findmnt -no UUID /boot || true)"
  if [ "$esp_uuid" != "${expectedEspUuid}" ]; then
    echo "" >&2
    echo "!!! WRONG ESP. ${thisOutput} entries were just written to /boot = UUID '$esp_uuid'," >&2
    echo "!!! but ${thisOutput} expects ${expectedEspUuid}." >&2
    echo "!!!" >&2
    echo "!!! This generation will NOT boot: its fstab names one disk's root while" >&2
    echo "!!! init= resolves in the other disk's store. DO NOT REBOOT yet." >&2
    echo "!!!" >&2
    # Best effort: point loader.conf back at the booted generation so a power
    # cut before manual recovery does not land on the bad entry. sed, not
    # `bootctl set-default` — that writes a persistent LoaderEntryDefault EFI
    # variable which would silently override every future rebuild.
    booted_n=""
    booted="$(${pkgs.coreutils}/bin/readlink -f /run/booted-system || true)"
    for gen in /nix/var/nix/profiles/system-*-link; do
      [ "$(${pkgs.coreutils}/bin/readlink -f "$gen" || true)" = "$booted" ] || continue
      n="''${gen//[!0-9]/}"
      if [ -n "$n" ] && [ -e "/boot/loader/entries/nixos-generation-$n.conf" ]; then
        # grep the postcondition rather than trusting sed's status: `sed -i`
        # exits 0 when it matched nothing, and a loader.conf with no `default`
        # line is precisely the state where systemd-boot falls back to the
        # highest-sorting entry — the bad one. Claiming success there would
        # tell the user to relax in the one case where the danger is real.
        if ${pkgs.gnused}/bin/sed -i "s|^default .*|default nixos-generation-$n.conf|" /boot/loader/loader.conf \
          && ${pkgs.gnugrep}/bin/grep -qx "default nixos-generation-$n.conf" /boot/loader/loader.conf; then
          # FAT has no journal and sed -i is write-temp-then-rename; flush so the
          # window where loader.conf could be absent is as short as possible.
          ${pkgs.coreutils}/bin/sync -f /boot/loader/loader.conf 2>/dev/null || true
          echo "!!! loader.conf default reset to nixos-generation-$n.conf (the booted one)," >&2
          echo "!!! so an unexpected power loss will not boot the bad entry. Still clean up:" >&2
          booted_n="$n"
        fi
      fi
      break
    done

    if [ -n "$booted_n" ]; then
      echo "!!! Recover ($booted_n is the generation you are booted from; replace" >&2
      echo "!!! <bad> with the generation number this failed rebuild just created):" >&2
      echo "!!!   sudo nix-env -p /nix/var/nix/profiles/system --switch-generation $booted_n" >&2
      echo '!!!   sudo nix-env -p /nix/var/nix/profiles/system --delete-generations <bad>' >&2
    else
      echo "!!! Recover. N = the generation you are BOOTED from. In 'bootctl list'" >&2
      echo "!!! that is the entry marked (selected) — do NOT read the (default)" >&2
      echo "!!! line, because in this state (default) is the bad generation." >&2
      echo '!!!   sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <N>' >&2
      echo '!!!   sudo nix-env -p /nix/var/nix/profiles/system --delete-generations <bad>' >&2
    fi
    echo '!!!   sudo /run/current-system/bin/switch-to-configuration boot' >&2
    echo "!!!" >&2
    echo "!!! The profile step is required: nixos-rebuild sets the system profile" >&2
    echo "!!! BEFORE running this installer, so it already points at this bad" >&2
    echo "!!! generation. The final command rewrites loader.conf from the good" >&2
    echo "!!! generation and drops the bad entry from the ESP." >&2
    echo '!!! Then rebuild for the running disk:  --flake .#$(nixos-host)' >&2
    echo "" >&2
    exit 1
  fi
''
