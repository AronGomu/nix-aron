#!/usr/bin/env python3
"""G6 dep-rules — module layering check over the changed files.

Reads .make-aron/layers.json. Absent -> exit 0 with `not configured` on stdout,
which the parent must print verbatim in the final report. Silence is not a pass.

Import parsing is regex-based and deliberately shallow: JS/TS, Python, Go, Rust,
Java/Kotlin, PHP. It resolves relative imports against the importing file and
maps both sides through `map` globs. A path it cannot resolve is reported as
unresolved, never as clean.

exit 0 pass | 1 violation | 2 cannot run
"""
import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys

CFG = ".make-aron/layers.json"

PATTERNS = [
    re.compile(r"""^\s*import\s+(?:[\w*{}\s,]+\s+from\s+)?['"]([^'"]+)['"]"""),   # js/ts
    re.compile(r"""^\s*export\s+(?:[\w*{}\s,]+\s+)?from\s+['"]([^'"]+)['"]"""),   # js/ts re-export
    re.compile(r"""require\(\s*['"]([^'"]+)['"]\s*\)"""),                          # cjs
    re.compile(r"""^\s*from\s+([\w.]+)\s+import\s"""),                             # py
    re.compile(r"""^\s*import\s+([\w.]+)"""),                                      # py / java / go
    re.compile(r"""^\s*use\s+([\w:]+)"""),                                         # rust
    re.compile(r"""^\s*(?:use|require|include)(?:_once)?\s+['"]?([\w\\/.]+)"""),   # php
]


def die2(msg):
    print(f"CANNOT RUN: {msg}", file=sys.stderr)
    sys.exit(2)


def norm(p):
    return p.replace("\\", "/").lstrip("./")


def layer_of(path, mapping):
    path = norm(path)
    for glob, layer in mapping.items():
        if fnmatch.fnmatch(path, glob):
            return layer
    return None


def resolve(spec, importer):
    """Best-effort module spec -> repo-relative path prefix."""
    if spec.startswith("."):
        return norm(os.path.normpath(os.path.join(os.path.dirname(importer), spec)))
    if spec.startswith("@/") or spec.startswith("~/"):
        return norm(spec[2:])
    if "/" in spec and not spec.startswith("@"):
        return norm(spec)
    if "." in spec and not spec.startswith("@"):
        return norm(spec.replace(".", "/"))          # python / java dotted
    if "::" in spec:
        return norm(spec.split("::")[0])             # rust crate root
    return None                                      # bare package — external


def changed_files(base):
    out = subprocess.run(
        ["git", "diff", "--name-only", "--diff-filter=AM", base, "--"],
        capture_output=True, text=True,
    )
    if out.returncode != 0:
        die2(f"git diff failed: {out.stderr.strip()}")
    return [f for f in out.stdout.split() if os.path.isfile(f)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD")
    args = ap.parse_args()

    if not os.path.exists(CFG):
        print("PASS(G6): not configured — no .make-aron/layers.json, "
              "module layering is unchecked for this project")
        return 0

    with open(CFG) as fh:
        cfg = json.load(fh)
    mapping = cfg.get("map") or {}
    allowed = {r["from"]: set(r.get("may_depend_on", [])) for r in cfg.get("rules", [])}
    if not mapping or not allowed:
        die2(f"{CFG} needs both `map` and `rules`")

    violations, unresolved, scanned = [], [], 0

    for path in changed_files(args.base):
        src_layer = layer_of(path, mapping)
        if src_layer is None:
            continue                                   # file outside every layer
        scanned += 1
        try:
            text = open(path, encoding="utf-8", errors="ignore").read()
        except OSError:
            continue
        for i, line in enumerate(text.splitlines(), 1):
            if len(line) > 400:
                continue
            for pat in PATTERNS:
                m = pat.search(line)
                if not m:
                    continue
                target = resolve(m.group(1), path)
                if target is None:
                    break                              # external package
                dst_layer = layer_of(target, mapping)
                if dst_layer is None:
                    for glob in mapping:
                        root = glob.split("*")[0].rstrip("/")
                        if root and target.startswith(root):
                            unresolved.append(f"{path}:{i} -> {m.group(1)}")
                            break
                    break
                if dst_layer != src_layer and dst_layer not in allowed.get(src_layer, set()):
                    violations.append(
                        f"{path}:{i}  {src_layer} -> {dst_layer}  ({m.group(1)})"
                    )
                break

    for u in unresolved[:20]:
        print(f"UNRESOLVED  {u}")

    if violations:
        print(f"FAIL(G6): {len(violations)} layer violation(s) over {scanned} changed file(s)")
        for v in violations:
            print(f"  {v}")
        print("Legal repairs, all structural: invert the dependency · "
              "insert an interface · split the module. Never suppress.")
        return 1

    print(f"PASS(G6): {scanned} changed file(s) in mapped layers, no violation"
          + (f", {len(unresolved)} unresolved import(s)" if unresolved else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
