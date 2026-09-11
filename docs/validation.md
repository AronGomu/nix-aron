# Config validation

Root [AGENTS.md](../AGENTS.md) owns sync/publish policy. Do not run system activation to validate source.

| ID | Command / check | Evidence |
|---|---|---|
| V1 | `PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p test_tailscale_open.py -v` | Mock-only VPN, sudo, Tailscale and browser paths. No live network changes. |
| V2 | `nix-instantiate --parse home/aron/tailscale.nix >/dev/null` | Nix module syntax accepted. |
| V3 | `nix eval --json .#nixosConfigurations.desk-main-nvme.config.home-manager.users.aron.xdg.desktopEntries.tailscale-open --apply 'entry: { inherit (entry) name exec terminal; }'` | Imported HM desktop entry resolves, terminal enabled, packaged executable. Also evaluate `desk-main-samsung` for mirrored module wiring. New Nix files must be staged first so flakes include them. |
| V4 | `nix flake check --no-build` | Broader evaluation if practical. Report environmental/inherited failures separately; do not claim full evaluation from syntax-only checks. |
| V5 | `nix shell nixpkgs#gitleaks -c gitleaks git --no-banner --redact --log-opts='origin/main..HEAD'` | Redacted outgoing-commit scan; also scan intentional working changes before committing using `gitleaks dir --no-banner --redact` on reviewed source scope. No unresolved findings. |
| V6 | `git diff --check`; `git diff --cached --check`; `git status --porcelain=v1 --untracked-files=all`; `git rev-list --left-right --count HEAD...origin/main` | Intentional paths only, empty final status, fetched remote equality `0 0`. |

## Runtime check after user rebuild

- R1. Open desktop launcher **Tailscale (disconnect other VPNs)** or run `tailscale-open` as desktop user. This disconnects VPNs and may expose traffic outside VPN protection. Use local desktop, not a remote connection relying on those VPNs.
- R2. With disposable/local network context, verify known VPN disconnect, browser login if logged out, no reauthentication if already logged in, reachable desktop tailnet IP. Browser auth and real network changes are not exercised by offline tests.
- R3. If an unknown tunnel or kill switch remains, verify visible blocker without firewall/DNS/security-service disablement. Do not publish raw auth URLs or account-bearing logs as evidence.
