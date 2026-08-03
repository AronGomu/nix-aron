// /btw — a replica of Claude Code's "by the way" side-question feature.
//
// Ask a quick question about the current conversation without derailing the
// task in progress. The answer is produced by a throwaway, read-only pi run
// that forks the *current* session (so it sees the full conversation) but has
// no tools and never writes back to history. The result is shown in a
// dismissible overlay and is not added to the transcript.
//
//   /btw what was that config file called again?
//
// It is, in the words of the original, the inverse of a subagent: full
// conversation context, zero tools.

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const BTW_SYSTEM = [
  'The user has asked a quick side question ("by the way") while a task is in progress.',
  "Answer it concisely and directly, using only what is already in the conversation.",
  "You have no tools and cannot take any action — do not try to read files, run commands, or continue the main task.",
  "Just answer the question.",
].join(" ");

const TIMEOUT_MS = 120_000;

interface BtwEntry {
  question: string;
  answer: string;
}

export default function btw(pi: ExtensionAPI): void {
  // Ephemeral history of side questions for this session, browsable in the
  // overlay with left/right — matches Claude's /btw. Never persisted.
  const history: BtwEntry[] = [];

  pi.registerCommand("btw", {
    description:
      "Ask a quick side question about the current context (read-only, ephemeral)",
    handler: async (args, ctx) => {
      const question = (args ?? "").trim();
      if (!question) {
        ctx.ui.notify("Usage: /btw <question>", "warning");
        return;
      }
      if (!ctx.hasUI) {
        ctx.ui.notify("/btw needs an interactive terminal", "warning");
        return;
      }

      ctx.ui.setStatus("btw", "btw thinking…");
      let answer: string;
      try {
        answer = await runSideQuestion(pi, ctx, question);
      } catch (err) {
        ctx.ui.setStatus("btw", undefined);
        ctx.ui.notify(`btw failed: ${(err as Error).message}`, "error");
        return;
      }
      ctx.ui.setStatus("btw", undefined);

      if (!answer) {
        ctx.ui.notify("btw: no answer returned", "warning");
        return;
      }

      history.push({ question, answer });
      await showOverlay(ctx, history, history.length - 1);
    },
  });
}

// Run the side question as a separate, read-only pi process that forks the
// current session so it inherits the full conversation context. The fork is
// written to a throwaway session dir and deleted afterwards, so the real
// session is never touched.
async function runSideQuestion(
  pi: ExtensionAPI,
  ctx: Parameters<Parameters<ExtensionAPI["registerCommand"]>[1]["handler"]>[1],
  question: string,
): Promise<string> {
  const model = ctx.model as { provider?: string; id?: string } | undefined;
  const sessionFile = ctx.sessionManager.getSessionFile?.();

  const args: string[] = [
    "--print",
    "--no-tools",
    "--no-extensions",
    "--no-skills",
    "--no-prompt-templates",
    "--no-context-files",
  ];

  let tmpDir: string | undefined;
  if (sessionFile) {
    tmpDir = mkdtempSync(join(tmpdir(), "pi-btw-"));
    // Fork the live session (read-only source) into the throwaway dir.
    args.push("--fork", sessionFile, "--session-dir", tmpDir);
  } else {
    // No conversation yet — answer standalone, without persisting anything.
    args.push("--no-session");
  }

  if (model?.provider) args.push("--provider", model.provider);
  if (model?.id) args.push("--model", model.id);

  args.push("--append-system-prompt", BTW_SYSTEM, question);

  try {
    // Intentionally not wired to ctx.signal: a side question must survive
    // (and not disturb) the main turn.
    const res = await pi.exec("pi", args, {
      cwd: ctx.cwd,
      timeout: TIMEOUT_MS,
    });
    if (res.code !== 0) {
      const detail =
        res.stderr.trim().split("\n").filter(Boolean).pop() ??
        `pi exited with code ${res.code}`;
      throw new Error(detail);
    }
    return res.stdout.trim();
  } finally {
    if (tmpDir) {
      try {
        rmSync(tmpDir, { recursive: true, force: true });
      } catch {
        // best effort
      }
    }
  }
}

const DIM = "\x1b[2m";
const BOLD = "\x1b[1m";
const ITALIC = "\x1b[3m";
const RESET = "\x1b[0m";

// A minimal, dismissible overlay showing the answer. Duck-typed to pi-tui's
// structural Component contract (render / handleInput / invalidate) so the
// extension needs no runtime import from the harness packages.
function showOverlay(
  ctx: Parameters<Parameters<ExtensionAPI["registerCommand"]>[1]["handler"]>[1],
  history: BtwEntry[],
  startIndex: number,
): Promise<void> {
  return ctx.ui.custom<void>(
    (tui: { requestRender: () => void }, _theme, _keybindings, done: () => void) => {
      let index = startIndex;
      let scroll = 0;
      let lastWidth = 80;
      let lastBody: string[] = [];

      const visibleRows = () =>
        Math.max(3, ((process.stdout.rows as number) || 24) - 9);

      const maxScroll = () => Math.max(0, lastBody.length - visibleRows());

      const rerender = () => tui.requestRender();

      return {
        invalidate() {},
        render(width: number): string[] {
          lastWidth = width;
          const inner = Math.max(10, width - 2);
          const entry = history[index];
          lastBody = wrap(entry.answer, inner);
          if (scroll > maxScroll()) scroll = maxScroll();

          const counter =
            history.length > 1 ? `${DIM} (${index + 1}/${history.length})${RESET}` : "";
          const lines: string[] = [];
          lines.push(`${BOLD}❓ btw${RESET}${counter}`);
          for (const q of wrap(entry.question, inner)) {
            lines.push(`${DIM}${ITALIC}${q}${RESET}`);
          }
          lines.push("");

          const window = lastBody.slice(scroll, scroll + visibleRows());
          lines.push(...window);
          if (maxScroll() > 0) {
            const more = scroll < maxScroll() ? " ↓ more" : "";
            lines.push(`${DIM}—${more}${RESET}`);
          }

          lines.push("");
          const nav = history.length > 1 ? " · ←/→ history" : "";
          lines.push(
            `${DIM}↑/↓ scroll · c copy${nav} · esc close${RESET}`,
          );
          return lines;
        },
        handleInput(data: string): void {
          switch (data) {
            case "\r":
            case "\n":
            case " ":
            case "q":
            case "\x1b": // bare escape
              done();
              return;
            case "\x1b[A": // up
            case "k":
              scroll = Math.max(0, scroll - 1);
              break;
            case "\x1b[B": // down
            case "j":
              scroll = Math.min(maxScroll(), scroll + 1);
              break;
            case "\x1b[5~": // page up
              scroll = Math.max(0, scroll - visibleRows());
              break;
            case "\x1b[6~": // page down
              scroll = Math.min(maxScroll(), scroll + visibleRows());
              break;
            case "\x1b[D": // left — previous side question
              if (index > 0) {
                index -= 1;
                scroll = 0;
              }
              break;
            case "\x1b[C": // right — next side question
              if (index < history.length - 1) {
                index += 1;
                scroll = 0;
              }
              break;
            case "c": {
              const ok = copyToClipboard(history[index].answer);
              ctx.ui.notify(
                ok ? "btw answer copied" : "no clipboard tool found",
                ok ? "info" : "warning",
              );
              return;
            }
            default:
              return;
          }
          rerender();
        },
      };
    },
    {
      overlay: true,
      overlayOptions: {
        anchor: "center",
        width: "80%",
        maxHeight: "70%",
        margin: 2,
      },
    },
  );
}

// Word-wrap plain text to a column width, preserving existing line breaks.
// Length is measured ignoring ANSI escapes (answers are plain, but be safe).
function wrap(text: string, width: number): string[] {
  const out: string[] = [];
  for (const raw of text.split("\n")) {
    if (raw.length <= width) {
      out.push(raw);
      continue;
    }
    let line = "";
    for (const word of raw.split(/(\s+)/)) {
      if (visibleLength(line + word) > width && line) {
        out.push(line.trimEnd());
        line = word.trimStart();
      } else {
        line += word;
      }
    }
    if (line.trim() || out.length === 0) out.push(line.trimEnd());
  }
  return out;
}

function visibleLength(s: string): number {
  // eslint-disable-next-line no-control-regex
  return s.replace(/\x1b\[[0-9;]*m/g, "").length;
}

function copyToClipboard(text: string): boolean {
  const tools: [string, string[]][] = [
    ["wl-copy", []],
    ["xclip", ["-selection", "clipboard"]],
    ["xsel", ["--clipboard", "--input"]],
    ["pbcopy", []],
  ];
  for (const [cmd, args] of tools) {
    try {
      const res = spawnSync(cmd, args, { input: text });
      if (!res.error && res.status === 0) return true;
    } catch {
      // try next
    }
  }
  return false;
}
