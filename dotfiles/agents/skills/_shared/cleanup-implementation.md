# Implementation cleanup

Passive protocol for implementation skills. No direct invocation.

Goal: obsolete AI planning artifacts + impl temp files removed. Product files + manual checklist preserved.

## Start cleanup

Run after current goal/plan known, before branch pre-flight.

1. Inspect `git status --short`, `./artifacts/`, `./.tmp/`.
2. Identify prior plan indexes + ticket dirs superseded by current impl. Require clear goal/file relation. Unclear relation → preserve.
3. Remove only obsolete prior impl files:
   - `./artifacts/PLAN_*.md`
   - matching `./artifacts/PLAN_*/` ticket dir
   - matching `./.tmp/MAKE_PROGRESS_*.md`
   - scratch patches, generated prompts, transient logs clearly created by prior impl
4. Preserve:
   - `./artifacts/manual_test_checklist.md`
   - current plan + tickets needed for running impl
   - requested deliverables
   - source, tests, docs, config
   - unrelated plans/artifacts
5. Record removed paths in progress log. Tracked removals belong to impl branch.

## End cleanup

Run after final validation + review fixes, before final commit/push/report.

1. Remove current impl plan index + matching ticket dir.
2. Remove current `./.tmp/MAKE_PROGRESS_*.md` + impl scratch/log/temp files.
3. Re-scan `git status --short`, `./artifacts/`, `./.tmp/`.
4. Preserve `./artifacts/manual_test_checklist.md`.
5. Stage only attributable cleanup. Commit + push cleanup when tracked branch diff exists.
6. Report removed paths. Report uncertain leftovers as residual risk; never guess-delete.

## Rules

- Relation proof required: matching plan slug, explicit path ref, progress metadata, or current impl provenance.
- Never broad-delete `./artifacts/` or `./.tmp/`.
- Never delete user-authored or unrelated files.
- Never delete untracked file solely because untracked.
- Never use `git clean`, wildcard `rm`, or recursive root cleanup.
- Cleanup failure → implementation incomplete unless filesystem permission/external lock causes hard stop.

## Done when

- Superseded/current plan indexes + matching ticket dirs absent.
- Impl progress/scratch/temp files absent.
- `./artifacts/manual_test_checklist.md` retained.
- `git status --short` contains only intended product/manual-checklist/cleanup changes.
