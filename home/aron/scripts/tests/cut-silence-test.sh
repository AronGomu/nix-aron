#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
CUT_SILENCE="$ROOT/home/aron/scripts/cut-silence.sh"
FIXTURES="$ROOT/home/aron/scripts/tests/fixtures"
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

make_edge_fixture() {
  local output=$1 position=$2 total=2 filter
  case $position in
    leading)
      filter='anullsrc=r=48000:cl=mono:d=1[s];sine=frequency=440:sample_rate=48000:duration=1[t];[s][t]concat=n=2:v=0:a=1[a]'
      ;;
    trailing)
      filter='sine=frequency=440:sample_rate=48000:duration=1[t];anullsrc=r=48000:cl=mono:d=1[s];[t][s]concat=n=2:v=0:a=1[a]'
      ;;
    all)
      total=1
      filter='anullsrc=r=48000:cl=mono:d=1[a]'
      ;;
    *) fail "make_edge_fixture" "unknown position: $position" ;;
  esac
  ffmpeg -hide_banner -loglevel error -y \
    -f lavfi -i "color=c=black:s=160x90:r=25:d=${total}" \
    -filter_complex "$filter" -map 0:v -map '[a]' \
    -c:v libx264 -preset ultrafast -crf 30 -pix_fmt yuv420p \
    -c:a aac -b:a 128k -shortest "$output"
}

legacy_invocation_removes_full_detected_silence() {
  local input="$TMP/legacy-input.mp4" output="$TMP/legacy-output.mp4"
  local default_output="$TMP/legacy-default-output.mp4" amplitude_output="$TMP/legacy-amplitude-output.mp4"
  make_fixture "$input" 1
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB >"$TMP/legacy.log" 2>&1
  assert_close "$(duration "$output")" 2.027 0.040 "legacy output duration"
  bash "$CUT_SILENCE" "$input" "$default_output" 0.45 >"$TMP/legacy-default.log" 2>&1
  assert_close "$(duration "$default_output")" "$(duration "$output")" 0.040 "default-noise legacy duration"
  bash "$CUT_SILENCE" "$input" "$amplitude_output" 0.45 0.0178 >"$TMP/legacy-amplitude.log" 2>&1
  assert_close "$(duration "$amplitude_output")" "$(duration "$output")" 0.040 "numeric-amplitude legacy duration"
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

word_inside_silence_vetoes_cut() {
  local input="$TMP/inside-input.mp4" output="$TMP/inside-output.mp4"
  make_fixture "$input" 1
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 \
    --transcript-json "$FIXTURES/transcript-word-in-gap.json" >"$TMP/inside.log" 2>&1
  assert_close "$(duration "$output")" "$(duration "$input")" 0.001 "word-overlap cut was not vetoed"
  pass "word_inside_silence_vetoes_cut"
}

word_padding_vetoes_near_boundary_cut() {
  local input="$TMP/padding-input.mp4" output="$TMP/padding-output.mp4"
  make_fixture "$input" 1
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 \
    --transcript-json "$FIXTURES/transcript-word-near-gap.json" >"$TMP/padding.log" 2>&1
  assert_close "$(duration "$output")" "$(duration "$input")" 0.001 "padded word-overlap cut was not vetoed"
  pass "word_padding_vetoes_near_boundary_cut"
}

word_outside_silence_allows_cut() {
  local input="$TMP/outside-input.mp4" output="$TMP/outside-output.mp4"
  make_fixture "$input" 1
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 \
    --transcript-json "$FIXTURES/transcript-word-outside-gap.json" >"$TMP/outside.log" 2>&1
  assert_close "$(duration "$output")" 2.327 0.040 "outside word vetoed cut"
  pass "word_outside_silence_allows_cut"
}

transcript_absent_keeps_t1_behavior() {
  local input="$TMP/absent-input.mp4" output="$TMP/absent-output.mp4" map="$TMP/absent-map.json"
  make_fixture "$input" 1
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 --audio-fade 0.008 \
    --cut-map "$map" >"$TMP/absent.log" 2>&1
  assert_close "$(duration "$output")" 2.327 0.040 "transcript-absent output changed"
  python3 - "$map" <<'PY'
import json
import sys
from pathlib import Path

keys = set(json.loads(Path(sys.argv[1]).read_text()))
expected = {"source_duration", "output_duration", "keep_silence", "audio_fade", "cuts"}
if keys != expected:
    raise SystemExit(f"transcript-absent cut-map schema changed: {sorted(keys)!r}")
PY
  pass "transcript_absent_keeps_t1_behavior"
}

malformed_transcript_fails_before_encode() {
  local input="$TMP/malformed-input.mp4" output fixture log
  make_fixture "$input" 1
  for fixture in \
    transcript-malformed-missing-end.json \
    transcript-negative.json \
    transcript-unsorted.json \
    transcript-nonfinite.json; do
    output="$TMP/${fixture%.json}-output.mp4"
    log="$TMP/${fixture%.json}.log"
    if bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
      --keep-silence 0.300 --transcript-json "$FIXTURES/$fixture" >"$log" 2>&1; then
      fail "malformed_transcript_fails_before_encode" "$fixture succeeded"
    fi
    [[ ! -e $output ]] || fail "malformed_transcript_fails_before_encode" "output created for $fixture"
    grep -q '^error: invalid transcript JSON:' "$log" || \
      fail "malformed_transcript_fails_before_encode" "unexpected error for $fixture"
    ! grep -q '^==> encode' "$log" || \
      fail "malformed_transcript_fails_before_encode" "encode started for $fixture"
  done
  pass "malformed_transcript_fails_before_encode"
}

path_collisions_fail_without_destruction() {
  local original="$TMP/collision-original.mp4" input="$TMP/collision-input.mp4"
  local transcript="$TMP/collision-transcript.json" log source_hash transcript_hash
  make_fixture "$original" 1
  cp "$original" "$input"
  cp "$FIXTURES/transcript-word-outside-gap.json" "$transcript"
  source_hash=$(sha256sum "$input" | cut -d' ' -f1)
  transcript_hash=$(sha256sum "$transcript" | cut -d' ' -f1)

  expect_collision() {
    local name=$1 output=$2 transcript_arg=$3 map=$4
    local args=(bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB --keep-silence 0.300)
    [[ -z $transcript_arg ]] || args+=(--transcript-json "$transcript_arg")
    [[ -z $map ]] || args+=(--cut-map "$map")
    log="$TMP/collision-${name}.log"
    if "${args[@]}" >"$log" 2>&1; then
      fail "path_collisions_fail_without_destruction" "$name succeeded"
    fi
    grep -q '^error: path collision:' "$log" || \
      fail "path_collisions_fail_without_destruction" "$name did not report collision"
    [[ $(sha256sum "$input" | cut -d' ' -f1) == "$source_hash" ]] || \
      fail "path_collisions_fail_without_destruction" "$name changed source"
    [[ $(sha256sum "$transcript" | cut -d' ' -f1) == "$transcript_hash" ]] || \
      fail "path_collisions_fail_without_destruction" "$name changed transcript"
  }

  expect_collision input-output "$input" "" ""
  ln -s "$input" "$TMP/collision-source-link"
  expect_collision input-map "$TMP/collision-output-1.mp4" "" "$TMP/collision-source-link"
  expect_collision input-transcript "$TMP/collision-output-2.mp4" "$TMP/collision-source-link" ""
  ln "$input" "$TMP/collision-source-hardlink.mp4"
  expect_collision input-output-inode "$TMP/collision-source-hardlink.mp4" "" ""
  ln -s "$transcript" "$TMP/collision-transcript-link"
  expect_collision transcript-output "$TMP/collision-transcript-link" "$transcript" ""
  expect_collision transcript-map "$TMP/collision-output-3.mp4" "$transcript" "$TMP/collision-transcript-link"
  expect_collision output-map "$TMP/collision-shared-path.mp4" "$transcript" "$TMP/collision-shared-path.mp4"
  pass "path_collisions_fail_without_destruction"
}

cut_map_publishes_only_after_successful_render() {
  local input="$TMP/publish-input.mp4" output="$TMP/publish-output.invalid"
  local existing_map="$TMP/publish-existing.json" new_map="$TMP/publish-new.json"
  make_fixture "$input" 1
  printf '%s\n' 'authoritative-old-map' >"$existing_map"
  if bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 --cut-map "$existing_map" >"$TMP/publish-existing.log" 2>&1; then
    fail "cut_map_publishes_only_after_successful_render" "invalid render succeeded"
  fi
  [[ $(cat "$existing_map") == authoritative-old-map ]] || \
    fail "cut_map_publishes_only_after_successful_render" "existing map was clobbered"
  if bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 --cut-map "$new_map" >"$TMP/publish-new.log" 2>&1; then
    fail "cut_map_publishes_only_after_successful_render" "second invalid render succeeded"
  fi
  [[ ! -e $new_map ]] || \
    fail "cut_map_publishes_only_after_successful_render" "new map was published"
  pass "cut_map_publishes_only_after_successful_render"
}

silence_intervals_are_clamped_to_duration() {
  local position input output map
  for position in leading trailing all; do
    input="$TMP/${position}-input.mp4"
    output="$TMP/${position}-output.mp4"
    map="$TMP/${position}-map.json"
    make_edge_fixture "$input" "$position"
    bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
      --keep-silence 0.300 --cut-map "$map" >"$TMP/${position}.log" 2>&1
    python3 - "$map" "$position" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
position = sys.argv[2]
duration = data["source_duration"]
cuts = data["cuts"]
if len(cuts) != 1:
    raise SystemExit(f"expected one {position} cut, got {len(cuts)}")
source_start, source_end = cuts[0]["source_interval"]
if position in ("leading", "all") and source_start != 0:
    raise SystemExit(f"{position} silence did not start at source edge: {source_start}")
if position in ("trailing", "all") and source_end != duration:
    raise SystemExit(f"{position} silence did not end at source edge: {source_end} != {duration}")
intervals = []
for cut in cuts:
    intervals.extend([
        cut["source_interval"],
        cut["removed_interval"],
        cut["retained_handles"]["before"],
        cut["retained_handles"]["after"],
    ])
for decision in data.get("decisions", []):
    intervals.extend([decision["source_interval"], decision["proposed_removed_interval"]])
for interval in intervals:
    if not 0 <= interval[0] <= interval[1] <= duration:
        raise SystemExit(f"interval outside [0, {duration}]: {interval}")
PY
  done
  pass "silence_intervals_are_clamped_to_duration"
}

short_retained_gap_never_removes_everything() {
  local input="$TMP/short-retain-input.mp4" output="$TMP/short-retain-output.mp4" map="$TMP/short-retain-map.json"
  make_edge_fixture "$input" all
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.080 --cut-map "$map" >"$TMP/short-retain.log" 2>&1
  python3 - "$(duration "$output")" "$map" <<'PY'
import json
import sys
from pathlib import Path

output_duration = float(sys.argv[1])
data = json.loads(Path(sys.argv[2]).read_text())
if len(data["cuts"]) != 1:
    raise SystemExit(f"expected one short-retain cut, got {len(data['cuts'])}")
if abs(data["output_duration"] - 0.080) > 0.000001:
    raise SystemExit(f"map output duration not 0.080s: {data['output_duration']}")
if abs(output_duration - 0.080) > 0.040:
    raise SystemExit(f"rendered output duration not within codec tolerance of 0.080s: {output_duration}")
PY
  pass "short_retained_gap_never_removes_everything"
}

invalid_noise_threshold_fails_without_artifacts() {
  local input="$TMP/noise-input.mp4" output map value log
  make_fixture "$input" 1
  for value in garbage NaN Infinity 2dBx; do
    output="$TMP/noise-${value}.mp4"
    map="$TMP/noise-${value}.json"
    log="$TMP/noise-${value}.log"
    if bash "$CUT_SILENCE" "$input" "$output" 0.45 "$value" \
      --keep-silence 0.300 --cut-map "$map" >"$log" 2>&1; then
      fail "invalid_noise_threshold_fails_without_artifacts" "$value succeeded"
    fi
    [[ ! -e $output ]] || fail "invalid_noise_threshold_fails_without_artifacts" "$value created output"
    [[ ! -e $map ]] || fail "invalid_noise_threshold_fails_without_artifacts" "$value created map"
    grep -Fxq 'error: noise_db must be finite numeric amplitude or numeric dB' "$log" || \
      fail "invalid_noise_threshold_fails_without_artifacts" "unexpected error for $value"
  done

  output="$TMP/noise-detector-failure.mp4"
  map="$TMP/noise-detector-failure.json"
  if bash "$CUT_SILENCE" "$input" "$output" 0.45 -1 \
    --keep-silence 0.300 --cut-map "$map" >"$TMP/noise-detector-failure.log" 2>&1; then
    fail "invalid_noise_threshold_fails_without_artifacts" "detector failure was suppressed"
  fi
  [[ ! -e $output ]] || fail "invalid_noise_threshold_fails_without_artifacts" "detector failure created output"
  [[ ! -e $map ]] || fail "invalid_noise_threshold_fails_without_artifacts" "detector failure created map"
  pass "invalid_noise_threshold_fails_without_artifacts"
}

cut_map_records_veto_reason() {
  local input="$TMP/veto-map-input.mp4" output="$TMP/veto-map-output.mp4" map="$TMP/veto-map.json"
  make_fixture "$input" 1 2
  bash "$CUT_SILENCE" "$input" "$output" 0.45 -35dB \
    --keep-silence 0.300 \
    --transcript-json "$FIXTURES/transcript-word-in-gap.json" \
    --cut-map "$map" >"$TMP/veto-map.log" 2>&1
  python3 - "$map" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text())
decisions = data["decisions"]
if [decision["decision"] for decision in decisions] != ["vetoed", "accepted"]:
    raise SystemExit(f"unexpected decisions: {decisions!r}")
veto = decisions[0]
if veto["reason"] != "word_overlap":
    raise SystemExit(f"unexpected veto reason: {veto['reason']!r}")
if veto["matching_words"] != [{"start": 1.4, "end": 1.5, "word": "quiet"}]:
    raise SystemExit(f"unexpected matching words: {veto['matching_words']!r}")
accepted = decisions[1]
if accepted["reason"] != "no_word_overlap" or accepted["matching_words"]:
    raise SystemExit(f"unexpected accepted audit: {accepted!r}")
if len(data["cuts"]) != 1:
    raise SystemExit(f"expected one rendered cut, got {len(data['cuts'])}")
PY
  assert_close "$(duration "$output")" 4.327 0.040 "mixed veto output duration"
  pass "cut_map_records_veto_reason"
}

legacy_invocation_removes_full_detected_silence
keep_silence_retains_requested_total_gap
audio_fade_preserves_expected_duration
short_gap_is_not_cut
invalid_new_flag_fails_without_output
cut_map_matches_rendered_duration
word_inside_silence_vetoes_cut
word_padding_vetoes_near_boundary_cut
word_outside_silence_allows_cut
transcript_absent_keeps_t1_behavior
malformed_transcript_fails_before_encode
cut_map_records_veto_reason
path_collisions_fail_without_destruction
cut_map_publishes_only_after_successful_render
silence_intervals_are_clamped_to_duration
short_retained_gap_never_removes_everything
invalid_noise_threshold_fails_without_artifacts

echo "1..$pass_count"
