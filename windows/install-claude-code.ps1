#Requires -Version 5.1

[CmdletBinding()]
param(
    [ValidateSet("prompt", "official", "api-key", "auth-token")]
    [string]$AuthMode = "prompt",
    [string]$ApiKey = "PLACEHOLDER_CLAUDE_API_KEY_OR_TOKEN",
    [ValidateSet("prompt", "official", "custom")]
    [string]$BaseUrlMode = "prompt",
    [string]$BaseUrl = "PLACEHOLDER_BASE_URL",
    [ValidateSet("zh", "en")]
    [string]$Language = "zh",
    [switch]$LaunchCcSwitch,
    [switch]$StartClaude
)

$ErrorActionPreference = "Stop"

if ($env:CLAUDE_INSTALLER_LANGUAGE -eq "zh" -or $env:CLAUDE_INSTALLER_LANGUAGE -eq "en") {
    $Language = $env:CLAUDE_INSTALLER_LANGUAGE
}

if ($env:CLAUDE_INSTALLER_AUTH_MODE -eq "prompt" -or $env:CLAUDE_INSTALLER_AUTH_MODE -eq "official" -or $env:CLAUDE_INSTALLER_AUTH_MODE -eq "api-key" -or $env:CLAUDE_INSTALLER_AUTH_MODE -eq "auth-token") {
    $AuthMode = $env:CLAUDE_INSTALLER_AUTH_MODE
}

if ($env:CLAUDE_INSTALLER_BASE_URL_MODE -eq "prompt" -or $env:CLAUDE_INSTALLER_BASE_URL_MODE -eq "official" -or $env:CLAUDE_INSTALLER_BASE_URL_MODE -eq "custom") {
    $BaseUrlMode = $env:CLAUDE_INSTALLER_BASE_URL_MODE
}

if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_INSTALLER_API_KEY)) {
    $ApiKey = $env:CLAUDE_INSTALLER_API_KEY
}

if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_INSTALLER_BASE_URL)) {
    $BaseUrl = $env:CLAUDE_INSTALLER_BASE_URL
}

$Messages = @{
    zh = @{
        OkPrefix = "完成"
        WarnPrefix = "警告"
        Title = "Windows 版 Claude Code + CC Switch 一键安装配置"
        Intro = "此脚本会安装 Git for Windows、Claude Code、CC Switch，并写入 Claude Code 配置。"
        AuthMenuTitle = "请选择 Claude Code 的认证方式："
        AuthMenuOfficial = "1. 官方登录/订阅：不写 API key，安装后运行 claude 并按浏览器提示登录。适合 Claude Pro/Max/Team/Enterprise。"
        AuthMenuApiKey = "2. Anthropic 官方 API Key：写入 ANTHROPIC_API_KEY，会以 X-Api-Key 请求头发送。适合 Claude Console 官方 API key。"
        AuthMenuToken = "3. 中转站/网关 Token/API key：写入 ANTHROPIC_AUTH_TOKEN，会以 Authorization: Bearer <token> 请求头发送。多数 Claude Code 中转站给你的 key/token 应该选这个。"
        AuthMenuPrompt = "请输入 1、2 或 3，直接回车默认选择 1"
        AuthInvalidChoice = "无效选择。请输入 1、2 或 3。"
        ApiKeyPrompt = "请粘贴 Anthropic 官方 API key"
        AuthTokenPrompt = "请粘贴中转站/网关提供的 token 或 API key（将作为 Bearer Token 使用）"
        ApiKeyRequired = "选择 API key/token 认证时，API key/token 不能为空。只填写 Base URL 无法完成认证。"
        BaseUrlMenuTitle = "请选择 API 服务地址："
        BaseUrlMenuOfficial = "1. 官方默认地址：不写 ANTHROPIC_BASE_URL，让 Claude Code 使用 Anthropic 官方默认服务。"
        BaseUrlMenuCustom = "2. 自定义 Anthropic/Claude-compatible Base URL：适合中转站、反代或国内模型服务。通常还需要选择第 3 项 Bearer Token，并粘贴服务商给你的 token/API key。请按服务商文档填写 Base URL，不要盲目拼 /v1。"
        BaseUrlMenuPrompt = "请输入 1 或 2，直接回车默认选择 1"
        BaseUrlCustomPrompt = "请输入自定义 Base URL（例如服务商给你的 Claude/Anthropic 地址）"
        BaseUrlInvalidChoice = "无效选择。请输入 1 或 2。"
        BaseUrlRequired = "自定义 Base URL 不能为空。"
        UsingOfficialLogin = "将使用官方登录/订阅模式，不写 API key/token。"
        UsingApiKey = "将使用 ANTHROPIC_API_KEY。"
        UsingAuthToken = "将使用 ANTHROPIC_AUTH_TOKEN。"
        UsingOfficialBaseUrl = "将使用 Claude Code 官方默认 API 地址。"
        UsingCustomBaseUrl = "将使用自定义 Base URL: {0}"
        CheckWinget = "检查 winget"
        WingetMissing = "未找到 winget。请先更新 Windows 应用安装程序，然后重新运行此脚本。"
        CheckGit = "检查 Git for Windows"
        GitInstalled = "Git Bash 已就绪: {0}"
        InstallGit = "正在安装 Git for Windows"
        GitInstallFailed = "Git for Windows 安装失败。退出码: {0}"
        GitBashMissing = "未找到 Git Bash。Claude Code 原生 Windows 模式需要 Git for Windows。"
        CheckClaude = "检查 Claude Code"
        ClaudeInstalled = "Claude Code 已就绪: {0}"
        InstallClaude = "正在安装 Claude Code"
        ClaudeInstallFailed = "Claude Code 安装失败。退出码: {0}"
        ClaudeMissing = "Claude Code 安装后仍未在 PATH 中找到 claude。请打开新的 PowerShell 后重试。"
        InstallCcSwitch = "正在安装 CC Switch（farion1231/cc-switch Portable 版）"
        DownloadCcSwitch = "正在下载: {0}"
        CcSwitchAssetMissing = "没有在最新 GitHub Release 中找到 Windows Portable zip。"
        CcSwitchExeMissing = "在 Portable 压缩包中没有找到 CC Switch 可执行文件。"
        CcSwitchCopyFailed = "CC Switch 可执行文件没有正确复制到安装目录。"
        CcSwitchInstalled = "CC Switch 已安装: {0}"
        ShortcutCreated = "快捷方式已创建: {0}"
        WriteClaudeJson = "正在写入 ~/.claude.json 的 hasCompletedOnboarding=true"
        WriteSettings = "正在写入 ~/.claude/settings.json"
        BackupCreated = "已有配置已备份: {0}"
        InvalidJsonBackedUp = "发现无效 JSON，已备份并重建: {0}"
        ConfigWritten = "配置已写入: {0}"
        EnvSet = "已设置 Windows 用户环境变量。"
        Verify = "正在验证安装"
        ClaudeVersionFailed = "claude --version 执行失败。退出码: {0}"
        SetupComplete = "安装配置完成。"
        NextStepOfficial = "请打开新的 PowerShell，进入项目文件夹运行 claude，并按浏览器提示登录。CC Switch 可从开始菜单或桌面快捷方式打开。"
        NextStepKey = "请打开新的 PowerShell，进入项目文件夹运行 claude。CC Switch 可从开始菜单或桌面快捷方式打开。"
        LaunchCcSwitch = "正在启动 CC Switch"
        StartClaude = "正在启动 Claude Code"
    }
    en = @{
        OkPrefix = "OK"
        WarnPrefix = "WARN"
        Title = "Claude Code + CC Switch one-click setup for Windows"
        Intro = "This script installs Git for Windows, Claude Code, CC Switch, and writes Claude Code config."
        AuthMenuTitle = "Choose Claude Code authentication:"
        AuthMenuOfficial = "1. Official login/subscription: do not write an API key. Run claude after install and sign in in the browser. Use this for Claude Pro/Max/Team/Enterprise."
        AuthMenuApiKey = "2. Official Anthropic API key: writes ANTHROPIC_API_KEY and sends it as the X-Api-Key header. Use this for official Claude Console API keys."
        AuthMenuToken = "3. Relay/gateway token/API key: writes ANTHROPIC_AUTH_TOKEN and sends it as Authorization: Bearer <token>. Most Claude Code relay keys/tokens should use this option."
        AuthMenuPrompt = "Enter 1, 2, or 3. Press Enter for 1"
        AuthInvalidChoice = "Invalid choice. Enter 1, 2, or 3."
        ApiKeyPrompt = "Paste the official Anthropic API key"
        AuthTokenPrompt = "Paste the relay/gateway token or API key. It will be used as a Bearer Token."
        ApiKeyRequired = "API key/token is required for API key/token authentication. Base URL alone cannot authenticate requests."
        BaseUrlMenuTitle = "Choose the API base URL:"
        BaseUrlMenuOfficial = "1. Official default: do not write ANTHROPIC_BASE_URL, so Claude Code uses Anthropic's default service."
        BaseUrlMenuCustom = "2. Custom Anthropic/Claude-compatible Base URL: use this for relays, reverse proxies, or regional model providers. Usually you should also choose option 3, Bearer Token, and paste the provider's token/API key. Follow the provider docs; do not blindly append /v1."
        BaseUrlMenuPrompt = "Enter 1 or 2. Press Enter for 1"
        BaseUrlCustomPrompt = "Enter the custom Base URL from your Claude/Anthropic-compatible provider"
        BaseUrlInvalidChoice = "Invalid choice. Enter 1 or 2."
        BaseUrlRequired = "Custom Base URL is required."
        UsingOfficialLogin = "Using official login/subscription mode; no API key/token will be written."
        UsingApiKey = "Using ANTHROPIC_API_KEY."
        UsingAuthToken = "Using ANTHROPIC_AUTH_TOKEN."
        UsingOfficialBaseUrl = "Using Claude Code official default API endpoint."
        UsingCustomBaseUrl = "Using custom Base URL: {0}"
        CheckWinget = "Checking winget"
        WingetMissing = "winget was not found. Update Windows App Installer, then rerun this script."
        CheckGit = "Checking Git for Windows"
        GitInstalled = "Git Bash is ready: {0}"
        InstallGit = "Installing Git for Windows"
        GitInstallFailed = "Git for Windows install failed. Exit code: {0}"
        GitBashMissing = "Git Bash was not found. Claude Code native Windows mode requires Git for Windows."
        CheckClaude = "Checking Claude Code"
        ClaudeInstalled = "Claude Code is ready: {0}"
        InstallClaude = "Installing Claude Code"
        ClaudeInstallFailed = "Claude Code install failed. Exit code: {0}"
        ClaudeMissing = "Claude Code installed, but claude is not on PATH. Open a new PowerShell window and retry."
        InstallCcSwitch = "Installing CC Switch portable build from farion1231/cc-switch"
        DownloadCcSwitch = "Downloading: {0}"
        CcSwitchAssetMissing = "Could not find a Windows Portable zip in the latest GitHub Release."
        CcSwitchExeMissing = "CC Switch executable was not found in the portable archive."
        CcSwitchCopyFailed = "CC Switch executable was not copied correctly."
        CcSwitchInstalled = "CC Switch installed: {0}"
        ShortcutCreated = "Shortcut created: {0}"
        WriteClaudeJson = "Writing hasCompletedOnboarding=true to ~/.claude.json"
        WriteSettings = "Writing ~/.claude/settings.json"
        BackupCreated = "Existing config backed up: {0}"
        InvalidJsonBackedUp = "Invalid JSON found; backed up and rebuilt: {0}"
        ConfigWritten = "Config written: {0}"
        EnvSet = "Windows user environment variables updated."
        Verify = "Verifying installation"
        ClaudeVersionFailed = "claude --version failed. Exit code: {0}"
        SetupComplete = "Setup complete."
        NextStepOfficial = "Open a new PowerShell window, cd into a project folder, run claude, and follow the browser login. Open CC Switch from Start Menu or the desktop shortcut."
        NextStepKey = "Open a new PowerShell window, cd into a project folder, then run claude. Open CC Switch from Start Menu or the desktop shortcut."
        LaunchCcSwitch = "Starting CC Switch"
        StartClaude = "Starting Claude Code"
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

function Backup-File {
    param([string]$Path)
    if (Test-Path $Path) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupPath = "$Path.bak-$stamp"
        Copy-Item $Path $backupPath -Force
        Write-Ok (T "BackupCreated" $backupPath)
        return $backupPath
    }
    return $null
}

function ConvertTo-Hashtable {
    param([object]$InputObject)

    if ($null -eq $InputObject) {
        return $null
    }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $hash = [ordered]@{}
        foreach ($key in $InputObject.Keys) {
            $hash[$key] = ConvertTo-Hashtable $InputObject[$key]
        }
        return $hash
    }

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $hash = [ordered]@{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $hash[$property.Name] = ConvertTo-Hashtable $property.Value
        }
        return $hash
    }

    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $items = @()
        foreach ($item in $InputObject) {
            $items += ConvertTo-Hashtable $item
        }
        return $items
    }

    return $InputObject
}

function Read-JsonHashtable {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return [ordered]@{}
    }

    $raw = Get-Content -Raw -Path $Path
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [ordered]@{}
    }

    try {
        return ConvertTo-Hashtable ($raw | ConvertFrom-Json)
    }
    catch {
        $backupPath = Backup-File $Path
        Write-Warn (T "InvalidJsonBackedUp" $backupPath)
        return [ordered]@{}
    }
}

function Write-JsonHashtable {
    param(
        [string]$Path,
        [object]$Value
    )

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $json = $Value | ConvertTo-Json -Depth 50
    Set-Content -Path $Path -Value $json -Encoding UTF8
    Write-Ok (T "ConfigWritten" $Path)
}

function Ensure-Winget {
    Write-Step (T "CheckWinget")
    if (-not (Get-CommandPath "winget")) {
        throw (T "WingetMissing")
    }
    Write-Ok "winget"
}

function Find-GitBash {
    $candidates = @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    )

    foreach ($path in $candidates) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Install-GitForWindows {
    Write-Step (T "CheckGit")
    $gitBash = Find-GitBash
    if ($gitBash) {
        Write-Ok (T "GitInstalled" $gitBash)
        return $gitBash
    }

    Write-Step (T "InstallGit")
    & winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw (T "GitInstallFailed" $LASTEXITCODE)
    }

    Add-PathForCurrentProcess "C:\Program Files\Git\cmd"
    Add-PathForCurrentProcess "C:\Program Files\Git\bin"

    $gitBash = Find-GitBash
    if (-not $gitBash) {
        throw (T "GitBashMissing")
    }

    Write-Ok (T "GitInstalled" $gitBash)
    return $gitBash
}

function Install-ClaudeCode {
    Write-Step (T "CheckClaude")
    $claude = Get-CommandPath "claude"
    if ($claude) {
        Write-Ok (T "ClaudeInstalled" $claude)
        return $claude
    }

    Write-Step (T "InstallClaude")
    & winget install --id Anthropic.ClaudeCode -e --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw (T "ClaudeInstallFailed" $LASTEXITCODE)
    }

    Add-PathForCurrentProcess "$env:USERPROFILE\.local\bin"
    Add-PathForCurrentProcess "$env:LOCALAPPDATA\Programs\ClaudeCode"

    $claude = Get-CommandPath "claude"
    if (-not $claude) {
        throw (T "ClaudeMissing")
    }

    Write-Ok (T "ClaudeInstalled" $claude)
    return $claude
}

function Install-CcSwitch {
    Write-Step (T "InstallCcSwitch")

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/farion1231/cc-switch/releases/latest" -Headers @{ "User-Agent" = "claude-code-oneclick-installer" }
    $asset = $release.assets | Where-Object { $_.name -match "Windows-Portable\.zip$" } | Select-Object -First 1
    if ($null -eq $asset) {
        throw (T "CcSwitchAssetMissing")
    }

    $tempRoot = Join-Path $env:TEMP ("cc-switch-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
    $zipPath = Join-Path $tempRoot $asset.name
    Write-Step (T "DownloadCcSwitch" $asset.browser_download_url)
    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath -Headers @{ "User-Agent" = "claude-code-oneclick-installer" }

    $extractPath = Join-Path $tempRoot "extract"
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

    $exe = Get-ChildItem -Path $extractPath -Recurse -Filter "*.exe" | Where-Object { $_.Name -match "CC.?Switch|cc.?switch" } | Select-Object -First 1
    if ($null -eq $exe) {
        throw (T "CcSwitchExeMissing")
    }

    $installRoot = Join-Path $env:LOCALAPPDATA "Programs\CCSwitch"
    if (Test-Path $installRoot) {
        $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupRoot = "$installRoot.bak-$stamp"
        Rename-Item -Path $installRoot -NewName (Split-Path -Leaf $backupRoot)
        Write-Ok (T "BackupCreated" $backupRoot)
    }

    New-Item -ItemType Directory -Force -Path $installRoot | Out-Null
    Copy-Item -Path (Join-Path $extractPath "*") -Destination $installRoot -Recurse -Force

    $installedExe = Get-ChildItem -Path $installRoot -Recurse -Filter $exe.Name | Select-Object -First 1
    if ($null -eq $installedExe) {
        throw (T "CcSwitchCopyFailed")
    }

    Create-Shortcut -ShortcutPath (Join-Path ([Environment]::GetFolderPath("Programs")) "CC Switch.lnk") -TargetPath $installedExe.FullName
    Create-Shortcut -ShortcutPath (Join-Path ([Environment]::GetFolderPath("Desktop")) "CC Switch.lnk") -TargetPath $installedExe.FullName
    Write-Ok (T "CcSwitchInstalled" $installedExe.FullName)
    return $installedExe.FullName
}

function Create-Shortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath
    )

    $directory = Split-Path -Parent $ShortcutPath
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($ShortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.WorkingDirectory = Split-Path -Parent $TargetPath
    $shortcut.Save()
    Write-Ok (T "ShortcutCreated" $ShortcutPath)
}

function Resolve-AuthMode {
    if ($AuthMode -eq "official") {
        Write-Ok (T "UsingOfficialLogin")
        return "official"
    }

    if ($AuthMode -eq "api-key") {
        Write-Ok (T "UsingApiKey")
        return "api-key"
    }

    if ($AuthMode -eq "auth-token") {
        Write-Ok (T "UsingAuthToken")
        return "auth-token"
    }

    Write-Host ""
    Write-Host (T "AuthMenuTitle") -ForegroundColor Cyan
    Write-Host (T "AuthMenuOfficial")
    Write-Host (T "AuthMenuApiKey")
    Write-Host (T "AuthMenuToken")
    $choice = Read-Host (T "AuthMenuPrompt")

    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq "1") {
        Write-Ok (T "UsingOfficialLogin")
        return "official"
    }

    if ($choice -eq "2") {
        Write-Ok (T "UsingApiKey")
        return "api-key"
    }

    if ($choice -eq "3") {
        Write-Ok (T "UsingAuthToken")
        return "auth-token"
    }

    throw (T "AuthInvalidChoice")
}

function Resolve-ApiKey {
    param([string]$FinalAuthMode)

    if ($FinalAuthMode -eq "official") {
        return $null
    }

    if ($ApiKey -and $ApiKey -ne "PLACEHOLDER_CLAUDE_API_KEY_OR_TOKEN") {
        return $ApiKey
    }

    if ($FinalAuthMode -eq "auth-token") {
        $secure = Read-Host (T "AuthTokenPrompt") -AsSecureString
    }
    else {
        $secure = Read-Host (T "ApiKeyPrompt") -AsSecureString
    }
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
    param([string]$FinalAuthMode)

    if ($FinalAuthMode -eq "official") {
        Write-Ok (T "UsingOfficialBaseUrl")
        return $null
    }

    if ($BaseUrl -and $BaseUrl -ne "PLACEHOLDER_BASE_URL") {
        Write-Ok (T "UsingCustomBaseUrl" $BaseUrl)
        return $BaseUrl
    }

    if ($BaseUrlMode -eq "official") {
        Write-Ok (T "UsingOfficialBaseUrl")
        return $null
    }

    if ($BaseUrlMode -eq "custom") {
        $customBaseUrl = Read-Host (T "BaseUrlCustomPrompt")
        if ([string]::IsNullOrWhiteSpace($customBaseUrl)) {
            throw (T "BaseUrlRequired")
        }
        Write-Ok (T "UsingCustomBaseUrl" $customBaseUrl)
        return $customBaseUrl
    }

    Write-Host ""
    Write-Host (T "BaseUrlMenuTitle") -ForegroundColor Cyan
    Write-Host (T "BaseUrlMenuOfficial")
    Write-Host (T "BaseUrlMenuCustom")
    $choice = Read-Host (T "BaseUrlMenuPrompt")

    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq "1") {
        Write-Ok (T "UsingOfficialBaseUrl")
        return $null
    }

    if ($choice -eq "2") {
        $customBaseUrl = Read-Host (T "BaseUrlCustomPrompt")
        if ([string]::IsNullOrWhiteSpace($customBaseUrl)) {
            throw (T "BaseUrlRequired")
        }
        Write-Ok (T "UsingCustomBaseUrl" $customBaseUrl)
        return $customBaseUrl
    }

    throw (T "BaseUrlInvalidChoice")
}

function Write-ClaudeJson {
    Write-Step (T "WriteClaudeJson")
    $path = Join-Path $env:USERPROFILE ".claude.json"
    Backup-File $path | Out-Null
    $config = Read-JsonHashtable $path
    $config["hasCompletedOnboarding"] = $true
    Write-JsonHashtable -Path $path -Value $config
}

function Write-ClaudeSettings {
    param(
        [string]$FinalAuthMode,
        [string]$FinalApiKey,
        [string]$FinalBaseUrl,
        [string]$GitBashPath
    )

    Write-Step (T "WriteSettings")
    $claudeDir = Join-Path $env:USERPROFILE ".claude"
    $settingsPath = Join-Path $claudeDir "settings.json"
    Backup-File $settingsPath | Out-Null
    $settings = Read-JsonHashtable $settingsPath

    if (-not $settings.Contains("env") -or $null -eq $settings["env"] -or $settings["env"] -isnot [System.Collections.IDictionary]) {
        $settings["env"] = [ordered]@{}
    }

    $envConfig = $settings["env"]
    $envConfig.Remove("ANTHROPIC_API_KEY")
    $envConfig.Remove("ANTHROPIC_AUTH_TOKEN")
    $envConfig.Remove("ANTHROPIC_BASE_URL")
    $envConfig["CLAUDE_CODE_GIT_BASH_PATH"] = $GitBashPath

    [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $null, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $null, "User")
    [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $null, "User")
    [Environment]::SetEnvironmentVariable("CLAUDE_CODE_GIT_BASH_PATH", $GitBashPath, "User")
    $env:CLAUDE_CODE_GIT_BASH_PATH = $GitBashPath

    if ($FinalAuthMode -eq "api-key") {
        $envConfig["ANTHROPIC_API_KEY"] = $FinalApiKey
        [Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $FinalApiKey, "User")
        $env:ANTHROPIC_API_KEY = $FinalApiKey
    }
    elseif ($FinalAuthMode -eq "auth-token") {
        $envConfig["ANTHROPIC_AUTH_TOKEN"] = $FinalApiKey
        [Environment]::SetEnvironmentVariable("ANTHROPIC_AUTH_TOKEN", $FinalApiKey, "User")
        $env:ANTHROPIC_AUTH_TOKEN = $FinalApiKey
    }

    if (-not [string]::IsNullOrWhiteSpace($FinalBaseUrl)) {
        $envConfig["ANTHROPIC_BASE_URL"] = $FinalBaseUrl
        [Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $FinalBaseUrl, "User")
        $env:ANTHROPIC_BASE_URL = $FinalBaseUrl
    }

    if (-not $settings.Contains("permissions") -or $null -eq $settings["permissions"] -or $settings["permissions"] -isnot [System.Collections.IDictionary]) {
        $settings["permissions"] = [ordered]@{
            allow = @()
            deny = @()
        }
    }

    Write-JsonHashtable -Path $settingsPath -Value $settings
    Write-Ok (T "EnvSet")
}

function Verify-Install {
    Write-Step (T "Verify")
    & claude --version
    if ($LASTEXITCODE -ne 0) {
        throw (T "ClaudeVersionFailed" $LASTEXITCODE)
    }
}

Write-Host (T "Title") -ForegroundColor White
Write-Host (T "Intro")

$finalAuthMode = Resolve-AuthMode
$finalApiKey = Resolve-ApiKey -FinalAuthMode $finalAuthMode
$finalBaseUrl = Resolve-BaseUrl -FinalAuthMode $finalAuthMode

Ensure-Winget
$gitBash = Install-GitForWindows
Install-ClaudeCode | Out-Null
$ccSwitchExe = Install-CcSwitch
Write-ClaudeJson
Write-ClaudeSettings -FinalAuthMode $finalAuthMode -FinalApiKey $finalApiKey -FinalBaseUrl $finalBaseUrl -GitBashPath $gitBash
Verify-Install

Write-Host ""
Write-Host (T "SetupComplete") -ForegroundColor Green
if ($finalAuthMode -eq "official") {
    Write-Host (T "NextStepOfficial") -ForegroundColor White
}
else {
    Write-Host (T "NextStepKey") -ForegroundColor White
}

if ($LaunchCcSwitch) {
    Write-Step (T "LaunchCcSwitch")
    Start-Process -FilePath $ccSwitchExe
}

if ($StartClaude) {
    Write-Step (T "StartClaude")
    & claude
}
