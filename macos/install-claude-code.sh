#!/usr/bin/env bash
set -euo pipefail

LANGUAGE="${CLAUDE_INSTALLER_LANGUAGE:-zh}"
AUTH_MODE="${CLAUDE_INSTALLER_AUTH_MODE:-prompt}"
API_KEY="${CLAUDE_INSTALLER_API_KEY:-}"
BASE_URL_MODE="${CLAUDE_INSTALLER_BASE_URL_MODE:-prompt}"
BASE_URL="${CLAUDE_INSTALLER_BASE_URL:-}"
STATUS_FILE="${TMPDIR:-/tmp}/liangai-claude-code-progress.html"

t() {
  local key="$1"
  case "${LANGUAGE}:${key}" in
    zh:title) echo "macOS 版 Claude Code + CC Switch 一键安装配置" ;;
    zh:intro) echo "此脚本会安装 Claude Code、CC Switch，并写入 Claude Code 配置。CC Switch 有 Homebrew 时优先使用 Homebrew；没有 Homebrew 时直接下载 macOS 版应用。" ;;
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
    zh:ccswitch) echo "安装 CC Switch" ;;
    zh:ccswitch_brew) echo "检测到 Homebrew，使用 brew install --cask cc-switch。" ;;
    zh:ccswitch_direct) echo "未检测到 Homebrew，改为直接下载 farion1231/cc-switch macOS Release。" ;;
    zh:download) echo "正在下载: $2" ;;
    zh:ccswitch_asset_missing) echo "没有在最新 GitHub Release 中找到 macOS zip。" ;;
    zh:ccswitch_app_missing) echo "下载包里没有找到 CC Switch.app。" ;;
    zh:json) echo "写入 ~/.claude.json 和 ~/.claude/settings.json" ;;
    zh:backup) echo "已有配置已备份: $2" ;;
    zh:done_official) echo "安装完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行 claude，并按浏览器提示登录。CC Switch 可从应用程序中打开。" ;;
    zh:done_key) echo "安装配置完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行: claude。CC Switch 可从应用程序中打开。" ;;
    zh:verify_fail) echo "未找到 claude 命令。请打开新的终端后重试，或检查 Claude Code 安装是否成功。" ;;
    en:title) echo "Claude Code + CC Switch one-click setup for macOS" ;;
    en:intro) echo "This script installs Claude Code, CC Switch, and writes Claude Code config. CC Switch uses Homebrew when available, otherwise it downloads the macOS app directly." ;;
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
    en:ccswitch) echo "Installing CC Switch" ;;
    en:ccswitch_brew) echo "Homebrew detected; using brew install --cask cc-switch." ;;
    en:ccswitch_direct) echo "Homebrew not found; downloading the farion1231/cc-switch macOS Release directly." ;;
    en:download) echo "Downloading: $2" ;;
    en:ccswitch_asset_missing) echo "Could not find a macOS zip in the latest GitHub Release." ;;
    en:ccswitch_app_missing) echo "CC Switch.app was not found in the downloaded archive." ;;
    en:json) echo "Writing ~/.claude.json and ~/.claude/settings.json" ;;
    en:backup) echo "Existing config backed up: $2" ;;
    en:done_official) echo "Setup complete. A new Terminal was opened. You can also run source ~/.zshrc in the current terminal, then run claude and sign in in the browser. Open CC Switch from Applications." ;;
    en:done_key) echo "Setup complete. A new Terminal was opened. You can also run source ~/.zshrc in the current terminal, then run: claude. Open CC Switch from Applications." ;;
    en:verify_fail) echo "claude command was not found. Open a new terminal and retry, or check whether Claude Code installed successfully." ;;
    *) echo "$key" ;;
  esac
}

step() { printf '\n==> %s\n' "$1"; }
ok() { printf 'OK  %s\n' "$1"; }
warn() { printf 'WARN %s\n' "$1"; }

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
  <title>Claude Code 安装进度</title>
  <style>
    body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI","Microsoft YaHei",sans-serif;background:#f6f7f9;color:#1e252e}
    .box{max-width:760px;margin:56px auto;padding:28px;background:#fff;border:1px solid #d9e0e8;border-radius:8px}
    .eyebrow{color:#147d64;font-weight:700;font-size:13px}h1{margin:10px 0 16px;font-size:32px}.detail{line-height:1.7;color:#596575}
    .bar{height:10px;background:#e8eef4;border-radius:99px;overflow:hidden;margin-top:24px}.bar span{display:block;width:68%;height:100%;background:#147d64}
    .hint{margin-top:20px;font-size:13px;color:#596575}code{background:#eef2f6;padding:2px 5px;border-radius:4px}
  </style>
</head>
<body><main class="box"><div class="eyebrow">Claude Code macOS Installer</div><h1>${title}</h1><p class="detail">${detail}</p><div class="bar"><span></span></div><p class="hint">这个页面由安装脚本写入，会自动刷新。安装完成后脚本会打开新的 Terminal；也可以执行 <code>source ~/.zshrc</code> 后运行 <code>claude</code>。</p></main></body>
</html>
EOF
}

open_new_terminal() {
  /usr/bin/osascript <<'EOF' >/dev/null 2>&1 || true
tell application "Terminal"
  activate
  do script "source ~/.zshrc >/dev/null 2>&1 || true; echo 'Claude Code 配置完成。请 cd 到项目文件夹后运行 claude。'; echo ''; command -v claude; claude --version; echo ''; exec $SHELL -l"
end tell
EOF
}

open_status_page() {
  status_page "等待用户选择" "请选择官方登录、Anthropic API key 或中转站 Bearer Token。"
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

load_brew_path() {
  [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
  [[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"
}

has_homebrew() {
  load_brew_path
  command -v brew >/dev/null 2>&1
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
    *) echo "Invalid choice." >&2; exit 1 ;;
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
  [[ -n "$value" ]] || { echo "$(t key_required)" >&2; exit 1; }
  echo "$value"
}

resolve_base_url() {
  local auth="$1"
  if [[ "$auth" == "official" ]]; then
    echo ""
    return
  fi
  [[ -n "$BASE_URL" ]] && { echo "$BASE_URL"; return; }
  case "$BASE_URL_MODE" in
    official) echo ""; return ;;
    custom)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || { echo "Base URL is required." >&2; exit 1; }
      echo "$value"
      return
      ;;
  esac

  printf '\n%s\n' "$(t base_title)"
  echo "$(t base_official)"
  echo "$(t base_custom)"
  read -r -p "$(t base_prompt): " choice
  case "${choice:-1}" in
    1) echo "" ;;
    2)
      read -r -p "$(t base_custom_prompt): " value
      [[ -n "$value" ]] || { echo "Base URL is required." >&2; exit 1; }
      echo "$value"
      ;;
    *) echo "Invalid choice." >&2; exit 1 ;;
  esac
}

install_claude() {
  step "$(t claude)"
  status_page "安装 Claude Code" "正在检查或安装 Claude Code。"
  if command -v claude >/dev/null 2>&1; then
    ok "$(command -v claude)"
    ensure_local_bin_path
    return
  fi
  curl -fsSL https://claude.ai/install.sh | bash
  ensure_local_bin_path
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

install_ccswitch() {
  step "$(t ccswitch)"
  status_page "安装 CC Switch" "正在检查或安装 CC Switch。"
  if has_homebrew; then
    ok "$(t ccswitch_brew)"
    brew install --cask cc-switch || brew upgrade --cask cc-switch || true
    return
  fi

  warn "$(t ccswitch_direct)"
  local api asset_url tmp extract app_path dest_dir
  api="$(curl -fsSL https://api.github.com/repos/farion1231/cc-switch/releases/latest)"
  asset_url="$(printf '%s' "$api" | grep -Eo 'https://[^"]+CC-Switch-[^"]+-macOS\.zip' | head -n 1 || true)"
  if [[ -z "$asset_url" ]]; then
    fail "$(t ccswitch_asset_missing)"
  fi

  tmp="$(mktemp -d)"
  extract="${tmp}/extract"
  mkdir -p "$extract"
  step "$(t download "$asset_url")"
  curl -fL "$asset_url" -o "${tmp}/cc-switch-macos.zip"
  /usr/bin/unzip -q "${tmp}/cc-switch-macos.zip" -d "$extract"
  app_path="$(find "$extract" -type d -name 'CC Switch.app' -print -quit)"
  if [[ -z "$app_path" ]]; then
    fail "$(t ccswitch_app_missing)"
  fi

  dest_dir="${HOME}/Applications"
  mkdir -p "$dest_dir"
  rm -rf "${dest_dir}/CC Switch.app"
  cp -R "$app_path" "$dest_dir/"
  ok "${dest_dir}/CC Switch.app"
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
  status_page "写入配置" "正在写入 ~/.claude.json 和 ~/.claude/settings.json。"
  mkdir -p "${HOME}/.claude"
  touch "${HOME}/.claude.json"
  [[ -s "${HOME}/.claude.json" ]] || printf '{}\n' > "${HOME}/.claude.json"
  touch "${HOME}/.claude/settings.json"
  [[ -s "${HOME}/.claude/settings.json" ]] || printf '{}\n' > "${HOME}/.claude/settings.json"
  backup_file "${HOME}/.claude.json"
  backup_file "${HOME}/.claude/settings.json"

  ruby -rjson -e '
    claude_json, settings_json, auth, secret, base_url = ARGV
    def read_json(path)
      JSON.parse(File.read(path))
    rescue
      {}
    end
    cj = read_json(claude_json)
    cj["hasCompletedOnboarding"] = true
    File.write(claude_json, JSON.pretty_generate(cj) + "\n")

    settings = read_json(settings_json)
    settings["env"] = settings["env"].is_a?(Hash) ? settings["env"] : {}
    env = settings["env"]
    env.delete("ANTHROPIC_API_KEY")
    env.delete("ANTHROPIC_AUTH_TOKEN")
    env.delete("ANTHROPIC_BASE_URL")
    if auth == "api-key"
      env["ANTHROPIC_API_KEY"] = secret
    elsif auth == "auth-token"
      env["ANTHROPIC_AUTH_TOKEN"] = secret
    end
    env["ANTHROPIC_BASE_URL"] = base_url unless base_url.nil? || base_url.empty?
    settings["permissions"] = {"allow" => [], "deny" => []} unless settings["permissions"].is_a?(Hash)
    File.write(settings_json, JSON.pretty_generate(settings) + "\n")
  ' "${HOME}/.claude.json" "${HOME}/.claude/settings.json" "$auth" "$secret" "$base_url"

  if [[ "$auth" == "api-key" ]]; then
    export ANTHROPIC_API_KEY="$secret"
  elif [[ "$auth" == "auth-token" ]]; then
    export ANTHROPIC_AUTH_TOKEN="$secret"
  fi
  [[ -n "$base_url" ]] && export ANTHROPIC_BASE_URL="$base_url"
}

verify_claude() {
  if ! command -v claude >/dev/null 2>&1; then
    fail "$(t verify_fail)"
  fi
  claude --version || true
}

main() {
  echo "$(t title)"
  echo "$(t intro)"
  open_status_page
  ensure_macos
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
    open_new_terminal
    status_page "完成" "安装完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行 claude，并按浏览器提示登录。"
    echo "$(t done_official)"
  else
    open_new_terminal
    status_page "完成" "安装配置完成。已打开新的 Terminal；也可以在当前终端执行 source ~/.zshrc 后运行 claude。"
    echo "$(t done_key)"
  fi
}

main "$@"
