#!/usr/bin/env bash
# make-aron-v2 gate runner.
#   usage: run.sh <G0|G1|G2|G3|G4|G5|G6|G7|G8|G9|G10|G11>
#   exit 0 pass | 1 fail | 2 cannot run (never treat 2 as a pass)
#
# env:
#   MA_ACCEPTANCE  test file or pattern for the ticket acceptance test (G0, G8)
#   MA_BASE        base ref for diff-scoped gates (default: merge-base with origin HEAD)
#   MA_TICKET      ticket id, for messages
set -u

GATE="${1:-}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG=".make-aron/gates.json"

die2() { echo "CANNOT RUN: $*" >&2; exit 2; }
[ -n "$GATE" ] || die2 "no gate id. usage: run.sh <G0..G11>"
[ -f "$CFG" ] || die2 "$CFG missing — run bootstrap/detect.py first"
command -v python3 >/dev/null || die2 "python3 not found"

# cfg <dotted.key> [default] -> value, or empty
cfg() {
  python3 - "$CFG" "$1" "${2-}" <<'PY'
import json,sys
cfg=json.load(open(sys.argv[1]))
cur=cfg
for k in sys.argv[2].split('.'):
    if isinstance(cur,dict) and k in cur: cur=cur[k]
    else: cur=None; break
print(sys.argv[3] if cur is None else (cur if isinstance(cur,str) else json.dumps(cur)))
PY
}

BASE="${MA_BASE:-$(git merge-base HEAD "$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || echo origin/main)" 2>/dev/null || echo HEAD)}"
SRC="$(cfg paths.src src)"

# expand {base} {src} {file} in a configured command
expand() { echo "$1" | sed -e "s|{base}|$BASE|g" -e "s|{src}|$SRC|g" -e "s|{file}|${2-}|g"; }

# run a configured command; exit 2 if it is not configured
runcfg() {
  local key="$1" file="${2-}" c
  c="$(cfg "cmd.$key")"
  [ -n "$c" ] || die2 "cmd.$key not set in $CFG"
  c="$(expand "$c" "$file")"
  echo "\$ $c"
  env $(cfg determinism.env '{}' | python3 -c 'import json,sys;print(" ".join(f"{k}={v}" for k,v in json.load(sys.stdin).items()))') \
      TZ="$(cfg determinism.TZ UTC)" bash -c "$c"
}

case "$GATE" in

  G0) # spec-red — the acceptance test must FAIL
    [ -n "${MA_ACCEPTANCE:-}" ] || die2 "MA_ACCEPTANCE not set"
    out="$(runcfg test_one "$MA_ACCEPTANCE" 2>&1)"; rc=$?
    echo "$out"
    if [ $rc -eq 0 ]; then
      echo "FAIL(G0): spec is already green; it constrains nothing"; exit 1
    fi
    if echo "$out" | grep -qiE 'no tests? (ran|collected|found)|cannot find module|importerror|syntaxerror|modulenotfounderror'; then
      echo "FAIL(G0): spec failed without reaching an assertion (import/collection error)"; exit 1
    fi
    echo "PASS(G0): spec fails as required"; exit 0 ;;

  G8) # acceptance — the same test must now PASS
    [ -n "${MA_ACCEPTANCE:-}" ] || die2 "MA_ACCEPTANCE not set"
    runcfg test_one "$MA_ACCEPTANCE"; rc=$?
    [ $rc -eq 0 ] && { echo "PASS(G8)"; exit 0; } || { echo "FAIL(G8): acceptance test red"; exit 1; } ;;

  G1) # build — typecheck + lint + build
    rc=0
    for k in typecheck lint build; do
      [ -n "$(cfg "cmd.$k")" ] || continue
      runcfg "$k" || { echo "FAIL(G1): $k"; rc=1; }
    done
    [ $rc -eq 0 ] && echo "PASS(G1)"; exit $rc ;;

  G2) runcfg test && { echo "PASS(G2)"; exit 0; } || { echo "FAIL(G2): suite red"; exit 1; } ;;

  G3) # coverage on changed lines
    runcfg coverage >/dev/null 2>&1
    LCOV="$(cfg paths.lcov coverage/lcov.info)"
    [ -f "$LCOV" ] || die2 "lcov report not produced at $LCOV"
    python3 "$HERE/crap.py" --coverage-only --base "$BASE" --lcov "$LCOV" ;;

  G4) # CRAP per changed function
    runcfg coverage >/dev/null 2>&1
    LCOV="$(cfg paths.lcov coverage/lcov.info)"
    [ -f "$LCOV" ] || die2 "lcov report not produced at $LCOV"
    CX="$(expand "$(cfg cmd.complexity)")"
    [ -n "$CX" ] || die2 "cmd.complexity not set"
    echo "\$ $CX"
    bash -c "$CX" > .make-aron/.complexity.csv || die2 "complexity command failed"
    python3 "$HERE/crap.py" --base "$BASE" --lcov "$LCOV" --complexity .make-aron/.complexity.csv ;;

  G5) # mutation, diff-scoped
    [ -n "$(cfg cmd.mutation)" ] || die2 "cmd.mutation not set — no mutation engine configured"
    runcfg mutation >/dev/null 2>&1
    MJ="$(cfg paths.mutation_json)"
    [ -f "$MJ" ] || die2 "mutation report not produced at $MJ"
    python3 "$HERE/crap.py" --mutation-score "$MJ" --threshold-key mutation ;;

  G6) python3 "$HERE/deprules.py" --base "$BASE" ;;

  G7) # residue: secrets, merge markers, debug leftovers
    files="$(git diff --name-only "$BASE"; git diff --cached --name-only; git ls-files --others --exclude-standard)"
    files="$(echo "$files" | sort -u | grep -v '^$' || true)"
    [ -n "$files" ] || { echo "PASS(G7): no changed files"; exit 0; }
    pat='sk_live_[0-9A-Za-z]|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{20}|xox[baprs]-|-----BEGIN [A-Z ]*PRIVATE KEY-----|^<<<<<<< |^>>>>>>> '
    hits="$(echo "$files" | tr '\n' '\0' | xargs -0 -r grep -nEI "$pat" 2>/dev/null || true)"
    if [ -n "$hits" ]; then
      echo "FAIL(G7): secret literal or merge marker in changed files"
      echo "$hits" | sed -E 's/(sk_live_|AKIA|ghp_|xox.-)[A-Za-z0-9_-]*/\1<redacted>/g'
      exit 1
    fi
    echo "PASS(G7)"; exit 0 ;;

  G9) # executable QA
    q="$(cfg qa.cmd)"
    if [ -z "$q" ]; then
      [ "$(cfg qa.required false)" = "true" ] && die2 "qa.cmd not set but qa.required is true"
      echo "SKIP(G9): qa.cmd not configured — ticket outcome is partial, never verified"; exit 0
    fi
    echo "\$ $q"; bash -c "$q" && { echo "PASS(G9)"; exit 0; } || { echo "FAIL(G9): QA script red"; exit 1; } ;;

  G10) exec bash "$HERE/flake.sh" ;;
  G11) exec bash "$HERE/prove-test.sh" --base "$BASE" ;;

  *) die2 "unknown gate '$GATE'" ;;
esac
