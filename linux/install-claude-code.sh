#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="${CLAUDE_INSTALLER_LANGUAGE:-zh}"
AUTH_MODE="${CLAUDE_INSTALLER_AUTH_MODE:-prompt}"
API_KEY="${CLAUDE_INSTALLER_API_KEY:-}"
BASE_URL_MODE="${CLAUDE_INSTALLER_BASE_URL_MODE:-prompt}"
BASE_URL="${CLAUDE_INSTALLER_BASE_URL:-}"

t() {
  local key="$1"
  case "${LANGUAGE}:${key}" in
    zh:title) echo "Linux 版 Claude Code 一键安装配置" ;;
    zh:intro) echo "此脚本会安装 Claude Code，并写入 Claude Code 配置。Linux 版不安装 CC Switch 桌面应用；需要管理配置时可直接编辑 ~/.claude/settings.json。" ;;
    zh:auth_title) echo "请选择 Claude Code 的认证方式：" ;;
    zh:auth_official) echo "1. 官方登录/订阅：不写 API key，安装后运行 claude 并按浏览器提示登录。" ;;
    zh:auth_api) echo "2. Anthropic 官方 API Key：写入 ANTHROPIC_API_KEY，会以 X-Api-Key 请求头发送。" ;;
    zh:auth_token) echo "3. 中转站/网关 Token/API key：写入 ANTHROPIC_AUTH_TOKEN，会以 Authorization: Bearer <token> 请求头发送。多数中转站选这个。" ;;
    zh:auth_prompt) echo "请输入 1、2 或 3，直接回车默认选择 1" ;;
    zh:api_prompt) echo "请粘贴 Anthropic 官方 API key" ;;
    zh:token_prompt) echo "请粘贴中转站/网关提供的 token 或 API key（将作为 Bearer Token 使用）" ;;
    zh:key_required) echo "选择 API key/token 认证时，API key/token 不能为空。只填写 Base URL 无法完成认证。" ;;
    zh:base_title) echo "请选择 API 服务地址：" ;;
    zh:base_official) echo "1. 官方默认地址：不写 ANTHROPIC_BASE_URL，让 Claude Code 使用 Anthropic 官方默认服务。" ;;
    zh:base_custom) echo "2. 自定义 Anthropic/Claude-compatible Base URL：适合中转站、反代或国内模型服务。请按服务商文档填写，不要盲目拼 /v1。" ;;
    zh:base_prompt) echo "请输入 1 或 2，直接回车默认选择 1" ;;
    zh:base_custom_prompt) echo "请输入自定义 Base URL（例如服务商给你的 Claude/Anthropic 地址）" ;;
    zh:claude) echo "安装 Claude Code" ;;
    zh:json) echo "写入 ~/.claude.json 和 ~/.claude/settings.json" ;;
    zh:backup) echo "已有配置已备份: $2" ;;
    zh:done_official) echo "安装完成。请打开新的终端，进入项目文件夹运行 claude，并按浏览器提示登录。" ;;
    zh:done_key) echo "安装配置完成。请打开新的终端，进入项目文件夹后运行: claude。" ;;
    zh:verify_fail) echo "未找到 claude 命令。请打开新的终端后重试，或检查 Claude Code 安装是否成功。" ;;
    en:title) echo "Claude Code one-click setup for Linux" ;;
    en:intro) echo "This script installs Claude Code and writes Claude Code config. The Linux installer does not install the CC Switch desktop app; edit ~/.claude/settings.json directly when needed." ;;
    en:auth_title) echo "Choose Claude Code authentication:" ;;
    en:auth_official) echo "1. Official login/subscription: no API key is written. Run claude after install and sign in in the browser." ;;
    en:auth_api) echo "2. Official Anthropic API key: writes ANTHROPIC_API_KEY and sends it as X-Api-Key." ;;
    en:auth_token) echo "3. Relay/gateway token/API key: writes ANTHROPIC_AUTH_TOKEN and sends it as Authorization: Bearer <token>. Most relays should use this." ;;
    en:auth_prompt) echo "Enter 1, 2, or 3. Press Enter for 1" ;;
    en:api_prompt) echo "Paste the official Anthropic API key" ;;
    en:token_prompt) echo "Paste the relay/gateway token or API key. It will be used as a Bearer Token" ;;
    en:key_required) echo "API key/token is required for API key/token authentication. Base URL alone cannot authenticate requests." ;;
    en:base_title) echo "Choose the API base URL:" ;;
    en:base_official) echo "1. Official default: do not write ANTHROPIC_BASE_URL, so Claude Code uses Anthropic's default service." ;;
    en:base_custom) echo "2. Custom Anthropic/Claude-compatible Base URL for relays, reverse proxies, or regional providers. Follow provider docs; do not blindly append /v1." ;;
    en:base_prompt) echo "Enter 1 or 2. Press Enter for 1" ;;
    en:base_custom_prompt) echo "Enter the custom Base URL from your Claude/Anthropic-compatible provider" ;;
    en:claude) echo "Installing Claude Code" ;;
    en:json) echo "Writing ~/.claude.json and ~/.claude/settings.json" ;;
    en:backup) echo "Existing config backed up: $2" ;;
    en:done_official) echo "Setup complete. Open a new terminal, cd into a project folder, run claude, and sign in in the browser." ;;
    en:done_key) echo "Setup complete. Open a new terminal, cd into a project folder, then run: claude." ;;
    en:verify_fail) echo "claude command was not found. Open a new terminal and retry, or check whether Claude Code installed successfully." ;;
    *) echo "$key" ;;
  esac
}

step() { printf '\n==> %s\n' "$1"; }
ok() { printf 'OK  %s\n' "$1"; }
fail() { echo "$1" >&2; exit 1; }

ensure_linux() {
  [[ "$(uname -s)" == "Linux" ]] || fail "This installer is for Linux only."
}

resolve_auth_mode() {
  case "$AUTH_MODE" in
    official) echo "official"; return ;;
    api-key) echo "api-key"; return ;;
    auth-token) echo "auth-token"; return ;;
  esac
  printf '\n%s\n' "$(t auth_title)"
  echo "$(t auth_official)"
  echo "$(t auth_api)"
  echo "$(t auth_token)"
  read -r -p "$(t auth_prompt): " choice
  case "${choice:-1}" in
    1) echo "official" ;;
    2) echo "api-key" ;;
    3) echo "auth-token" ;;
    *) fail "Invalid choice." ;;
  esac
}

read_secret() {
  local auth="$1"
  [[ -n "$API_KEY" ]] && { echo "$API_KEY"; return; }
  if [[ "$auth" == "auth-token" ]]; then
    read -r -s -p "$(t token_prompt): " value
  else
    read -r -s -p "$(t api_prompt): " value
  fi
  printf '\n'
  [[ -n "$value" ]] || fail "$(t key_required)"
  echo "$value"
}

resolve_base_url() {
  local auth="$1"
  [[ "$auth" == "official" ]] && { echo ""; return; }
  [[ -n "$BASE_URL" ]] && { echo "$BASE_URL"; return; }
  case "$BASE_URL_MODE" in
    official) echo ""; return ;;
    custom)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || fail "Base URL is required."
      echo "$value"; return ;;
  esac
  printf '\n%s\n' "$(t base_title)"
  echo "$(t base_official)"
  echo "$(t base_custom)"
  read -r -p "$(t base_prompt): " choice
  case "${choice:-1}" in
    1) echo "" ;;
    2)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || fail "Base URL is required."
      echo "$value" ;;
    *) fail "Invalid choice." ;;
  esac
}

install_claude() {
  step "$(t claude)"
  if command -v claude >/dev/null 2>&1; then
    ok "$(command -v claude)"
    return
  fi
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="${HOME}/.local/bin:${PATH}"
}

backup_file() {
  local path="$1"
  if [[ -f "$path" ]]; then
    local backup="${path}.bak-$(date +%Y%m%d-%H%M%S)"
    cp "$path" "$backup"
    ok "$(t backup "$backup")"
  fi
}

write_json_config() {
  local auth="$1"
  local secret="${2:-}"
  local base_url="${3:-}"
  step "$(t json)"
  mkdir -p "${HOME}/.claude"
  [[ -s "${HOME}/.claude.json" ]] || printf '{}\n' > "${HOME}/.claude.json"
  [[ -s "${HOME}/.claude/settings.json" ]] || printf '{}\n' > "${HOME}/.claude/settings.json"
  backup_file "${HOME}/.claude.json"
  backup_file "${HOME}/.claude/settings.json"

  python3 - "$HOME/.claude.json" "$HOME/.claude/settings.json" "$auth" "$secret" "$base_url" <<'PY'
import json, sys
claude_json, settings_json, auth, secret, base_url = sys.argv[1:]
def read_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}
cj = read_json(claude_json)
cj["hasCompletedOnboarding"] = True
with open(claude_json, "w", encoding="utf-8") as f:
    json.dump(cj, f, ensure_ascii=False, indent=2)
    f.write("\n")
settings = read_json(settings_json)
env = settings.get("env")
if not isinstance(env, dict):
    env = {}
settings["env"] = env
for key in ("ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_BASE_URL"):
    env.pop(key, None)
if auth == "api-key":
    env["ANTHROPIC_API_KEY"] = secret
elif auth == "auth-token":
    env["ANTHROPIC_AUTH_TOKEN"] = secret
if base_url:
    env["ANTHROPIC_BASE_URL"] = base_url
if not isinstance(settings.get("permissions"), dict):
    settings["permissions"] = {"allow": [], "deny": []}
with open(settings_json, "w", encoding="utf-8") as f:
    json.dump(settings, f, ensure_ascii=False, indent=2)
    f.write("\n")
PY
}

verify_claude() {
  command -v claude >/dev/null 2>&1 || fail "$(t verify_fail)"
  claude --version || true
}

main() {
  echo "$(t title)"
  echo "$(t intro)"
  ensure_linux
  command -v curl >/dev/null 2>&1 || fail "curl is required."
  command -v python3 >/dev/null 2>&1 || fail "python3 is required."
  local auth secret base_url
  auth="$(resolve_auth_mode)"
  if [[ "$auth" != "official" ]]; then
    secret="$(read_secret "$auth")"
  fi
  base_url="$(resolve_base_url "$auth")"
  install_claude
  write_json_config "$auth" "${secret:-}" "$base_url"
  verify_claude
  if [[ "$auth" == "official" ]]; then
    echo "$(t done_official)"
  else
    echo "$(t done_key)"
  fi
}

main "$@"
