import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

interface TrustedPermissionGateConfig {
  patterns: RegExp[];
  blockWithoutUI: boolean;
  errors?: string[];
}

const DEFAULT_PATTERNS = [
  /\bsudo\b/i,
  /\b(chmod|chown)\s+(?:-[a-z]+\s+)*777(?:\b|$)/i,
  /\bprintenv\b/i,
  /(^|\s)env(\s|$)/i,
];

const CONFIG_PATH = join(
  homedir(),
  ".pi",
  "agent",
  "configs",
  "trusted-permission-gate.json",
);

export function loadConfig(): TrustedPermissionGateConfig {
  try {
    const parsed = JSON.parse(readFileSync(CONFIG_PATH, "utf8"));
    const blockWithoutUI =
      typeof parsed.blockWithoutUI === "boolean"
        ? parsed.blockWithoutUI
        : true;
    const patternStrings =
      Array.isArray(parsed.patterns) && parsed.patterns.length > 0
        ? (parsed.patterns as unknown[]).filter(
            (pattern): pattern is string => typeof pattern === "string",
          )
        : null;

    if (!patternStrings?.length) {
      return { patterns: DEFAULT_PATTERNS, blockWithoutUI };
    }

    const patterns: RegExp[] = [];
    const errors: string[] = [];
    for (const pattern of patternStrings) {
      try {
        patterns.push(new RegExp(pattern, "i"));
      } catch {
        errors.push(`Invalid pattern: "${pattern}"`);
      }
    }

    return {
      patterns: patterns.length > 0 ? patterns : DEFAULT_PATTERNS,
      blockWithoutUI,
      errors: errors.length > 0 ? errors : undefined,
    };
  } catch {
    return { patterns: DEFAULT_PATTERNS, blockWithoutUI: true };
  }
}
