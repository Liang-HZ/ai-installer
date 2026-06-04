#!/usr/bin/env node
import process from "node:process";

const failures = [];

async function assertRedirectingSource(name, url, expectedFirstLocationPrefix, expectedFinalPrefixes) {
  const firstResponse = await fetch(url, { redirect: "manual" });
  const location = firstResponse.headers.get("location") ?? "";
  if (firstResponse.status < 300 || firstResponse.status > 399) {
    failures.push(`${name}: ${url} 第一跳不是重定向，返回 HTTP ${firstResponse.status}`);
    return;
  }
  if (!location.startsWith(expectedFirstLocationPrefix)) {
    failures.push(`${name}: 第一跳 ${location} 不在预期官方前缀 ${expectedFirstLocationPrefix} 下`);
  }

  const response = await fetch(url, { redirect: "follow" });
  if (!response.ok) {
    failures.push(`${name}: ${url} 返回 HTTP ${response.status}`);
    return;
  }
  if (!expectedFinalPrefixes.some((prefix) => response.url.startsWith(prefix))) {
    failures.push(`${name}: 最终地址 ${response.url} 不在预期官方下载前缀中`);
  }
}

await assertRedirectingSource(
  "Codex macOS/Linux 官方安装器",
  "https://chatgpt.com/codex/install.sh",
  "https://github.com/openai/codex/releases/",
  ["https://github.com/openai/codex/releases/", "https://release-assets.githubusercontent.com/"]
);
await assertRedirectingSource(
  "Codex Windows 官方安装器",
  "https://chatgpt.com/codex/install.ps1",
  "https://github.com/openai/codex/releases/",
  ["https://github.com/openai/codex/releases/", "https://release-assets.githubusercontent.com/"]
);
await assertRedirectingSource(
  "Claude macOS/Linux 官方安装器",
  "https://claude.ai/install.sh",
  "https://downloads.claude.ai/claude-code-releases/",
  ["https://downloads.claude.ai/claude-code-releases/"]
);
await assertRedirectingSource(
  "Claude Windows PowerShell 官方安装器",
  "https://claude.ai/install.ps1",
  "https://downloads.claude.ai/claude-code-releases/",
  ["https://downloads.claude.ai/claude-code-releases/"]
);
await assertRedirectingSource(
  "Claude Windows CMD 官方安装器",
  "https://claude.ai/install.cmd",
  "https://downloads.claude.ai/claude-code-releases/",
  ["https://downloads.claude.ai/claude-code-releases/"]
);

const releaseResponse = await fetch("https://api.github.com/repos/farion1231/cc-switch/releases/latest", {
  headers: { "User-Agent": "liangai-installer-contract-check" },
});
if (!releaseResponse.ok) {
  failures.push(`CC Switch latest Release API 返回 HTTP ${releaseResponse.status}`);
} else {
  const release = await releaseResponse.json();
  const names = new Set(release.assets.map((asset) => asset.name));
  const requiredPatterns = [
    /^CC-Switch-v.+-macOS\.zip$/,
    /^CC-Switch-v.+-Windows-Portable\.zip$/,
    /^CC-Switch-v.+-Linux-x86_64\.deb$/,
    /^CC-Switch-v.+-Linux-arm64\.deb$/,
    /^CC-Switch-v.+-Linux-x86_64\.rpm$/,
    /^CC-Switch-v.+-Linux-arm64\.rpm$/,
    /^CC-Switch-v.+-Linux-x86_64\.AppImage$/,
    /^CC-Switch-v.+-Linux-arm64\.AppImage$/,
  ];

  for (const pattern of requiredPatterns) {
    if (![...names].some((name) => pattern.test(name))) {
      failures.push(`CC Switch ${release.tag_name}: 缺少资产 ${pattern}`);
    }
  }
}

if (failures.length) {
  console.error("官方来源 live check 失败：");
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log("官方来源 live check 通过。");
