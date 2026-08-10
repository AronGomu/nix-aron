# Trusted permission gate

Pi extension gating selected `bash` commands only in untrusted projects. Trusted projects run every model-issued shell command without confirmation.

Config: `~/.pi/agent/configs/trusted-permission-gate.json`

- `patterns`: case-insensitive regex strings gated in untrusted projects
- `blockWithoutUI`: block matching commands in headless mode when `true`

Package-provided `permission-gate` must remain excluded in `settings.json`; otherwise its global prompts still apply.
