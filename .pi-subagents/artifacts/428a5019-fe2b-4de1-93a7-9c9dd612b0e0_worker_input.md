# Task for worker

Goal slug: transcript_safe_silence_cut_tuning
Branch: goal/transcript-safe-silence-cut-tuning
CWD: /home/aron/coding/nix-aron
Slice: T5 optional output + non-interactive transcript opt-in
Current HEAD e8122bd; T4 22/22.

Sole app writer. No subagents/user questions. Preserve unrelated dirty/untracked files. Never reset/stash/delete/sudo/push.

User explicitly reverts transcript prompting.

Required:
- Remove all transcript yes/no/path prompting and non-TTY omission failure.
- Audio-only default when no transcript option.
- Transcript protection only via `--transcript-json FILE`; keep `--word-padding` behavior.
- Remove `--no-transcript` from usage/parser. It should become unknown option.
- Input is sole required arg.
- Add `-o OUTPUT` and `--output OUTPUT` for custom output.
- Keep existing positional output accepted for compatibility where unambiguous. Reject positional output plus `-o/--output` conflict.
- If output omitted, derive sibling path:
  - `/x/video.mp4` => `/x/video-altered.mp4`
  - `/x/video.test.mp4` => `/x/video.test-altered.mp4`
  - extensionless `/x/video` or hidden basename => `/x/video-altered.mp4`
- Auto-derived output must not overwrite existing file: fail with `-o` hint. Original always untouched.
- Preserve tuned defaults 0.60/-37dB/0.300/0.008.
- Preserve explicit positional max-silence/noise overrides. Resolve ambiguity safely: a first remaining non-option matching numeric seconds may be max-silence when no output specified; otherwise positional path is output. `-o` removes ambiguity.
- Preserve all R1 path collision + atomic map safety.
- Usage/examples emphasize:
  `cut-silence INPUT`
  `cut-silence INPUT -o OUTPUT`
  optional `--transcript-json FILE`.

TDD first:
- Adapt T4 prompt/non-TTY tests away.
- Add no-output auto sibling test, multi-dot, extensionless, existing-auto-output refusal/no mutation, `-o`, `--output`, positional output, output-source collision, positional+flag conflict, no-prompt audio-only, transcript opt-in.
- Existing safety/cutter tests stay green.

Validation: bash syntax; full suite; Nix eval/system build no sudo; built-package smoke with auto output in temp dir + `-o`; verify no prompt/non-TTY works.

Plan duty: flip T5 boxes only after evidence.
Commit only cutter + tests/fixtures if needed. Do not stage `.tmp` or docs. Commit `feat(video): derive altered output when omitted`.

Required report:
## Slice T5 report
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