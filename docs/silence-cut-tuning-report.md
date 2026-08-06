# Transcript-safe silence-cut tuning report

## Result

Recommended winner: `B_n37_s060_p080`. Evaluator join-window checks, cut-map gap arithmetic, and boundary-step gates pass; final copied automatically for one-shot workflow. User taste approval remains residual review, not execution blocker.

- Source: `/mnt/data/Videos/OBS_Output/2026-08-02 17-38-52.mp4`
- 180 s sample: `/home/aron/.tmp/silence-cut-tuning/source-first-180s.mp4`
- Final: `/mnt/data/Videos/OBS_Output/2026-08-02 17-38-52_first-3m_silence-cut.mp4`
- Workdir: `/home/aron/.tmp/silence-cut-tuning`
- Winner SHA-256: `e26c0d55bf4bc3f65e76647d4f009b76e44128f76e7a940a745314f969593363`
- Source SHA-256 before/after: `ff25032d5ee4f28d453491a2569e05d96f8890b741667a79989e6cda2e29c58c` / `ff25032d5ee4f28d453491a2569e05d96f8890b741667a79989e6cda2e29c58c` — unchanged
- Winner settings: noise `-37dB`; min silence `0.60 s`; retained gap `0.300 s`; word padding `0.080 s`; audio fade `0.008 s`
- Cuts: 4 accepted; 25 transcript-vetoed
- Removed duration: `2.324501 s` from cut map
- Duration: sample `180.000000 s`; final container `177.700000 s`
- Transcript evidence: evaluator found zero baseline deletion/substitution within its ±0.5 s join windows; 27 remote ASR deletions/substitutions remain. ASR supports review; it does not prove speech preservation.
- Retained-gap plan: cut-map arithmetic gives `0.300000 s` for all four joins (max floating-point error `1.14e-14 s`). Aggregate rendered duration supports the planned removed total; no independent per-join MP4 gap measurement was made.

## Selection

Ranking order: transcript safety → 300 ms adherence → removed duration → fewer vetoes/jarring joins. All retained candidates passed evaluator join-window checks plus cut-map-planned gap arithmetic. Winner removed most (`2.324501 s`) with four cuts. `B_n37_s060_p060` rendered byte-identical media, but 80 ms padding gives larger protection margin. At `-37dB`, `0.50 s` produced same media with more vetoes; `0.70 s` removed less; 100 ms padding removed less. Neighbor thresholds `-35dB` plus Phase-A `-40dB` removed less. No tested in-grid neighbor improved safety/pacing rank → Phase B stopped.

Initial no-VAD baseline produced repeated hallucination after ~134 s. That baseline could not safely protect words near late cuts. It plus first Phase-A outputs remain under `/home/aron/.tmp/silence-cut-tuning/superseded-no-vad/` as audit evidence only. Final sweep reran baseline plus every candidate with fixed VAD config below.

## Source guard + probes

Full before/after records:

- `/home/aron/.tmp/silence-cut-tuning/source.sha256.before`
- `/home/aron/.tmp/silence-cut-tuning/source.sha256.after`
- `/home/aron/.tmp/silence-cut-tuning/source.ffprobe.before.json`
- `/home/aron/.tmp/silence-cut-tuning/source.ffprobe.after.json`

Source probe before/after stayed byte-identical: duration `754.433333 s`; H.264 1280×720 30 fps; AAC stereo 48 kHz; size `581610204` bytes. Final probe: H.264 1280×720 30 fps + AAC stereo 48 kHz. Full final record: `/home/aron/.tmp/silence-cut-tuning/final.ffprobe.json`.

Extraction commands:

```bash
ffmpeg -hide_banner -y -i '/mnt/data/Videos/OBS_Output/2026-08-02 17-38-52.mp4' -t 180.000 -map 0:v:0 -map 0:a:0 -c:v libx264 -preset veryfast -crf 18 -c:a aac -b:a 192k -movflags +faststart '/home/aron/.tmp/silence-cut-tuning/source-first-180s.mp4'
ffmpeg -hide_banner -y -i '/home/aron/.tmp/silence-cut-tuning/source-first-180s.mp4' -vn -ac 1 -ar 16000 -c:a pcm_s16le '/home/aron/.tmp/silence-cut-tuning/source-first-180s.mono16k.wav'
```

Sample hashes/probe: `/home/aron/.tmp/silence-cut-tuning/sample.sha256`, `/home/aron/.tmp/silence-cut-tuning/sample.ffprobe.json`.

## Local STT runtime

No cloud transcription. Model inference ran locally on NVIDIA GeForce RTX 5060 Ti via CUDA. Hugging Face supplied model files only; isolated model/cache/env stayed under workdir.

- Python `3.12.13`; `uv 0.11.21`
- `faster-whisper 1.2.1`; `ctranslate2 4.8.1`
- `nvidia-cublas-cu12 12.9.2.10`; `nvidia-cudnn-cu12 9.24.0.43`; `nvidia-cuda-nvrtc-cu12 12.9.86`
- Model `large-v3`; device `cuda`; compute type `float16`
- Baseline/candidates: identical model, runtime, decode config
- Pin files: `/home/aron/.tmp/silence-cut-tuning/requirements.in`, `/home/aron/.tmp/silence-cut-tuning/requirements.lock`, `/home/aron/.tmp/silence-cut-tuning/versions.freeze.txt`
- Model/cache roots: `/home/aron/.tmp/silence-cut-tuning/model-cache`, `/home/aron/.tmp/silence-cut-tuning/uv-cache`

Fixed decode config:

```json
{
  "beam_size": 5,
  "best_of": 5,
  "condition_on_previous_text": true,
  "language": "en",
  "length_penalty": 1.0,
  "no_repeat_ngram_size": 0,
  "patience": 1.0,
  "repetition_penalty": 1.0,
  "task": "transcribe",
  "temperature": 0.0,
  "vad_filter": true,
  "vad_parameters": {
    "min_silence_duration_ms": 500
  },
  "word_timestamps": true
}
```

Baseline command pattern:

```bash
export UV_CACHE_DIR=/home/aron/.tmp/silence-cut-tuning/uv-cache
export HF_HOME=/home/aron/.tmp/silence-cut-tuning/model-cache/hf-home
export LD_LIBRARY_PATH=/home/aron/.tmp/silence-cut-tuning/.venv/lib/python3.12/site-packages/nvidia/cublas/lib:/home/aron/.tmp/silence-cut-tuning/.venv/lib/python3.12/site-packages/nvidia/cudnn/lib:/run/opengl-driver/lib
/home/aron/.tmp/silence-cut-tuning/.venv/bin/python /home/aron/.tmp/silence-cut-tuning/transcribe.py /home/aron/.tmp/silence-cut-tuning/source-first-180s.mono16k.wav /home/aron/.tmp/silence-cut-tuning/baseline/baseline --device cuda --model-cache /home/aron/.tmp/silence-cut-tuning/model-cache --local-files-only
```

Each baseline/candidate has raw segments, flat `{model,words:[...]}` JSON, TXT, SRT, metadata. Baseline prefix: `/home/aron/.tmp/silence-cut-tuning/baseline/baseline`. Winner prefix: `/home/aron/.tmp/silence-cut-tuning/candidates/B_n37_s060_p080/B_n37_s060_p080`.

## Exact winner render

```bash
bash /home/aron/config/nix-aron/home/aron/scripts/cut-silence.sh /home/aron/.tmp/silence-cut-tuning/source-first-180s.mp4 /home/aron/.tmp/silence-cut-tuning/candidates/B_n37_s060_p080/B_n37_s060_p080.mp4 0.60 -37dB --keep-silence 0.300 --audio-fade 0.008 --transcript-json /home/aron/.tmp/silence-cut-tuning/baseline/baseline.words.json --word-padding 0.080 --cut-map /home/aron/.tmp/silence-cut-tuning/candidates/B_n37_s060_p080/B_n37_s060_p080.cut-map.json
```

Exact saved command: `/home/aron/.tmp/silence-cut-tuning/candidates/B_n37_s060_p080/render-command.txt`. Cut map: `/home/aron/.tmp/silence-cut-tuning/candidates/B_n37_s060_p080/B_n37_s060_p080.cut-map.json`.

| Join | Source silence | Removed source interval | Output time | Planned retained gap (s) |
|---:|---:|---:|---:|---:|
| 1 | 50.261104–51.557146 | 50.411104–51.407146 | 50.411104 | 0.300000 |
| 2 | 54.462896–55.436125 | 54.612896–55.286125 | 53.616854 | 0.300000 |
| 3 | 55.692687–56.332667 | 55.842687–56.182667 | 54.173416 | 0.300000 |
| 4 | 69.658771–70.274021 | 69.808771–70.124021 | 67.799520 | 0.300000 |

Final copy command:

```bash
cp --reflink=auto --no-clobber '/home/aron/.tmp/silence-cut-tuning/candidates/B_n37_s060_p080/B_n37_s060_p080.mp4' '/mnt/data/Videos/OBS_Output/2026-08-02 17-38-52_first-3m_silence-cut.mp4'
```

## Tuning progress

| Phase | Candidate | dB | Min silence | Padding | Safe | Gap | Cuts | Vetoes | Removed (s) | Join loss | Remote loss | Align |
|---|---|---:|---:|---:|:---:|:---:|---:|---:|---:|---:|---:|---:|
| A | `A_n35_s045_p080` | -35 | 0.45 | 0.080 | yes | yes | 3 | 37 | 1.677 | 0 | 16 | 0.959233 |
| A | `A_n35_s060_p080` | -35 | 0.60 | 0.080 | yes | yes | 3 | 26 | 1.677 | 0 | 16 | 0.959233 |
| A | `A_n35_s080_p080` | -35 | 0.80 | 0.080 | yes | yes | 1 | 14 | 1.002 | 0 | 27 | 0.939614 |
| A | `A_n40_s045_p080` | -40 | 0.45 | 0.080 | yes | yes | 4 | 28 | 1.611 | 0 | 21 | 0.952955 |
| A | `A_n40_s060_p080` | -40 | 0.60 | 0.080 | yes | yes | 3 | 21 | 1.315 | 0 | 12 | 0.968825 |
| A | `A_n40_s080_p080` | -40 | 0.80 | 0.080 | yes | yes | 1 | 11 | 0.604 | 0 | 21 | 0.951807 |
| A | `A_n45_s045_p080` | -45 | 0.45 | 0.080 | yes | yes | 2 | 19 | 1.266 | 0 | 6 | 0.983213 |
| A | `A_n45_s060_p080` | -45 | 0.60 | 0.080 | yes | yes | 2 | 11 | 1.266 | 0 | 6 | 0.983213 |
| A | `A_n45_s080_p080` | -45 | 0.80 | 0.080 | yes | yes | 1 | 6 | 0.852 | 0 | 208 | 0.422764 |
| B | `B_n33_s060_p080` | -33 | 0.60 | 0.080 | yes | yes | 3 | 28 | 1.934 | 0 | 26 | 0.942029 |
| B | `B_n35_s050_p080` | -35 | 0.50 | 0.080 | yes | yes | 3 | 31 | 1.677 | 0 | 16 | 0.959233 |
| B | `B_n35_s060_p060` | -35 | 0.60 | 0.060 | yes | yes | 3 | 26 | 1.677 | 0 | 16 | 0.959233 |
| B | `B_n35_s060_p100` | -35 | 0.60 | 0.100 | yes | yes | 3 | 26 | 1.677 | 0 | 16 | 0.959233 |
| B | `B_n35_s070_p080` | -35 | 0.70 | 0.080 | yes | yes | 1 | 17 | 1.002 | 0 | 27 | 0.939614 |
| B | `B_n37_s050_p080` | -37 | 0.50 | 0.080 | yes | yes | 4 | 30 | 2.325 | 0 | 27 | 0.936221 |
| B | `B_n37_s060_p060` | -37 | 0.60 | 0.060 | yes | yes | 4 | 25 | 2.325 | 0 | 27 | 0.936221 |
| B | `B_n37_s060_p080` | -37 | 0.60 | 0.080 | yes | yes | 4 | 25 | 2.325 | 0 | 27 | 0.936221 |
| B | `B_n37_s060_p100` | -37 | 0.60 | 0.100 | yes | yes | 3 | 26 | 1.651 | 0 | 27 | 0.940750 |
| B | `B_n37_s070_p080` | -37 | 0.70 | 0.080 | yes | yes | 2 | 17 | 1.669 | 0 | 213 | 0.399606 |

Phase A covered required 3×3 grid. Phase B evaluated ten unique neighbor configs; duplicate config avoided. Per-candidate MP4, cut map, transcript formats, comparison metrics, probe, exact command remain under `/home/aron/.tmp/silence-cut-tuning/candidates/`; comparisons under `/home/aron/.tmp/silence-cut-tuning/metrics/`.

## Transcript comparison

Evaluator: `/home/aron/.tmp/silence-cut-tuning/evaluator.py`. Normalization uses Unicode NFKC + case-folding + Unicode punctuation/symbol removal only. Raw transcript text/JSON stays unchanged. Alignment ratio: `0.936221420`; baseline words `416`; winner words `415`.

Within evaluator ±0.5 s join windows, baseline deletion/substitution count: zero. This fixed-config ASR comparison is supporting evidence, not proof that speech was preserved. Remote ASR loss/substitution count: 27. Report: `application`@33.99–34.81 (delete), `that`@60.61–60.83 (delete), `that`@65.22–65.36 (replace), `well`@71.14–71.70 (replace), `it's`@72.26–72.74 (replace), `it's`@77.22–77.42 (replace), `it's`@84.56–86.24 (replace), `more`@86.24–86.26 (replace), `timux`@93.30–96.06 (replace), `timux`@99.01–100.03 (replace), `and`@104.43–104.65 (replace), `order`@104.65–106.19 (replace), `stuff`@137.44–137.60 (replace), `did`@166.99–167.07 (replace), `like`@167.21–167.31 (replace), `it`@168.67–168.79 (replace), `may`@168.79–168.99 (replace), `be`@168.99–169.23 (replace), `do`@172.53–172.53 (replace), `not`@173.39–173.99 (replace), `did`@176.07–176.17 (replace), `not`@176.17–176.33 (replace), `did`@177.11–177.21 (replace), `not`@177.21–177.37 (replace), `did`@178.99–179.03 (replace), `not`@179.03–179.23 (replace), `bar`@179.85–179.93 (delete)

Normalized alignment changes:

| Operation | Baseline token range | Baseline | Winner |
|---|---:|---|---|
| insert | 65:65 | — | application then so |
| delete | 69:70 | application | — |
| delete | 107:108 | that | — |
| replace | 122:123 | that | which |
| replace | 132:133 | well | not |
| replace | 135:136 | its | it is |
| replace | 147:148 | its | it is |
| replace | 168:170 | its more | it is rather |
| replace | 186:188 | timux timux | tmux tmux |
| replace | 201:203 | and order | herder |
| replace | 294:295 | stuff | thing |
| insert | 372:372 | — | of windows |
| replace | 374:375 | did | had |
| replace | 376:377 | like | liked |
| replace | 379:382 | it may be | its maybe |
| replace | 389:391 | do not | dont |
| replace | 394:396 | did not | didnt |
| replace | 399:401 | did not | didnt |
| replace | 406:408 | did not | didnt |
| delete | 415:416 | bar | — |

### Raw baseline text

```text
Hello everyone, today I'm going to present you a new terminal tool called Herder and I fell in love with it a few days ago or a week ago, I don't remember exactly and at the time I hated it, I fell in love immediately, it's just insane and as you can see here, I'm already in Herder and what is Herder? So it's a terminal interface user interface application so it's an application that launches into the terminal and it's a multiplexer so I'm going to bring you the site and so here is the site here and in fact the principle is it's an application that you install it looks like that as you have seen it is a multiplexer that allows you to manage multiple sessions in a terminal well more exactly it's a single terminal that will manage multiple sessions of terminals and it's very practical for if you have a lot of agents that launch or to switch between terminals between terminals rather it's more practical to do that and it replaces in any case it is the predecessor of a timux timux which is the most famous application to do this kind of thing and and order wants the same thing but in more modern with an interface which is clearly better honestly I will say that it is one of the big advantages it is the interface and also the fact that it is completely agent first and the third advantage is that it is very friendly for the use of a mouse so that is to say a mouse that is to say that there as you can see I click and it works even though I am in the terminal I can click on the stuff there are menus that open etc so I can do everything with the mouse there is also of course all the keyboard shortcuts to do it but it was thought to be used by the mouse and it is a huge plus and in fact to tell my personal story a little with this kind of software I had tried a few times timux when I was still working on windows with the application by default terminal and I did not like it so it may be because I was working in wsl I do not know but I did not like it I did not like the keyboard shortcuts I did not like the fact that there was a bar
```

### Raw winner text

```text
Hello everyone, today I'm going to present you a new terminal tool called Herder and I fell in love with it a few days ago or a week ago, I don't remember exactly and at the time I hated it, I fell in love immediately, it's just insane and as you can see here I'm already in Herder and what is Herder? So it's a application then so terminal interface user interface so it's an application that launches into the terminal and it's a multiplexer so I'm going to bring you the site and so here is the site here and in fact the principle is it's an application you install it looks like that as you have seen it is a multiplexer which allows you to manage multiple sessions in a terminal not more exactly it is a single terminal that will manage multiple sessions of terminals and it is very practical for if you have a lot of agents that launch or to switch between terminals between terminals rather it is rather practical to do that and it replaces in any case it is the predecessor of a tmux tmux which is the most famous application to do this kind of thing and Herder wants the same thing but in more modern with an interface which is clearly better honestly I will say that it is one of the big advantages it is the interface and also the fact that it is completely agent first and the third advantage is that it is very friendly for the use of a mouse so that is to say a mouse that is to say that there as you can see I click and it works even though I am in the terminal I can click on the thing there are menus that open etc so I can do everything with the mouse there is also of course all the keyboard shortcuts to do it but it was thought to be used by the mouse and it is a huge plus and in fact to tell my personal story a little with this kind of software I had tried a few times timux when I was still working on windows with the application by default terminal of windows and I had not liked it so it's maybe because I was working in wsl I don't know but I didn't like it I didn't like the keyboard shortcuts I didn't like the fact that there was a
```

Full evidence: `/home/aron/.tmp/silence-cut-tuning/metrics/B_n37_s060_p080.json`, baseline/winner word JSON, raw segment JSON, TXT, SRT.

## Every-join waveform/energy inspection

Decoded winner MP4 to mono 16 kHz signed-16 PCM. Checked exact cut-map output offset for each join. Boundary-step gate: `≤0.005 FS` (`-46.02 dBFS`); 4/4 gates passed, with max boundary step `0.000030518 FS`. Recorded 8 ms pre/post RMS plus ±20 ms peak. The cut map and filter planned 300 ms total retained handles plus 8 ms fades. No independent per-join rendered-gap measurement or fade-shape proof was made. Waveform PNGs: `/home/aron/.tmp/silence-cut-tuning/join-checks/B_n37_s060_p080-join-1.png` through `-join-4.png`. Numeric evidence: `/home/aron/.tmp/silence-cut-tuning/join-checks/B_n37_s060_p080.json`.

| Join | Output time | Step dBFS | Pre-join RMS dBFS | Post-join RMS dBFS | ±20 ms peak dBFS | Raw ASR context baseline → winner | Boundary-step gate |
|---:|---:|---:|---:|---:|---:|---|:---:|
| 1 | 50.411104 | -90.31 | -58.24 | -51.84 | -39.60 | you the site → you the site | pass |
| 2 | 53.616854 | -120.00 | -51.41 | -66.15 | -44.20 | and → and so | pass |
| 3 | 54.173416 | -90.31 | -64.84 | -65.14 | -48.10 | so here → and so here | pass |
| 4 | 67.799520 | -90.31 | -64.85 | -65.01 | -50.94 | a terminal → a terminal not | pass |

Sensory listening unavailable in execution env. No sensory proof or listening claim was made. Recorded waveform and energy values cannot prove perceptual pacing or absence of clipped phonemes. Final user taste/listening approval remains residual review.

## TDD + validation

Evaluator tests were written before implementation. Red log proves missing `evaluator` module; green log shows 5/5 pass:

- identical normalized words pass
- missing join word fails
- punctuation/case-only diff passes
- missing remote word reported
- source checksum change fails

Evidence: `/home/aron/.tmp/silence-cut-tuning/test_evaluator.py`, `/home/aron/.tmp/silence-cut-tuning/logs/evaluator-red.log`, `/home/aron/.tmp/silence-cut-tuning/logs/evaluator-green.log`, `/home/aron/.tmp/silence-cut-tuning/validation.json`.

Objective result: recommended/copy complete. Source untouched. Full 12:34 input unprocessed. Global Nix rebuild remains blocked by sudo password; repo cutter was invoked directly, so tuning did not depend on install.

## Residual review

- Listen to final once for subjective 300 ms rhythm, clipped phonemes, perceptual clicks. Sensory approval not performed.
- 27 remote normalized ASR deletions/substitutions occurred away from joins. Fixed-config ASR drift after timeline edits can explain them; evaluator reports, does not silently accept as identical. No cuts occur near those missing baseline tokens under 500 ms join context.
- Local ASR can miss quiet words. 80 ms protection, VAD-corrected baseline, silence detection, every-join PCM checks reduce risk; cannot prove absent ASR omissions.
- No visual-motion veto by accepted scope.
