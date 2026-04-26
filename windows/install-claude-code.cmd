@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
set "STATUS_FILE=%TEMP%\liangai-claude-code-progress.html"
set "NEED_NEW_CMD=0"

call :status "等待用户选择" "请选择官方登录、Anthropic API key 或中转站 Bearer Token。"
start "" "%STATUS_FILE%"

echo Windows 版 Claude Code + CC Switch 一键安装配置
echo 此脚本在 CMD 中运行，会安装 Git for Windows、Claude Code、CC Switch，并写入 Claude Code 配置。
echo.
echo 请选择 Claude Code 的认证方式：
echo 1. 官方登录/订阅：不写 API key，安装后在新的 CMD 中运行 claude 并按浏览器提示登录。
echo 2. Anthropic 官方 API Key：写入 ANTHROPIC_API_KEY，会以 X-Api-Key 请求头发送。
echo 3. 中转站/网关 Token/API key：写入 ANTHROPIC_AUTH_TOKEN，会以 Authorization: Bearer ^<token^> 请求头发送。多数中转站选这个。
set /p AUTH_CHOICE=请输入 1、2 或 3，直接回车默认选择 1: 
if "%AUTH_CHOICE%"=="" set "AUTH_CHOICE=1"
if not "%AUTH_CHOICE%"=="1" if not "%AUTH_CHOICE%"=="2" if not "%AUTH_CHOICE%"=="3" (
  echo 无效选择。
  exit /b 1
)

if not "%AUTH_CHOICE%"=="1" (
  if "%AUTH_CHOICE%"=="2" (
    set /p FINAL_SECRET=请粘贴 Anthropic 官方 API key（CMD 中会明文显示）: 
  ) else (
    set /p FINAL_SECRET=请粘贴中转站/网关提供的 token 或 API key（CMD 中会明文显示，将作为 Bearer Token 使用）: 
  )
  if "!FINAL_SECRET!"=="" (
    echo 选择 API key/token 认证时，API key/token 不能为空。只填写 Base URL 无法完成认证。
    exit /b 1
  )
  echo.
  echo 请选择 API 服务地址：
  echo 1. 官方默认地址：不写 ANTHROPIC_BASE_URL，让 Claude Code 使用 Anthropic 官方默认服务。
  echo 2. 自定义 Anthropic/Claude-compatible Base URL：适合中转站、反代或国内模型服务。请按服务商文档填写，不要盲目拼 /v1。
  set /p BASE_CHOICE=请输入 1 或 2，直接回车默认选择 1: 
  if "!BASE_CHOICE!"=="" set "BASE_CHOICE=1"
  if "!BASE_CHOICE!"=="1" (
    set "FINAL_BASE_URL="
  ) else if "!BASE_CHOICE!"=="2" (
    set /p FINAL_BASE_URL=请输入自定义 Base URL: 
    if "!FINAL_BASE_URL!"=="" (
      echo Base URL 不能为空。
      exit /b 1
    )
  ) else (
    echo 无效选择。
    exit /b 1
  )
)

echo.
echo ==^> 检查 winget
call :status "检查 winget" "确认系统具备 winget 安装能力。"
where winget >nul 2>nul
if errorlevel 1 (
  call :status "安装失败" "未找到 winget。请先更新 Windows 应用安装程序。"
  echo 未找到 winget。请先更新 Windows 应用安装程序，然后重新运行此脚本。
  exit /b 1
)

echo.
echo ==^> 检查 Git for Windows
call :status "检查 Git for Windows" "Claude Code Windows 原生模式需要 Git Bash。"
set "GIT_BASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GIT_BASH%" set "GIT_BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not exist "%GIT_BASH%" (
  echo 正在安装 Git for Windows
  winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    call :status "安装失败" "Git for Windows 安装失败。"
    echo Git for Windows 安装失败。
    exit /b 1
  )
)
set "GIT_BASH=%ProgramFiles%\Git\bin\bash.exe"
if not exist "%GIT_BASH%" set "GIT_BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not exist "%GIT_BASH%" (
  call :status "需要新的 CMD" "Git 已安装，但当前 CMD 暂时找不到 Git Bash。请打开新的 CMD 后重新运行。"
  echo 未找到 Git Bash。Claude Code 原生 Windows 模式需要 Git for Windows。请打开新的 CMD 后重试。
  exit /b 1
)

echo.
echo ==^> 安装 Claude Code
call :status "安装 Claude Code" "正在通过 winget 安装或检查 Anthropic Claude Code。"
where claude >nul 2>nul
if errorlevel 1 (
  winget install --id Anthropic.ClaudeCode -e --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    call :status "安装失败" "Claude Code 安装失败。"
    echo Claude Code 安装失败。
    exit /b 1
  )
)
set "PATH=%USERPROFILE%\.local\bin;%LOCALAPPDATA%\Programs\ClaudeCode;%PATH%"
where claude >nul 2>nul
if errorlevel 1 (
  call :status "需要新的 CMD" "Claude Code 已安装，但当前 CMD 找不到 claude。脚本会继续写配置，并在最后打开新的 CMD。"
  set "NEED_NEW_CMD=1"
  echo Claude Code 已安装，但当前 CMD 找不到 claude。请打开新的 CMD 后运行: claude
)

echo.
echo ==^> 安装 CC Switch（farion1231/cc-switch Portable 版）
call :status "安装 CC Switch" "正在下载并安装 farion1231/cc-switch Windows Portable 版。"
set "CC_API=https://api.github.com/repos/farion1231/cc-switch/releases/latest"
set "CC_URL="
for /f "tokens=2,* delims=:" %%A in ('curl.exe -fsSL "%CC_API%" ^| findstr /i "Windows-Portable.zip"') do (
  set "CC_URL=https:%%B"
)
set "CC_URL=%CC_URL: =%"
set "CC_URL=%CC_URL:"=%"
set "CC_URL=%CC_URL:,=%"
if "%CC_URL%"=="" (
  call :status "安装失败" "没有在最新 GitHub Release 中找到 Windows Portable zip。"
  echo 没有在最新 GitHub Release 中找到 Windows Portable zip。
  exit /b 1
)
set "TMP_ROOT=%TEMP%\cc-switch-%RANDOM%%RANDOM%"
set "CC_ZIP=%TMP_ROOT%\cc-switch.zip"
set "CC_EXTRACT=%TMP_ROOT%\extract"
mkdir "%CC_EXTRACT%" >nul
curl.exe -fL "%CC_URL%" -o "%CC_ZIP%"
if errorlevel 1 (
  call :status "安装失败" "CC Switch 下载失败。"
  echo CC Switch 下载失败。
  exit /b 1
)
tar -xf "%CC_ZIP%" -C "%CC_EXTRACT%"
if errorlevel 1 (
  call :status "安装失败" "CC Switch 解压失败。"
  echo CC Switch 解压失败。
  exit /b 1
)
set "CC_EXE="
for /r "%CC_EXTRACT%" %%F in (*.exe) do (
  echo %%~nxF | findstr /i "switch" >nul && set "CC_EXE=%%F"
)
if "%CC_EXE%"=="" (
  call :status "安装失败" "在 Portable 压缩包中没有找到 CC Switch 可执行文件。"
  echo 在 Portable 压缩包中没有找到 CC Switch 可执行文件。
  exit /b 1
)
set "CC_INSTALL=%LOCALAPPDATA%\Programs\CCSwitch"
if exist "%CC_INSTALL%" (
  ren "%CC_INSTALL%" "CCSwitch.bak-%RANDOM%%RANDOM%"
)
mkdir "%CC_INSTALL%" >nul
xcopy "%CC_EXTRACT%\*" "%CC_INSTALL%\" /E /I /Y >nul
set "CC_INSTALLED_EXE="
for /r "%CC_INSTALL%" %%F in (*.exe) do (
  echo %%~nxF | findstr /i "switch" >nul && set "CC_INSTALLED_EXE=%%F"
)

set "VBS=%TEMP%\create-ccswitch-shortcuts.vbs"
> "%VBS%" echo Set shell = CreateObject("WScript.Shell")
>> "%VBS%" echo target = "%CC_INSTALLED_EXE%"
>> "%VBS%" echo Set link = shell.CreateShortcut(shell.SpecialFolders("Desktop") ^& "\CC Switch.lnk")
>> "%VBS%" echo link.TargetPath = target
>> "%VBS%" echo link.WorkingDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(target)
>> "%VBS%" echo link.Save
>> "%VBS%" echo Set link = shell.CreateShortcut(shell.SpecialFolders("Programs") ^& "\CC Switch.lnk")
>> "%VBS%" echo link.TargetPath = target
>> "%VBS%" echo link.WorkingDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(target)
>> "%VBS%" echo link.Save
cscript //nologo "%VBS%" >nul 2>nul

echo.
echo ==^> 写入 Claude Code 配置
call :status "写入配置" "正在写入 .claude.json 和 .claude\settings.json。"
set "CLAUDE_JSON=%USERPROFILE%\.claude.json"
set "CLAUDE_DIR=%USERPROFILE%\.claude"
set "SETTINGS_JSON=%CLAUDE_DIR%\settings.json"
if not exist "%CLAUDE_DIR%" mkdir "%CLAUDE_DIR%"
if exist "%CLAUDE_JSON%" copy "%CLAUDE_JSON%" "%CLAUDE_JSON%.bak-%DATE:/=-%-%TIME::=-%" >nul
if exist "%SETTINGS_JSON%" copy "%SETTINGS_JSON%" "%SETTINGS_JSON%.bak-%DATE:/=-%-%TIME::=-%" >nul

set "JS=%TEMP%\write-claude-config.js"
> "%JS%" echo var fso = new ActiveXObject("Scripting.FileSystemObject");
>> "%JS%" echo function readJson(path){try{if(!fso.FileExists(path))return {};var s=fso.OpenTextFile(path,1,false,-1).ReadAll();if(!s)return {};return JSON.parse(s);}catch(e){return {};}}
>> "%JS%" echo function writeJson(path,obj){var file=fso.OpenTextFile(path,2,true,-1);file.Write(JSON.stringify(obj,null,2));file.Close();}
>> "%JS%" echo var claudeJson=WScript.Arguments(0), settingsJson=WScript.Arguments(1), auth=WScript.Arguments(2), secret=WScript.Arguments(3), base=WScript.Arguments(4), gitbash=WScript.Arguments(5);
>> "%JS%" echo var cj=readJson(claudeJson); cj.hasCompletedOnboarding=true; writeJson(claudeJson,cj);
>> "%JS%" echo var st=readJson(settingsJson); if(!st.env || typeof st.env!=="object") st.env={}; delete st.env.ANTHROPIC_API_KEY; delete st.env.ANTHROPIC_AUTH_TOKEN; delete st.env.ANTHROPIC_BASE_URL; st.env.CLAUDE_CODE_GIT_BASH_PATH=gitbash;
>> "%JS%" echo if(auth==="2") st.env.ANTHROPIC_API_KEY=secret; if(auth==="3") st.env.ANTHROPIC_AUTH_TOKEN=secret; if(base) st.env.ANTHROPIC_BASE_URL=base;
>> "%JS%" echo if(!st.permissions || typeof st.permissions!=="object") st.permissions={allow:[],deny:[]}; writeJson(settingsJson,st);
cscript //nologo "%JS%" "%CLAUDE_JSON%" "%SETTINGS_JSON%" "%AUTH_CHOICE%" "%FINAL_SECRET%" "%FINAL_BASE_URL%" "%GIT_BASH%"
if errorlevel 1 (
  call :status "安装失败" "Claude Code 配置写入失败。"
  echo Claude Code 配置写入失败。
  exit /b 1
)

reg delete HKCU\Environment /v ANTHROPIC_API_KEY /f >nul 2>nul
reg delete HKCU\Environment /v ANTHROPIC_AUTH_TOKEN /f >nul 2>nul
reg delete HKCU\Environment /v ANTHROPIC_BASE_URL /f >nul 2>nul
setx CLAUDE_CODE_GIT_BASH_PATH "%GIT_BASH%" >nul
if "%AUTH_CHOICE%"=="2" setx ANTHROPIC_API_KEY "%FINAL_SECRET%" >nul
if "%AUTH_CHOICE%"=="3" setx ANTHROPIC_AUTH_TOKEN "%FINAL_SECRET%" >nul
if not "%FINAL_BASE_URL%"=="" setx ANTHROPIC_BASE_URL "%FINAL_BASE_URL%" >nul

echo.
call :status "完成，需要新的 CMD" "配置已写入。脚本已打开新的 CMD；请在新窗口进入项目目录后运行 claude。CC Switch 可从桌面快捷方式打开。"
echo 安装配置完成。已打开新的 CMD，请在新窗口进入项目文件夹后运行: claude
start "Claude Code" cmd /k "echo Claude Code 配置完成。请进入项目文件夹后运行 claude。& echo. & where claude & claude --version & echo. & echo 如果上面显示了版本号，就可以直接 cd 到项目文件夹运行 claude。"
exit /b 0

:status
set "STATUS_TITLE=%~1"
set "STATUS_DETAIL=%~2"
> "%STATUS_FILE%" echo ^<!doctype html^>
>> "%STATUS_FILE%" echo ^<html lang="zh-CN"^>^<head^>^<meta charset="utf-8"^>^<meta http-equiv="refresh" content="2"^>^<meta name="viewport" content="width=device-width, initial-scale=1"^>^<title^>Claude Code 安装进度^</title^>
>> "%STATUS_FILE%" echo ^<style^>body{margin:0;font-family:Segoe UI,Microsoft YaHei,sans-serif;background:#f6f7f9;color:#1e252e}.box{max-width:760px;margin:56px auto;padding:28px;background:#fff;border:1px solid #d9e0e8;border-radius:8px}.eyebrow{color:#147d64;font-weight:700;font-size:13px}h1{margin:10px 0 16px;font-size:32px}.detail{line-height:1.7;color:#596575}.bar{height:10px;background:#e8eef4;border-radius:99px;overflow:hidden;margin-top:24px}.bar span{display:block;width:68%;height:100%;background:#147d64}.hint{margin-top:20px;font-size:13px;color:#596575}code{background:#eef2f6;padding:2px 5px;border-radius:4px}^</style^>
>> "%STATUS_FILE%" echo ^</head^>^<body^>^<main class="box"^>^<div class="eyebrow"^>Claude Code Windows CMD Installer^</div^>^<h1^>%STATUS_TITLE%^</h1^>^<p class="detail"^>%STATUS_DETAIL%^</p^>^<div class="bar"^>^<span^>^</span^>^</div^>^<p class="hint"^>这个页面由安装脚本写入，会自动刷新。安装完成后脚本会打开新的 CMD 运行 ^<code^>claude^</code^>。^</p^>^</main^>^</body^>^</html^>
exit /b 0
