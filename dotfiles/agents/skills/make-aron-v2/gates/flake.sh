#!/usr/bin/env bash
# G10 flake guard — run the suite twice with identical determinism env and
# compare. Runs once per invocation, before any ticket.
#
# A mutation run on a flaky suite reads a random failure as a kill and a random
# pass as a survivor. Every downstream gate then reports a number that means
# nothing. This gate stops that, and it will fail on most existing repos the
# first time. That is correct, not a bug.
#
# exit 0 pass | 1 flaky | 2 cannot run
set -u

CFG=".make-aron/gates.json"
die2() { echo "CANNOT RUN: $*" >&2; exit 2; }
[ -f "$CFG" ] || die2 "$CFG missing"
command -v python3 >/dev/null || die2 "python3 not found"

cfg() { python3 -c '
import json,sys
c=json.load(open(".make-aron/gates.json"))
cur=c
for k in sys.argv[1].split("."):
    cur = cur.get(k) if isinstance(cur,dict) else None
print("" if cur is None else (cur if isinstance(cur,str) else json.dumps(cur)))' "$1"; }

TEST="$(cfg cmd.test)"
[ -n "$TEST" ] || die2 "cmd.test not set in $CFG"
TZ_V="$(cfg determinism.TZ)"; TZ_V="${TZ_V:-UTC}"
ENVKV="$(cfg determinism.env | python3 -c 'import json,sys
try: d=json.load(sys.stdin)
except Exception: d={}
print(" ".join(f"{k}={v}" for k,v in d.items()))')"

run_once() {
  # shellcheck disable=SC2086
  env $ENVKV TZ="$TZ_V" bash -c "$TEST" 2>&1
}

# normalize: drop timings, durations, paths with pids, ansi
normalize() {
  sed -E \
    -e 's/\x1b\[[0-9;]*[mK]//g' \
    -e 's/[0-9]+(\.[0-9]+)?\s?(ms|s|sec|seconds|m)\b/<t>/g' \
    -e 's/\b[0-9]{2}:[0-9]{2}:[0-9]{2}\b/<clock>/g' \
    -e 's/\/tmp\/[A-Za-z0-9_.-]+/<tmp>/g' \
    -e 's/pid [0-9]+/pid <n>/g'
}

echo "\$ $TEST   (run 1 of 2)"
OUT1="$(run_once)"; RC1=$?
echo "\$ $TEST   (run 2 of 2)"
OUT2="$(run_once)"; RC2=$?

N1="$(printf '%s' "$OUT1" | normalize)"
N2="$(printf '%s' "$OUT2" | normalize)"

if [ "$RC1" -ne "$RC2" ]; then
  echo "FAIL(G10): suite exit code differs between identical runs — $RC1 then $RC2"
  echo "--- diff (normalized) ---"
  diff <(printf '%s\n' "$N1") <(printf '%s\n' "$N2") | head -40
  echo "Pin the clock, seed the PRNG, set TZ, isolate DB state. Then re-run."
  exit 1
fi

if [ "$N1" != "$N2" ]; then
  echo "FAIL(G10): suite output differs between identical runs (exit code $RC1 both times)"
  echo "--- diff (normalized) ---"
  diff <(printf '%s\n' "$N1") <(printf '%s\n' "$N2") | head -40
  echo "Nondeterministic output means test selection or results vary. Fix before any mutation run."
  exit 1
fi

if [ "$RC1" -ne 0 ]; then
  echo "FAIL(G10): suite is deterministic but red (exit $RC1). Fix the suite first."
  printf '%s\n' "$OUT1" | tail -30
  exit 1
fi

echo "PASS(G10): two identical runs, exit 0 both times"
exit 0
