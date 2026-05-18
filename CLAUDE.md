# Claude Code Project Instructions

## Model Routing

- The main Claude Code session runs with `--model opus`, mapped to `mimo-v2.5-pro[1m]`.
- Treat the main `opus` model as text-only for image tasks.
- The `image-reader` subagent runs with `model: sonnet`, mapped to `mimo-v2.5[1m]`, and is responsible for image understanding.

## Image Workflow

When the user asks about an image, screenshot, UI mockup, chart, OCR task, visual bug, or a folder containing images:

1. Do not attempt to interpret the image directly in the main agent.
2. Use the `image-reader` subagent first.
3. Pass the local file path or folder path to `image-reader`.
4. Let `image-reader` read the image with `Read` and return structured text.
5. Continue the main task using only the structured text returned by `image-reader`.

Preferred user input format:

```text
请调用 image-reader 分析 F:\ClaudeCodeAgentsTeamProjects\figures\conference MS-IPM.png，然后把识别结果交给主模型总结。
```

Do not rely on pasted image blocks for this project. Ask for a local image path when the user only pastes or attaches an image.
