#!/usr/bin/env node
// install.mjs — connect this computer's coding agents to a glimmer display.
//
//   node tools/agents/install.mjs                 install / update (idempotent)
//   node tools/agents/install.mjs --url http://192.168.1.50 --token abc
//   node tools/agents/install.mjs --uninstall
//
// Run once per machine (Windows, macOS, Linux — only Node is needed). It:
//   1. copies glimmer-hook.mjs to ~/.glimmer/
//   2. writes ~/.glimmer/config.json ({url, token}) — default http://glimmer.local,
//      which any machine on the display's network can reach, so moving to
//      another computer needs nothing but this script
//   3. merges glimmer's hooks into ~/.claude/settings.json (Claude Code) and,
//      if ~/.codex exists, ~/.codex/hooks.json (Codex). Other settings and
//      other hooks are left alone; a .bak copy is kept the first time.
//   4. sends a test ping and says whether the display answered
//
// Hook templates: claude-settings.json / codex-hooks.json next to this file.

import { copyFileSync, existsSync, mkdirSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const home = homedir();
const glimmerDir = join(home, ".glimmer");
const hookDst = join(glimmerDir, "glimmer-hook.mjs");
const cfgPath = join(glimmerDir, "config.json");
const MARK = "glimmer-hook";                       // how our entries are recognised

const args = process.argv.slice(2);
const opt = (name) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : undefined; };
const uninstall = args.includes("--uninstall");

const readJson = (p, dflt) => { try { return JSON.parse(readFileSync(p, "utf8")); } catch { return dflt; } };
const writeJson = (p, v) => { mkdirSync(dirname(p), { recursive: true }); writeFileSync(p, JSON.stringify(v, null, 2) + "\n"); };

// Forward slashes work in cmd, PowerShell and sh alike; quotes survive spaces.
const command = (agent) => `node "${hookDst.replace(/\\/g, "/")}" ${agent}`;

const isOurs = (group) => (group.hooks || []).some((h) => String(h.command || "").includes(MARK));

// Drop every glimmer entry (old glimmer-hook.sh ones included), then add ours.
function merge(settingsPath, templatePath, agent) {
  if (!existsSync(settingsPath + ".bak") && existsSync(settingsPath))
    copyFileSync(settingsPath, settingsPath + ".bak");
  const s = readJson(settingsPath, {});
  if (existsSync(settingsPath) && Object.keys(s).length === 0 && readFileSync(settingsPath, "utf8").trim())
    throw new Error(`${settingsPath} is not valid JSON — fix it first, nothing was changed`);
  s.hooks = s.hooks || {};
  for (const ev of Object.keys(s.hooks)) {
    s.hooks[ev] = (s.hooks[ev] || []).filter((g) => !isOurs(g));
    if (!s.hooks[ev].length) delete s.hooks[ev];
  }
  if (!uninstall) {
    const tpl = readJson(templatePath, {}).hooks || {};
    for (const [ev, groups] of Object.entries(tpl)) {
      const mine = groups.map((g) => ({ ...g, hooks: g.hooks.map((h) => ({ ...h, command: command(agent) })) }));
      s.hooks[ev] = [...(s.hooks[ev] || []), ...mine];
    }
  }
  if (!Object.keys(s.hooks).length) delete s.hooks;
  writeJson(settingsPath, s);
  return settingsPath;
}

async function ping(url, token) {
  const headers = { "Content-Type": "application/json" };
  if (token) headers.Authorization = `Bearer ${token}`;
  try {
    // An event the device ignores: proves reachability without touching the screen.
    const r = await fetch(`${url}/hook?agent=claude`, { method: "POST", headers, body: '{"event":"ping"}',
                                                        signal: AbortSignal.timeout(4000) });
    return r.status;
  } catch (e) { return e.cause?.code || e.name; }
}

async function main() {
  const done = [];
  if (uninstall) {
    done.push(merge(join(home, ".claude", "settings.json"), join(here, "claude-settings.json"), "claude"));
    if (existsSync(join(home, ".codex", "hooks.json")))
      done.push(merge(join(home, ".codex", "hooks.json"), join(here, "codex-hooks.json"), "codex"));
    rmSync(glimmerDir, { recursive: true, force: true });
    console.log("glimmer hooks removed from:\n  " + done.join("\n  ") + `\nand ${glimmerDir} deleted.`);
    return;
  }

  mkdirSync(glimmerDir, { recursive: true });
  copyFileSync(join(here, "glimmer-hook.mjs"), hookDst);
  const prev = readJson(cfgPath, {});
  const cfg = {
    url: (opt("--url") || prev.url || "http://glimmer.local").replace(/\/+$/, ""),
    token: opt("--token") ?? prev.token ?? "",
  };
  writeJson(cfgPath, cfg);

  done.push(merge(join(home, ".claude", "settings.json"), join(here, "claude-settings.json"), "claude"));
  if (existsSync(join(home, ".codex")))
    done.push(merge(join(home, ".codex", "hooks.json"), join(here, "codex-hooks.json"), "codex"));

  const status = await ping(cfg.url, cfg.token);
  console.log(`hook:    ${hookDst}\nconfig:  ${cfgPath}  (url ${cfg.url}${cfg.token ? ", token set" : ""})`);
  console.log("hooks in:\n  " + done.join("\n  "));
  if (status === 200) console.log(`display: OK — ${cfg.url} answered. Start a new agent session to see it.`);
  else if (status === 401) console.log(`display: reachable but wants a token — rerun with --token <api token>`);
  else console.log(`display: no answer from ${cfg.url} (${status}). Same Wi-Fi? Else rerun with --url http://<device-ip>`);
  if (existsSync(join(home, ".codex"))) console.log("Codex asks you to trust new hooks once.");
}

main().catch((e) => { console.error("install failed:", e.message); process.exit(1); });
