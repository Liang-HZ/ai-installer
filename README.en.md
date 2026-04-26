# AI 安装站 · ai-installer

> One-line install for Codex and Claude Code. Beginner-friendly — running in 30 seconds.
>
> 🌐 Full guide and FAQ: <https://cli.liangai.org>
>
> 🇨🇳 [中文](./README.md)

Supported tools:

- **OpenAI Codex CLI**
- **Anthropic Claude Code**

Supported auth methods (you pick at install time):

- Official login / subscription
- Official API key (OpenAI / Anthropic)
- Gateway / proxy token with custom Base URL (OpenAI-compatible / Claude-compatible)

---

## Windows

### Codex CLI

```cmd
curl.exe -fL https://cli.liangai.org/codex.cmd -o "%TEMP%\codex.cmd" && "%TEMP%\codex.cmd"
```

SHA256: `d940f38a1e8089265869a15fe61d088d93898228d3a1f93dbfa27c879ce69179`

### Claude Code

```cmd
curl.exe -fL https://cli.liangai.org/claude-code.cmd -o "%TEMP%\claude-code.cmd" && "%TEMP%\claude-code.cmd"
```

SHA256: `2bc362629b2e22e3eb370902bd167d80e0d38fde65845b2b66f3292815274020`

[👉 Details and FAQ (cli.liangai.org/?os=win)](https://cli.liangai.org/?os=win)

---

## macOS

### Codex CLI

```bash
/bin/bash -c "$(curl -fsSL https://cli.liangai.org/codex-macos.sh)"
```

SHA256: `5c9e119ec99b035c61e92fc8d89aa26c808dd614f5d1811afd8a4125f14b4a08`

### Claude Code

```bash
/bin/bash -c "$(curl -fsSL https://cli.liangai.org/claude-code-macos.sh)"
```

SHA256: `50074de8c499a4111751683c152ec4a5b3388d92481854abbfefcf7204ab90aa`

[👉 Details and FAQ (cli.liangai.org/?os=mac)](https://cli.liangai.org/?os=mac)

---

## Linux

### Codex CLI

```bash
/bin/bash -c "$(curl -fsSL https://cli.liangai.org/codex-linux.sh)"
```

SHA256: `973cd0343c6952092b022a48812b969eb0c3b9b4d8ffb325980a9b0fcb18177b`

### Claude Code

```bash
/bin/bash -c "$(curl -fsSL https://cli.liangai.org/claude-code-linux.sh)"
```

SHA256: `548d6748e8cb55cb3d77aeffaffd21faf731a2a3e3a15d9bd9f9f6c7283ae3c2`

[👉 Details and FAQ (cli.liangai.org/?os=linux)](https://cli.liangai.org/?os=linux)

---

## FAQ

### `codex` / `claude` command not found after install?

- **Windows**: close the current terminal and open a **new** CMD or PowerShell window. The PATH the script wrote only takes effect in new processes.
- **macOS**: close the current Terminal and open a new one, or run `source ~/.zshrc`.
- **Linux**: open a new terminal, or run `source ~/.bashrc` / `source ~/.zshrc`.

### `npm` cannot install Claude Code?

- All OSes: confirm `node --version` returns ≥ 18. If you don't have Node, the script auto-installs it; if auto-install fails, install manually from <https://nodejs.org/>.

### How do I fill in the gateway/proxy Base URL?

When the script asks "choose API endpoint", pick `2` (custom Base URL):

- **Codex / OpenAI-compatible**: usually ends with `/v1`. e.g. `https://your-gateway.com/v1`.
- **Claude Code / Claude-compatible**: usually **do not** append `/v1`. e.g. `https://your-gateway.com`.

### How do I verify the script wasn't tampered with?

After download:

- **Windows**: `certutil -hashfile codex.cmd SHA256`
- **macOS / Linux**: `shasum -a 256 install-codex.sh`

Compare with the SHA256 listed above. If they match, the script is intact.

### How do I uninstall?

**Codex**:
- via npm: `npm uninstall -g @openai/codex`
- via binary: delete `~/.local/bin/codex` (macOS/Linux) or `%LOCALAPPDATA%\Codex\codex.exe` (Windows)

**Claude Code**:
- via npm: `npm uninstall -g @anthropic-ai/claude-code`
- macOS cc-switch app: drag to Trash

### Where to report bugs?

GitHub Issues: <https://github.com/Liang-HZ/ai-installer/issues>

Please include:

- OS version
- The last 5–10 lines of script output (**do not paste your key/token**)
- The auth mode you selected

[More FAQs → cli.liangai.org/#faq](https://cli.liangai.org/#faq)

---

## Security Notes

- **No keys or tokens baked in**: the script asks you to enter them at runtime.
- **No API forwarding**: this repo and cli.liangai.org do **not** proxy any API request. All requests go directly to the API endpoint you chose.
- **SHA256 published**: all hashes are listed in this README and on cli.liangai.org.
- **Full source in this repo**: every line is yours to inspect.

---

## Follow the maker

- Xiaohongshu (rednote): `@AI动不动就超限` ([profile](https://xhslink.com/m/AxR4QhwEOBP))
- WeChat Official Account: `AI动不动就超限`

Updates and field notes are posted to both platforms.

## License

[MIT](./LICENSE) © 2026 Liang-HZ
