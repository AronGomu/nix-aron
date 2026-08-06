---
name: make-html
description: generate html doc from input
disable-model-invocation: true
---

# Make Html

## Input

1. Prompt and/or list of path to file.

2. Effort :
   low - markdown style
   medium - css styling, graphs (default)
   high - heavy css styling, graphs and images

3. verbosity:
   prose (default)
   caveman-lite
   caveman-ultra

## Pre-flight

If not already, read :
`~/.agents/skills/caveman/SKILL.md`

## Process

1. Analyse resources given.
2. If **high** : Find local and/or internet images for illustration.
3. Generate and open to browser.

**DO NOT ASK USER INPUT UNTIL HTML GENERATION IS COMPLETE !**

## Style

Dark mode by default.
Focus human readability.

## Resources paths

### Local

~/brain/3_resources/assets/*
/mnt/data/Images/*
/mnt/data/Videos/*

### Online

- [Wojakland](https://wojakland.com/)
- [Know Your Meme](https://knowyourmeme.com)
- [Imgflip templates](https://imgflip.com/memetemplates)
- [GIPHY](https://giphy.com)
- [Tenor](https://tenor.com)
