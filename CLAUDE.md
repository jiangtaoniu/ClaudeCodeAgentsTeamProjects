# Claude Code 项目说明

## 模型路由

- 当前 Claude Code 主会话使用 `--model opus`，实际映射到 `mimo-v2.5-pro[1m]`。
- 所有纯文本任务都使用 `opus -> mimo-v2.5-pro[1m]`，包括规划、实现、调试、数据分析、机器学习、MLOps、科研调研、协调、代码审查和安全审计。
- 只有视觉或多模态任务使用 `sonnet -> mimo-v2.5[1m]`。
- `image-reader` 子 Agent 使用 `model: sonnet`，实际映射到 `mimo-v2.5[1m]`，专门负责图片理解。
- `ui-visual-validator` 子 Agent 也使用 `model: sonnet`，实际映射到 `mimo-v2.5[1m]`，专门负责 UI 截图和视觉效果校验。
- 项目级专业子 Agent 安装在 `.claude/agents/`。
- 本项目内置的 wshobson Agent Teams 插件安装在 `.claude/plugins/agent-teams/`，并由 `start_claude_mimo.bat` 通过 `--plugin-dir` 加载。

## 图片与多模态流程

当用户询问图片、截图、UI 设计稿、图表、OCR、视觉报错，或提供包含图片的文件夹时：

1. 主 Agent 不要直接解释图片内容。
2. 必须先调用 `image-reader` 子 Agent。
3. 把本地图片路径或文件夹路径交给 `image-reader`。
4. 让 `image-reader` 使用 `Read` 读取图片，并返回结构化文本。
5. 主 Agent 只能基于 `image-reader` 返回的结构化文本继续分析、总结或执行后续任务。

推荐用户输入格式：

```text
请调用 image-reader 分析 F:\ClaudeCodeAgentsTeamProjects\figures\conference MS-IPM.png，然后把识别结果交给主模型总结。
```

不要依赖直接粘贴图片的方式。用户如果只粘贴图片或附件，应要求用户提供本地图片路径。

## 项目级 Agents

当任务自然匹配某个 Agent 的职责时，优先使用对应项目级 Agent：

- `ai-engineer` (`opus`)：AI 架构、模型设计、训练策略、生产级 AI 系统规划。
- `multi-agent-coordinator` (`opus`)：任务拆分、Agent 协调、依赖管理。
- `code-reviewer` (`opus`)：代码质量、正确性、可维护性和风险审查。
- `security-auditor` (`opus`)：安全审计和合规检查。
- `python-pro` (`opus`)：Python 实现、重构和工程化代码。
- `debugger` (`opus`)：Bug 诊断、日志分析、堆栈分析和运行失败定位。
- `data-scientist` (`opus`)：数据分析、指标解释、统计验证。
- `ml-engineer` (`opus`)：机器学习训练流水线、模型实现、验证和服务化。
- `mlops-engineer` (`opus`)：实验跟踪、checkpoint、CI/CD 和部署运维。
- `scientific-literature-researcher` (`opus`)：科研文献调研和证据综合。
- `image-reader` (`sonnet`)：所有原始图片、截图、图表、UI、OCR 和视觉多模态输入。
- `ui-visual-validator` (`sonnet`)：截图/UI 视觉校验、设计一致性和可访问性视觉检查。

不要设置 `CLAUDE_CODE_SUBAGENT_MODEL`。这个变量会覆盖每个 Agent 自己的 `model` 字段，破坏本项目的模型路由。

## Agent Teams

本项目内置的 `agent-teams` 插件提供以下命令：

- `/team-spawn`
- `/team-review`
- `/team-debug`
- `/team-feature`
- `/team-delegate`
- `/team-status`
- `/team-shutdown`

当用户明确要求使用 `agent team`、`team`、`多 Agent 团队`、`并行 agent`，或者任务明显适合通过审查、调试、功能开发、调研或迁移等并行工作流完成时，应使用 Agent Teams。

不要为了很小的任务创建团队。以下任务优先使用普通项目级 Agent：

- 小范围单点任务
- 单文件修改
- 简单解释
- 简单图片分析
- 不适合并行、开团队只会增加协调成本的任务

当用户要求使用 Agent Team 但没有指定团队类型时，自动选择合适的预设：

- 代码审查、质量检查、安全检查、架构检查 -> `review` team 或 `/team-review`
- 复杂 bug、运行错误、训练失败、NaN/loss 问题、根因不明确的问题 -> `debug` team 或 `/team-debug`
- 功能开发、代码实现、多文件修改 -> `feature` team 或 `/team-feature`
- 仓库分析、文档/资料调研、方案对比 -> `research` team 或 `/team-spawn research`
- 安全审计 -> `security` team 或 `/team-spawn security`
- 大规模重构或迁移 -> `migration` team 或 `/team-spawn migration`

默认 Agent Team 工作流程：

1. 先判断任务是否适合使用团队。如果不适合，应说明普通项目级 Agent 更合适，并正常完成任务。
2. 如果适合使用团队，由 `team-lead` 或主 Agent 先分析任务，并在修改文件前输出团队类型、子任务、文件所有权边界、依赖关系和验收标准。
3. 功能开发任务优先采用 `/team-feature ... --plan-first` 的行为：先规划，明确后再实现。
4. 审查任务应拆成不同维度，例如安全、性能、架构、测试和可维护性。
5. 调试任务应先生成多个竞争性假设，并为每个调查员分配一个假设。
6. 所有原始视觉输入必须先经过 `image-reader`。截图或 UI 质量判断可使用 `ui-visual-validator`。
7. 纯文本团队 Agent 使用 `opus -> mimo-v2.5-pro[1m]`；只有视觉/多模态 Agent 使用 `sonnet -> mimo-v2.5[1m]`。
8. 团队任务完成后，汇总各成员结果，列出修改过的文件，说明已执行的验证，并在不再需要团队时使用 `/team-shutdown` 关闭团队。

如果用户说“请使用 agent team 完成下面任务”或类似表达，就把这视为允许创建合适 Agent Team 的授权。除非任务描述过于模糊，无法安全选择团队类型，否则不要再询问用户应该用哪种 team。
