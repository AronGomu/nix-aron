# Task for worker

Goal slug: transcript_safe_silence_cut_tuning
Branch: goal/transcript-safe-silence-cut-tuning
CWD: /home/aron/coding/nix-aron
Plan: .tmp/IMPLEMENTATION_PLAN_transcript_safe_silence_cut_tuning.md
Ticket: T2 Veto cuts overlapping words
Depends output: T1 commit 53760c0; parent reran `bash -n` + 6/6 tests successfully.

Sole app-code writer. Parent orchestrates. Do not spawn subagents. No user ask: auto-decide safest in-scope + report assumption. Preserve unrelated dirty/untracked files. Never reset/stash/delete user work.

Requirements:
- Accept JSON `{model, words:[{start,end,word}]}`.
- `--transcript-json` absent => T1 behavior unchanged.
- `--word-padding` default 0.080 only with transcript.
- Protected interval `[max(0,start-padding), end+padding]`.
- Proposed removed interval intersecting any protected word (1ms epsilon; touching counts) => veto whole source silence interval.
- Reject malformed, unsorted, non-finite timestamps before encode/output.
- Cut map records accepted/vetoed decisions, matching word text/times, reason.
- Keep `cut-silence` runtime Bash + FFmpeg + Python stdlib. STT external.

TDD first. Add fixtures + tests:
- word_inside_silence_vetoes_cut
- word_padding_vetoes_near_boundary_cut
- word_outside_silence_allows_cut
- transcript_absent_keeps_t1_behavior
- malformed_transcript_fails_before_encode
- cut_map_records_veto_reason
Preserve all T1 tests.

Impl target:
- `home/aron/scripts/cut-silence.sh`
- `home/aron/scripts/tests/cut-silence-test.sh`
- `home/aron/scripts/tests/fixtures/*.json`

Validation:
- `bash -n home/aron/scripts/cut-silence.sh`
- `bash home/aron/scripts/tests/cut-silence-test.sh`
- `nix eval .#nixosConfigurations.desk-main.config.system.build.toplevel.drvPath`
- Do NOT run sudo rebuild in this worker if it risks long interactive sudo/auth; parent handles activation after code commit. If passwordless sudo works safely, may run exact plan command.
- Old + T1 + transcript paths pass.

Success check affected: transcript word overlap veto tests pass.

Plan checkbox duty:
- Flip only T2 TDD/impl/validation boxes after evidence.
- Leave rebuild/global smoke boxes unchecked unless actually verified.
- Leave T3 untouched.

Commit policy:
- Commit only T2-owned script/test/fixtures after validation.
- Do not stage `.tmp`, docs, `.pi-subagents`, unrelated paths.
- Commit: `feat(video): veto silence cuts across transcript words`
- No push.

Required report:
## Slice T2 report
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