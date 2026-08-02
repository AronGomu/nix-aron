#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
CUT_SILENCE="$ROOT/home/aron/scripts/cut-silence.sh"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

pass_count=0

pass() {
  echo "ok - $1"
  pass_count=$((pass_count + 1))
}

fail() {
  echo "not ok - $1: $2" >&2
  exit 1
}

duration() {
  ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$1"
}

assert_close() {
  local actual=$1 expected=$2 tolerance=$3 message=$4
  python3 - "$actual" "$expected" "$tolerance" "$message" <<'PY'
import sys
actual, expected, tolerance = map(float, sys.argv[1:4])
if abs(actual - expected) > tolerance:
    raise SystemExit(f"{sys.argv[4]}: {actual:.6f} not within {tolerance:.6f} of {expected:.6f}")
PY
}

make_fixture() {
  local output=$1 silence_duration=$2 gaps=${3:-1} quiet_volume=${4:-0}
  local filter="sine=frequency=440:sample_rate=48000:duration=1[t0]"
  local concat="[t0]"
  local total=1
  local i
  for ((i = 0; i < gaps; i++)); do
    if [[ $quiet_volume == 0 ]]; then
      filter+=";anullsrc=r=48000:cl=mono:d=${silence_duration}[s${i}]"
    else
      filter+=";sine=frequency=220:sample_rate=48000:duration=${silence_duration},volume=${quiet_volume}[s${i}]"
    fi
    filter+=";sine=frequency=$((550 + i * 110)):sample_rate=48000:duration=1[t$((i + 1))]"
    concat+="[s${i}][t$((i + 1))]"
    total=$(python3 - "$total" "$silence_duration" <<'PY'
import sys
print(float(sys.argv[1]) + float(sys.argv[2]) + 1)
PY
)
  done
  filter+=";${concat}concat=n=$((gaps * 2 + 1)):v=0:a=1[a]"

  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "color=c=black:s=160x90:r=25:d=${total}" \
    -filter_complex "$filter" -map 0:v -map '[a]' \
    -c:v libx264 -preset ultrafast -crf 30 -pix_fmt yuv420p \
    -c:a aac -b:a 128k -shortest "$output"
}

legacy_invocation_removes_full_detected_silence() {
  local input="$TMP/legacy-input.mp4" output="$TMP/legacy-output.mp4" default_output="$TMP/legacy-default-output.mp4"
  make_fixture "$input" 1
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB >"$TMP/legacy.log" 2>&1
  assert_close "$(duration "$output")" 2.027 0.040 "legacy output duration"
  bash "$CUT_SILENCE" "$input" "$default_output" 0.45 >"$TMP/legacy-default.log" 2>&1
  assert_close "$(duration "$default_output")" "$(duration "$output")" 0.040 "default-noise legacy duration"
  pass "legacy_invocation_removes_full_detected_silence"
}

keep_silence_retains_requested_total_gap() {
  local input="$TMP/keep-input.mp4" output="$TMP/keep-output.mp4"
  make_fixture "$input" 1
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 >"$TMP/keep.log" 2>&1
  assert_close "$(duration "$output")" 2.327 0.040 "retained-gap output duration"
  pass "keep_silence_retains_requested_total_gap"
}

audio_fade_preserves_expected_duration() {
  local input="$TMP/fade-input.mp4" plain="$TMP/fade-plain.mp4" faded="$TMP/fade-output.mp4"
  make_fixture "$input" 1 1 0.01
  bash "$CUT_SILENCE" "$input" "$plain" 0.45 -35dB \
    --keep-silence 0.300 >"$TMP/fade-plain.log" 2>&1
  bash "$CUT_SILENCE" "$input" "$faded" 0.45 -35dB \
    --keep-silence 0.300 --audio-fade 0.008 >"$TMP/fade.log" 2>&1
  assert_close "$(duration "$faded")" "$(duration "$plain")" 0.025 "fade changed duration"

  ffmpeg -hide_banner -loglevel error -y -i "$faded" -map 0:a:0 \
    -ac 1 -ar 48000 -c:a pcm_s16le "$TMP/faded.wav"
  python3 - "$TMP/faded.wav" <<'PY'
import struct
import sys
import wave

with wave.open(sys.argv[1], "rb") as wav:
    rate = wav.getframerate()
    samples = struct.unpack("<" + "h" * wav.getnframes(), wav.readframes(wav.getnframes()))

def mean_abs(start, end):
    values = samples[int(start * rate):int(end * rate)]
    return sum(abs(value) for value in values) / len(values)

near = (mean_abs(1.146, 1.150) + mean_abs(1.150, 1.154)) / 2
far = (mean_abs(1.125, 1.133) + mean_abs(1.167, 1.175)) / 2
if not near < far * 0.80:
    raise SystemExit(f"fade ramp not visible at join: near={near:.8f}, far={far:.8f}")
PY
  pass "audio_fade_preserves_expected_duration"
}

short_gap_is_not_cut() {
  local input="$TMP/short-input.mp4" output="$TMP/short-output.mp4"
  make_fixture "$input" 0.2
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 >"$TMP/short.log" 2>&1
  assert_close "$(duration "$output")" "$(duration "$input")" 0.001 "short gap was cut"
  pass "short_gap_is_not_cut"
}

invalid_new_flag_fails_without_output() {
  local input="$TMP/invalid-input.mp4" output value option expected log
  make_fixture "$input" 1
  for case in '--keep-silence NaN' '--keep-silence -0.1' '--audio-fade Infinity'; do
    read -r option value <<<"$case"
    output="$TMP/invalid-${option#--}-${value}.mp4"
    log="$TMP/invalid-${option#--}-${value}.log"
    if bash "$CUT_SILENCE" "$input" "$output" 0.45 "$option" "$value" >"$log" 2>&1; then
      fail "invalid_new_flag_fails_without_output" "$option $value succeeded"
    fi
    [[ ! -e $output ]] || fail "invalid_new_flag_fails_without_output" "output created for $option $value"
    expected="error: $option must be finite non-negative seconds"
    grep -Fxq "$expected" "$log" || \
      fail "invalid_new_flag_fails_without_output" "unexpected $option $value error"
  done

  output="$TMP/invalid-missing.mp4"
  if bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB --audio-fade \
    >"$TMP/invalid-missing.log" 2>&1; then
    fail "invalid_new_flag_fails_without_output" "missing value succeeded"
  fi
  [[ ! -e $output ]] || fail "invalid_new_flag_fails_without_output" "output created for missing value"
  grep -Fxq 'error: --audio-fade requires SEC' "$TMP/invalid-missing.log" || \
    fail "invalid_new_flag_fails_without_output" "unexpected missing-value error"
  pass "invalid_new_flag_fails_without_output"
}

cut_map_matches_rendered_duration() {
  local input="$TMP/map-input.mp4" output="$TMP/map-output.mp4" map="$TMP/cut-map.json"
  make_fixture "$input" 1 2
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 --audio-fade 0.008 --cut-map "$map" >"$TMP/map.log" 2>&1
  local streams
  streams=$(ffprobe -v error -show_entries stream=codec_type -of csv=p=0 "$output")
  [[ $(grep -c '^video$' <<<"$streams") -eq 1 ]] || fail "cut_map_matches_rendered_duration" "expected one video stream"
  [[ $(grep -c '^audio$' <<<"$streams") -eq 1 ]] || fail "cut_map_matches_rendered_duration" "expected one audio stream"
  python3 - "$map" "$(duration "$input")" "$(duration "$output")" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
source_duration = float(sys.argv[2])
rendered_duration = float(sys.argv[3])
data = json.loads(path.read_text())
cuts = data["cuts"]
if len(cuts) != 2:
    raise SystemExit(f"expected 2 cuts, got {len(cuts)}")
removed = sum(cut["removed_interval"][1] - cut["removed_interval"][0] for cut in cuts)
expected = source_duration - removed
if abs(rendered_duration - expected) > 0.040:
    raise SystemExit(f"rendered duration {rendered_duration:.6f} != mapped {expected:.6f}")
if abs(data["output_duration"] - expected) > 1e-6:
    raise SystemExit("map output_duration does not match intervals")
removed_before = 0.0
for cut in cuts:
    before = cut["retained_handles"]["before"]
    after = cut["retained_handles"]["after"]
    retained = (before[1] - before[0]) + (after[1] - after[0])
    if abs(retained - 0.300) > 1e-6:
        raise SystemExit(f"retained handles total {retained:.6f}, expected 0.300")
    expected_offset = cut["removed_interval"][0] - removed_before
    if abs(cut["output_offset"] - expected_offset) > 1e-6:
        raise SystemExit("output_offset does not match rendered join")
    removed_before += cut["removed_interval"][1] - cut["removed_interval"][0]
PY
  pass "cut_map_matches_rendered_duration"
}

legacy_invocation_removes_full_detected_silence
keep_silence_retains_requested_total_gap
audio_fade_preserves_expected_duration
short_gap_is_not_cut
invalid_new_flag_fails_without_output
cut_map_matches_rendered_duration

echo "1..$pass_count"
