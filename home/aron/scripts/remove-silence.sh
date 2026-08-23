# remove-silence — auto-editor wrapper with pinned defaults
# Usage: remove-silence INPUT [-o OUTPUT] [extra auto-editor flags...]
# INPUT must come first. Any auto-editor flag passed after it is appended
# last, and auto-editor honours the last occurrence of a flag, so anything
# below can be overridden per invocation:
#   remove-silence talk.mov --margin 0.5sec,0.5sec --video-bitrate 20M

set -euo pipefail

# Defaults. Edit here for a permanent change (needs a rebuild), or drop the
# same assignments into ~/.config/remove-silence.conf to retune without one.
RS_THRESHOLD="0.014" # linear peak fraction, ~-37dB
RS_STREAM="all"
RS_MARGIN="0.15sec,0.15sec" # 0.3s of retained breathing room per cut
RS_WHEN_NORMAL="nil"
RS_WHEN_SILENT="cut"
RS_EXPORT="default"
RS_VIDEO_CODEC="libx264"
RS_VIDEO_BITRATE="8000k"
RS_AUDIO_CODEC="aac"
RS_AUDIO_BITRATE="192k"
RS_PROGRESS="modern"
RS_SUFFIX="-nosilence"

RS_CONFIG=${RS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/remove-silence.conf}
# shellcheck source=/dev/null
[[ -f $RS_CONFIG ]] && source "$RS_CONFIG"

usage() {
  echo "Usage: remove-silence INPUT [-o OUTPUT] [extra auto-editor flags...]" >&2
  echo "  INPUT must be the first argument" >&2
  echo "  -o, --output OUTPUT  default: sibling <stem>${RS_SUFFIX}<ext>" >&2
  echo "  defaults live in this script and in $RS_CONFIG" >&2
  echo "  any trailing auto-editor flag overrides the matching default" >&2
  exit 1
}

[[ $# -ge 1 ]] || usage

IN=$1
shift
[[ -f $IN ]] || {
  echo "error: input not found: $IN" >&2
  exit 1
}

OUT=
EXTRA=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -o | --output)
      [[ $# -ge 2 ]] || {
        echo "error: $1 needs a path" >&2
        exit 1
      }
      OUT=$2
      shift 2
      ;;
    *)
      EXTRA+=("$1")
      shift
      ;;
  esac
done

if [[ -z $OUT ]]; then
  case $IN in
    *.*) OUT="${IN%.*}${RS_SUFFIX}.${IN##*.}" ;;
    *) OUT="${IN}${RS_SUFFIX}" ;;
  esac
fi

[[ -e $OUT ]] && {
  echo "error: output exists, pass -o to pick another path: $OUT" >&2
  exit 1
}

exec auto-editor "$IN" \
  --edit "audio:threshold=${RS_THRESHOLD},stream=${RS_STREAM}" \
  --margin "$RS_MARGIN" \
  --when-normal "$RS_WHEN_NORMAL" \
  --when-silent "$RS_WHEN_SILENT" \
  --export "$RS_EXPORT" \
  --video-codec "$RS_VIDEO_CODEC" \
  --video-bitrate "$RS_VIDEO_BITRATE" \
  --audio-codec "$RS_AUDIO_CODEC" \
  --audio-bitrate "$RS_AUDIO_BITRATE" \
  --no-faststart \
  --no-open \
  --progress "$RS_PROGRESS" \
  --output "$OUT" \
  ${EXTRA[@]+"${EXTRA[@]}"}
