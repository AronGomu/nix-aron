Implemented R2 evidence/test tightening. No prod cutter change.

Changed files: report, test harness; R2 plan boxes unstaged.  
Validation: 17/17 tests pass. Syntax/diff/report checks pass.  
Open risks/questions: sensory proof absent by design. Independent reviewer gate pending.  
Recommended next step: run reviewer gate.

## Slice R2 report
- State: done
- SHA: `355b4b95ac84a7f4e3230c0fb65c9bab4cf7ab28`
- Files:
  - `docs/silence-cut-tuning-report.md`
  - `home/aron/scripts/tests/cut-silence-test.sh`
  - `.tmp/IMPLEMENTATION_PLAN_transcript_safe_silence_cut_tuning.md` — R2 boxes only; unstaged
- Validation: pass — bash syntax clean; cutter suite 17/17; `git diff --check` clean; unsupported fade/handle pass wording absent
- Assumptions: rendered codec tolerance = 40 ms, matching suite convention. Map tolerance = 1 µs.
- Blocker: none
- Next parent action: continue