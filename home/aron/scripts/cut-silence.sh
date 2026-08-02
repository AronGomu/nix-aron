# cut-silence — remove silence stretches longer than MAX_SEC from video
# Usage: cut-silence <input> <output> <max_silence_sec> [noise_db]
# Example: cut-silence talk.mp4 talk-tight.mp4 1.5
#          cut-silence talk.mp4 talk-tight.mp4 1.5 -40dB

set -euo pipefail

usage() {
  echo "Usage: cut-silence <input> <output> <max_silence_sec> [noise_db]" >&2
  echo "  max_silence_sec  drop any silence longer than this (e.g. 1.5)" >&2
  echo "  noise_db         silence threshold (default: -40dB)" >&2
  exit 1
}

[[ $# -ge 3 && $# -le 4 ]] || usage

IN=$1
OUT=$2
MAX_SEC=$3
NOISE=${4:--40dB}

[[ -f "$IN" ]] || { echo "error: input not found: $IN" >&2; exit 1; }
[[ "$MAX_SEC" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "error: max_silence_sec must be number" >&2; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "==> probe duration"
DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$IN")
echo "    ${DUR}s"

echo "==> detect silence >= ${MAX_SEC}s (noise=${NOISE})"
ffmpeg -hide_banner -nostats -i "$IN" \
  -af "silencedetect=noise=${NOISE}:d=${MAX_SEC}" \
  -f null - 2>"$TMP/detect.log" || true

python3 - "$TMP" "$DUR" <<'PY'
import re, sys
from pathlib import Path

tmp = Path(sys.argv[1])
duration = float(sys.argv[2])
log = (tmp / "detect.log").read_text(errors="replace")

starts = [float(x) for x in re.findall(r"silence_start:\s*([0-9.]+)", log)]
ends = [float(x) for x in re.findall(r"silence_end:\s*([0-9.]+)", log)]

pairs = []
i_e = 0
for s in starts:
    while i_e < len(ends) and ends[i_e] <= s:
        i_e += 1
    if i_e < len(ends):
        pairs.append((s, ends[i_e]))
        i_e += 1
    else:
        pairs.append((s, duration))

keeps = []
t = 0.0
min_keep = 0.05
for s, e in pairs:
    end_keep = max(t, s)
    if end_keep - t > min_keep:
        keeps.append((t, end_keep))
    t = e
if duration - t > min_keep:
    keeps.append((t, duration))

if not keeps:
    print("error: nothing left after silence cut", file=sys.stderr)
    sys.exit(2)

keep_dur = sum(b - a for a, b in keeps)
sil_dur = sum(b - a for a, b in pairs)
print(f"    silence periods: {len(pairs)} ({sil_dur:.2f}s)")
print(f"    keep segments:   {len(keeps)} ({keep_dur:.2f}s / {duration:.2f}s)")

if not pairs:
    (tmp / "nosilence").write_text("1")
    sys.exit(0)

parts_v, parts_a, fc = [], [], []
for i, (a, b) in enumerate(keeps):
    fc.append(f"[0:v]trim=start={a}:end={b},setpts=PTS-STARTPTS[v{i}]")
    fc.append(f"[0:a]atrim=start={a}:end={b},asetpts=PTS-STARTPTS[a{i}]")
    parts_v.append(f"[v{i}]")
    parts_a.append(f"[a{i}]")
n = len(keeps)
fc.append("".join(parts_v) + f"concat=n={n}:v=1:a=0[vout]")
fc.append("".join(parts_a) + f"concat=n={n}:v=0:a=1[aout]")
(tmp / "fc.txt").write_text(";\n".join(fc))
PY

if [[ -f "$TMP/nosilence" ]]; then
  echo "==> no silence over ${MAX_SEC}s — stream copy"
  ffmpeg -hide_banner -y -i "$IN" -c copy "$OUT"
else
  echo "==> encode → $OUT"
  ffmpeg -hide_banner -y -i "$IN" \
    -filter_complex_script "$TMP/fc.txt" \
    -map "[vout]" -map "[aout]" \
    -c:v libx264 -preset veryfast -crf 18 \
    -c:a aac -b:a 192k \
    "$OUT"
fi

OUT_DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")
echo "==> done: $OUT (${OUT_DUR}s)"
