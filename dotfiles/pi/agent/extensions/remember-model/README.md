# Remember model / thinking

- A1. Pi 0.85.1 model/thinking controls normally change session state only; Ctrl+S saves defaults. This extension saves each interactive selection automatically, including model shortcuts, Ctrl+P, Shift+Tab, `/model`, `/thinking`, extension selections, session-restore selection events.
- A2. Writes `defaultProvider`, `defaultModel`, `defaultThinkingLevel` in Pi's writable global `settings.json`, using native SettingsManager locking/merge. `PI_CODING_AGENT_DIR` supported through `getAgentDir()`.
- A3. Existing thinking override for selected model follows effective selected level. Other prefs/overrides preserved. No new per-model override created when absent. Keep runtime `modelThinkingLevels` during config redeployment.
- A4. Fresh Pi process or `/new` reads saved defaults. Explicit CLI/project overrides still win. No startup/shutdown-only write; selection events required. Across terminals, last completed write wins.
- A5. Only TUI selections persist. RPC, JSON, print/subagent runs ignored. No timers, auth reads, model API calls, forced model switch, repository writes, or Git sync on selection. Pending writes drain before session teardown.
- A6. Deploy directory under Pi's global `extensions/`; existing recursive Nix wiring includes it. User runs `rebuild`, then `/reload` or restarts Pi. Portable installer deploys same source. Existing model-switch shortcut thinking presets remain unchanged; selecting a preset sets low, subsequent thinking changes are remembered.
- A7. Pi source references: installed `docs/settings.md` Model & Thinking; `docs/extensions.md` model_select/thinking_level_select/session_shutdown; `dist/core/settings-manager.js` SettingsManager setters/flush. Requires these Pi 0.85.1 APIs; no extra npm dependency.

## Validation

From repo root, with Pi importable as npm dependency:

```bash
node --experimental-vm-modules --test tests/pi-remember-model.mjs
```

For externally installed Pi, set `PI_TEST_PACKAGE_DIR` to inspected package root containing `dist/index.js`. Tests use real SettingsManager + isolated temporary config, mock only extension events/getAgentDir. No live config/API writes.

- V1. Interactive model/thinking persistence, effective off/max values, rapid-event ordering, shutdown drain, headless isolation, unrelated/project settings preservation, per-model override, malformed JSON recovery covered.
- V2. Manual target check: select model → set thinking → `/new`; confirm pair. Quit/restart plain `pi`; confirm pair again. Run headless child with other model; interactive defaults stay unchanged. Explicit CLI/project overrides excluded from this expectation.
