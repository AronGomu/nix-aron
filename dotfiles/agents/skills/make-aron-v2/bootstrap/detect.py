#!/usr/bin/env python3
"""Bootstrap .make-aron/gates.json for this project.

Detects the stack from marker files, proposes a command per gate, VERIFIES each
one by running it, and writes the config. Any command that cannot be resolved
or cannot run -> exit 2 with the exact install command. Never writes a config
with a gate silently disabled.

    python3 bootstrap/detect.py [--write] [--skip-verify]

Without --write it prints the proposed config and exits 0.
exit 0 ok | 2 unresolvable
"""
import argparse
import json
import os
import shutil
import subprocess
import sys

OUT = ".make-aron/gates.json"

STACKS = [
    # (name, markers, cmd template, paths, install hints)
    ("node-ts", ["package.json"], {
        "typecheck": "npx tsc --noEmit",
        "lint": "npx eslint . --max-warnings 0",
        "build": "npm run build",
        "test": "npx vitest run",
        "test_one": "npx vitest run {file}",
        "coverage": "npx vitest run --coverage --coverage.reporter=lcov",
    }, {"src": "src", "lcov": "coverage/lcov.info"},
     {"npx": "install node"}),

    ("python", ["pyproject.toml", "setup.py", "setup.cfg"], {
        "typecheck": "mypy .",
        "lint": "ruff check .",
        "build": "",
        "test": "pytest -q",
        "test_one": "pytest -q {file}",
        "coverage": "pytest -q --cov={src} --cov-report=lcov:coverage/lcov.info",
    }, {"src": "src", "lcov": "coverage/lcov.info"},
     {"ruff": "pip install ruff", "mypy": "pip install mypy"}),

    ("go", ["go.mod"], {
        "typecheck": "go vet ./...",
        "lint": "golangci-lint run",
        "build": "go build ./...",
        "test": "go test ./...",
        "test_one": "go test ./... -run {file}",
        "coverage": "go test ./... -coverprofile=coverage.out && gcov2lcov -infile=coverage.out -outfile=coverage/lcov.info",
    }, {"src": ".", "lcov": "coverage/lcov.info"},
     {"gcov2lcov": "go install github.com/jandelgado/gcov2lcov@latest"}),

    ("rust", ["Cargo.toml"], {
        "typecheck": "cargo check --all-targets",
        "lint": "cargo clippy --all-targets -- -D warnings",
        "build": "cargo build",
        "test": "cargo test",
        "test_one": "cargo test --test {file}",
        "coverage": "cargo llvm-cov --lcov --output-path coverage/lcov.info",
    }, {"src": "src", "lcov": "coverage/lcov.info"},
     {"cargo-llvm-cov": "cargo install cargo-llvm-cov"}),

    ("php", ["composer.json"], {
        "typecheck": "./vendor/bin/phpstan analyse",
        "lint": "./vendor/bin/php-cs-fixer fix --dry-run",
        "build": "",
        "test": "./vendor/bin/phpunit",
        "test_one": "./vendor/bin/phpunit {file}",
        "coverage": "./vendor/bin/phpunit --coverage-clover coverage/clover.xml",
    }, {"src": "src", "lcov": "coverage/lcov.info"},
     {}),

    ("java", ["pom.xml", "build.gradle", "build.gradle.kts"], {
        "typecheck": "mvn -q compile",
        "lint": "mvn -q checkstyle:check",
        "build": "mvn -q package -DskipTests",
        "test": "mvn -q test",
        "test_one": "mvn -q test -Dtest={file}",
        "coverage": "mvn -q jacoco:report",
    }, {"src": "src/main", "lcov": "target/site/jacoco/lcov.info"},
     {}),
]

DEFAULT_THRESHOLDS = {
    "coverage": 1.0,
    "max_file_lines": 400,
}


def die2(msg, hint=""):
    print(f"CANNOT RUN: {msg}", file=sys.stderr)
    if hint:
        print(f"  install: {hint}", file=sys.stderr)
    sys.exit(2)


def detect():
    for name, markers, cmd, paths, hints in STACKS:
        found = [m for m in markers if os.path.exists(m)]
        if found:
            return name, found, dict(cmd), dict(paths), hints
    die2("no stack marker found (package.json, pyproject.toml, go.mod, "
         "Cargo.toml, composer.json, pom.xml). Write .make-aron/gates.json by hand.")


def verify(cmd, hints):
    """Return (ok, reason). A command that runs at all is resolvable; a red
    suite is a G2 problem, not a bootstrap problem."""
    if not cmd.strip():
        return True, "not applicable"
    exe = cmd.split()[0]
    if exe in ("npx", "./vendor/bin/phpunit"):
        pass
    elif shutil.which(exe) is None:
        return False, f"`{exe}` not on PATH"
    probe = subprocess.run(f"{cmd} --help", shell=True,
                           capture_output=True, text=True, timeout=120)
    if probe.returncode not in (0, 1, 2) and "not found" in (probe.stderr or "").lower():
        return False, (probe.stderr or "").strip().splitlines()[:1]
    return True, "resolvable"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--skip-verify", action="store_true",
                    help="write without probing. Use only when you already know the tools exist.")
    args = ap.parse_args()

    stack, found, cmd, paths, hints = detect()

    # drop src default when the repo has no src/
    if paths.get("src") == "src" and not os.path.isdir("src"):
        paths["src"] = "."

    if not args.skip_verify:
        problems = []
        for key in ("typecheck", "lint", "test", "coverage"):
            c = cmd.get(key, "")
            ok, why = verify(c, hints)
            if not ok:
                exe = c.split()[0] if c else key
                problems.append((key, c, why, hints.get(exe, hints.get(key, ""))))
        if problems:
            print("CANNOT RUN: unresolvable gate commands. "
                  "make-aron-v2 never runs with a gate disabled.\n", file=sys.stderr)
            for key, c, why, hint in problems:
                print(f"  cmd.{key}: `{c}`\n    {why}"
                      + (f"\n    install: {hint}" if hint else ""), file=sys.stderr)
            print("\nFix the tools, or edit the command in .make-aron/gates.json "
                  "and re-run with --skip-verify.", file=sys.stderr)
            sys.exit(2)

    config = {
        "version": 1,
        "stack": stack,
        "detected_from": found,
        "cmd": cmd,
        "paths": paths,
        "thresholds": DEFAULT_THRESHOLDS,
        "determinism": {"TZ": "UTC",
                        "env": {"SEED": "0", "PYTHONHASHSEED": "0"}},
        "qa": {"cmd": "", "required": False},
    }
    blob = json.dumps(config, indent=2)

    if not args.write:
        print(blob)
        print("\n# not written. re-run with --write", file=sys.stderr)
        return 0

    os.makedirs(".make-aron/runs", exist_ok=True)
    if os.path.exists(OUT):
        print(f"CANNOT RUN: {OUT} already exists — refusing to overwrite. "
              f"Edit it by hand or delete it deliberately.", file=sys.stderr)
        sys.exit(2)
    with open(OUT, "w") as fh:
        fh.write(blob + "\n")
    gi = ".make-aron/.gitignore"
    if not os.path.exists(gi):
        with open(gi, "w") as fh:
            fh.write("runs/\n")
    print(f"wrote {OUT} (stack: {stack}, detected from {', '.join(found)})")
    print("Set qa.cmd before the first risk-signal ticket — G9 is required there.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
