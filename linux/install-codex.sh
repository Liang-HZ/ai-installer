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

t() {
  local key="$1"
  case "${LANGUAGE}:${key}" in
    zh:title) echo "Linux 版 Codex CLI 一键安装配置" ;;
    zh:intro) echo "此脚本会补齐基础依赖，调用 OpenAI 官方 Codex 安装器安装 CLI，并写入 ~/.codex/config.toml。" ;;
    zh:auth_title) echo "请选择 Codex 的使用方式：" ;;
    zh:auth_login) echo "1. ChatGPT 官方登录/订阅：不写 API key，安装后运行 codex 并按提示登录。" ;;
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
    zh:install_official) echo "正在运行 OpenAI 官方安装器：https://chatgpt.com/codex/install.sh" ;;
    zh:install_deps) echo "正在安装缺失的基础依赖: $2" ;;
    zh:deps_failed) echo "基础依赖安装失败。当前系统不在脚本支持的包管理器范围内，或缺少 sudo/root 权限；请联系页面作者补充该系统支持。" ;;
    zh:download) echo "正在下载: $2" ;;
    zh:asset_missing) echo "没有找到适合当前 Linux 架构的 Codex Release 资产。" ;;
    zh:write_config) echo "写入 Codex 配置" ;;
    zh:backup) echo "已有配置已备份: $2" ;;
    zh:done) echo "安装配置完成。请打开新的终端，进入项目文件夹后运行: codex" ;;
    zh:login_done) echo "安装完成。请打开新的终端，进入项目文件夹运行 codex，并按提示登录 ChatGPT。" ;;
    zh:verify_fail) echo "未找到 codex 命令。请打开新的终端后重试，或检查 Codex 安装是否成功。" ;;
    en:title) echo "Codex CLI one-click setup for Linux" ;;
    en:intro) echo "This script installs base prerequisites, runs the official OpenAI Codex installer, and writes ~/.codex/config.toml." ;;
    en:auth_title) echo "Choose how to use Codex:" ;;
    en:auth_login) echo "1. ChatGPT login/subscription: no API key is written. Run codex after install and sign in." ;;
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
    en:install_official) echo "Running the official OpenAI installer: https://chatgpt.com/codex/install.sh" ;;
    en:install_deps) echo "Installing missing base prerequisites: $2" ;;
    en:deps_failed) echo "Failed to install base prerequisites. This system is outside the supported package manager set, or sudo/root permission is missing; contact the page owner to add support for this system." ;;
    en:download) echo "Downloading: $2" ;;
    en:asset_missing) echo "Could not find a Codex Release asset for this Linux architecture." ;;
    en:write_config) echo "Writing Codex configuration" ;;
    en:backup) echo "Existing config backed up: $2" ;;
    en:done) echo "Setup complete. Open a new terminal, cd into a project folder, then run: codex" ;;
    en:login_done) echo "Setup complete. Open a new terminal, cd into a project folder, run codex, and sign in with ChatGPT." ;;
    en:verify_fail) echo "codex command was not found. Open a new terminal and retry, or check whether Codex installed successfully." ;;
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
  # 用户粘贴的地址后面会写入 shell 启动文件；这里提前拦住会触发解释执行的字符。
  case "$value" in
    *[$' \t\r\n'\'\"\`\$\\\;\&\|\<\>\(\)\{\}]*)
      fail "$(t base_invalid_chars)"
      ;;
  esac
}

shell_quote() {
  # 写入 .bashrc/.zshrc 时只允许作为字符串保存，不能让 $()、反引号等被 shell 执行。
  printf "'%s'" "$(printf '%s' "$1" | sed "s/'/'\\\\''/g")"
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

ensure_codex_prereqs() {
  local packages=()
  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    packages+=("curl")
  fi
  command -v tar >/dev/null 2>&1 || packages+=("tar")
  command -v mktemp >/dev/null 2>&1 || packages+=("coreutils")
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1 && ! command -v openssl >/dev/null 2>&1; then
    packages+=("coreutils")
  fi
  if [[ "${#packages[@]}" -gt 0 ]]; then
    install_linux_packages "${packages[@]}"
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
    *) fail "Invalid choice." ;;
  esac
}

read_api_key() {
  [[ -n "$API_KEY" ]] && { echo "$API_KEY"; return; }
  read -r -s -p "$(t key_prompt): " value
  printf '\n'
  [[ -n "$value" ]] || fail "$(t key_required)"
  echo "$value"
}

resolve_base_url() {
  [[ -n "$BASE_URL" ]] && { validate_base_url "$BASE_URL"; echo "$BASE_URL"; return; }
  case "$BASE_URL_MODE" in
    openai|official) echo "$OPENAI_BASE_URL"; return ;;
    custom)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || fail "Base URL is required."
      validate_base_url "$value"
      echo "$value"; return ;;
  esac
  printf '\n%s\n' "$(t base_title)"
  echo "$(t base_openai)"
  echo "$(t base_custom)"
  read -r -p "$(t base_prompt): " choice
  case "${choice:-1}" in
    1) echo "$OPENAI_BASE_URL" ;;
    2)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || fail "Base URL is required."
      validate_base_url "$value"
      echo "$value" ;;
    *) fail "Invalid choice." ;;
  esac
}

ensure_local_bin_path() {
  mkdir -p "${HOME}/.local/bin"
  local rc="${HOME}/.bashrc"
  [[ -n "${ZSH_VERSION:-}" ]] && rc="${HOME}/.zshrc"
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

install_codex() {
  step "$(t install_codex)"
  if command -v codex >/dev/null 2>&1; then
    ok "$(command -v codex)"
    return
  fi
  ensure_codex_prereqs
  ok "$(t install_official)"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
  else
    wget -qO- https://chatgpt.com/codex/install.sh | sh
  fi
  export PATH="${HOME}/.codex/bin:${HOME}/.local/bin:${PATH}"
}

toml_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

write_shell_exports() {
  local key="$1"
  local base_url="$2"
  local rc="${HOME}/.bashrc"
  [[ -n "${ZSH_VERSION:-}" ]] && rc="${HOME}/.zshrc"
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
  command -v codex >/dev/null 2>&1 || fail "$(t verify_fail)"
  codex --version || true
}

main() {
  echo "$(t title)"
  echo "$(t intro)"
  ensure_linux
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
    echo "$(t login_done)"
  else
    echo "$(t done)"
  fi
}

main "$@"
