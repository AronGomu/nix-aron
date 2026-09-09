import assert from "node:assert/strict";
import { existsSync } from "node:fs";
import { mkdtemp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import { stripTypeScriptTypes } from "node:module";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { SourceTextModule, SyntheticModule } from "node:vm";
import test from "node:test";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = existsSync(join(root, "config/pi/agent")) ? "config" : "dotfiles";
const extension = process.env.PI_TEST_EXTENSION || join(root, sourceRoot, "pi/agent/extensions/remember-model/index.ts");
const api = process.env.PI_TEST_PACKAGE_DIR
  ? await import(pathToFileURL(join(process.env.PI_TEST_PACKAGE_DIR, "dist/index.js")))
  : await import("@earendil-works/pi-coding-agent");

async function fixture(t, initial = {}) {
  await mkdir(join(root, ".tmp"), { recursive: true });
  const dir = await mkdtemp(join(root, ".tmp/pi-defaults-"));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const agentDir = join(dir, "agent");
  const cwd = join(dir, "project");
  await mkdir(agentDir);
  await mkdir(join(cwd, ".pi"), { recursive: true });
  const settingsPath = join(agentDir, "settings.json");
  await writeFile(settingsPath, JSON.stringify(initial));
  const imported = new SyntheticModule(["SettingsManager", "getAgentDir"], function () {
    this.setExport("SettingsManager", api.SettingsManager);
    this.setExport("getAgentDir", () => agentDir);
  });
  const source = new SourceTextModule(stripTypeScriptTypes(await readFile(extension, "utf8")));
  await source.link((specifier) => {
    assert.equal(specifier, "@earendil-works/pi-coding-agent");
    return imported;
  });
  await source.evaluate();
  const handlers = new Map();
  const notices = [];
  const ctx = {
    cwd, mode: "tui", model: { provider: "test-provider", id: "model-a" },
    thinkingLevel: "low", ui: { notify: (...args) => notices.push(args) },
  };
  source.namespace.default({ on: (event, handler) => handlers.set(event, handler) });
  return {
    ctx, handlers, notices, settingsPath, agentDir, cwd,
    emit: async (event, data = {}) => handlers.get(event)?.(data, ctx),
    saved: async () => JSON.parse(await readFile(settingsPath, "utf8")),
  };
}

test("last selected model and effective thinking become startup defaults", async (t) => {
  const f = await fixture(t, { theme: "slop", packages: ["keep"] });
  f.ctx.thinkingLevel = "high";
  await f.emit("model_select", { model: f.ctx.model, source: "set" });
  const fresh = api.SettingsManager.create(f.cwd, f.agentDir, { projectTrusted: false });
  assert.equal(fresh.getDefaultProvider(), "test-provider");
  assert.equal(fresh.getDefaultModel(), "model-a");
  assert.equal(fresh.getDefaultThinkingLevel(), "high");
  assert.equal((await f.saved()).theme, "slop");
  assert.deepEqual((await f.saved()).packages, ["keep"]);
});

test("thinking-only selection saves immediately without waiting for exit", async (t) => {
  const f = await fixture(t);
  f.ctx.thinkingLevel = "max";
  await f.emit("thinking_level_select", { level: "max" });
  assert.equal((await f.saved()).defaultThinkingLevel, "max");
  assert.equal((await f.saved()).defaultModel, "model-a");
});

test("rapid model/thinking events retain final pair; shutdown drains writes", async (t) => {
  const f = await fixture(t);
  const first = f.emit("model_select", { model: f.ctx.model, source: "cycle" });
  f.ctx.model = { provider: "other", id: "model-b" };
  f.ctx.thinkingLevel = "off";
  const second = f.emit("thinking_level_select", { level: "off" });
  await f.emit("session_shutdown");
  await Promise.all([first, second]);
  const saved = await f.saved();
  assert.equal(saved.defaultProvider, "other");
  assert.equal(saved.defaultModel, "model-b");
  assert.equal(saved.defaultThinkingLevel, "off");
});

test("headless RPC/print/JSON selections cannot overwrite interactive defaults", async (t) => {
  const f = await fixture(t, { defaultModel: "keep" });
  for (const mode of ["rpc", "print", "json"]) {
    f.ctx.mode = mode;
    await f.emit("model_select", { model: f.ctx.model, source: "set" });
    await f.emit("thinking_level_select", { level: "high" });
  }
  assert.deepEqual(await f.saved(), { defaultModel: "keep" });
});

test("startup/shutdown alone do not overwrite defaults; missing model ignored", async (t) => {
  const f = await fixture(t, { defaultModel: "keep" });
  await f.emit("session_start", { reason: "startup" });
  await f.emit("session_shutdown");
  f.ctx.model = undefined;
  await f.emit("thinking_level_select", { level: "high" });
  assert.deepEqual(await f.saved(), { defaultModel: "keep" });
});

test("existing per-model override follows effective level; other overrides preserved", async (t) => {
  const f = await fixture(t, { modelThinkingLevels: { "test-provider/model-a": "low", "other/model": "max" } });
  f.ctx.thinkingLevel = "high";
  await f.emit("thinking_level_select", { level: "high" });
  assert.deepEqual((await f.saved()).modelThinkingLevels, { "test-provider/model-a": "high", "other/model": "max" });
});

test("project settings untouched; unrelated runtime settings preserved", async (t) => {
  const f = await fixture(t, { theme: "light" });
  const project = join(f.cwd, ".pi/settings.json");
  await writeFile(project, '{"defaultModel":"project-override"}');
  await f.emit("model_select", { model: f.ctx.model, source: "set" });
  await writeFile(f.settingsPath, JSON.stringify({ ...await f.saved(), customRuntimeKey: 42 }));
  f.ctx.thinkingLevel = "medium";
  await f.emit("thinking_level_select", { level: "medium" });
  assert.equal((await f.saved()).customRuntimeKey, 42);
  assert.equal(await readFile(project, "utf8"), '{"defaultModel":"project-override"}');
});

test("malformed settings are never overwritten; generic error notification", async (t) => {
  const f = await fixture(t);
  await writeFile(f.settingsPath, '{broken private-data');
  await f.emit("model_select", { model: f.ctx.model, source: "set" });
  assert.equal(await readFile(f.settingsPath, "utf8"), '{broken private-data');
  assert.equal(f.notices.length, 1);
  assert.equal(f.notices[0][1], "error");
  assert.ok(!JSON.stringify(f.notices).includes("private-data"));
});
