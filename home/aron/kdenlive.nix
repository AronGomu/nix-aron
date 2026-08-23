{ pkgs, lib, ... }:
let
  # Kdenlive's Speech-to-Text runs out of a pip venv it builds itself in
  # ~/.local/share/kdenlive/venv, so those wheels are plain manylinux binaries
  # that expect a distro loader path. vosk dies at import with
  # "libvosk.so: libstdc++.so.6: cannot open shared object file", and torch
  # reports cuda unavailable without libcuda.so.1. Both are resolved from the
  # process environment, which the venv python inherits from kdenlive.
  # gcc-lib here is the very same store path kdenlive itself links against, so
  # nothing else in the process can pick up a mismatched libstdc++.
  kdenlive = pkgs.symlinkJoin {
    name = "kdenlive-wrapped";
    paths = [ pkgs.kdePackages.kdenlive ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/kdenlive \
        --suffix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]
        }:/run/opengl-driver/lib"
    '';
  };
in
{
  home.packages = [ kdenlive ];

  # kdenliverc also holds recent files, dock layout and window state, so a
  # read-only Nix-store symlink would stop Kdenlive saving any of it. Seed the
  # keys in place instead.
  home.activation.kdenliveDefaults = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    kreadconfig=${pkgs.kdePackages.kconfig}/bin/kreadconfig6
    kwriteconfig=${pkgs.kdePackages.kconfig}/bin/kwriteconfig6

    # KColorSchemeManager keys schemes by the .colors basename since KF 6.16.
    # kdeglobals cascades into this group, so the per-app entry is what pins
    # Kdenlive to dark regardless of the platform theme.
    $DRY_RUN_CMD "$kwriteconfig" --file kdenliverc --group UiSettings \
      --key ColorScheme BreezeDark

    # Kdenlive discovers VOSK models by scanning this folder for mfcc.conf;
    # pinning it keeps both models visible even if the XDG data lookup shifts.
    $DRY_RUN_CMD "$kwriteconfig" --file kdenliverc --group speech \
      --key vosk_folder_path "$HOME/.local/share/kdenlive/speechmodels"

    # vosk_text_model (speech to text) and vosk_srt_model (auto subtitles) each
    # hold a single model name, so only seed them when unset or pointing at a
    # model that is not installed — switching language in the UI must stick.
    for key in vosk_text_model vosk_srt_model; do
      current=$("$kreadconfig" --file kdenliverc --group speech --key "$key" 2>/dev/null || true)
      case "$current" in
        vosk-model-fr-0.22 | vosk-model-en-us-0.42-gigaspeech) ;;
        *)
          $DRY_RUN_CMD "$kwriteconfig" --file kdenliverc --group speech \
            --key "$key" vosk-model-fr-0.22
          ;;
      esac
    done

    # Whisper weights live in ~/.cache/whisper; turbo is large-v3-turbo.pt.
    if [ -z "$("$kreadconfig" --file kdenliverc --group speech --key whisperModel 2>/dev/null || true)" ]; then
      $DRY_RUN_CMD "$kwriteconfig" --file kdenliverc --group speech \
        --key whisperModel turbo
    fi
  '';
}
