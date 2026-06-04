@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion

set "MODEL=gpt-5.5"
set "REASONING_EFFORT=high"
set "OPENAI_BASE_URL=https://api.openai.com/v1"
set "STATUS_FILE=%TEMP%\liangai-codex-progress.html"
set "NEED_NEW_CMD=0"

call :status "等待用户选择" "请选择 ChatGPT 登录或 API key 模式。"
start "" "%STATUS_FILE%"

echo Windows 版 Codex CLI 一键安装配置
echo 此脚本在 CMD 中运行，会调用 OpenAI 官方安装器安装 Codex CLI，并写入 %%USERPROFILE%%\.codex\config.toml。
echo.
echo 请选择 Codex 的使用方式：
echo 1. ChatGPT 官方登录/订阅：不写 API key，安装后在新的 CMD 中运行 codex 并按提示登录。
echo 2. API key / 中转站 key：写入 OPENAI_API_KEY，并配置官方或自定义 OpenAI-compatible Base URL。
set /p AUTH_CHOICE=请输入 1 或 2，直接回车默认选择 1: 
if "%AUTH_CHOICE%"=="" set "AUTH_CHOICE=1"
if not "%AUTH_CHOICE%"=="1" if not "%AUTH_CHOICE%"=="2" (
  echo 无效选择。
  exit /b 1
)

if "%AUTH_CHOICE%"=="2" (
  echo.
  set /p FINAL_API_KEY=请粘贴 OpenAI API key 或中转站 key（CMD 中会明文显示）: 
  if "!FINAL_API_KEY!"=="" (
    echo 选择 API key 模式时，key 不能为空。只填写 Base URL 无法认证。
    exit /b 1
  )
  echo.
  echo 请选择 API 服务地址：
  echo 1. OpenAI 官方 API（%OPENAI_BASE_URL%）
  echo 2. 自定义 OpenAI-compatible Base URL：适合中转站、反代、国内模型服务等，通常以 /v1 结尾。
  set /p BASE_CHOICE=请输入 1 或 2，直接回车默认选择 1: 
  if "!BASE_CHOICE!"=="" set "BASE_CHOICE=1"
  if "!BASE_CHOICE!"=="1" (
    set "FINAL_BASE_URL=%OPENAI_BASE_URL%"
  ) else if "!BASE_CHOICE!"=="2" (
    set /p FINAL_BASE_URL=请输入自定义 Base URL（例如 https://example.com/v1）: 
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
echo ==^> 检查 PowerShell
call :status "检查 PowerShell" "确认系统可以运行 OpenAI 官方 Codex 安装器。"
where powershell >nul 2>nul
if errorlevel 1 (
  call :status "安装失败" "未找到 PowerShell，无法运行 OpenAI 官方 Codex 安装器。"
  echo 未找到 PowerShell，无法运行 OpenAI 官方 Codex 安装器。
  exit /b 1
)

echo.
echo ==^> 安装或升级 OpenAI Codex CLI
call :status "安装 Codex CLI" "正在运行 OpenAI 官方安装器：https://chatgpt.com/codex/install.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://chatgpt.com/codex/install.ps1 | iex"
if errorlevel 1 (
  call :status "安装失败" "Codex CLI 安装失败。"
  echo Codex CLI 安装失败。
  exit /b 1
)
set "PATH=%USERPROFILE%\.codex\bin;%USERPROFILE%\.local\bin;%APPDATA%\npm;%PATH%"

where codex >nul 2>nul
if errorlevel 1 (
  call :status "需要新的 CMD" "Codex 已安装，但当前 CMD 找不到 codex。正在打开新的 CMD。"
  set "NEED_NEW_CMD=1"
  echo Codex 已安装，但当前 CMD 找不到 codex。请打开新的 CMD 后运行: codex
)

echo.
echo ==^> 写入 Codex 配置
call :status "写入配置" "正在写入 %USERPROFILE%\.codex\config.toml。"
set "CODEX_HOME=%USERPROFILE%\.codex"
if not exist "%CODEX_HOME%" mkdir "%CODEX_HOME%"
set "CONFIG_PATH=%CODEX_HOME%\config.toml"
if exist "%CONFIG_PATH%" (
  copy "%CONFIG_PATH%" "%CONFIG_PATH%.bak-%DATE:/=-%-%TIME::=-%" >nul
)

if "%AUTH_CHOICE%"=="1" (
  > "%CONFIG_PATH%" echo model = "%MODEL%"
  >> "%CONFIG_PATH%" echo model_reasoning_effort = "%REASONING_EFFORT%"
  >> "%CONFIG_PATH%" echo approval_policy = "on-request"
  >> "%CONFIG_PATH%" echo sandbox_mode = "workspace-write"
) else (
  setx OPENAI_API_KEY "!FINAL_API_KEY!" >nul
  setx OPENAI_BASE_URL "!FINAL_BASE_URL!" >nul
  set "OPENAI_API_KEY=!FINAL_API_KEY!"
  set "OPENAI_BASE_URL=!FINAL_BASE_URL!"
  > "%CONFIG_PATH%" echo model = "%MODEL%"
  >> "%CONFIG_PATH%" echo model_provider = "oneclick_openai_compatible"
  >> "%CONFIG_PATH%" echo model_reasoning_effort = "%REASONING_EFFORT%"
  >> "%CONFIG_PATH%" echo approval_policy = "on-request"
  >> "%CONFIG_PATH%" echo sandbox_mode = "workspace-write"
  >> "%CONFIG_PATH%" echo cli_auth_credentials_store = "file"
  >> "%CONFIG_PATH%" echo.
  >> "%CONFIG_PATH%" echo [model_providers.oneclick_openai_compatible]
  >> "%CONFIG_PATH%" echo name = "One-click OpenAI-compatible provider"
  >> "%CONFIG_PATH%" echo base_url = "!FINAL_BASE_URL!"
  >> "%CONFIG_PATH%" echo env_key = "OPENAI_API_KEY"
  >> "%CONFIG_PATH%" echo wire_api = "responses"
)

echo.
call :status "完成，需要新的 CMD" "配置已写入。脚本已打开新的 CMD；请在新窗口进入项目目录后运行 codex。"
echo 安装配置完成。已打开新的 CMD，请在新窗口进入项目文件夹后运行: codex
start "Codex CLI" cmd /k "echo Codex 配置完成。请进入项目文件夹后运行 codex。& echo. & where codex & codex --version & echo. & echo 如果上面显示了版本号，就可以直接 cd 到项目文件夹运行 codex。"
exit /b 0

:status
set "STATUS_TITLE=%~1"
set "STATUS_DETAIL=%~2"
> "%STATUS_FILE%" echo ^<!doctype html^>
>> "%STATUS_FILE%" echo ^<html lang="zh-CN"^>^<head^>^<meta charset="utf-8"^>^<meta http-equiv="refresh" content="2"^>^<meta name="viewport" content="width=device-width, initial-scale=1"^>^<title^>Codex 安装进度^</title^>
>> "%STATUS_FILE%" echo ^<style^>body{margin:0;font-family:Segoe UI,Microsoft YaHei,sans-serif;background:#f6f7f9;color:#1e252e}.box{max-width:760px;margin:56px auto;padding:28px;background:#fff;border:1px solid #d9e0e8;border-radius:8px}.eyebrow{color:#147d64;font-weight:700;font-size:13px}h1{margin:10px 0 16px;font-size:32px}.detail{line-height:1.7;color:#596575}.bar{height:10px;background:#e8eef4;border-radius:99px;overflow:hidden;margin-top:24px}.bar span{display:block;width:68%;height:100%;background:#147d64}.hint{margin-top:20px;font-size:13px;color:#596575}code{background:#eef2f6;padding:2px 5px;border-radius:4px}^</style^>
>> "%STATUS_FILE%" echo ^</head^>^<body^>^<main class="box"^>^<div class="eyebrow"^>Codex Windows CMD Installer^</div^>^<h1^>%STATUS_TITLE%^</h1^>^<p class="detail"^>%STATUS_DETAIL%^</p^>^<div class="bar"^>^<span^>^</span^>^</div^>^<p class="hint"^>这个页面由安装脚本写入，会自动刷新。安装完成后脚本会打开新的 CMD 运行 ^<code^>codex^</code^>。^</p^>^</main^>^</body^>^</html^>
exit /b 0
