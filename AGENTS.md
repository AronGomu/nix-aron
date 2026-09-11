# nix-aron — config ownership

Read `/home/aron/AGENTS.md`, shared `~/.agents/GLOBAL_RULES.md`, and `NIX-CHEATSHEET.md` before work.

## Sync contract

- S1. This checkout owns NixOS/Home Manager sources described in [docs/deployment.md](docs/deployment.md). Checks: [docs/validation.md](docs/validation.md). Invoke shared `sync-config-aron` skill before edits and after each completed batch; manual/GUI changes need explicit reconciliation, not a watcher.
- S2. User-authorized remote: existing `origin` (`AronGomu/nix-aron` on GitHub). Authoritative bootstrap branch: `main`. Public repository: never publish credentials, auth state, or private data. Current task authorizes reviewed fast-forward pushes to `origin/main` from the working branch. Future work follows global branch/approval policy.
- S3. Inspect status, fetch without pruning, verify ancestry before edits. Preserve unrelated work. No amend/rebase/reset/revert/force-push; recovery is a new corrective commit. Inspect outgoing content and publish hooks; no tracked GitHub workflows existed when this contract was established. Recheck if deployment hooks or remote policy change. Source pushes do not authorize system activation.
- S4. Completion requires validated intentional changes committed, whole worktree clean including untracked files, fetched `origin/main` equal to HEAD, ahead/behind `0 0`. Missing auth, divergence, unknown irreversible publish effects, or unrelated dirt block full sync; never hide or discard them.

## Apply boundary

- A1. Active outputs: `desk-main-nvme` and `desk-main-samsung`; no bare `desk-main`. Running disk determines output through `nixos-host`.
- A2. Home Manager is integrated into NixOS. Never run `home-manager switch`, never edit legacy `/etc/nixos`, never activate the system on behalf of the user.
- A3. After validated push, ask user to run `sudo nixos-rebuild switch --flake /home/aron/config/nix-aron#$(nixos-host)`. No rebuild is implied by commit or push.
