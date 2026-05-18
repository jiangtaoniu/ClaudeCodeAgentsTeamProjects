# ClaudeCodeAgentsTeamProjects

Claude Code project configuration for routing image tasks through a multimodal `sonnet` subagent while keeping the main session on `opus`.

## Model Routing

- Main model: `opus` -> `mimo-v2.5-pro[1m]`
- Image subagent: `image-reader` with `model: sonnet` -> `mimo-v2.5[1m]`
- Endpoint: Anthropic-compatible MiMo API

The main model should receive image paths and task text. It should call `image-reader`, which reads local image files with Claude Code's `Read` tool and returns structured text for the main model to answer with.

## Usage

Copy the example launcher, add your API key locally, and run it:

```powershell
Copy-Item .\start_claude_mimo.example.bat .\start_claude_mimo.bat
notepad .\start_claude_mimo.bat
.\start_claude_mimo.bat
```

Example prompt inside Claude Code:

```text
请调用 image-reader 分析 F:\ClaudeCodeAgentsTeamProjects\figures\conference MS-IPM.png，然后把识别结果交给主模型总结。
```

Do not paste images directly into the main `opus` session for this setup. Use local image paths so the `sonnet` subagent can read the image first.

## Security

`start_claude_mimo.bat` is intentionally ignored by Git because it may contain a private API key. Commit only `start_claude_mimo.example.bat`.
