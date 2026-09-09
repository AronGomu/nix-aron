import {
  getAgentDir,
  SettingsManager,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";

export default function rememberModel(pi: ExtensionAPI) {
  let pending = Promise.resolve();

  function remember(ctx: ExtensionContext) {
    // Child/RPC/one-shot sessions must not change interactive startup defaults.
    if (ctx.mode !== "tui" || !ctx.model) return;
    const { provider, id } = ctx.model;
    const level = ctx.thinkingLevel ?? pi.getThinkingLevel();
    const cwd = ctx.cwd;

    // Capture the selection before queuing: rapid shortcuts may mutate ctx.
    pending = pending.then(async () => {
      try {
        const settings = SettingsManager.create(cwd, getAgentDir(), {
          projectTrusted: false,
        });
        if (settings.drainErrors().length) throw new Error("Settings unavailable");
        settings.setDefaultModelAndProvider(provider, id);
        settings.setDefaultThinkingLevel(level);
        // Existing per-model defaults otherwise override the remembered level.
        if (settings.getModelThinkingLevel(provider, id) !== undefined) {
          settings.setModelThinkingLevel(provider, id, level);
        }
        await settings.flush();
        if (settings.drainErrors().length) throw new Error("Settings write failed");
      } catch {
        ctx.ui.notify("Could not save Pi model/thinking defaults; check writable settings.json", "error");
      }
    });
    return pending;
  }

  pi.on("model_select", (_event, ctx) => remember(ctx));
  pi.on("thinking_level_select", (_event, ctx) => remember(ctx));
  pi.on("session_shutdown", () => pending);
}
