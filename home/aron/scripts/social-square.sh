# social-square — PNG, padded to 1:1 with transparent bars, lightly compressed
# Usage: social-square INPUT [-o OUTPUT] [--quality MIN-MAX]
# Examples: social-square photo.jpg
#           social-square photo.jpg -o ~/Pictures/post.png

set -euo pipefail

usage() {
  echo "Usage: social-square INPUT [-o OUTPUT] [--quality MIN-MAX]" >&2
  echo "  -o, --output OUTPUT   write to OUTPUT instead of <input>-square.png" >&2
  echo "  --quality MIN-MAX     pngquant quality range (default: 80-98)" >&2
  exit 1
}

[[ $# -ge 1 ]] || usage

IN=
OUT=
QUALITY=80-98

while [[ $# -gt 0 ]]; do
  case $1 in
    -o | --output)
      [[ $# -ge 2 ]] || usage
      OUT=$2
      shift 2
      ;;
    --quality)
      [[ $# -ge 2 ]] || usage
      QUALITY=$2
      shift 2
      ;;
    -h | --help) usage ;;
    -*)
      echo "error: unknown option $1" >&2
      usage
      ;;
    *)
      [[ -z $IN ]] || usage
      IN=$1
      shift
      ;;
  esac
done

[[ -n $IN ]] || usage
[[ -f $IN ]] || {
  echo "error: no such file: $IN" >&2
  exit 1
}

if [[ -z $OUT ]]; then
  base=$(basename -- "$IN")
  OUT="$(dirname -- "$IN")/${base%.*}-square.png"
fi
mkdir -p -- "$(dirname -- "$OUT")"

# [0] takes the first frame, so animated GIFs and layered files yield one image.
read -r w h < <(magick identify -format '%w %h\n' "${IN}[0]")
side=$((w > h ? w : h))

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# -auto-orient before -strip: EXIF rotation has to be baked in before the tag
# that describes it is dropped. PNG32 keeps the alpha channel the bars need.
magick "${IN}[0]" -auto-orient -strip \
  -background none -gravity center -extent "${side}x${side}" \
  "PNG32:$tmp/square.png"

# pngquant exits 99 when it cannot reach the quality floor; keep the lossless
# image in that case rather than shipping a visibly degraded one.
if pngquant --quality="$QUALITY" --speed 1 --strip --force \
  --output "$tmp/quant.png" -- "$tmp/square.png"; then
  mv "$tmp/quant.png" "$tmp/square.png"
fi

oxipng --quiet -o 4 --strip safe "$tmp/square.png"

mv "$tmp/square.png" "$OUT"
printf '%s (%dx%d, %s)\n' "$OUT" "$side" "$side" "$(du -h "$OUT" | cut -f1)"
