#!/usr/bin/env python3
"""Changed-line coverage floor, diff-scoped.

    G3 — every line the ticket changed must be executed by the suite.

Coverage over the whole project is the unterminating-loop failure; this gate
only ever looks at the diff. The floor lives in .make-aron/gates.json; nothing
in this file hardcodes one.

exit 0 pass | 1 fail | 2 cannot run
"""
import argparse
import json
import os
import subprocess
import sys
from collections import defaultdict

CFG = ".make-aron/gates.json"


def die2(msg):
    print(f"CANNOT RUN: {msg}", file=sys.stderr)
    sys.exit(2)


def load_cfg():
    if not os.path.exists(CFG):
        die2(f"{CFG} missing")
    with open(CFG) as fh:
        return json.load(fh)


def norm(p):
    p = p.replace("\\", "/")
    p = os.path.relpath(p, os.getcwd()) if os.path.isabs(p) else p
    return p.lstrip("./")


def changed_lines(base):
    """-> {file: set(line numbers added or modified)} from the unified diff."""
    out = subprocess.run(
        ["git", "diff", "-U0", base, "--"], capture_output=True, text=True
    )
    if out.returncode != 0:
        die2(f"git diff failed: {out.stderr.strip()}")
    files, cur = defaultdict(set), None
    for line in out.stdout.splitlines():
        if line.startswith("+++ b/"):
            cur = norm(line[6:])
        elif line.startswith("@@") and cur:
            # @@ -a,b +c,d @@
            plus = line.split("+")[1].split(" ")[0]
            start, _, count = plus.partition(",")
            start, count = int(start), int(count or 1)
            files[cur].update(range(start, start + count))
    return files


def parse_lcov(path):
    """-> {file: {line: hits}}"""
    files, cur = defaultdict(dict), None
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if line.startswith("SF:"):
                cur = norm(line[3:])
            elif line.startswith("DA:") and cur:
                num, hits = line[3:].split(",")[:2]
                files[cur][int(num)] = int(hits)
            elif line == "end_of_record":
                cur = None
    return files

# ---------------------------------------------------------------- G3


def gate_coverage(args, cfg):
    floor = cfg["thresholds"]["coverage"]
    cov = parse_lcov(args.lcov)
    changed = changed_lines(args.base)
    total = covered = 0
    misses = []
    for path, lines in changed.items():
        filecov = cov.get(path)
        if not filecov:
            continue  # not an instrumented source file (test, config, doc)
        for ln in sorted(lines):
            if ln in filecov:
                total += 1
                if filecov[ln] > 0:
                    covered += 1
                else:
                    misses.append(f"{path}:{ln}")
    if total == 0:
        print("PASS(G3): no instrumented changed lines")
        return 0
    ratio = covered / total
    print(f"changed-line coverage {covered}/{total} = {ratio:.3f} / threshold {floor}")
    if ratio + 1e-9 < floor:
        print(f"FAIL(G3): {len(misses)} uncovered changed line(s)")
        for m in misses[:40]:
            print(f"  {m}")
        return 1
    print("PASS(G3)")
    return 0


# ----------------------------------------------------------------


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD")
    ap.add_argument("--lcov")
    ap.add_argument("--coverage-only", action="store_true")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    cfg = load_cfg()
    if not args.lcov:
        die2("--lcov required")
    sys.exit(gate_coverage(args, cfg))


if __name__ == "__main__":
    main()
