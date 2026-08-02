# ADR 002: Local faster-whisper for tuning evidence

- Status: Accepted
- Date: 2026-08-02
- Scope: 3-minute silence-cut tuning workflow

## Context

Workflow needs scriptable word timestamps before/after each candidate. Host has RTX 5060 Ti 16 GB, FFmpeg, `uv`, OpenWhispr GUI. No batch Whisper CLI/Python stack currently installed.

OpenWhispr batch import + word-time export remain unverified. Cloud STT would upload audio. `faster-whisper` exposes word timestamps + deterministic decode controls.

## Decision

Use local `faster-whisper` in isolated workdir env/cache.

Baseline defaults:

- model: `large-v3`
- `word_timestamps=True`
- temperature: `0`
- fixed beam/config
- same pinned package/model/config for baseline + every candidate
- GPU first: CUDA 12 + cuDNN 9
- CPU fallback: same model/config when GPU runtime fails

Store raw segments, normalized word JSON, TXT/SRT, runtime metadata.

## Why

- Word timestamps directly support cut veto.
- Local run preserves media privacy.
- Large model prioritizes word safety.
- Isolated env avoids global Python mutation.
- Same config reduces candidate-comparison drift.

## Rejected

### OpenWhispr GUI

Already installed. Batch automation + word timestamp export unproven.

### whisper.cpp

Lean local CLI. More glue for exact word JSON + comparison. Lower fit than Python API.

### Cloud STT

No API key detected. Upload/privacy cost unnecessary.

### Permanent global Python install

Fast setup. Pollutes host state; conflicts with declarative Nix workflow.

## Consequences

### Positive

- Repeatable baseline/candidate evidence.
- No source audio leaves host.
- GPU can accelerate iterative sweep.

### Negative

- First run downloads deps + model.
- CTranslate2/Blackwell/CUDA compatibility may fail.
- CPU fallback slower.
- ASR output is evidence, not proof; manual join review still required.

## Verification

- Record package/model revisions + decode config.
- Transcribe same sample twice; normalized words stable.
- Candidate comparator flags synthetic deleted word.
- Final report contains raw + normalized transcript diff.
