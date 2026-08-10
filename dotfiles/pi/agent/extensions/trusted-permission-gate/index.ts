import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

import { loadConfig } from "./config.js";

export default function trustedPermissionGate(pi: ExtensionAPI) {
  const { patterns, blockWithoutUI, errors } = loadConfig();

  if (errors?.length) {
    pi.on("session_start", (_event, ctx) => {
      ctx.ui.notify(
        `[trusted-permission-gate] Bad pattern(s) in config:\n${errors.join("\n")}\n\nFalling back to built-in defaults. Edit ~/.pi/agent/configs/trusted-permission-gate.json to fix.`,
        "warning",
      );
    });
  }

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash" || ctx.isProjectTrusted()) {
      return undefined;
    }

    const command = event.input.command as string;
    if (!patterns.some((pattern) => pattern.test(command))) {
      return undefined;
    }

    if (!ctx.hasUI) {
      return blockWithoutUI
        ? {
            block: true,
            reason:
              "[trusted-permission-gate] Command blocked in untrusted project — matches a gated pattern.",
          }
        : undefined;
    }

    const allowed = await ctx.ui.confirm(
      "Dangerous command in untrusted project",
      `${command}\n\nAllow this command?`,
    );

    return allowed
      ? undefined
      : {
          block: true,
          reason:
            "[trusted-permission-gate] Command blocked by user in untrusted project.",
        };
  });
}
