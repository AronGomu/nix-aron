import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SWITCHES = [
  {
    command: "grok",
    description: "Switch to Grok 4.5 (xai)",
    provider: "xai",
    model: "grok-4.5",
  },
  {
    command: "sol",
    description: "Switch to GPT-5.6 Sol (openai-codex)",
    provider: "openai-codex",
    model: "gpt-5.6-sol",
  },
] as const;

export default function modelSwitch(pi: ExtensionAPI) {
  for (const entry of SWITCHES) {
    pi.registerCommand(entry.command, {
      description: entry.description,
      handler: async (_args, ctx) => {
        const model = ctx.modelRegistry.find(entry.provider, entry.model);
        if (!model) {
          ctx.ui.notify(
            `Model ${entry.provider}/${entry.model} not found`,
            "error",
          );
          return;
        }

        const ok = await pi.setModel(model);
        if (!ok) {
          ctx.ui.notify(
            `No API key for ${entry.provider}/${entry.model}`,
            "error",
          );
          return;
        }

        ctx.ui.notify(`Model → ${entry.provider}/${entry.model}`, "info");
      },
    });
  }
}
