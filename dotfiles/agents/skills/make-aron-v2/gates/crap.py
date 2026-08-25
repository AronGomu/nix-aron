#!/usr/bin/env python3
"""CRAP per changed function — join complexity with coverage, diff-scoped.

    CRAP(m) = comp(m)**2 * (1 - cov(m))**3 + comp(m)

At cov = 1.0 the first term vanishes and CRAP == cyclomatic complexity, which is
why the threshold here is 6 and not the published 30. Thresholds live in
.make-aron/gates.json; nothing in this file hardcodes one.

modes:
  (default)          G4 — CRAP per changed function
  --coverage-only    G3 — changed-line coverage floor
  --mutation-score   G5 — mutation score from a mutation.json report

exit 0 pass | 1 fail | 2 cannot run
"""
import argparse
import csv
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


def risk_match(path, cfg):
    pats = cfg.get("risk_paths")
    if pats:
        import fnmatch

        return any(fnmatch.fnmatch(path, p) for p in pats)
    words = ("auth", "billing", "payment", "migration", "webhook",
             "job", "queue", "cron", "session", "token", "permission")
    low = path.lower()
    return any(w in low for w in words)


def crap(comp, cov):
    return comp ** 2 * (1 - cov) ** 3 + comp


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


# ---------------------------------------------------------------- G4


def gate_crap(args, cfg):
    th = cfg["thresholds"]["crap"]
    th_risk = cfg["thresholds"].get("crap_risk", th)
    cov = parse_lcov(args.lcov)
    changed = changed_lines(args.base)

    offenders, scanned = [], 0
    with open(args.complexity) as fh:
        for row in csv.reader(fh):
            # lizard --csv: NLOC,CCN,tokens,PARAM,length,location,file,fn,long_name,start,end
            if len(row) < 11 or not row[1].strip().isdigit():
                continue
            comp = int(row[1])
            src = norm(row[6])
            fname = row[7]
            start, end = int(row[9]), int(row[10])

            touched = changed.get(src)
            if not touched or not any(start <= ln <= end for ln in touched):
                continue  # function not touched by this diff
            scanned += 1

            lines = cov.get(src, {})
            execd = [h for ln, h in lines.items() if start <= ln <= end]
            c = (sum(1 for h in execd if h > 0) / len(execd)) if execd else 0.0

            limit = th_risk if risk_match(src, cfg) else th
            score = crap(comp, c)
            if score > limit:
                offenders.append(
                    dict(file=src, fn=fname, line=start, comp=comp,
                         cov=round(c, 3), crap=round(score, 2), limit=limit)
                )

    if args.json:
        print(json.dumps({"scanned": scanned, "offenders": offenders}, indent=2))
    else:
        for o in sorted(offenders, key=lambda r: -r["crap"]):
            print(f"{o['crap']:>8.2f}  cc={o['comp']:<3} cov={o['cov']:.0%}  "
                  f"limit={o['limit']}  {o['file']}:{o['line']}  {o['fn']}")
        if offenders:
            print(f"FAIL(G4): {len(offenders)} of {scanned} changed function(s) over threshold")
        else:
            print(f"PASS(G4): {scanned} changed function(s), all within threshold {th}")
    return 1 if offenders else 0


# ---------------------------------------------------------------- G5


def gate_mutation(args, cfg):
    th = cfg["thresholds"]["mutation"]
    cap = cfg["thresholds"].get("max_equivalents_per_ticket", 3)

    allow_path = ".make-aron/equivalent-mutants.json"
    allow = []
    if os.path.exists(allow_path):
        with open(allow_path) as fh:
            allow = json.load(fh)
        bad = [a for a in allow if not a.get("justification", "").strip()]
        if bad:
            print(f"FAIL(G5): {len(bad)} equivalent-mutant entr(ies) with no justification")
            for a in bad[:10]:
                print(f"  {a.get('file')}:{a.get('line')} {a.get('mutator')}")
            return 1
        ticket = os.environ.get("MA_TICKET")
        if ticket:
            n = sum(1 for a in allow if a.get("added_by") == ticket)
            if n > cap:
                print(f"FAIL(G5): {n} equivalents added by {ticket}, cap is {cap}")
                return 1

    allowed = {(norm(a["file"]), int(a["line"]), a.get("mutator")) for a in allow}

    with open(args.mutation_score) as fh:
        report = json.load(fh)

    killed = survived = skipped = 0
    survivors = []
    for path, entry in (report.get("files") or {}).items():
        p = norm(path)
        for m in entry.get("mutants", []):
            line = (m.get("location", {}).get("start", {}) or {}).get("line", 0)
            key = (p, int(line), m.get("mutatorName"))
            status = m.get("status")
            if key in allowed:
                skipped += 1
                continue
            if status in ("Killed", "Timeout", "CompileError"):
                killed += 1
            elif status == "Survived":
                survived += 1
                survivors.append(f"{p}:{line} {m.get('mutatorName')} -> {m.get('replacement','')}")
            elif status in ("NoCoverage",):
                survived += 1
                survivors.append(f"{p}:{line} {m.get('mutatorName')} (no coverage)")

    total = killed + survived
    if total == 0:
        print("PASS(G5): no mutants generated for this diff")
        return 0
    score = killed / total
    print(f"mutation score {killed}/{total} = {score:.3f} / threshold {th}"
          f"  ({skipped} allowlisted equivalent)")
    if score + 1e-9 < th:
        print(f"FAIL(G5): {len(survivors)} surviving mutant(s)")
        for s in survivors[:40]:
            print(f"  {s}")
        return 1
    print("PASS(G5)")
    return 0


# ----------------------------------------------------------------


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD")
    ap.add_argument("--lcov")
    ap.add_argument("--complexity")
    ap.add_argument("--coverage-only", action="store_true")
    ap.add_argument("--mutation-score", metavar="MUTATION_JSON")
    ap.add_argument("--threshold-key", default="crap")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    cfg = load_cfg()

    if args.mutation_score:
        sys.exit(gate_mutation(args, cfg))
    if args.coverage_only:
        if not args.lcov:
            die2("--lcov required")
        sys.exit(gate_coverage(args, cfg))
    if not (args.lcov and args.complexity):
        die2("--lcov and --complexity required")
    sys.exit(gate_crap(args, cfg))


if __name__ == "__main__":
    main()
