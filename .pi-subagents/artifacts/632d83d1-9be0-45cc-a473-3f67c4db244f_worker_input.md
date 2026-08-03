# Task for worker

Goal slug: transcript_safe_silence_cut_tuning
Branch: goal/transcript-safe-silence-cut-tuning
CWD: /home/aron/coding/nix-aron
Slice: R2 narrow follow-up
Depends: R1 commit 0e589cc; follow-up reviewers found no blocker.

Sole writer. No subagents. Preserve unrelated files. No reset/stash/delete/sudo/push. No user ask.

Apply only:
1. In `docs/silence-cut-tuning-report.md`, remove unsupported language that fade/handle checks "passed" when checker only gates cut-map gap arithmetic + boundary sample step. State exact truth: boundary-step gates 4/4 passed; RMS/peak recorded; 300ms handles + 8ms fades planned by cut map/filter; no independent per-join rendered-gap/fade-shape or sensory proof.
2. Strengthen `silence_intervals_are_clamped_to_duration` test: assert expected nonzero cut count and edge bounds so empty list cannot pass.
3. Strengthen `short_retained_gap_never_removes_everything`: assert one cut, map output duration ~0.080s, rendered duration ~0.080s with codec tolerance; no full-copy alternative.
Do not change production cutter unless stronger tests expose actual defect; if defect appears, report and fix minimally.

Plan duty: flip only R2 boxes with evidence.
Validation: bash syntax; full cutter test suite; `git diff --check`; report wording grep/read.
Commit only test harness + report. Commit `test(video): tighten silence-cut evidence gates`. No `.tmp` stage.

Required report:
## Slice R2 report
- State: done|failed|blocked_user
- SHA: {sha|—}
- Files: ...
- Validation: pass|fail + evidence
- Assumptions: ...
- Blocker: ...
- Next parent action: continue|retry|halt-chain

## Acceptance Contract
Acceptance level: checked
Completion is not accepted from prose alone. End with a structured acceptance report.

Criteria:
- criterion-1: Implement the requested change without widening scope
- criterion-2: Return evidence sufficient for an independent acceptance review

Required evidence: changed-files, tests-added, commands-run, residual-risks, no-staged-files, validation-output

Review gate: required by reviewer.

Finish with a fenced JSON block tagged `acceptance-report` in this shape:
Use empty arrays when no items apply; array fields contain strings unless object entries are shown.
`criteriaSatisfied[].status` must be exactly one of: satisfied, not-satisfied, not-applicable.
`commandsRun[].result` must be exactly one of: passed, failed, not-run.
`manualNotes` and `notes` are optional strings; an empty string means no note and does not satisfy `manual-notes` evidence.
```acceptance-report
{
  "criteriaSatisfied": [
    {
      "id": "criterion-1",
      "status": "satisfied",
      "evidence": "specific proof"
    },
    {
      "id": "criterion-2",
      "status": "satisfied",
      "evidence": "specific proof"
    }
  ],
  "changedFiles": [
    "src/file.ts"
  ],
  "testsAddedOrUpdated": [
    "test/file.test.ts"
  ],
  "commandsRun": [
    {
      "command": "command",
      "result": "passed",
      "summary": "short result"
    }
  ],
  "validationOutput": [
    "validation output or concise summary"
  ],
  "residualRisks": [
    "none"
  ],
  "noStagedFiles": true,
  "diffSummary": "short description of the diff",
  "reviewFindings": [
    "blocker: file.ts:12 - issue found, or no blockers"
  ],
  "manualNotes": "anything else the parent should know"
}
```