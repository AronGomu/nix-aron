# Task for worker

Goal slug: transcript_safe_silence_cut_tuning
Branch: goal/transcript-safe-silence-cut-tuning
CWD: /home/aron/coding/nix-aron
Plan source: .tmp/IMPLEMENTATION_PLAN_transcript_safe_silence_cut_tuning.md
Ticket: T1 Retain gaps + micro fades
Depends: none

You are sole app-code writer. Parent owns orchestration. Do not spawn subagents. No user ask: auto-decide safest in-scope detail + report assumption. Preserve unrelated dirty/untracked files. Never reset/stash/delete user work.

Ticket requirements:
- Preserve exact legacy `cut-silence <input> <output> <max_silence_sec> [noise_db]` behavior when new flags absent.
- Parse optional `--keep-silence SEC`, `--audio-fade SEC`, `--cut-map FILE` after optional `noise_db`.
- Validate finite non-negative seconds.
- For silence [s,e], retain total keep_silence, half each side. Skip non-positive removal.
- Hard video concat.
- Apply 8ms-capable audio fade at joins only inside retained silent handles; never speech boundary.
- Emit JSON cut map: source interval, removed interval, retained handles, output offset.
- Keep one video + one audio behavior.

TDD required. Add `home/aron/scripts/tests/cut-silence-test.sh` with generated tiny FFmpeg fixtures. Tests named/cover:
- legacy_invocation_removes_full_detected_silence
- keep_silence_retains_requested_total_gap
- audio_fade_preserves_expected_duration
- short_gap_is_not_cut
- invalid_new_flag_fails_without_output
- cut_map_matches_rendered_duration
Write Red first, then min Green, refactor only needed.

Validation contract:
- `bash -n home/aron/scripts/cut-silence.sh`
- `bash home/aron/scripts/tests/cut-silence-test.sh`
- legacy output duration pre/post tolerance <=40ms
- old command path still works
- inspect generated audio join evidence; if actual listening unavailable, leave manual mpv checkbox unchecked + report

Success checks affected:
- Legacy behavior compatible.
- New retained-gap/fade/cut-map tests pass.

Plan checkbox duty:
- Add `- [ ]` only if missing.
- Continuously flip only T1 checkboxes to `[x]` after evidence. Leave unsupported manual checks unchecked.
- Do not edit T2/T3 boxes.

Commit policy:
- Commit only T1-owned app/test files after validation. Do not stage `.tmp`, planning docs, ADRs, architecture docs, `.pi-subagents`, unrelated files.
- Commit msg: `feat(video): retain breathing room across silence cuts`
- No push.

Required report exact shape:
## Slice T1 report
- State: done|failed|blocked_user
- SHA: {sha|—}
- Files: ...
- Validation: pass|fail + evidence
- Assumptions: ...
- Blocker: ...
- Next parent action: continue|retry|halt-chain

## Acceptance Contract
Acceptance level: verified
Completion is not accepted from prose alone. End with a structured acceptance report.

Criteria:
- criterion-1: Implement the requested change without widening scope
- criterion-2: Return evidence sufficient for an independent acceptance review

Required evidence: changed-files, tests-added, commands-run, validation-output, residual-risks, no-staged-files

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