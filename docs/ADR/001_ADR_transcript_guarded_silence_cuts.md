# ADR 001: Transcript-guarded silence cuts

- Status: Accepted
- Date: 2026-08-02
- Scope: `cut-silence` timeline planning

## Context

Audio silence detection alone can classify quiet phonemes as silence. Goal forbids clipped words. Montage still needs fixed 300 ms breathing room.

Current `cut-silence` detects gaps with FFmpeg, then removes each full detected gap. No retained handles. No word-aware veto. No audit map.

## Decision

Require both signals before removal:

1. FFmpeg marks source interval silent at selected dB + duration.
2. No transcript word interval overlaps proposed removal after configurable word padding.

Any overlap vetoes whole candidate silence interval. Accepted gap keeps 300 ms total, normally 150 ms each side. Cut map records accepted/vetoed decisions + reasons.

Hard video cuts. 8 ms audio fades occur inside retained silent handles.

## Why

- Dual gate → safer than audio-only or transcript-only.
- Whole-gap veto → simple, conservative failure mode.
- Retained gap → dynamic pace without robotic joins.
- Cut map → transcript progress + reproducible review.

## Rejected

### Audio only

Simple. Quiet speech can cross threshold → clipped word risk.

### Transcript only

Semantic. ASR miss can erase real speech.

### Visual-motion veto

Could preserve silent UI work. User chose audio + transcript only. Added complexity not needed for stated success.

### Split silence around protected word

More compression. More complex timeline; can isolate quiet word unnaturally. Whole-gap veto safer.

## Consequences

### Positive

- Cut cannot knowingly overlap recognized word.
- 300 ms rhythm explicit.
- Candidate decisions auditable.
- Legacy non-transcript use remains possible.

### Negative

- Baseline ASR miss remains residual risk.
- Quiet meaningful non-speech screen action can be cut.
- Conservative veto leaves some long gaps.
- Requires transcript JSON for strongest mode.

## Verification

- Synthetic quiet-word overlap test vetoes cut.
- Padding-boundary test vetoes cut.
- Cut map duration matches rendered output.
- Candidate transcript alignment shows zero join-local baseline-token loss.
- Human waveform/audio review covers every winning-candidate join.
