#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$ApiKey = "PLACEHOLDER_OPENAI_API_KEY",
    [string]$BaseUrl = "PLACEHOLDER_BASE_URL",
    [ValidateSet("prompt", "openai", "custom")]
    [string]$BaseUrlMode = "prompt",
    [string]$Model = "gpt-5.5",
    [ValidateSet("minimal", "low", "medium", "high")]
    [string]$ReasoningEffort = "high",
    [ValidateSet("elevated", "unelevated")]
    [string]$WindowsSandbox = "elevated",
    [ValidateSet("zh", "en")]
    [string]$Language = "zh",
    [switch]$StartCodex
)

$ErrorActionPreference = "Stop"
$OpenAIBaseUrl = "https://api.openai.com/v1"

if ($env:CODEX_INSTALLER_LANGUAGE -eq "zh" -or $env:CODEX_INSTALLER_LANGUAGE -eq "en") {
    $Language = $env:CODEX_INSTALLER_LANGUAGE
}

if ($env:CODEX_INSTALLER_BASE_URL_MODE -eq "prompt" -or $env:CODEX_INSTALLER_BASE_URL_MODE -eq "openai" -or $env:CODEX_INSTALLER_BASE_URL_MODE -eq "custom") {
    $BaseUrlMode = $env:CODEX_INSTALLER_BASE_URL_MODE
}

if (-not [string]::IsNullOrWhiteSpace($env:CODEX_INSTALLER_BASE_URL)) {
    $BaseUrl = $env:CODEX_INSTALLER_BASE_URL
}

$Messages = @{
    zh = @{
        OkPrefix = "完成"
        WarnPrefix = "警告"
        Title = "Windows 版 OpenAI Codex CLI 一键安装配置"
        Intro = "此脚本会按需安装 Node.js LTS、安装 Codex CLI，并写入 ~/.codex/config.toml。"
        CheckNode = "检查 Node.js 和 npm"
        NodeAlready = "Node.js 已安装: {0}"
        NpmAlready = "npm 已安装: {0}"
        WingetMissing = "未找到 winget。请先更新 Windows 应用安装程序，然后重新运行此脚本。"
        InstallNode = "正在通过 winget 安装 Node.js LTS"
        WingetNodeFailed = "winget 安装 Node.js LTS 失败。退出码: {0}"
        NodePathMissing = "Node.js 已安装，但当前 PowerShell 会话中找不到 node/npm。请关闭 PowerShell，重新打开后再运行此脚本。"
        NodeInstalled = "Node.js 已安装: {0}"
        NpmInstalled = "npm 已安装: {0}"
        InstallCodex = "正在安装或升级 OpenAI Codex CLI"
        NpmCodexFailed = "npm 安装 @openai/codex@latest 失败。退出码: {0}"
        CodexPathMissingAfterInstall = "Codex 已安装，但 PATH 中找不到 codex。请打开新的 PowerShell 窗口后运行: codex"
        CodexInstalled = "Codex CLI 已安装: {0}"
        ApiKeyPlaceholder = "API key 仍是占位符。"
        ApiKeyPrompt = "请粘贴 Codex 使用的 API key"
        ApiKeyRequired = "API key 不能为空。"
        BaseUrlMenuTitle = "请选择 Codex 连接的 API 服务地址："
        BaseUrlMenuOpenAI = "1. OpenAI 官方 API（{0}）：适合能直连官方，并使用 OpenAI 官方 API key 的用户。"
        BaseUrlMenuCustom = "2. 自定义 OpenAI-compatible 地址：适合中转站、反代、开源模型服务、国内模型服务等。通常需要以 /v1 结尾。"
        BaseUrlMenuPrompt = "请输入 1 或 2，直接回车默认选择 1"
        BaseUrlCustomPrompt = "请输入自定义 Base URL（例如 https://example.com/v1）"
        BaseUrlInvalidChoice = "无效选择。请输入 1 或 2。"
        BaseUrlUsingOpenAI = "将使用 OpenAI 官方 API: {0}"
        BaseUrlUsingCustom = "将使用自定义 API 地址: {0}"
        BaseUrlCustomHint = "请确认该地址是 OpenAI-compatible 接口；很多服务要求 base URL 以 /v1 结尾。"
        BaseUrlRequired = "自定义 Base URL 不能为空。"
        WriteConfig = "正在写入 Codex 配置"
        BaseUrlMissing = "BaseUrl 不能为空。请设置为 OpenAI-compatible 接口地址，例如 https://api.openai.com/v1。"
        ModelMissing = "Model 不能为空。请设置为你的 API key 可访问的模型。"
        ConfigBackup = "已有配置已备份为 config.toml.bak-{0}"
        ConfigWritten = "配置已写入: {0}"
        EnvSet = "已设置 Windows 用户环境变量: OPENAI_API_KEY, OPENAI_BASE_URL"
        VerifyCodex = "正在验证 Codex 命令"
        CodexPathMissing = "PATH 中找不到 codex。"
        CodexVersionFailed = "codex --version 执行失败。退出码: {0}"
        CodexReady = "Codex 命令已就绪"
        SetupComplete = "安装配置完成。"
        NextStep = "请打开新的 PowerShell 窗口，进入项目文件夹，然后运行: codex"
        StartCodex = "正在启动 Codex"
    }
    en = @{
        OkPrefix = "OK"
        WarnPrefix = "WARN"
        Title = "OpenAI Codex CLI one-click setup for Windows"
        Intro = "This script installs Node.js LTS if needed, installs Codex CLI, and writes ~/.codex/config.toml."
        CheckNode = "Checking Node.js and npm"
        NodeAlready = "Node.js is already installed: {0}"
        NpmAlready = "npm is already installed: {0}"
        WingetMissing = "winget was not found. Update Windows App Installer, then rerun this script."
        InstallNode = "Installing Node.js LTS with winget"
        WingetNodeFailed = "winget failed to install Node.js LTS. Exit code: {0}"
        NodePathMissing = "Node.js was installed, but node/npm is not available in this PowerShell session. Close PowerShell, reopen it, and rerun this script."
        NodeInstalled = "Node.js installed: {0}"
        NpmInstalled = "npm installed: {0}"
        InstallCodex = "Installing or upgrading OpenAI Codex CLI"
        NpmCodexFailed = "npm failed to install @openai/codex@latest. Exit code: {0}"
        CodexPathMissingAfterInstall = "Codex installed, but codex is not available on PATH. Open a new PowerShell window and run: codex"
        CodexInstalled = "Codex CLI installed: {0}"
        ApiKeyPlaceholder = "API key placeholder was not replaced."
        ApiKeyPrompt = "Paste the API key for Codex"
        ApiKeyRequired = "API key is required."
        BaseUrlMenuTitle = "Choose the API base URL Codex should use:"
        BaseUrlMenuOpenAI = "1. Official OpenAI API ({0}): use this if you can reach OpenAI directly and have an official OpenAI API key."
        BaseUrlMenuCustom = "2. Custom OpenAI-compatible URL: use this for relay/proxy services, self-hosted open models, or regional model providers. It often needs to end with /v1."
        BaseUrlMenuPrompt = "Enter 1 or 2. Press Enter for 1"
        BaseUrlCustomPrompt = "Enter the custom Base URL, for example https://example.com/v1"
        BaseUrlInvalidChoice = "Invalid choice. Enter 1 or 2."
        BaseUrlUsingOpenAI = "Using official OpenAI API: {0}"
        BaseUrlUsingCustom = "Using custom API base URL: {0}"
        BaseUrlCustomHint = "Make sure this is an OpenAI-compatible endpoint. Many services require the base URL to end with /v1."
        BaseUrlRequired = "Custom Base URL is required."
        WriteConfig = "Writing Codex configuration"
        BaseUrlMissing = "BaseUrl is missing. Set it to an OpenAI-compatible endpoint, for example https://api.openai.com/v1."
        ModelMissing = "Model is missing. Set it to a model your API key can access."
        ConfigBackup = "Existing config backed up to config.toml.bak-{0}"
        ConfigWritten = "Config written: {0}"
        EnvSet = "User environment variables set: OPENAI_API_KEY, OPENAI_BASE_URL"
        VerifyCodex = "Verifying Codex command"
        CodexPathMissing = "codex is not available on PATH."
        CodexVersionFailed = "codex --version failed. Exit code: {0}"
        CodexReady = "Codex command is ready"
        SetupComplete = "Setup complete."
        NextStep = "Open a new PowerShell window, cd into a project folder, then run: codex"
        StartCodex = "Starting Codex"
    }
}

function T {
    param(
        [string]$Key,
        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$Args
    )

    $template = $Messages[$Language][$Key]
    if ($null -eq $template) {
        if ($Language -eq "zh") {
            throw "缺少提示文本: $Language.$Key"
        }
        throw "Missing message: $Language.$Key"
    }

    if ($Args -and $Args.Count -gt 0) {
        return [string]::Format($template, $Args)
    }

    return $template
}

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host ("{0}  {1}" -f (T "OkPrefix"), $Message) -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host ("{0} {1}" -f (T "WarnPrefix"), $Message) -ForegroundColor Yellow
}

function Get-CommandPath {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        return $null
    }
    return $command.Source
}

function Add-PathForCurrentProcess {
    param([string]$PathToAdd)
    if (-not [string]::IsNullOrWhiteSpace($PathToAdd) -and (Test-Path $PathToAdd)) {
        $parts = $env:Path -split ";"
        if ($parts -notcontains $PathToAdd) {
            $env:Path = "$PathToAdd;$env:Path"
        }
    }
}

function Install-NodeWithWinget {
    Write-Step (T "CheckNode")
    $node = Get-CommandPath "node"
    $npm = Get-CommandPath "npm"
    if ($node -and $npm) {
        Write-Ok (T "NodeAlready" $node)
        Write-Ok (T "NpmAlready" $npm)
        return
    }

    $winget = Get-CommandPath "winget"
    if (-not $winget) {
        throw (T "WingetMissing")
    }

    Write-Step (T "InstallNode")
    & winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw (T "WingetNodeFailed" $LASTEXITCODE)
    }

    Add-PathForCurrentProcess "C:\Program Files\nodejs"
    Add-PathForCurrentProcess "$env:APPDATA\npm"

    $node = Get-CommandPath "node"
    $npm = Get-CommandPath "npm"
    if (-not $node -or -not $npm) {
        throw (T "NodePathMissing")
    }

    Write-Ok (T "NodeInstalled" $node)
    Write-Ok (T "NpmInstalled" $npm)
}

function Install-CodexCli {
    Write-Step (T "InstallCodex")
    & npm install -g "@openai/codex@latest"
    if ($LASTEXITCODE -ne 0) {
        throw (T "NpmCodexFailed" $LASTEXITCODE)
    }

    Add-PathForCurrentProcess "$env:APPDATA\npm"

    $codex = Get-CommandPath "codex"
    if (-not $codex) {
        throw (T "CodexPathMissingAfterInstall")
    }

    Write-Ok (T "CodexInstalled" $codex)
    & codex --version
}

function Read-ApiKeyIfNeeded {
    if ($ApiKey -and $ApiKey -ne "PLACEHOLDER_OPENAI_API_KEY") {
        return $ApiKey
    }

    Write-Warn (T "ApiKeyPlaceholder")
    $secure = Read-Host (T "ApiKeyPrompt") -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }

    if ([string]::IsNullOrWhiteSpace($plain)) {
        throw (T "ApiKeyRequired")
    }

    return $plain
}

function Resolve-BaseUrl {
    if ($BaseUrl -and $BaseUrl -ne "PLACEHOLDER_BASE_URL") {
        Write-Ok (T "BaseUrlUsingCustom" $BaseUrl)
        Write-Warn (T "BaseUrlCustomHint")
        return $BaseUrl
    }

    if ($BaseUrlMode -eq "openai") {
        Write-Ok (T "BaseUrlUsingOpenAI" $OpenAIBaseUrl)
        return $OpenAIBaseUrl
    }

    if ($BaseUrlMode -eq "custom") {
        $customBaseUrl = Read-Host (T "BaseUrlCustomPrompt")
        if ([string]::IsNullOrWhiteSpace($customBaseUrl)) {
            throw (T "BaseUrlRequired")
        }
        Write-Ok (T "BaseUrlUsingCustom" $customBaseUrl)
        Write-Warn (T "BaseUrlCustomHint")
        return $customBaseUrl
    }

    Write-Host ""
    Write-Host (T "BaseUrlMenuTitle") -ForegroundColor Cyan
    Write-Host (T "BaseUrlMenuOpenAI" $OpenAIBaseUrl)
    Write-Host (T "BaseUrlMenuCustom")
    $choice = Read-Host (T "BaseUrlMenuPrompt")

    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq "1") {
        Write-Ok (T "BaseUrlUsingOpenAI" $OpenAIBaseUrl)
        return $OpenAIBaseUrl
    }

    if ($choice -eq "2") {
        $customBaseUrl = Read-Host (T "BaseUrlCustomPrompt")
        if ([string]::IsNullOrWhiteSpace($customBaseUrl)) {
            throw (T "BaseUrlRequired")
        }
        Write-Ok (T "BaseUrlUsingCustom" $customBaseUrl)
        Write-Warn (T "BaseUrlCustomHint")
        return $customBaseUrl
    }

    throw (T "BaseUrlInvalidChoice")
}

function Escape-TomlString {
    param([string]$Value)
    return $Value.Replace('\', '\\').Replace('"', '\"')
}

function Write-CodexConfig {
    param(
        [string]$FinalApiKey,
        [string]$FinalBaseUrl
    )

    Write-Step (T "WriteConfig")

    if ([string]::IsNullOrWhiteSpace($FinalBaseUrl) -or $FinalBaseUrl -eq "PLACEHOLDER_BASE_URL") {
        throw (T "BaseUrlMissing")
    }

    if ([string]::IsNullOrWhiteSpace($Model) -or $Model -eq "PLACEHOLDER_MODEL") {
        throw (T "ModelMissing")
    }

    $codexHome = Join-Path $env:USERPROFILE ".codex"
    New-Item -ItemType Directory -Force -Path $codexHome | Out-Null

    $configPath = Join-Path $codexHome "config.toml"
    if (Test-Path $configPath) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        Copy-Item $configPath "$configPath.bak-$stamp" -Force
        Write-Ok (T "ConfigBackup" $stamp)
    }

    $providerId = "oneclick_openai_compatible"
    $escapedBaseUrl = Escape-TomlString $FinalBaseUrl
    $escapedModel = Escape-TomlString $Model

    $config = @"
model = "$escapedModel"
model_provider = "$providerId"
model_reasoning_effort = "$ReasoningEffort"
approval_policy = "on-request"
sandbox_mode = "workspace-write"
cli_auth_credentials_store = "file"

[windows]
sandbox = "$WindowsSandbox"

[model_providers.$providerId]
name = "One-click OpenAI-compatible provider"
base_url = "$escapedBaseUrl"
env_key = "OPENAI_API_KEY"
wire_api = "responses"
"@

    Set-Content -Path $configPath -Value $config -Encoding UTF8

    [Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $FinalApiKey, "User")
    [Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", $FinalBaseUrl, "User")
    $env:OPENAI_API_KEY = $FinalApiKey
    $env:OPENAI_BASE_URL = $FinalBaseUrl

    Write-Ok (T "ConfigWritten" $configPath)
    Write-Ok (T "EnvSet")
}

function Test-CodexCommand {
    Write-Step (T "VerifyCodex")
    $codex = Get-CommandPath "codex"
    if (-not $codex) {
        throw (T "CodexPathMissing")
    }

    & codex --version
    if ($LASTEXITCODE -ne 0) {
        throw (T "CodexVersionFailed" $LASTEXITCODE)
    }

    Write-Ok (T "CodexReady")
}

Write-Host (T "Title") -ForegroundColor White
Write-Host (T "Intro")

$finalBaseUrl = Resolve-BaseUrl
$finalApiKey = Read-ApiKeyIfNeeded
Install-NodeWithWinget
Install-CodexCli
Write-CodexConfig -FinalApiKey $finalApiKey -FinalBaseUrl $finalBaseUrl
Test-CodexCommand

Write-Host ""
Write-Host (T "SetupComplete") -ForegroundColor Green
Write-Host (T "NextStep") -ForegroundColor White

if ($StartCodex) {
    Write-Step (T "StartCodex")
    & codex
}
