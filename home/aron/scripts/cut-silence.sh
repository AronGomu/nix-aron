# cut-silence — remove silence stretches longer than MAX_SEC from video
# Usage: cut-silence <input> <output> <max_silence_sec> [noise_db] [options]
# Example: cut-silence talk.mp4 talk-tight.mp4 1.5
#          cut-silence talk.mp4 talk-tight.mp4 1.5 -40dB
#          cut-silence talk.mp4 talk-tight.mp4 1.5 --keep-silence 0.300 --audio-fade 0.008

set -euo pipefail

usage() {
  echo "Usage: cut-silence <input> <output> <max_silence_sec> [noise_db] [options]" >&2
  echo "  max_silence_sec  drop any silence longer than this (e.g. 1.5)" >&2
  echo "  noise_db         silence threshold (default: -40dB)" >&2
  echo "  --keep-silence SEC  retain SEC total silence around each cut" >&2
  echo "  --audio-fade SEC    fade audio at joins inside retained silence" >&2
  echo "  --transcript-json FILE  protect transcript word intervals" >&2
  echo "  --word-padding SEC  pad protected words (default: 0.080 with transcript)" >&2
  echo "  --cut-map FILE      write JSON cut timeline" >&2
  exit 1
}

[[ $# -ge 3 ]] || usage

IN=$1
OUT=$2
MAX_SEC=$3
shift 3

NOISE=-40dB
KEEP_SILENCE=0
AUDIO_FADE=0
TRANSCRIPT_JSON=
WORD_PADDING=
CUT_MAP=
LEGACY_MODE=1

if [[ $# -gt 0 && $1 != --* ]]; then
  NOISE=$1
  shift
fi

validate_seconds() {
  local option=$1 value=$2
  if ! python3 - "$value" <<'PY'
import math
import sys

try:
    value = float(sys.argv[1])
except ValueError:
    raise SystemExit(1)
raise SystemExit(0 if math.isfinite(value) and value >= 0 else 1)
PY
  then
    echo "error: $option must be finite non-negative seconds" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --keep-silence|--audio-fade|--word-padding)
      option=$1
      [[ $# -ge 2 && $2 != --* ]] || { echo "error: $option requires SEC" >&2; exit 1; }
      validate_seconds "$option" "$2"
      if [[ $option == --keep-silence ]]; then
        KEEP_SILENCE=$2
      elif [[ $option == --audio-fade ]]; then
        AUDIO_FADE=$2
      else
        WORD_PADDING=$2
      fi
      LEGACY_MODE=0
      shift 2
      ;;
    --transcript-json)
      [[ $# -ge 2 && $2 != --* ]] || { echo "error: --transcript-json requires FILE" >&2; exit 1; }
      TRANSCRIPT_JSON=$2
      LEGACY_MODE=0
      shift 2
      ;;
    --cut-map)
      [[ $# -ge 2 && $2 != --* ]] || { echo "error: --cut-map requires FILE" >&2; exit 1; }
      CUT_MAP=$2
      LEGACY_MODE=0
      shift 2
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage
      ;;
  esac
done

[[ -f "$IN" ]] || { echo "error: input not found: $IN" >&2; exit 1; }
[[ "$MAX_SEC" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "error: max_silence_sec must be number" >&2; exit 1; }
if [[ -n $TRANSCRIPT_JSON ]]; then
  [[ -f $TRANSCRIPT_JSON ]] || { echo "error: transcript not found: $TRANSCRIPT_JSON" >&2; exit 1; }
  WORD_PADDING=${WORD_PADDING:-0.080}
elif [[ -n $WORD_PADDING ]]; then
  echo "error: --word-padding requires --transcript-json" >&2
  exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo "==> probe duration"
DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$IN")
echo "    ${DUR}s"

echo "==> detect silence >= ${MAX_SEC}s (noise=${NOISE})"
ffmpeg -hide_banner -nostats -i "$IN" \
  -af "silencedetect=noise=${NOISE}:d=${MAX_SEC}" \
  -f null - 2>"$TMP/detect.log" || true

python3 - "$TMP" "$DUR" "$KEEP_SILENCE" "$AUDIO_FADE" "$CUT_MAP" "$LEGACY_MODE" "$TRANSCRIPT_JSON" "$WORD_PADDING" <<'PY'
import json
import math
import re
import sys
from pathlib import Path

tmp = Path(sys.argv[1])
duration = float(sys.argv[2])
keep_silence = float(sys.argv[3])
audio_fade = float(sys.argv[4])
cut_map = sys.argv[5]
legacy_mode = sys.argv[6] == "1"
transcript_json = sys.argv[7]
word_padding = float(sys.argv[8]) if transcript_json else None


def transcript_error(message):
    print(f"error: invalid transcript JSON: {message}", file=sys.stderr)
    sys.exit(2)


transcript_model = None
words = []
if transcript_json:
    try:
        transcript = json.loads(Path(transcript_json).read_text())
    except (OSError, UnicodeError, json.JSONDecodeError) as error:
        transcript_error(str(error))
    if not isinstance(transcript, dict):
        transcript_error("root must be an object")
    transcript_model = transcript.get("model")
    if not isinstance(transcript_model, str) or not transcript_model:
        transcript_error("model must be a non-empty string")
    raw_words = transcript.get("words")
    if not isinstance(raw_words, list):
        transcript_error("words must be an array")
    previous_start = None
    for index, raw_word in enumerate(raw_words):
        if not isinstance(raw_word, dict):
            transcript_error(f"words[{index}] must be an object")
        if not isinstance(raw_word.get("word"), str):
            transcript_error(f"words[{index}].word must be a string")
        start = raw_word.get("start")
        end = raw_word.get("end")
        if (isinstance(start, bool) or not isinstance(start, (int, float)) or
                isinstance(end, bool) or not isinstance(end, (int, float))):
            transcript_error(f"words[{index}] timestamps must be numbers")
        start = float(start)
        end = float(end)
        if not math.isfinite(start) or not math.isfinite(end):
            transcript_error(f"words[{index}] timestamps must be finite")
        if start < 0 or end < 0 or end < start:
            transcript_error(f"words[{index}] timestamps must satisfy 0 <= start <= end")
        if previous_start is not None and start < previous_start:
            transcript_error("words must be sorted by start timestamp")
        words.append({"start": start, "end": end, "word": raw_word["word"]})
        previous_start = start

protected_words = [
    (max(0.0, word["start"] - word_padding), word["end"] + word_padding, word)
    for word in words
]
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

def intervals_overlap(start_a, end_a, start_b, end_b):
    epsilon = 0.001
    return start_a <= end_b + epsilon and end_a >= start_b - epsilon


min_keep = 0.05
cuts = []
decisions = []
removed_before = 0.0
for s, e in pairs:
    handle = 0.0 if legacy_mode else keep_silence / 2
    remove_start = s + handle
    remove_end = e - handle
    remove_duration = remove_end - remove_start
    if remove_duration <= 0 or (not legacy_mode and remove_duration <= min_keep):
        continue
    matching_words = [
        word for protected_start, protected_end, word in protected_words
        if intervals_overlap(remove_start, remove_end, protected_start, protected_end)
    ]
    decision = {
        "source_interval": [s, e],
        "proposed_removed_interval": [remove_start, remove_end],
        "decision": "vetoed" if matching_words else "accepted",
        "reason": (
            "word_overlap" if matching_words else
            "no_word_overlap" if transcript_json else
            "transcript_not_provided"
        ),
        "matching_words": matching_words,
    }
    decisions.append(decision)
    if matching_words:
        continue
    cuts.append({
        "source_start": s,
        "source_end": e,
        "remove_start": remove_start,
        "remove_end": remove_end,
        "handle": handle,
        "output_offset": remove_start - removed_before,
    })
    removed_before += remove_duration

keeps = []
t = 0.0
for cut in cuts:
    end_keep = max(t, cut["remove_start"])
    if end_keep - t > min_keep:
        keeps.append((t, end_keep))
    t = cut["remove_end"]
if duration - t > min_keep:
    keeps.append((t, duration))

if not keeps:
    print("error: nothing left after silence cut", file=sys.stderr)
    sys.exit(2)

keep_dur = sum(b - a for a, b in keeps)
sil_dur = sum(b - a for a, b in pairs)
print(f"    silence periods: {len(pairs)} ({sil_dur:.2f}s)")
print(f"    keep segments:   {len(keeps)} ({keep_dur:.2f}s / {duration:.2f}s)")

if cut_map:
    mapped_cuts = []
    for cut in cuts:
        s = cut["source_start"]
        e = cut["source_end"]
        remove_start = cut["remove_start"]
        remove_end = cut["remove_end"]
        mapped_cuts.append({
            "source_interval": [s, e],
            "removed_interval": [remove_start, remove_end],
            "retained_handles": {
                "before": [s, remove_start],
                "after": [remove_end, e],
            },
            "output_offset": cut["output_offset"],
        })
    map_data = {
        "source_duration": duration,
        "output_duration": keep_dur,
        "keep_silence": keep_silence,
        "audio_fade": audio_fade,
        "cuts": mapped_cuts,
    }
    if transcript_json:
        map_data.update({
            "transcript_model": transcript_model,
            "word_padding": word_padding,
            "decisions": decisions,
        })
    Path(cut_map).write_text(json.dumps(map_data, indent=2, sort_keys=True) + "\n")

if not cuts:
    (tmp / "nosilence").write_text("1")
    sys.exit(0)

parts_v, parts_a, fc = [], [], []
for i, (a, b) in enumerate(keeps):
    segment_duration = b - a
    fc.append(f"[0:v]trim=start={a}:end={b},setpts=PTS-STARTPTS[v{i}]")

    audio_filters = [f"[0:a]atrim=start={a}:end={b}", "asetpts=PTS-STARTPTS"]
    start_handle = next((cut["handle"] for cut in cuts if cut["remove_end"] == a), 0.0)
    end_handle = next((cut["handle"] for cut in cuts if cut["remove_start"] == b), 0.0)
    fade_in = min(audio_fade, start_handle, segment_duration)
    fade_out = min(audio_fade, end_handle, segment_duration)
    if fade_in > 0:
        audio_filters.append(f"afade=t=in:st=0:d={fade_in}")
    if fade_out > 0:
        audio_filters.append(f"afade=t=out:st={segment_duration - fade_out}:d={fade_out}")
    fc.append(",".join(audio_filters) + f"[a{i}]")

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
