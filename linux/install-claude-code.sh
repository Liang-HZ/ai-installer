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
    zh:title) echo "Linux 版 Claude Code + CC Switch 一键安装配置" ;;
    zh:intro) echo "此脚本会补齐基础依赖，调用 Anthropic 官方安装器安装 Claude Code，从 farion1231/cc-switch 官方 Release 安装 CC Switch，并写入 Claude Code 配置。" ;;
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
    zh:base_invalid_scheme) echo "Base URL 必须以 https:// 开头。请复制服务商提供的 HTTPS 地址。" ;;
    zh:base_invalid_chars) echo "Base URL 含有空白、换行或 shell 特殊字符。为保护你的终端，脚本已停止；请只粘贴纯 HTTPS 地址。" ;;
    zh:claude) echo "安装 Claude Code" ;;
    zh:ccswitch) echo "安装 CC Switch" ;;
    zh:install_deps) echo "正在安装缺失的基础依赖: $2" ;;
    zh:deps_failed) echo "基础依赖安装失败。当前系统不在脚本支持的包管理器范围内，或缺少 sudo/root 权限；请联系页面作者补充该系统支持。" ;;
    zh:ccswitch_asset_missing) echo "没有在最新 GitHub Release 中找到适合当前 Linux 架构和包格式的 CC Switch 资产。" ;;
    zh:ccswitch_appimage) echo "未识别到 deb/rpm 包管理器，改为安装官方 AppImage 到 ~/.local/bin/cc-switch.AppImage。" ;;
    zh:download) echo "正在下载: $2" ;;
    zh:json) echo "写入 ~/.claude.json 和 ~/.claude/settings.json" ;;
    zh:backup) echo "已有配置已备份: $2" ;;
    zh:done_official) echo "安装完成。请打开新的终端，进入项目文件夹运行 claude，并按浏览器提示登录。" ;;
    zh:done_key) echo "安装配置完成。请打开新的终端，进入项目文件夹后运行: claude。" ;;
    zh:verify_fail) echo "未找到 claude 命令。请打开新的终端后重试，或检查 Claude Code 安装是否成功。" ;;
    en:title) echo "Claude Code + CC Switch one-click setup for Linux" ;;
    en:intro) echo "This script installs base prerequisites, runs the official Anthropic installer for Claude Code, installs CC Switch from the official farion1231/cc-switch Release, and writes Claude Code config." ;;
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
    en:base_invalid_scheme) echo "Base URL must start with https://. Paste the HTTPS URL from your provider." ;;
    en:base_invalid_chars) echo "Base URL contains whitespace, newlines, or shell metacharacters. To protect your terminal, setup stopped. Paste only the plain HTTPS URL." ;;
    en:claude) echo "Installing Claude Code" ;;
    en:ccswitch) echo "Installing CC Switch" ;;
    en:install_deps) echo "Installing missing base prerequisites: $2" ;;
    en:deps_failed) echo "Failed to install base prerequisites. This system is outside the supported package manager set, or sudo/root permission is missing; contact the page owner to add support for this system." ;;
    en:ccswitch_asset_missing) echo "Could not find a CC Switch asset for this Linux architecture and package format in the latest GitHub Release." ;;
    en:ccswitch_appimage) echo "No deb/rpm package manager was detected; installing the official AppImage to ~/.local/bin/cc-switch.AppImage." ;;
    en:download) echo "Downloading: $2" ;;
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
warn() { printf 'WARN %s\n' "$1"; }
fail() { echo "$1" >&2; exit 1; }

validate_base_url() {
  local value="$1"
  [[ "$value" == https://* ]] || fail "$(t base_invalid_scheme)"
  # Base URL 来自用户复制粘贴；提前拒绝会污染终端或配置文件的内容。
  case "$value" in
    *[$' \t\r\n'\'\"\`\$\\\;\&\|\<\>\(\)\{\}]*)
      fail "$(t base_invalid_chars)"
      ;;
  esac
}

ensure_linux() {
  [[ "$(uname -s)" == "Linux" ]] || fail "This installer is for Linux only."
}

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
    return
  fi
  command -v sudo >/dev/null 2>&1 || fail "$(t deps_failed)"
  sudo "$@"
}

install_linux_packages() {
  local packages=("$@")
  [[ "${#packages[@]}" -gt 0 ]] || return
  step "$(t install_deps "${packages[*]}")"
  if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y "${packages[@]}"
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y "${packages[@]}"
  elif command -v yum >/dev/null 2>&1; then
    run_as_root yum install -y "${packages[@]}"
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -Sy --noconfirm --needed "${packages[@]}"
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install "${packages[@]}"
  else
    fail "$(t deps_failed)"
  fi
}

ensure_linux_prereqs() {
  local packages=()
  command -v curl >/dev/null 2>&1 || packages+=("curl")
  command -v python3 >/dev/null 2>&1 || packages+=("python3")
  command -v tar >/dev/null 2>&1 || packages+=("tar")
  command -v mktemp >/dev/null 2>&1 || packages+=("coreutils")
  if [[ "${#packages[@]}" -gt 0 ]]; then
    install_linux_packages "${packages[@]}"
  fi
  command -v curl >/dev/null 2>&1 || fail "$(t deps_failed)"
  command -v python3 >/dev/null 2>&1 || fail "$(t deps_failed)"
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
  [[ -n "$BASE_URL" ]] && { validate_base_url "$BASE_URL"; echo "$BASE_URL"; return; }
  case "$BASE_URL_MODE" in
    official) echo ""; return ;;
    custom)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || fail "Base URL is required."
      validate_base_url "$value"
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
      validate_base_url "$value"
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

install_ccswitch() {
  step "$(t ccswitch)"
  # 官方资产名示例：CC-Switch-v3.16.1-Linux-x86_64.deb / CC-Switch-v3.16.1-Linux-arm64.rpm / CC-Switch-v3.16.1-Linux-x86_64.AppImage
  local machine cc_arch package_ext api asset_url tmp package_path
  machine="$(uname -m)"
  case "$machine" in
    x86_64|amd64) cc_arch="x86_64" ;;
    aarch64|arm64) cc_arch="arm64" ;;
    *) fail "Unsupported architecture: $machine" ;;
  esac

  if command -v dpkg >/dev/null 2>&1 && command -v apt-get >/dev/null 2>&1; then
    package_ext="deb"
  elif command -v rpm >/dev/null 2>&1 && { command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1 || command -v zypper >/dev/null 2>&1; }; then
    package_ext="rpm"
  else
    package_ext="AppImage"
    warn "$(t ccswitch_appimage)"
  fi

  api="$(curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest)"
  asset_url="$(printf '%s' "$api" | grep -Eo "https://[^\"]+CC-Switch-v[^\"]+-Linux-${cc_arch}\\.${package_ext}" | head -n 1 || true)"
  [[ -n "$asset_url" ]] || fail "$(t ccswitch_asset_missing)"

  tmp="$(mktemp -d)"
  package_path="${tmp}/cc-switch.${package_ext}"
  step "$(t download "$asset_url")"
  curl -fL "$asset_url" -o "$package_path"

  case "$package_ext" in
    deb)
      if ! run_as_root dpkg -i "$package_path"; then
        run_as_root apt-get install -f -y
      fi
      ;;
    rpm)
      if command -v dnf >/dev/null 2>&1; then
        run_as_root dnf install -y "$package_path"
      elif command -v yum >/dev/null 2>&1; then
        run_as_root yum install -y "$package_path"
      else
        run_as_root zypper --non-interactive install "$package_path"
      fi
      ;;
    AppImage)
      mkdir -p "${HOME}/.local/bin"
      cp "$package_path" "${HOME}/.local/bin/cc-switch.AppImage"
      chmod +x "${HOME}/.local/bin/cc-switch.AppImage"
      ok "${HOME}/.local/bin/cc-switch.AppImage"
      ;;
  esac
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
  ensure_linux_prereqs
  local auth secret base_url
  auth="$(resolve_auth_mode)"
  if [[ "$auth" != "official" ]]; then
    secret="$(read_secret "$auth")"
  fi
  base_url="$(resolve_base_url "$auth")"
  install_claude
  install_ccswitch
  write_json_config "$auth" "${secret:-}" "$base_url"
  verify_claude
  if [[ "$auth" == "official" ]]; then
    echo "$(t done_official)"
  else
    echo "$(t done_key)"
  fi
}

main "$@"
