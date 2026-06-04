#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="${CODEX_INSTALLER_LANGUAGE:-zh}"
AUTH_MODE="${CODEX_INSTALLER_AUTH_MODE:-prompt}"
API_KEY="${CODEX_INSTALLER_API_KEY:-}"
BASE_URL_MODE="${CODEX_INSTALLER_BASE_URL_MODE:-prompt}"
BASE_URL="${CODEX_INSTALLER_BASE_URL:-}"
MODEL="${CODEX_INSTALLER_MODEL:-gpt-5.5}"
REASONING_EFFORT="${CODEX_INSTALLER_REASONING_EFFORT:-high}"

OPENAI_BASE_URL="https://api.openai.com/v1"
STATUS_FILE="$(mktemp "${TMPDIR:-/tmp}/liangai-codex-progress.html.XXXXXX")"

t() {
  local key="$1"
  case "${LANGUAGE}:${key}" in
    zh:title) echo "macOS 版 Codex CLI 一键安装配置" ;;
    zh:intro) echo "此脚本会调用 OpenAI 官方 Codex 安装器安装 CLI，并写入 ~/.codex/config.toml。" ;;
    zh:auth_title) echo "请选择 Codex 的使用方式：" ;;
    zh:auth_login) echo "1. ChatGPT 官方登录/订阅：不写 API key，安装后运行 codex 并按提示登录。适合 Plus/Pro/Business/Edu/Enterprise。" ;;
    zh:auth_key) echo "2. API key / 中转站 key：写入 OPENAI_API_KEY，并配置官方或自定义 OpenAI-compatible Base URL。" ;;
    zh:auth_prompt) echo "请输入 1 或 2，直接回车默认选择 1" ;;
    zh:key_prompt) echo "请粘贴 OpenAI API key 或中转站 key" ;;
    zh:key_required) echo "选择 API key 模式时，key 不能为空。只填写 Base URL 无法认证。" ;;
    zh:base_title) echo "请选择 API 服务地址：" ;;
    zh:base_openai) echo "1. OpenAI 官方 API（https://api.openai.com/v1）" ;;
    zh:base_custom) echo "2. 自定义 OpenAI-compatible Base URL：适合中转站、反代、国内模型服务等，通常以 /v1 结尾。" ;;
    zh:base_prompt) echo "请输入 1 或 2，直接回车默认选择 1" ;;
    zh:base_custom_prompt) echo "请输入自定义 Base URL（例如 https://example.com/v1）" ;;
    zh:base_invalid_scheme) echo "Base URL 必须以 https:// 开头。请复制服务商提供的 HTTPS 地址。" ;;
    zh:base_invalid_chars) echo "Base URL 含有空白、换行或 shell 特殊字符。为保护你的终端，脚本已停止；请只粘贴纯 HTTPS 地址。" ;;
    zh:install_codex) echo "安装 Codex CLI" ;;
    zh:install_codex_official) echo "正在运行 OpenAI 官方安装器：https://chatgpt.com/codex/install.sh" ;;
    zh:download) echo "正在下载: $2" ;;
    zh:write_config) echo "写入 Codex 配置" ;;
    zh:backup) echo "已有配置已备份: $2" ;;
    zh:done) echo "安装配置完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行: codex" ;;
    zh:login_done) echo "安装完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行 codex，并按提示登录 ChatGPT。" ;;
    zh:official_installer_missing) echo "未找到 curl。macOS 正常应内置 curl；请先修复系统命令行工具后重试。" ;;
    zh:verify_fail) echo "未找到 codex 命令。请打开新的终端后重试，或检查 Codex 安装是否成功。" ;;
    en:title) echo "Codex CLI one-click setup for macOS" ;;
    en:intro) echo "This script runs the official OpenAI Codex installer, then writes ~/.codex/config.toml." ;;
    en:auth_title) echo "Choose how to use Codex:" ;;
    en:auth_login) echo "1. ChatGPT login/subscription: no API key is written. Run codex after install and sign in. Use this for Plus/Pro/Business/Edu/Enterprise." ;;
    en:auth_key) echo "2. API key / relay key: writes OPENAI_API_KEY and configures official or custom OpenAI-compatible Base URL." ;;
    en:auth_prompt) echo "Enter 1 or 2. Press Enter for 1" ;;
    en:key_prompt) echo "Paste the OpenAI API key or relay key" ;;
    en:key_required) echo "API key is required in API key mode. Base URL alone cannot authenticate requests." ;;
    en:base_title) echo "Choose the API base URL:" ;;
    en:base_openai) echo "1. Official OpenAI API (https://api.openai.com/v1)" ;;
    en:base_custom) echo "2. Custom OpenAI-compatible Base URL for relays, reverse proxies, or regional providers. It often ends with /v1." ;;
    en:base_prompt) echo "Enter 1 or 2. Press Enter for 1" ;;
    en:base_custom_prompt) echo "Enter the custom Base URL, for example https://example.com/v1" ;;
    en:base_invalid_scheme) echo "Base URL must start with https://. Paste the HTTPS URL from your provider." ;;
    en:base_invalid_chars) echo "Base URL contains whitespace, newlines, or shell metacharacters. To protect your terminal, setup stopped. Paste only the plain HTTPS URL." ;;
    en:install_codex) echo "Installing Codex CLI" ;;
    en:install_codex_official) echo "Running the official OpenAI installer: https://chatgpt.com/codex/install.sh" ;;
    en:download) echo "Downloading: $2" ;;
    en:write_config) echo "Writing Codex configuration" ;;
    en:backup) echo "Existing config backed up: $2" ;;
    en:done) echo "Setup complete. A new Terminal was opened. You can also run source ~/.zshrc in the current terminal, then run: codex" ;;
    en:login_done) echo "Setup complete. A new Terminal was opened. You can also run source ~/.zshrc in the current terminal, then run codex and sign in with ChatGPT." ;;
    en:official_installer_missing) echo "curl was not found. macOS normally includes curl; repair the system command line tools and rerun this script." ;;
    en:verify_fail) echo "codex command was not found. Open a new terminal and retry, or check whether Codex installed successfully." ;;
    *) echo "$key" ;;
  esac
}

step() { printf '\n==> %s\n' "$1"; }
ok() { printf 'OK  %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }

validate_base_url() {
  local value="$1"
  [[ "$value" == https://* ]] || fail "$(t base_invalid_scheme)"
  # 用户粘贴的地址后面会写入 shell 启动文件；这里提前拦住会触发解释执行的字符。
  case "$value" in
    *[$' \t\r\n'\'\"\`\$\\\;\&\|\<\>\(\)\{\}]*)
      fail "$(t base_invalid_chars)"
      ;;
  esac
}

shell_quote() {
  # 写入 .zshrc 时只允许作为字符串保存，不能让 $()、反引号等被 shell 执行。
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
}

status_page() {
  local title="$1"
  local detail="$2"
  cat > "$STATUS_FILE" <<EOF
<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="2">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Codex 安装进度</title>
  <style>
    body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","Microsoft YaHei",sans-serif;background:#f6f7f9;color:#1e252e}
    .box{max-width:760px;margin:56px auto;padding:28px;background:#fff;border:1px solid #d9e0e8;border-radius:8px}
    .eyebrow{color:#147d64;font-weight:700;font-size:13px}h1{margin:10px 0 16px;font-size:32px}.detail{line-height:1.7;color:#596575}
    .bar{height:10px;background:#e8eef4;border-radius:99px;overflow:hidden;margin-top:24px}.bar span{display:block;width:68%;height:100%;background:#147d64}
    .hint{margin-top:20px;font-size:13px;color:#596575}code{background:#eef2f6;padding:2px 5px;border-radius:4px}
  </style>
</head>
<body><main class="box"><div class="eyebrow">Codex macOS Installer</div><h1>${title}</h1><p class="detail">${detail}</p><div class="bar"><span></span></div><p class="hint">这个页面由安装脚本写入，会自动刷新。安装完成后脚本会打开新的 Terminal；也可以执行 <code>source ~/.zshrc</code> 后运行 <code>codex</code>。</p></main></body>
</html>
EOF
}

open_new_terminal() {
  /usr/bin/osascript <<'EOF' >/dev/null 2>&1 || true
tell application "Terminal"
  activate
  do script "source ~/.zshrc >/dev/null 2>&1 || true; echo 'Codex 配置完成。请 cd 到项目文件夹后运行 codex。'; echo ''; command -v codex; codex --version; echo ''; exec $SHELL -l"
end tell
EOF
}

open_status_page() {
  status_page "等待用户选择" "请选择 ChatGPT 登录或 API key 模式。"
  open "$STATUS_FILE" >/dev/null 2>&1 || true
}

fail() {
  status_page "安装失败" "$1"
  echo "$1" >&2
  exit 1
}

ensure_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    fail "This installer is for macOS only."
  fi
}

resolve_auth_mode() {
  case "$AUTH_MODE" in
    login|official) echo "login"; return ;;
    api-key|key) echo "api-key"; return ;;
  esac

  printf '\n%s\n' "$(t auth_title)"
  echo "$(t auth_login)"
  echo "$(t auth_key)"
  read -r -p "$(t auth_prompt): " choice
  case "${choice:-1}" in
    1) echo "login" ;;
    2) echo "api-key" ;;
    *) echo "Invalid choice." >&2; exit 1 ;;
  esac
}

read_api_key() {
  if [[ -n "$API_KEY" ]]; then
    echo "$API_KEY"
    return
  fi
  read -r -s -p "$(t key_prompt): " value
  printf '\n'
  if [[ -z "$value" ]]; then
    echo "$(t key_required)" >&2
    exit 1
  fi
  echo "$value"
}

resolve_base_url() {
  if [[ -n "$BASE_URL" ]]; then
    validate_base_url "$BASE_URL"
    echo "$BASE_URL"
    return
  fi
  case "$BASE_URL_MODE" in
    openai|official) echo "$OPENAI_BASE_URL"; return ;;
    custom)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || { echo "Base URL is required." >&2; exit 1; }
      validate_base_url "$value"
      echo "$value"
      return
      ;;
  esac

  printf '\n%s\n' "$(t base_title)"
  echo "$(t base_openai)"
  echo "$(t base_custom)"
  read -r -p "$(t base_prompt): " choice
  case "${choice:-1}" in
    1) echo "$OPENAI_BASE_URL" ;;
    2)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || { echo "Base URL is required." >&2; exit 1; }
      validate_base_url "$value"
      echo "$value"
      ;;
    *) echo "Invalid choice." >&2; exit 1 ;;
  esac
}

toml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

install_codex() {
  step "$(t install_codex)"
  status_page "安装 Codex CLI" "正在检查或安装 Codex CLI。"
  if command -v codex >/dev/null 2>&1; then
    ok "$(command -v codex)"
    return
  fi

  command -v curl >/dev/null 2>&1 || fail "$(t official_installer_missing)"
  ok "$(t install_codex_official)"
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
  export PATH="${HOME}/.codex/bin:${HOME}/.local/bin:${PATH}"
}

ensure_local_bin_path() {
  local rc="${HOME}/.zshrc"
  touch "$rc"
  local start="# >>> liangai local bin >>>"
  local end="# <<< liangai local bin <<<"
  if ! grep -qF "$start" "$rc"; then
    cat >> "$rc" <<EOF

${start}
export PATH="\$HOME/.local/bin:\$PATH"
${end}
EOF
  fi
  export PATH="${HOME}/.local/bin:${PATH}"
}

write_shell_exports() {
  local key="$1"
  local base_url="$2"
  local rc="${HOME}/.zshrc"
  touch "$rc"
  local start="# >>> liangai codex installer >>>"
  local end="# <<< liangai codex installer <<<"
  local tmp
  tmp="$(mktemp)"
  sed "/${start}/,/${end}/d" "$rc" > "$tmp"
  cat >> "$tmp" <<EOF
${start}
export OPENAI_API_KEY=$(shell_quote "$key")
export OPENAI_BASE_URL=$(shell_quote "$base_url")
${end}
EOF
  mv "$tmp" "$rc"
  export OPENAI_API_KEY="$key"
  export OPENAI_BASE_URL="$base_url"
}

write_config() {
  local auth="$1"
  local key="${2:-}"
  local base_url="${3:-}"
  step "$(t write_config)"
  status_page "写入配置" "正在写入 ~/.codex/config.toml 和 shell 环境变量。"
  mkdir -p "${HOME}/.codex"
  local config="${HOME}/.codex/config.toml"
  if [[ -f "$config" ]]; then
    local backup="${config}.bak-$(date +%Y%m%d-%H%M%S)"
    cp "$config" "$backup"
    ok "$(t backup "$backup")"
  fi

  if [[ "$auth" == "login" ]]; then
    cat > "$config" <<EOF
model = "$(toml_escape "$MODEL")"
model_reasoning_effort = "$(toml_escape "$REASONING_EFFORT")"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
EOF
    return
  fi

  write_shell_exports "$key" "$base_url"
  cat > "$config" <<EOF
model = "$(toml_escape "$MODEL")"
model_provider = "oneclick_openai_compatible"
model_reasoning_effort = "$(toml_escape "$REASONING_EFFORT")"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
cli_auth_credentials_store = "file"

[model_providers.oneclick_openai_compatible]
name = "One-click OpenAI-compatible provider"
base_url = "$(toml_escape "$base_url")"
env_key = "OPENAI_API_KEY"
wire_api = "responses"
EOF
}

verify_codex() {
  if ! command -v codex >/dev/null 2>&1; then
    fail "$(t verify_fail)"
  fi
  codex --version || true
}

main() {
  echo "$(t title)"
  echo "$(t intro)"
  open_status_page
  ensure_macos
  local auth key base_url
  auth="$(resolve_auth_mode)"
  if [[ "$auth" == "api-key" ]]; then
    key="$(read_api_key)"
    base_url="$(resolve_base_url)"
  fi
  install_codex
  write_config "$auth" "${key:-}" "${base_url:-}"
  verify_codex
  if [[ "$auth" == "login" ]]; then
    open_new_terminal
    status_page "完成" "安装完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行 codex，并按提示登录 ChatGPT。"
    echo "$(t login_done)"
  else
    open_new_terminal
    status_page "完成" "安装配置完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行 codex。"
    echo "$(t done)"
  fi
}

main "$@"
