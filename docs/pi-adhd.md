# Pi ADHD mode

- A1. Upstream: [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd/tree/24d22f783e57cb73c957848b588c6f651b6f9cd8), reviewed revision `24d22f783e57cb73c957848b588c6f651b6f9cd8` (package version 0.2.0). Followed upstream `AGENTS.md`, `INSTALL.md` Pi instructions. Native package includes extension + canonical skill; no copied rules or extra skill registration.
- A2. Nix source: `dotfiles/pi/agent/settings.json` pins package; `dotfiles/pi/agent/i-have-adhd.json` supplies defaults. `home/aron/agents.nix` deploys global defaults through Home Manager. User runs `rebuild`; Pi installs missing package at next network-enabled startup. No system apply from agent.
- A3. Portable source: corresponding `config/pi/agent/` files. Merge package entry into writable `~/.pi/agent/settings.json`; seed `~/.pi/agent/i-have-adhd.json` after conflict review. Preserve model choices, package exclusions, auth, sessions. Restart Pi after deployment.
- A4. New sessions start ON; footer reports `● ADHD ON`. `/i-have-adhd` toggles; `/i-have-adhd on` enables; `/i-have-adhd off` disables. Upstream contract preserves saved session choice on resume/reload; new sessions still use global ON default. See V3 for remaining resume validation. `/skill:i-have-adhd` enables via alias.
- A5. Caveman config remains unchanged. Prefer mode-specific slash commands; upstream also recognizes `normal mode`, which can be ambiguous with other style modes. Global OFF default requires changing managed `alwaysOn` to `false` and redeploying; remove any separately created `.i-have-adhd-always` flag only after reviewing it.

## Validation

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_pi_adhd.py -v
```

- V1. Config checks cover exact package pin, one installation, global ON/visible status, preserved caveman ultra default.
- V2. Upstream runtime check: from reviewed package checkout, `python3 scripts/check_pi_extension.py --runtime pi`. Uses isolated agent config, no model request; tests commands, skill alias, toggling, reload, always-on flag. Config-file default additionally requires fresh-session check using deployed `i-have-adhd.json` without `--adhd`.
- V3. After deployment, start Pi; check `● ADHD ON`, run `/i-have-adhd off`, then `/new`. New session must show ON; resumed disabled session must remain OFF. Omarchy target UI remains user validation. Pi 0.85.1 isolated checks passed global config default ON across two fresh processes, explicit OFF, upstream toggle/alias/reload smoke. Custom restart/resume probe did not recover its synthetic session state; real-conversation resume persistence remains unverified. No model requests were made.

## Assumptions

- S1. Requested future-session behavior means global ON default with per-session toggles, matching upstream contract; not a cross-session toggle writer.
- S2. Package download uses Pi's existing package-management mechanism, not a new Nix flake input. Changing upstream pin is a separately reviewed update.
