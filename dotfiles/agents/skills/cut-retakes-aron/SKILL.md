---
name: cut-retakes-aron
description: >
  Cut retakes out of a talking-head recording: silence pass, word-level
  transcript, script-anchored retake detection, rendered video. Use when user
  asks to remove retakes / repeated takes / bad takes from a recording, or says
  "cut my video", "montage auto", "retake-cut".
disable-model-invocation: true
argument-hint: "{video path} [script path]"
---

# cut-retakes-aron

Raw recording + written script -> video where each line survives once, in its last take.

## Inputs

1. **Video** — path. Missing -> STOP, ask.
2. (Optional) **Script** — `.md` used at recording. Not given -> `Process` step 1 finds it.
3. (Optional) **Window** — `--duration SEC` for a test pass. Not given -> full file.

## Const

| name          | value                                                              |
| ------------- | ------------------------------------------------------------------ |
| Tool home     | `/home/aron/projects/retake-cut/`                                  |
| Pipeline      | `{tool home}/retake-pipeline` — silence -> transcribe -> ctc -> plan -> render |
| Single steps  | `{tool home}/retake-cut {transcribe\|ctc\|plan\|report\|render}`   |
| Venv          | `{tool home}/.venv` — torch cu128, whisperx, rapidfuzz             |
| Docs          | `{tool home}/README.md` — flags, algo, venv rebuild                |
| Work dir      | `{video stem}-retake/` — `nosilence.mov words.json ctc.json plan.json report.md` |
| Output        | `{video stem}-retakecut.mp4`                                       |
| Silence pass  | `remove-silence` (auto-editor wrapper, already on PATH)            |
| Script pool   | `~/brain/**/*.md`                                                  |
| Example       | `assets/example.md` — 3 min, both transcripts, every cut + reason  |

## Process

1. **Find script** — not given -> transcribe 60s (`retake-cut transcribe VIDEO -o /tmp/probe.json --duration 60 --language fr`), take 10 content words, `grep -ril` them under `~/brain`. 0 hits -> STOP, ask user. 2+ hits -> show candidates, ask.
2. **Test window** — `retake-pipeline VIDEO SCRIPT --duration 180 --plan-only`. Reuses `words.json` + `ctc.json` on re-run, so tuning is free.
3. **Read report** — `{work}/report.md`: every drop = dropped text + surviving take + timestamps, tagged with its rule. Also read `plan.json.rejected` (near-misses spared, with reason) and `plan.json.review` (phonetic repeats left in).
4. **Calibrate** — compare shape against `assets/example.md`. Retakes left in -> lower `--ctc-repeat-sim` (85) or `--sim-floor` (55). Good speech eaten -> raise them. Long bogus cuts -> lower `--ctc-max-span` (6.0) / `--ctc-window` (14). Stutters left -> `--stutter-words 2`; emphasis eaten -> `--stutter-words 0`.
5. **Full plan** — `retake-pipeline VIDEO SCRIPT --plan-only`. Re-read report. Retake density is uneven: a clean first 3 min proves nothing.
6. **Render** — drop `--plan-only`, add `--nvenc` (RTX 5060 Ti, ~27x realtime). Never overwrite the source.
7. **Verify** — run [Verify](#verify). Fail -> retune, re-render, max 1 loop, then report blocker.
8. **Report** — output path, seconds removed, drop count, verification numbers, residual candidates the guards spared.

## Output

```
{video stem}-retake/
├── nosilence.mov      # auto-editor pass, reused
├── words.json         # whisper: readable text, punctuation, proper nouns
├── ctc.json           # wav2vec2: verbatim words + phonetic repeat pairs
├── plan.json          # takes, drops, rejected, review, keeps, words
└── report.md          # human review: every cut, its rule, its survivor
{video stem}-retakecut.mp4
```

Report a cut like `assets/example.md` does — `✂ **3.4s** [01:52.696 → 01:56.140] **R2 script regression** · sim 96 — "Ça va de la quatrième édition de Scourge,"`.

Quote surviving audio from **ctc**, never whisper: whisper writes a repeated
phrase once, so subtracting its dropped words hides audio that is still there.

### Rules that fire

| id | what it sees | source | auto |
| -- | ------------ | ------ | ---- |
| R1 | phrase said twice, adjacent | whisper | yes |
| R2 | script alignment jumps backwards = new take | whisper + script | yes |
| D1 | speech whisper transcribed as **nothing** | ctc gap vs whisper | yes |
| D3 | phrase retried a moment later, verbatim only | ctc anchor search | yes |
| D2 | phonetic repeat with no text evidence | ctc features | **no — review** |

### Verify

| check                                                                                                        | fix                        |
| ------------------------------------------------------------------------------------------------------------ | -------------------------- |
| `retake-cut ctc RENDER` then diff vs source-ctc-minus-drops -> seq similarity ≥ 95 | retune, re-render          |
| **no leftover repeat**: no adjacent n-gram pair in the render's ctc words scores `ratio ≥ 82`                   | lower `--ctc-repeat-sim`, replan |
| every `keeps` boundary sits between two words, none inside one                                                 | check `snap_to_gap`, replan |
| output duration == sum of `keeps`                                                                              | inspect ffmpeg filter      |

Verify against the **ctc** transcript, never whisper: whisper deletes the very
repetitions the check is looking for, so it would pass a cut that is still wrong.

## Rules

- **Whisper is not the truth.** Trained on cleaned captions -> it deletes stutters and merges repeated takes. Never detect retakes from `words.json` alone; `ctc.json` is the evidence. Whisper is there for readable text and script alignment only.
- **Last take wins.** Every script position kept only from its last delivery; earlier take truncated at the exact word the survivor resumes. Mid-sentence restart -> mid-sentence cut.
- **Improvisation is protected.** Only re-said material is a cut candidate. Off-script passages stay.
- **Cuts land in silence**, never inside a word. `--pad` capped at half the gap; ctc-timed drops snap **outward** to the surrounding gap, so a straddled word dies with the take it belongs to.
- **A repetition written in the script is rhetorical**, not a retake. D3 skips it, D2 flags `in_script`. Never auto-cut one.
- **A restart is immediate.** `--ctc-max-span 6.0` / `--ctc-window 14` are what stop a recurring phrase ("c'est la période…") from swallowing 10s of good speech. Raise them only with evidence.
- **Incomplete last take supersedes nothing** — half-said tail looks like a restart. Only bites with `--duration`.
- Transcribe once, plan many. Never re-transcribe to tune.
- Source file never overwritten, never moved. `remove-silence` suffixes instead of clobbering.
- GPU + certs come from `retake-cut`, not the caller: `LD_LIBRARY_PATH=/run/opengl-driver/lib`, `SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt`. Calling `.venv/bin/python` directly -> "Found no NVIDIA driver" or SSL failure.
- Venv missing/broken -> rebuild per `{tool home}/README.md`. ~7 GB download, run it in background, never inline in a turn.
- K1: never run `nixos-rebuild`. Print cmd.

## Done when

- `{work}/ctc.json` + `{work}/plan.json` + `{work}/report.md` exist, drops carry text + timestamps + rule
- rendered mp4 exists, duration == sum of `keeps`
- [Verify](#verify) rows pass, numbers quoted in the report
- user has: output path, seconds removed, drops per rule, count left for review

## Caller override

Caller may set **autonomous**. Then:

- No script confirmation — best `grep` hit wins, logged under `## Assumptions`.
- No mid-run review — full plan, render, verify, one report at the end.
- Verify failure still stops: report numbers, never ship an unverified cut.

Caller override wins over this file.
