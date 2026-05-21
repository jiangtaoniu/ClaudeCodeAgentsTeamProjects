# ClaudeCodeAgentsTeamProjects

基于多 Agent 协作的自动驾驶感知算法工程化项目仓库。

## 项目总览

本仓库包含一个完整的**激光雷达 3D 点云目标检测部署系统**，覆盖从 PyTorch 模型训练、ONNX 导出、TensorRT 高性能推理到 ROS2 实时感知节点的全链路工程流程。同时配备了专业的多 Agent 开发工具链，支持并行代码审查、调试、功能开发等协作模式。

### 核心项目

| 项目 | 说明 | 详细文档 |
|------|------|----------|
| **[激光雷达 3D 点云目标检测部署系统](projects/Lidar_3D_Perception/)** | 基于 PointPillars + TensorRT + ROS2 的完整自动驾驶感知部署流水线 | [项目 README](projects/Lidar_3D_Perception/README.md) |

### 技术亮点

- **端到端部署**：PyTorch 训练 → ONNX 导出 → TensorRT FP16 加速 → C++ ROS2 节点，完整覆盖工业级感知算法落地流程
- **实时性能**：TensorRT FP16 推理 + C++ 内存管理，端到端延迟约 **7ms (140+ FPS)**
- **工程化架构**：6 阶段递进式目录结构，每个阶段独立可复现

---

## 开发工具链：多 Agent 协作系统

本仓库同时维护了一套 Claude Code 项目级 Agent 配置，用于辅助开发过程中的代码实现、调试、审查和部署优化。

### 模型路由

| 路由 | 实际模型 | 适用任务 |
|------|----------|----------|
| `opus` | `mimo-v2.5-pro[1m]` | 所有纯文本任务：代码实现、调试、数据分析、ML、论文调研、架构设计、代码审查、安全审计 |
| `sonnet` | `mimo-v2.5[1m]` | 视觉/多模态任务：图片识别、截图分析、UI 视觉校验、图表 OCR |

> 不要设置 `CLAUDE_CODE_SUBAGENT_MODEL`，否则会覆盖每个 Agent 的 `model` 字段，破坏路由分工。

### 项目级 Agents

所有 Agent 安装在 `.claude/agents/`：

| Agent | 模型 | 职责 |
|-------|------|------|
| `image-reader` | sonnet | 图片/截图/图表/OCR 多模态识别 |
| `ui-visual-validator` | sonnet | UI 截图视觉校验、设计一致性检查 |
| `ai-engineer` | opus | AI 系统架构、模型设计、训练策略 |
| `python-pro` | opus | Python 实现、重构、工程化代码 |
| `debugger` | opus | Bug 诊断、日志/堆栈分析、根因定位 |
| `data-scientist` | opus | 数据分析、统计检验、指标解释 |
| `ml-engineer` | opus | ML 训练流水线、模型验证、推理服务 |
| `mlops-engineer` | opus | 实验跟踪、CI/CD、GPU 调度、部署运维 |
| `code-reviewer` | opus | 代码质量、正确性、安全风险审查 |
| `security-auditor` | opus | 安全审计、合规检查、凭证泄露排查 |
| `multi-agent-coordinator` | opus | 任务拆分、Agent 协调、依赖管理 |
| `scientific-literature-researcher` | opus | 科研文献调研、证据综合 |

### Agent Teams 插件

内置 `agent-teams` 插件（`.claude/plugins/agent-teams/`），支持以下团队命令：

| 命令 | 用途 |
|------|------|
| `/team-spawn` | 创建团队（review / debug / feature / research / security / migration） |
| `/team-review` | 并行多维度代码审查 |
| `/team-debug` | 多假设并行 Bug 排查 |
| `/team-feature` | 按文件所有权并行功能开发 |
| `/team-delegate` | 任务分配管理 |
| `/team-status` | 查看团队状态 |
| `/team-shutdown` | 关闭团队并清理资源 |

### 快速开始

```powershell
# 复制启动脚本模板，填入 API Key
Copy-Item .\start_claude_mimo.example.bat .\start_claude_mimo.bat
notepad .\start_claude_mimo.bat
.\start_claude_mimo.bat
```

多模态任务推荐用图片路径触发：

```text
请调用 image-reader 分析 F:\ClaudeCodeAgentsTeamProjects\figures\xxx.png，然后把识别结果交给主模型总结。
```

---

## 仓库结构

```text
ClaudeCodeAgentsTeamProjects/
├── projects/
│   └── Lidar_3D_Perception/        # 激光雷达 3D 点云目标检测部署系统
│       ├── 01_environment_setup/    #   环境搭建脚本
│       ├── 02_model_export/         #   OpenPCDet 模型训练与 ONNX 导出
│       ├── 03_tensorrt_build/       #   TensorRT 引擎构建
│       ├── 04_ros2_deployment/      #   ROS2 C++ 实时推理节点
│       ├── 05_simulation_data/      #   KITTI 点云仿真回放
│       └── 06_docs_and_results/     #   文档与性能报告
├── .claude/
│   ├── agents/                      # 项目级 Agent 定义
│   └── plugins/agent-teams/         # Agent Teams 插件
├── figures/                         # 项目图片资源
├── wsl-setup/                       # WSL 环境配置工具
├── start_claude_mimo.example.bat    # 启动脚本模板（可提交）
└── CLAUDE.md                        # Claude Code 项目指令
```

## 安全说明

`start_claude_mimo.bat` 包含私有 API Key，已被 `.gitignore` 排除。仅 `start_claude_mimo.example.bat` 模板文件会提交到仓库。

## 许可证

本项目学习用途。OpenPCDet 遵循 Apache-2.0 许可证。
