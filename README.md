# ClaudeCodeAgentsTeamProjects

这是一个 Claude Code 项目级 Agent 配置仓库。目标是让 Claude Code 在开发时具备多 Agent 协作能力，同时按照本项目的模型能力进行精确分工：

- 纯文本任务全部使用 `opus -> mimo-v2.5-pro[1m]`
- 图片、截图、UI、图表、OCR 等多模态任务使用 `sonnet -> mimo-v2.5[1m]`
- 主会话默认使用 `opus`
- 项目级子 Agent 放在 `.claude/agents/`
- wshobson 的 Agent Teams 插件放在 `.claude/plugins/agent-teams/`

## 模型分配策略

当前模型路由规则非常明确：

- `opus`：对应 `mimo-v2.5-pro[1m]`，用于所有纯文本任务，包括代码实现、调试、数据分析、机器学习、论文调研、架构设计、代码审查、安全审计和多 Agent 协调。
- `sonnet`：对应 `mimo-v2.5[1m]`，只用于视觉/多模态任务，包括图片识别、截图分析、UI 视觉校验、图表 OCR 和视觉证据判断。

不要设置 `CLAUDE_CODE_SUBAGENT_MODEL`，否则会覆盖每个 Agent 自己的 `model` 字段，破坏上面的分工。

## 使用方式

复制启动脚本模板，填入你自己的 API Key，然后运行：

```powershell
Copy-Item .\start_claude_mimo.example.bat .\start_claude_mimo.bat
notepad .\start_claude_mimo.bat
.\start_claude_mimo.bat
```

推荐用图片路径触发多模态 Agent，不要直接把图片粘贴给主模型：

```text
请调用 image-reader 分析 F:\ClaudeCodeAgentsTeamProjects\figures\conference MS-IPM.png，然后把识别结果交给主模型总结。
```

## 当前项目级 Agents

项目级 Agent 都安装在 `.claude/agents/`。Claude Code 在当前项目中会优先使用这些 Agent。

### `image-reader`

- 模型：`sonnet -> mimo-v2.5[1m]`
- 类型：多模态/图片识别 Agent
- 优势：专门负责图片、截图、UI、图表、OCR、视觉错误信息识别。
- 适用场景：用户提供本地图片路径、截图路径、图表文件、UI 报错图、论文插图时，先由它读取图片并输出结构化文本。
- 关键价值：避免纯文本 `opus` 主模型直接接收图片导致失败；它先把图片内容转成文本，再交给主模型分析。

### `ui-visual-validator`

- 模型：`sonnet -> mimo-v2.5[1m]`
- 类型：视觉校验 Agent
- 优势：擅长从截图判断 UI 修改是否真正生效，检查视觉一致性、布局问题、设计系统符合度和可访问性。
- 适用场景：前端页面截图、组件视觉回归、移动端/桌面端 UI 效果检查、颜色对比度和焦点状态判断。
- 关键价值：比普通文字分析更适合做“看图判断效果是否达标”的任务。

### `ai-engineer`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：AI 系统架构 Agent
- 优势：覆盖模型选择、训练流程、AI 系统架构、部署监控和端到端 AI 工程设计。
- 适用场景：设计深度学习模型、规划训练流水线、评估 AI 系统方案、分析模型上线和监控策略。
- 关键价值：适合作为 AI/ML 项目的总体技术设计者。

### `python-pro`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：Python 开发 Agent
- 优势：擅长类型安全、生产级 Python、异步模式、工具脚本、复杂应用和测试结构。
- 适用场景：Python 代码实现、重构、脚本开发、训练代码整理、数据处理工具编写。
- 关键价值：把具体实现落到可维护、可运行、符合项目风格的 Python 代码上。

### `debugger`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：调试 Agent
- 优势：擅长分析错误日志、堆栈、失败路径和根因定位。
- 适用场景：代码报错、训练 NaN、shape mismatch、依赖冲突、运行失败、测试不通过。
- 关键价值：用系统化方式定位问题，而不是只根据表面报错猜测。

### `data-scientist`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：数据分析 Agent
- 优势：擅长数据模式分析、统计检验、指标解释、预测建模和实验结论提炼。
- 适用场景：数据集分析、实验指标解释、结果表格分析、误差分析、可视化结果评估。
- 关键价值：帮助判断实验数据是否支撑结论。

### `ml-engineer`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：机器学习工程 Agent
- 优势：擅长训练流水线、模型验证、推理服务、性能优化和自动化重训。
- 适用场景：训练脚本设计、模型保存/加载、推理流程、评估流程、生产级 ML 代码结构。
- 关键价值：把模型研究代码整理成更可靠的工程流程。

### `mlops-engineer`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：MLOps Agent
- 优势：擅长实验跟踪、模型版本管理、checkpoint、CI/CD、GPU 资源调度和模型监控。
- 适用场景：训练实验管理、结果追踪、部署流程、模型注册、自动化训练流水线。
- 关键价值：让机器学习项目从“能跑”变成“可复现、可追踪、可部署”。

### `code-reviewer`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：代码审查 Agent
- 优势：关注正确性、可维护性、安全风险、性能问题和最佳实践。
- 适用场景：提交前审查、重构后检查、复杂模块质量评估、潜在 bug 排查。
- 关键价值：从审查者视角发现实现中的隐藏风险。

### `security-auditor`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：安全审计 Agent
- 优势：擅长漏洞分析、合规检查、权限风险、凭证泄露和安全控制评估。
- 适用场景：检查 API Key 泄露、依赖安全、访问控制、配置安全、合规风险。
- 关键价值：防止项目配置和代码把安全问题带到公开仓库或生产环境。

### `multi-agent-coordinator`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：多 Agent 协调 Agent
- 优势：擅长任务拆分、依赖管理、并行工作流协调、结果合并和冲突处理。
- 适用场景：大型功能开发、多文件重构、多 Agent 并行分析、任务边界规划。
- 关键价值：让多个 Agent 分工清晰，避免重复工作和文件冲突。

### `scientific-literature-researcher`

- 模型：`opus -> mimo-v2.5-pro[1m]`
- 类型：科研文献分析 Agent
- 优势：擅长检索、阅读和综合论文证据，关注方法、实验结果、样本规模、限制和结论可靠性。
- 适用场景：论文调研、baseline 对比、相关工作整理、方法复现依据分析。
- 关键价值：让技术决策和实验设计更有文献依据。

## Agent Teams 插件

本项目还内置了 wshobson 的 `agent-teams` 插件，位置：

```text
.claude/plugins/agent-teams/
```

启动脚本会用下面的方式加载它：

```bat
claude --dangerously-skip-permissions --model opus --effort max --plugin-dir ".claude\plugins\agent-teams"
```

可用团队命令包括：

- `/team-spawn`：创建一个团队，例如 review、debug、feature、research 等预设团队。
- `/team-review`：并行代码审查，可让不同 reviewer 分别检查安全、性能、架构、测试等维度。
- `/team-debug`：基于多个假设并行排查复杂 bug。
- `/team-feature`：按文件所有权拆分复杂功能，让多个实现 Agent 并行开发。
- `/team-delegate`：管理团队任务分配和消息。
- `/team-status`：查看团队成员和任务状态。
- `/team-shutdown`：关闭团队并清理资源。

建议平时优先使用普通项目级 Agent；只有任务很大、可以并行拆分时，再使用 Agent Teams。

## 安全说明

`start_claude_mimo.bat` 可能包含你的私有 API Key，因此已经被 `.gitignore` 排除，不会提交到 GitHub。

可以提交的是：

```text
start_claude_mimo.example.bat
```

这个模板文件只包含占位符，不包含真实 Key。
