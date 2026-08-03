Implemented optional output derivation + transcript opt-in.

## Slice T5 report
- State: done
- SHA: `35fb2fae340351669836eff6310bbed186b31509`
- Files: `home/aron/scripts/cut-silence.sh`, `home/aron/scripts/tests/cut-silence-test.sh`; T5 plan boxes updated unstaged
- Validation: pass — syntax clean; 26/26 tests; Nix eval/build; built-package auto-output + `-o` smoke
- Assumptions: hidden `.video` → `.video-altered.mp4`; numeric max-silence keeps existing decimal syntax
- Blocker: none. Independent reviewer gate pending
- Next parent action: continue