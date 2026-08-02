---
name: grok-imagine
description: >
  Generate or edit images with xAI Grok Imagine via the grok-imagine CLI.
  Load when the user asks to generate, create, or edit images with Grok/xAI/Imagine.
---

# grok-imagine

Use system binary `grok-imagine` (from nix-aron). Needs `XAI_API_KEY` or `GROK_API_KEY`
in env or `~/.pi/agent/configs/.env`.

## Generate

```bash
grok-imagine -o /tmp/out.jpg "prompt here"
grok-imagine -r 16:9 -R 2k -o hero.jpg "wide cinematic landscape"
grok-imagine -n 4 -o var.jpg "four variations of a logo mark"
```

## Edit

```bash
grok-imagine --edit ./photo.png -o edited.jpg "render as pencil sketch"
grok-imagine --edit https://example.com/a.png -o out.jpg "add dramatic lighting"
```

## Defaults

| Flag | Default |
|------|---------|
| model | `grok-imagine-image-quality` |
| res | `1k` (`2k` allowed) |
| count | `1` |

## Rules

1. Write outputs under workspace or `/tmp`, not secrets dirs.
2. Print final path(s) to user.
3. On auth error: tell user to set `XAI_API_KEY` in `~/.pi/agent/configs/.env` then restart pi / open new shell.
4. Do not invent API calls when CLI exists.
