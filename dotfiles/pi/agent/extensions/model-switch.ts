import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";

const CLAUDE_BRIDGE = "claude-bridge";

// `thinking` is deliberately absent on the xai/openai-codex entries: those keep
// whatever shift+tab left the session on. The Claude entries pin low —
// reaching for Claude here should default to fast, cheap thinking.
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
  {
    command: "opus",
    description: "Switch to Claude Opus 5.0 (claude-bridge, low thinking)",
    provider: CLAUDE_BRIDGE,
    model: "claude-opus-5",
    thinking: "low",
  },
  {
    command: "sonnet",
    description: "Switch to Claude Sonnet 5.0 (claude-bridge, low thinking)",
    provider: CLAUDE_BRIDGE,
    model: "claude-sonnet-5",
    thinking: "low",
  },
  {
    command: "fable",
    description: "Switch to Claude Fable 5 (claude-bridge, low thinking)",
    provider: CLAUDE_BRIDGE,
    model: "claude-fable-5",
    thinking: "low",
  },
] as const;

type Switch = (typeof SWITCHES)[number];
type Thinking = Extract<Switch, { thinking: unknown }>["thinking"];

async function applySwitch(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
  provider: string,
  modelId: string,
  thinking?: Thinking,
) {
  const model = ctx.modelRegistry.find(provider, modelId);
  if (!model) {
    ctx.ui.notify(`Model ${provider}/${modelId} not found`, "error");
    return;
  }

  const ok = await pi.setModel(model);
  if (!ok) {
    ctx.ui.notify(`No credentials for ${provider}/${modelId}`, "error");
    return;
  }

  // setThinkingLevel clamps to what the model actually supports, so a model
  // without xhigh degrades instead of erroring.
  if (thinking) {
    pi.setThinkingLevel(thinking);
  }

  const suffix = thinking ? ` (thinking ${thinking})` : "";
  ctx.ui.notify(`Model → ${provider}/${modelId}${suffix}`, "info");
}

export default function modelSwitch(pi: ExtensionAPI) {
  for (const entry of SWITCHES) {
    pi.registerCommand(entry.command, {
      description: entry.description,
      handler: async (_args, ctx) => {
        await applySwitch(
          pi,
          ctx,
          entry.provider,
          entry.model,
          "thinking" in entry ? entry.thinking : undefined,
        );
      },
    });
  }
}
