# ADR 003: Backward-compatible cut-silence CLI extension

- Status: Accepted
- Date: 2026-08-02
- Scope: active NixOS `cut-silence` command

## Context

Active command source:

`/home/aron/config/nix-aron/home/aron/scripts/cut-silence.sh`

Packaging:

`home/aron/packages.nix` → `pkgs.writeShellApplication` → installed `cut-silence`.

Existing contract:

```text
cut-silence <input> <output> <max_silence_sec> [noise_db]
```

Existing behavior removes full qualifying silence. New workflow needs retained gap, micro fades, transcript veto, cut audit. Existing callers must not change silently.

## Decision

Extend same command with optional flags after current positional args:

```text
--keep-silence SEC
--audio-fade SEC
--transcript-json FILE
--word-padding SEC
--cut-map FILE
```

No new flags → exact legacy behavior.

`cut-silence` consumes transcript JSON but does not install/run STT. Runtime stays Bash + FFmpeg + Python stdlib. Tuning-only `faster-whisper` stays isolated under `/home/aron/.tmp/silence-cut-tuning`.

## Why

- One active timeline implementation.
- No duplicate cut command.
- Existing Nix ownership preserved.
- STT dependency stays outside daily runtime.
- Optional JSON keeps core command deterministic + testable.

## Rejected

### New installed command

Cleaner API boundary. Duplicates timeline/filter logic or requires premature shared abstraction.

### Task-only cutter

Avoids repo changes. Leaves reusable active command unable to meet requested pacing.

### Bundle faster-whisper into cut-silence package

One-shot UX. Large model/CUDA deps burden every install + complicate Nix closure.

### Break positional CLI

Cleaner new parser. Existing usage would fail or change meaning.

## Consequences

### Positive

- Existing calls remain valid.
- New behavior opt-in.
- Nix remains source of truth.
- Core tests need no ML runtime.

### Negative

- Mixed positional + named parsing needs care.
- Shell script gains options.
- Transcript JSON schema becomes public contract.

## Compatibility gate

Before merge:

- Run old invocation against deterministic fixture before/after.
- Assert same duration/cut count within codec tolerance.
- Assert no transcript dependency when `--transcript-json` absent.
- Rebuild `desk-main`; resolve installed path to new Nix store output.

## Worktree preflight

Cutter + ADR baseline landed in commit `905a374` during planning. Current observed plan-completion `HEAD` = `ef86346`; relevant paths were clean. Execution must recheck `HEAD` + path status, preserve ownership, never reset/stash/delete silently.
