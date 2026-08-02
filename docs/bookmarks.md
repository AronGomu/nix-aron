# Bookmarks hybrid setup

Two layers. Different jobs.

| Layer | Where | Editable in browser? | On work PC? |
| --- | --- | --- | --- |
| **Nix managed** | `/etc/brave/policies/managed/` | No (read-only folder **Nix**) | No — this machine only |
| **Floccus sync** | Your normal bookmarks + private git repo | Yes | Yes — install Floccus, same repo |

Nix = small always-on pin set after rebuild.  
Floccus = daily bookmarks, multi-device, work laptop.

---

## Home (this NixOS box)

### 1. Rebuild

```bash
sudo nixos-rebuild switch --flake /home/aron/coding/nix-aron#desk-main
```

Restart Brave. You should see a **Nix** bookmarks folder (managed).

### 2. One-time Floccus + git backend

Local seed already at `/home/aron/coding/bookmarks` (`bookmarks.xbel` + README).

Create private GitHub remote (needs `gh auth` once):

```bash
gh auth login   # if gh not logged in
cd /home/aron/coding/bookmarks
gh repo create bookmarks --private --source=. --remote=origin --push
```

Then:

1. GitHub → Settings → Developer settings → Personal access tokens  
   Fine-grained token: Contents read/write on `bookmarks` only.
2. Brave → Floccus → Add account → **Git**
   - Repo URL: `https://github.com/AronGomu/bookmarks.git`
   - Branch: `main`
   - File: `bookmarks.xbel`
   - Auth: token
3. Pick local folder to sync (usually **Bookmarks bar** or a folder `Synced`).
4. Sync strategy: **merge** (safest) or bidirectional.
5. Click **Sync** once. Confirm GitHub file updates.

After that: add/edit/delete bookmarks in Brave as usual. Floccus pushes/pulls on its interval (or manual sync).

**Do not** put the Floccus file inside `nix-aron` if you hate noisy commits. Separate private repo is cleaner.

---

## Work PC (no Nix)

Goal: same daily bookmarks, zero Nix.

1. Install Brave (or Chrome/Firefox).
2. Install **Floccus** from the store  
   Chrome ID: `fnaicdffflnofjppbagibeoednhnbjhg`
3. Same Git account settings as home (repo URL + token + same file path).
4. First sync → bookmarks land in the folder you chose.
5. Work as normal. Sync back home the same way.

Optional work hygiene:

- Sync only a folder `Personal` / `Synced` (not whole profile junk).
- Leave work-only bookmarks in a local folder **not** synced.
- Revoke token when leaving the job; create a new one at home if needed.

---

## Import existing bookmarks into Floccus (first time)

If Brave already has bookmarks:

1. Set Floccus local folder = Bookmarks bar (or parent folder that holds them).
2. Backend empty file OK.
3. Sync once → upload wins into git.
4. Work PC pulls that file.

Or classic HTML:

1. Brave → Bookmark manager → ⋮ → Export bookmarks (HTML).
2. On other browser: Import bookmarks from HTML.  
   (One-shot; no ongoing sync. Prefer Floccus for ongoing.)

---

## Edit Nix managed set

File: `modules/nixos/brave-policies.nix`  
Rebuild → restart Brave. Managed folder updates. Normal bar unchanged.

---

## Mental model

```
┌──────────────────────────────┐
│  Brave on home (NixOS)       │
│  ├─ folder "Nix"  ← policy   │  rebuild only
│  └─ bar / Synced  ← Floccus ─┼── private git repo ──► work Brave + Floccus
└──────────────────────────────┘
```

- Lost laptop? Git still has synced bookmarks.  
- Work locked down, no extension? Export HTML from home once, import at work (manual).  
- Nix folder missing on work: expected — not part of Floccus.
