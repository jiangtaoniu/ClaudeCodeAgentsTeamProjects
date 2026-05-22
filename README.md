# ClaudeCodeAgentsTeamProjects 

**[企业级 AI/自动驾驶边缘算法部署与 Agent 协作工程仓库]**

本仓库是一个用于存放并管理高标准、强工程化的人工智能落地项目集群。核心愿景是建立一套可直接移植到企业级生产环境的关键能力论证库：覆盖从深度学习算法的低阶显存控制、跨芯片架构极速编译，到 ROS2 节点协同通信的硬件全链路，并搭载前沿的多 Agent 并行研发与审查工具链。

---

## 🚀 核心项目群 (Projects Matrix)

*(当前仓库作为总基座，后续所有的算法部署、嵌入式落地及视觉项目都将作为独立模块并入 `projects/` 目录下)*

| 模块子系统 (Sub-project) | 核心定位与技术底座 | 专属部署白皮书 |
| :--- | :--- | :--- |
| **[Lidar_3D_Perception](projects/Lidar_3D_Perception/)** | **自动驾驶工业级点云感知主站** <br> 彻底解耦 PyTorch 实验环境。利用 `TensorRT (FP16/AMP)` 将 PointPillars 模型编译为极致压缩的 GPU 机器码；采用纯 C++ (无冗余 `new` 内存开销) 接管 NMS 及显存预分配；借助 `ROS2 DDS` 完成总线数据分发。<br> *延迟基准：~7.1ms / 并发峰值：>140FPS* | [项目 README](projects/Lidar_3D_Perception/README.md) |
| *(TBD)* | *后续视觉闭环控制 / MLOps 监控等系统持续扩展中...* | - |

---

## 🧠 基建设施与自动代理开发架构 (A.I. Agents System)

本仓库不单是代码存放地，其底层自带一套完整的 `Claude Code Agent` 并行治理体系，深度服务于项目的重构、审查与复杂 Bug 分析。系统基于 `mimo-v2.5-pro` 族群进行智能路由：

### 1. 动态节点分流路由 (Model Routing)
*   🔘 **`opus` 核心** (映射 `mimo-v2.5-pro[1m]`)：接管基建代码（CUDA/C++/ROS2）架构决策、算法移植、数据结构洗牌及多进程 Bug 脱水分析。
*   🔘 **`sonnet` 核心** (映射 `mimo-v2.5[1m]`)：特化定点处理多模态图像识别、RViz 截屏审查与全链路 UI 视觉保真。

### 2. 团队级 Agent 矩阵 (Professional Agent Fleet)
所有核心智囊存放在 `.claude/agents/` 中，针对庞大的自动驾驶级代码进行无损解构：
*   **工程编译组**：`ai-engineer` (全局架构)、`python-pro` (数据脚本提纯)、`code-reviewer` (显存泄露及死锁审查)。
*   **后端支撑组**：`ml-engineer` (模型降维指导)、`mlops-engineer` (编译环境管道部署)。
*   **异常熔断组**：`debugger` (底层 Core Dump 及段错误追踪)、`security-auditor` (容器越权审查)。

### 3. Agent Teams (多线程自治与并行审查)
由内置插件（`.claude/plugins/agent-teams/`）驱动，强力支持在项目复杂技改时的并发性介入：
*   执行 `/team-review` 进行 C++ 底层与依赖项冲突隔离审查。
*   执行 `/team-debug` 实现例如“TensorRT FP16 精度突降”这一类极难故障的分布式溯源假设。
*   执行 `/team-feature` 实施物理设备之间的解耦开发协调分工。

---

## 📁 宏观拓扑结构 (System Topology)

```text
ClaudeCodeAgentsTeamProjects/
├── projects/                        # 物理工程主干聚簇区
│   └── Lidar_3D_Perception/         # 📌 当前主力：激光雷达点云端到端部署 (C++ / TRT / ROS2)
│       ├── 01_environment_setup/    # [系统层] CUDA 与 ROS2 Humble 强环境基石
│       ├── 02_model_export/         # [解构层] PointPillars 模型剥离与 ONNX 脱维导出
│       ├── 03_tensorrt_build/       # [编译层] 混合精度(AMP) 设定与 engine 核心锁死
│       ├── 04_ros2_deployment/      # [硬件层] C++ 显存预分配、NMS 极值肃清与 DDS 发射主干
│       ├── 05_simulation_data/      # [仿真层] Python 高压点云 (10Hz) 态势伪装源
│       └── 06_docs_and_results/     # 📚 [归档层] 各子模块配套底层文档与全链架构蓝图
├── .claude/
│   ├── agents/                      # 驻留系统的独立 Agent 工作组
│   ├── plugins/agent-teams/         # 并行智体协同引擎
│   └── skills/                      # 强制性项目写作、源码探查与底层基建铁律插件
├── figures/                         # 公共图形界面与测绘回放图床
├── wsl-setup/                       # 容器及底层 Linux/GPU 穿透配置集
└── start_claude_mimo.example.bat    # Agent 系统激活拉起脚本模板
```

## ⚙️ 接入与授权 (Authentication & Start)

引擎系统高度绑定本地环境，依赖脱敏加载：
```powershell
# 将凭证模板克隆至私有激活区，填入 Auth Key 后唤醒大代理矩阵
Copy-Item .\start_claude_mimo.example.bat .\start_claude_mimo.bat
notepad .\start_claude_mimo.bat
.\start_claude_mimo.bat
```

*(项目内代码遵循 Apache-2.0 分发许可。本文档排版与结构设计均通过内置专属技能自查，保持内外系统强一致性与工程纯洁度。)*