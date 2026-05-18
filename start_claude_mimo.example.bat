@echo off
chcp 65001 >nul
setlocal
title Claude Code - MiMo V2.5 Pro

cd /d "%~dp0"

echo ================================================
echo   Claude Code with Xiaomi MiMo Models
echo   Enabled 1M context with [1m] suffix
echo ================================================
echo.
echo [Config] Project: %cd%
echo [Config] Settings: .claude\settings.local.json
echo [Config] Agent: image-reader
echo [Config] Agents:   VoltAgent project agents + local agent-teams plugin
echo [Config] Text:     all pure-text agents -^> opus=mimo-v2.5-pro[1m]
echo [Config] Visual:   image/multimodal agents -^> sonnet=mimo-v2.5[1m]
echo [Config] Image:    local path -^> image-reader -^> text summary
echo [Config] Teams:    enabled via .claude\plugins\agent-teams
echo [Config] Mode:     Dangerous (Auto-approve all)
echo.

REM === Third-party Anthropic-compatible endpoint ===
set "ANTHROPIC_BASE_URL=https://token-plan-cn.xiaomimimo.com/anthropic"
set "ANTHROPIC_API_KEY=replace-with-your-api-key"
set "ANTHROPIC_DEFAULT_OPUS_MODEL=mimo-v2.5-pro[1m]"
set "ANTHROPIC_DEFAULT_SONNET_MODEL=mimo-v2.5[1m]"
set "ANTHROPIC_DEFAULT_HAIKU_MODEL=mimo-v2.5[1m]"
set "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"
set "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"

if "%ANTHROPIC_API_KEY%"=="replace-with-your-api-key" (
  echo [Error] Please edit start_claude_mimo.bat and set ANTHROPIC_API_KEY.
  pause
  exit /b 1
)

claude --dangerously-skip-permissions --model opus --effort max --plugin-dir ".claude\plugins\agent-teams"

pause
