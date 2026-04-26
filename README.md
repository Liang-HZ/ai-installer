# AI 安装站 · ai-installer

> Codex 和 Claude Code 一键安装。新手也能 30 秒跑起来。
>
> 🌐 完整教程和 FAQ：<https://install.liangai.org>
>
> 🇺🇸 [English](./README.en.md)

支持的工具：

- **OpenAI Codex CLI**
- **Anthropic Claude Code**

支持的认证方式（脚本运行时让你选）：

- 官方账号登录 / 订阅
- 官方 API key（OpenAI / Anthropic）
- 中转站 / 网关 token + 自定义 Base URL（OpenAI-compatible / Claude-compatible）

---

## Windows

### Codex CLI

```cmd
curl.exe -fL https://install.liangai.org/codex.cmd -o "%TEMP%\codex.cmd" && "%TEMP%\codex.cmd"
```

SHA256: `d940f38a1e8089265869a15fe61d088d93898228d3a1f93dbfa27c879ce69179`

### Claude Code

```cmd
curl.exe -fL https://install.liangai.org/claude-code.cmd -o "%TEMP%\claude-code.cmd" && "%TEMP%\claude-code.cmd"
```

SHA256: `2bc362629b2e22e3eb370902bd167d80e0d38fde65845b2b66f3292815274020`

[👉 查看详情和常见问题（install.liangai.org/?os=win）](https://install.liangai.org/?os=win)

---

## macOS

### Codex CLI

```bash
/bin/bash -c "$(curl -fsSL https://install.liangai.org/codex-macos.sh)"
```

SHA256: `5c9e119ec99b035c61e92fc8d89aa26c808dd614f5d1811afd8a4125f14b4a08`

### Claude Code

```bash
/bin/bash -c "$(curl -fsSL https://install.liangai.org/claude-code-macos.sh)"
```

SHA256: `50074de8c499a4111751683c152ec4a5b3388d92481854abbfefcf7204ab90aa`

[👉 查看详情和常见问题（install.liangai.org/?os=mac）](https://install.liangai.org/?os=mac)

---

## Linux

### Codex CLI

```bash
/bin/bash -c "$(curl -fsSL https://install.liangai.org/codex-linux.sh)"
```

SHA256: `973cd0343c6952092b022a48812b969eb0c3b9b4d8ffb325980a9b0fcb18177b`

### Claude Code

```bash
/bin/bash -c "$(curl -fsSL https://install.liangai.org/claude-code-linux.sh)"
```

SHA256: `548d6748e8cb55cb3d77aeffaffd21faf731a2a3e3a15d9bd9f9f6c7283ae3c2`

[👉 查看详情和常见问题（install.liangai.org/?os=linux）](https://install.liangai.org/?os=linux)

---

## 常见问题

### 装完 `codex` / `claude` 命令找不到？

- **Windows**：关掉当前终端，**新开**一个 CMD 或 PowerShell。脚本写入的 PATH 在新进程才生效。
- **macOS**：关掉当前 Terminal，新开一个；或者运行 `source ~/.zshrc`。
- **Linux**：新开终端，或运行 `source ~/.bashrc` / `source ~/.zshrc`。

### npm 装不上 Claude Code？

- 三个 OS 通用：先确认 `node --version` 输出 ≥ 18。没装 Node 的话，脚本会自动装；如果自动装失败，从 <https://nodejs.org/> 手动下载安装即可。

### 怎么填中转站的 Base URL？

脚本运行到「选择 API 服务地址」时选 `2`（自定义 Base URL），按服务商文档填：

- **Codex / OpenAI-compatible**：通常需要 `/v1` 结尾。例：`https://your-gateway.com/v1`。
- **Claude Code / Claude-compatible**：通常**不要**自己加 `/v1`。例：`https://your-gateway.com`。

### 怎么校验脚本未被篡改？

下载脚本后对比 SHA256：

- **Windows**：`certutil -hashfile codex.cmd SHA256`
- **macOS / Linux**：`shasum -a 256 install-codex.sh`

输出与本 README 列出的 SHA256 一致即未被篡改。

### 怎么卸载？

**Codex**：
- npm 装：`npm uninstall -g @openai/codex`
- 二进制装：删除 `~/.local/bin/codex`（macOS/Linux）或 `%LOCALAPPDATA%\Codex\codex.exe`（Windows）

**Claude Code**：
- npm 装：`npm uninstall -g @anthropic-ai/claude-code`
- macOS App 装的 cc-switch：拖到废纸篓即可

### 脚本失败了在哪报 bug？

GitHub Issues：<https://github.com/Liang-HZ/ai-installer/issues>

报告时附上：

- 操作系统版本
- 脚本最后输出的 5–10 行（**不要贴 key/token**）
- 你选的认证方式

[更多问题 → install.liangai.org/#faq](https://install.liangai.org/#faq)

---

## 安全说明

- **不内置任何 key/token**：脚本运行时由你自己输入。
- **不转发任何 API 请求**：本仓库和 install.liangai.org **不**做任何 API 中转，所有请求直接发给你选的 API 服务。
- **SHA256 公开**：所有 hash 在本 README 和 install.liangai.org 同步公布。
- **全部源码在本仓库**：欢迎自查每一行。

---

## 关注作者

- 小红书：`@AI动不动就超限`（[主页](https://xhslink.com/m/AxR4QhwEOBP)）
- 公众号：`AI动不动就超限`

更新和踩坑笔记会在两个平台同步。

## License

[MIT](./LICENSE) © 2026 Liang-HZ
