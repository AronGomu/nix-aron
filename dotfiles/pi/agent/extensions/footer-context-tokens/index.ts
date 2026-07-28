import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import footer from "../../npm/node_modules/@adrianapan/pikit/agent/extensions/footer/index.js";
import { contextPctSegment } from "../../npm/node_modules/@adrianapan/pikit/agent/extensions/footer/segments/context.js";
import { formatTokens } from "../../npm/node_modules/@adrianapan/pikit/agent/extensions/footer/segments/helpers.js";

const PATCH_FLAG = Symbol.for("aron.footer-context-tokens.patched");

type PatchableSegment = typeof contextPctSegment & {
  [PATCH_FLAG]?: boolean;
};

export default function footerContextTokens(pi: ExtensionAPI) {
  const segment = contextPctSegment as PatchableSegment;
  if (!segment[PATCH_FLAG]) {
    const render = segment.render.bind(segment);
    segment.render = (ctx) => {
      const result = render(ctx);
      const tokenCount = formatTokens(ctx.usageStats.input + ctx.usageStats.output);

      return {
        ...result,
        content: result.content.replace(/\d+(?:\.\d+)?%/, tokenCount),
      };
    };
    segment[PATCH_FLAG] = true;
  }

  footer(pi);
}
