#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

const root = path.resolve(import.meta.dirname, "..");

const read = (relativePath) =>
  fs.readFileSync(path.join(root, relativePath), "utf8");

const scripts = {
  codexMac: read("macos/install-codex.sh"),
  codexLinux: read("linux/install-codex.sh"),
  codexCmd: read("windows/install-codex.cmd"),
  codexPs1: read("windows/install-codex.ps1"),
  claudeMac: read("macos/install-claude-code.sh"),
  claudeLinux: read("linux/install-claude-code.sh"),
  claudeCmd: read("windows/install-claude-code.cmd"),
  claudePs1: read("windows/install-claude-code.ps1"),
};

const failures = [];

function assertContains(name, source, needle, reason) {
  if (!source.includes(needle)) {
    failures.push(`${name}: 缺少 ${needle}；${reason}`);
  }
}

function assertNotContains(name, source, needle, reason) {
  if (source.includes(needle)) {
    failures.push(`${name}: 不应出现 ${needle}；${reason}`);
  }
}

function assertMatches(name, source, pattern, reason) {
  if (!pattern.test(source)) {
    failures.push(`${name}: 未匹配 ${pattern}；${reason}`);
  }
}

const all = Object.values(scripts).join("\n");

assertContains(
  "macos/install-codex.sh",
  scripts.codexMac,
  "https://chatgpt.com/codex/install.sh",
  "Codex macOS 必须复用 OpenAI 官方安装器"
);
assertContains(
  "linux/install-codex.sh",
  scripts.codexLinux,
  "https://chatgpt.com/codex/install.sh",
  "Codex Linux 必须复用 OpenAI 官方安装器"
);
assertContains(
  "windows/install-codex.cmd",
  scripts.codexCmd,
  "https://chatgpt.com/codex/install.ps1",
  "Codex Windows CMD 必须调用 OpenAI 官方 PowerShell 安装器"
);
assertContains(
  "windows/install-codex.ps1",
  scripts.codexPs1,
  "https://chatgpt.com/codex/install.ps1",
  "Codex Windows PowerShell 必须调用 OpenAI 官方安装器"
);

for (const [name, source] of [
  ["macos/install-codex.sh", scripts.codexMac],
  ["linux/install-codex.sh", scripts.codexLinux],
  ["windows/install-codex.cmd", scripts.codexCmd],
  ["windows/install-codex.ps1", scripts.codexPs1],
]) {
  assertNotContains(name, source, "@openai/codex@latest", "不能把 npm 作为一键安装主路径");
  assertNotContains(name, source, "unknown-linux-gnu", "官方 Linux standalone 资产是 musl，不是 gnu");
}

assertContains(
  "macos/install-claude-code.sh",
  scripts.claudeMac,
  "https://claude.ai/install.sh",
  "Claude Code macOS 必须复用 Anthropic 官方安装器"
);
assertContains(
  "linux/install-claude-code.sh",
  scripts.claudeLinux,
  "https://claude.ai/install.sh",
  "Claude Code Linux 必须复用 Anthropic 官方安装器"
);
assertContains(
  "windows/install-claude-code.cmd",
  scripts.claudeCmd,
  "https://claude.ai/install.cmd",
  "Claude Code Windows CMD 必须复用 Anthropic 官方 CMD 安装器"
);
assertContains(
  "windows/install-claude-code.ps1",
  scripts.claudePs1,
  "https://claude.ai/install.ps1",
  "Claude Code Windows PowerShell 必须复用 Anthropic 官方安装器"
);
assertNotContains(
  "windows/install-claude-code.cmd",
  scripts.claudeCmd,
  "Anthropic.ClaudeCode",
  "Windows Claude 不再把 winget 包当主安装来源"
);
assertNotContains(
  "windows/install-claude-code.ps1",
  scripts.claudePs1,
  "Anthropic.ClaudeCode",
  "Windows Claude 不再把 winget 包当主安装来源"
);

assertContains(
  "macos/install-claude-code.sh",
  scripts.claudeMac,
  "brew install --cask cc-switch",
  "CC Switch macOS Homebrew 路线必须使用官方 README 推荐 cask"
);
assertContains(
  "windows/install-claude-code.ps1",
  scripts.claudePs1,
  "Windows-Portable.zip",
  "CC Switch Windows 无管理员安装路线必须使用官方 Release 资产"
);
assertMatches(
  "linux/install-claude-code.sh",
  scripts.claudeLinux,
  /Linux-(x86_64|arm64)\.(deb|rpm|AppImage)/,
  "Linux Claude 管家必须覆盖 CC Switch 官方 Linux Release 资产"
);
assertContains(
  "linux/install-claude-code.sh",
  scripts.claudeLinux,
  "https://api.github.com/repos/farion1231/cc-switch/releases/latest",
  "CC Switch Linux 必须从官方 GitHub Release 读取资产"
);

for (const [name, source] of Object.entries(scripts)) {
  if (name.toLowerCase().includes("codex")) {
    assertContains(name, source, "OPENAI_BASE_URL", "Codex API key 模式必须继续写入 Base URL");
  }
}

assertContains("macos/install-codex.sh", scripts.codexMac, "validate_base_url", "安全检查不能回退");
assertContains("linux/install-codex.sh", scripts.codexLinux, "validate_base_url", "安全检查不能回退");
assertContains("macos/install-codex.sh", scripts.codexMac, "shell_quote", "shell 写入必须单引号保护");
assertContains("linux/install-codex.sh", scripts.codexLinux, "shell_quote", "shell 写入必须单引号保护");

if (/PLACEHOLDER_(OPENAI|CLAUDE|BASE_URL)/.test(all)) {
  failures.push("脚本仍包含 PLACEHOLDER_* 默认值；远程一键安装不应要求页面替换占位符");
}

if (failures.length) {
  console.error("安装管家契约检查失败：");
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log("安装管家契约检查通过。");
