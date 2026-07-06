# RUNBOOK — ai-installer

## 给 agent 的速览

- 本仓库 (`Liang-HZ/ai-installer`) 是 Claude Code / Codex 一键安装脚本的**唯一真源（source of truth）**。
- 本仓库**不部署到任何服务器或平台**，没有自己的构建/发布 CI。
- 下游消费方是 **`Liang-HZ/ai-cli-installers-page`**（`install.liangai.org` 展示页所在仓库）：它的 CI 会 `checkout` 本仓库，用 `tools/build-site.sh` 里的映射表把脚本拷贝过去、重新计算 SHA256，再注入到页面上供用户 `curl` 下载。
- **改动本仓库任何脚本的文件名或路径之前，必须先去 `ai-cli-installers-page/tools/build-site.sh` 核对映射表**，否则下游 CI 会因为找不到文件而报错。
- 本仓库内 `tools/check-installer-contracts.mjs`、`tools/check-official-sources-live.mjs` 是**本地契约检查脚本**（非 CI，需要手动运行），用来确保脚本仍然复用官方安装器、没有内置占位符密钥等约束没有被破坏。

## 架构一页

本仓库 = 脚本源码仓库，无构建、无部署、无发布产物。它只是被 `ai-cli-installers-page` 仓库的 CI 拉取消费。

脚本清单（与 `ai-cli-installers-page/tools/build-site.sh` 映射表比对结果：**一致**，共 8 个脚本文件）：

| 平台 | 脚本文件 | 用途 |
| --- | --- | --- |
| macOS | `macos/install-claude-code.sh` | 安装 Claude Code CLI + CC Switch（优先 Homebrew，否则直接下载 macOS 应用），写入认证方式（官方登录 / `ANTHROPIC_API_KEY` / `ANTHROPIC_AUTH_TOKEN`）和可选自定义 `ANTHROPIC_BASE_URL` |
| macOS | `macos/install-codex.sh` | 复用 OpenAI 官方安装器 (`https://chatgpt.com/codex/install.sh`) 安装 Codex CLI，写入认证方式和可选 `OPENAI_BASE_URL` |
| Linux | `linux/install-claude-code.sh` | 同 macOS 版本，Linux 上通过 CC Switch 官方 GitHub Release 资产（deb/rpm/AppImage）安装管家 |
| Linux | `linux/install-codex.sh` | 复用 OpenAI 官方安装器，同 macOS 版本逻辑 |
| Windows | `windows/install-claude-code.cmd` | CMD 版一键安装入口，复用 Anthropic 官方 CMD 安装器 (`https://claude.ai/install.cmd`)，安装 Git for Windows / Claude Code / CC Switch |
| Windows | `windows/install-claude-code.ps1` | PowerShell 版，复用 Anthropic 官方安装器 (`https://claude.ai/install.ps1`)，无管理员场景用 CC Switch 官方 `Windows-Portable.zip` |
| Windows | `windows/install-codex.cmd` | CMD 版，调用 OpenAI 官方 PowerShell 安装器 (`https://chatgpt.com/codex/install.ps1`) |
| Windows | `windows/install-codex.ps1` | PowerShell 版，直接调用 OpenAI 官方安装器 |

所有脚本运行时才向用户交互式索取 API key / token，**不含任何硬编码密钥**，也不做任何 API 请求转发。

## 消费契约（原"部署路径"）

`ai-cli-installers-page` 如何消费本仓库：

1. `ai-cli-installers-page` 的 CI（在它自己仓库内）`checkout` 本仓库到构建环境。
2. 运行 `tools/build-site.sh`：脚本里有一份"本仓库路径 → 页面命名"的映射表（例如 `macos/install-claude-code.sh` → `claude-code-macos.sh`），把本仓库脚本原样拷贝到构建产物目录。
3. 对拷贝后的每个脚本重新计算 SHA256，注入到 `install.liangai.org` 页面（以及本仓库 README 里手工同步的 SHA256，见 README.md）。
4. 页面上的 `curl | bash` 命令直接从 `install.liangai.org` 拉取这份拷贝，SHA256 用于用户自行校验脚本未被篡改。

**改脚本前必须做的核对：**

- **不能随意改名或删除**本仓库现有的 8 个脚本文件路径——下游 `build-site.sh` 的映射表是硬编码路径，路径不存在会导致下游 CI 直接报错"缺少 xxx"。
- 如果确实需要新增脚本、改名或调整目录结构，必须**同时**去 `ai-cli-installers-page` 仓库提交 PR，更新 `tools/build-site.sh` 的映射表，两边 PR 应尽量同批次合并，避免下游 CI 在窗口期内构建失败。
- 脚本内容（非路径）的修改不需要通知下游做映射表变更，但下游页面上展示的 SHA256（以及本仓库 README 里的 SHA256）在下一次下游构建后会自动变化——记得在本仓库 README.md / README.en.md 里手工同步新的 SHA256（当前 README 是手工维护的展示值，不是自动生成）。

## secrets 名称清单

本仓库**没有 `.github/workflows`，无 CI/CD，不涉及任何 secrets**。脚本运行时向用户索取的 API key/token 由用户在自己机器上输入，从不写入本仓库、不上传、不经过任何本仓库控制的服务器。

## 服务器侧约定

不适用。**本仓库不部署到任何服务器**，脚本的执行环境是最终用户自己的电脑（macOS/Linux/Windows）。

## 契约校验（原"冒烟与回滚"）

脚本改动后按以下步骤校验，而不是"部署后冒烟":

1. **本地跑一遍脚本逻辑**：在对应平台（或至少用 `bash -n` / `pwsh -NoProfile -Command "$null = Get-Content ... | Out-Null"` 之类静态检查）确认语法没问题；有条件的话实际跑一遍安装流程（尤其是新增的认证分支）。
2. **运行本仓库自带的契约检查脚本**：
   - `node tools/check-installer-contracts.mjs` — 检查所有脚本仍然复用官方安装器 URL、没有回退到 npm/winget 作为主安装路径、没有遗留 `PLACEHOLDER_*` 占位符、`shell_quote`/`validate_base_url` 等安全防护仍然存在。
   - `node tools/check-official-sources-live.mjs` — 实际访问官方安装器 URL，确认重定向目标仍然落在预期的官方域名/GitHub Releases 前缀下（需要联网）。
3. **确认是否需要同步 `ai-cli-installers-page`**：
   - 只改脚本内容、没改路径 → 不需要改下游映射表，但下一次下游构建后 SHA256 会变，需要回头更新本仓库 README 里的 SHA256 展示值。
   - 新增/改名/删除脚本文件 → 必须同时提交 PR 到 `ai-cli-installers-page` 更新 `tools/build-site.sh` 映射表，两个仓库的 PR 最好同批次处理。
4. 没有"回滚"概念意义上的线上服务——如果发现脚本有问题，直接在本仓库提交修复 PR/commit 即可，下游会在下次构建时自动拿到新版本。

## 常见故障

- **改了脚本路径/文件名，下游 `build-site.sh` 报错"缺少 xxx"**：说明本仓库路径变更没有同步到 `ai-cli-installers-page` 的映射表。修复方式：要么把本仓库路径改回去，要么去下游仓库同步更新映射表。
- **脚本内容改动后忘记通知/更新下游，导致页面哈希与实际不符**：用户下载后 `shasum -a 256` 校验会发现与 README 展示的 SHA256 不一致，误以为脚本被篡改。修复方式：下游重新构建一次拿到新 SHA256，再回来更新本仓库 README.md / README.en.md 里的展示值。
- **`tools/check-installer-contracts.mjs` 报错"必须复用官方安装器"**：说明脚本改动误删了对官方安装器 URL 的调用，或者引入了 npm/winget 作为主安装路径——这是本仓库明确禁止的（详见脚本内注释的理由字符串）。
- **`tools/check-official-sources-live.mjs` 报错"第一跳不是重定向"或"最终地址不在预期前缀"**：可能是 OpenAI/Anthropic 官方安装器地址或重定向目标发生了变化，需要人工确认后再决定是否需要更新脚本里硬编码的官方 URL 假设。

## 恢复演练

不适用额外流程：**本仓库即 GitHub 本身就是唯一真源与备份**，没有需要额外恢复的"线上状态"。若误删文件或误改内容，直接 `git revert` 对应 commit 或从 git 历史恢复文件即可；不存在"服务器状态"与"仓库状态"不一致需要对齐的问题。
