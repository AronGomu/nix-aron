#!/usr/bin/env bash
# G11 prove-test — every test added or changed by this ticket must FAIL against
# the base implementation. A test that passes without the implementation tests
# nothing.
#
# Uses a temp git worktree at the base ref. The working tree is never touched,
# so a crash cannot lose work. Never `git stash`.
#
# exit 0 pass | 1 fail | 2 cannot run
set -u

BASE="HEAD"
[ "${1:-}" = "--base" ] && { BASE="${2:-HEAD}"; shift 2; }

CFG=".make-aron/gates.json"
die2() { echo "CANNOT RUN: $*" >&2; exit 2; }
[ -f "$CFG" ] || die2 "$CFG missing"
command -v python3 >/dev/null || die2 "python3 not found"
git rev-parse --git-dir >/dev/null 2>&1 || die2 "not a git repo"

cfg() { python3 -c '
import json,sys
c=json.load(open(".make-aron/gates.json"))
cur=c
for k in sys.argv[1].split("."):
    cur = cur.get(k) if isinstance(cur,dict) else None
print("" if cur is None else cur)' "$1"; }

TEST_ONE="$(cfg cmd.test_one)"
[ -n "$TEST_ONE" ] || die2 "cmd.test_one not set in $CFG (needed to run one test file)"
TZ_V="$(cfg determinism.TZ)"; TZ_V="${TZ_V:-UTC}"

# test files added or modified vs base, still present on disk.
# Source files only — generated caches and vendored trees are untracked and would
# otherwise match the path patterns below (a .pyc in tests/ is not a test file).
EXCLUDE='(^|/)(__pycache__|node_modules|\.venv|venv|vendor|target|dist|build|coverage|\.pytest_cache|\.mypy_cache)/'
SRCEXT='\.(py|js|ts|jsx|tsx|mjs|cjs|go|rs|rb|php|java|kt|cs|swift|scala|lua|exs?)$'
mapfile -t TESTS < <(
  { git diff --name-only --diff-filter=AM "$BASE" --
    git ls-files --others --exclude-standard; } \
  | sort -u \
  | grep -Ev "$EXCLUDE" \
  | grep -E "$SRCEXT" \
  | grep -E '(^|/)(tests?|spec|__tests__)/|[._-](test|spec)\.[A-Za-z0-9]+$|_test\.[A-Za-z0-9]+$|(^|/)test_[^/]*\.py$' \
  | while read -r f; do [ -f "$f" ] && echo "$f"; done
)

if [ "${#TESTS[@]}" -eq 0 ]; then
  echo "PASS(G11): no test files added or changed vs $BASE"
  exit 0
fi

WT="$(mktemp -d -t ma-v2-provetest-XXXXXX)"
cleanup() { git worktree remove --force "$WT" >/dev/null 2>&1 || true; rm -rf "$WT"; }
trap cleanup EXIT

git worktree add --detach "$WT" "$BASE" >/dev/null 2>&1 \
  || die2 "git worktree add failed at $BASE (uncommitted base? dirty index?)"

# bring dependencies over rather than reinstalling: link, do not copy, and only
# when the base tree lacks them.
for d in node_modules vendor .venv target/debug; do
  [ -e "$d" ] && [ ! -e "$WT/$d" ] && ln -s "$(pwd)/$d" "$WT/$d" 2>/dev/null || true
done

FAILED_TO_FAIL=()
RAN=0

for t in "${TESTS[@]}"; do
  mkdir -p "$WT/$(dirname "$t")"
  cp "$t" "$WT/$t"
done

for t in "${TESTS[@]}"; do
  cmd="${TEST_ONE//\{file\}/$t}"
  echo "\$ (at $BASE) $cmd"
  out="$(cd "$WT" && TZ="$TZ_V" bash -c "$cmd" 2>&1)"; rc=$?
  RAN=$((RAN+1))
  if [ $rc -eq 0 ]; then
    FAILED_TO_FAIL+=("$t")
    echo "  -> PASSED against base. This test does not test the implementation."
  elif echo "$out" | grep -qiE 'importerror|modulenotfounderror|cannot import name|cannot find module|undefined: |unresolved reference|no such (module|file or directory)'; then
    # The symbol under test does not exist at base. That is the strongest
    # possible proof the test depends on this ticket's code.
    echo "  -> failed as required (symbol absent at base)"
  elif echo "$out" | grep -qiE 'no tests? (ran|collected|found)|collected 0 items'; then
    FAILED_TO_FAIL+=("$t (collected nothing, no error)")
    echo "  -> collected no tests against base and reported no error. Cannot prove anything."
  else
    echo "  -> failed as required"
  fi
done

if [ "${#FAILED_TO_FAIL[@]}" -gt 0 ]; then
  echo "FAIL(G11): ${#FAILED_TO_FAIL[@]} of $RAN new test file(s) pass without the implementation"
  for f in "${FAILED_TO_FAIL[@]}"; do echo "  $f"; done
  echo "Each listed file asserts something already true at $BASE. Rewrite it against the new behaviour."
  exit 1
fi

echo "PASS(G11): $RAN/$RAN new test file(s) fail against $BASE"
exit 0
