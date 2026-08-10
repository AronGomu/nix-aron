import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const THRESHOLD_TOKENS = 200_000;

export default function uncachedAutoCompact(pi: ExtensionAPI) {
  let enabled = true;
  let compacting = false;

  pi.on("turn_end", (event, ctx) => {
    if (
      !enabled ||
      compacting ||
      event.message.role !== "assistant" ||
      event.message.stopReason === "aborted" ||
      event.message.stopReason === "error"
    ) {
      return;
    }

    // cacheRead was served from cache. input + cacheWrite is fresh prompt work.
    const uncachedTokens =
      event.message.usage.input + event.message.usage.cacheWrite;
    if (uncachedTokens <= THRESHOLD_TOKENS) {
      return;
    }

    compacting = true;
    if (ctx.hasUI) {
      ctx.ui.notify(
        `Uncached prompt reached ${uncachedTokens.toLocaleString()} tokens; compacting`,
        "warning",
      );
    }

    ctx.compact({
      onComplete: () => {
        compacting = false;
        if (ctx.hasUI) {
          ctx.ui.notify("Uncached auto-compaction completed", "info");
        }
      },
      onError: (error) => {
        compacting = false;
        if (ctx.hasUI) {
          ctx.ui.notify(
            `Uncached auto-compaction failed: ${error.message}`,
            "error",
          );
        }
      },
    });
  });

  pi.registerCommand("uncached-compact", {
    description: "Toggle auto-compaction above 200K uncached prompt tokens",
    handler: async (_args, ctx) => {
      enabled = !enabled;
      ctx.ui.notify(
        `Uncached auto-compaction ${enabled ? "enabled" : "disabled"}`,
        "info",
      );
    },
  });
}
