import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { Component } from "@earendil-works/pi-tui";
import { truncateToWidth } from "@earendil-works/pi-tui";

const ART = [
  "      █████      ██████████      █████████       █████      ████",
  "     ███ ███     ███     ███   ███     ███      ██████     ████",
  "    ███   ███    ███     ███  ███       ███     ███ ███    ████",
  "   ███     ███   ███     ███  ███       ███     ███  ███   ████",
  "  █████████████  ██████████   ███       ███     ███   ███  ████",
  "  ███       ███  ███   ███    ███       ███     ███    ███ ████",
  "  ███       ███  ███    ███   ███       ███     ███     ███████",
  "  ███       ███  ███     ███   ███     ███      ███      ██████",
  "  ███       ███  ███      ███   █████████       ███       █████",
];

function centerLine(line: string, width: number): string {
  const leftPadding = Math.max(0, Math.floor((width - line.length) / 2));
  return " ".repeat(leftPadding) + line;
}

class AronHeader implements Component {
  constructor(private readonly theme: any) {}

  render(width: number): string[] {
    const borderWidth = Math.max(0, Math.min(width, 92));
    const border = this.theme.fg("borderMuted", centerLine("─".repeat(borderWidth), width));
    const art = ART.map((line) => {
      const centered = centerLine(line, width);
      return truncateToWidth(this.theme.fg("error", this.theme.bold(centered)), width);
    });

    return [border, ...art, border];
  }

  invalidate(): void {}
}

export default function aronWelcome(pi: ExtensionAPI) {
  const install = (ctx: any) => {
    if (!ctx.hasUI) return;
    ctx.ui.setTitle("ARON // pi");
    ctx.ui.setStatus("aron", ctx.ui.theme.fg("error", "ARON"));
    ctx.ui.setHeader((_tui, theme) => new AronHeader(theme));
  };

  pi.on("session_start", async (_event, ctx) => {
    install(ctx);
  });

  pi.on("model_select", async (_event, ctx) => {
    install(ctx);
  });

  pi.registerCommand("aron", {
    description: "Refresh the ARON neofetch-style startup header",
    handler: async (_args, ctx) => {
      install(ctx);
      ctx.ui.notify("ARON header refreshed", "info");
    },
  });
}
