@echo off
setlocal
title Claude Code - Danger Mode

cd /d "%~dp0"

echo ================================================
echo   Claude Code - Danger Mode + Agent Teams
echo ================================================
echo.
echo [Config] Project: %cd%
echo [Config] Mode: Dangerous - Auto-approve all
echo [Config] API: User default only - skip project settings
echo [Config] Agent Teams: Enabled
echo.

REM Enable Agent Teams
set "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1"

REM settings.local.json renamed to settings.local1.json to disable mimo config
claude --dangerously-skip-permissions --effort max --plugin-dir ".claude\plugins\agent-teams"

pause
