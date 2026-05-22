# 基于 ROS2 + TensorRT 的 3D 点云目标检测系统启动指南

本指南记录了本项目的完整启动流程与运行方案，以便在任何时候重新启动并展示这套工业级自动驾驶感知部署系统。

## 1. 项目简介
本项目成功打通了从深度学习模型训练到边缘端高性能部署的完整链路。核心流程如下：
- **模型**：基于 PyTorch 训练的 PointPillars 3D 目标检测模型。
- **推理**：使用 NVIDIA TensorRT 10.x C++ API 构建 FP16 半精度推理引擎。
- **框架**：封装为 ROS2 (Humble) 节点，支持流式点云订阅与 3D Bounding Box 结果发布。
- **性能**：得益于纯 C++ 内存管理与 TensorRT 极致优化，系统端到端总延迟仅约 **7ms (140+ FPS)**。

---

## 2. 环境准备与激活

每次新打开一个 WSL (Ubuntu) 终端时，必须先激活 ROS2 环境和 Python 虚拟环境，才能正常运行相关脚本。

### 2.1 激活基础环境
请在终端中执行以下命令：
```bash
# 激活 ROS2 Humble 基础环境
source /opt/ros/humble/setup.bash

# 激活本项目的 Python 环境 (用于运行点云发布器)
source ~/miniconda3/bin/activate lidar3d
```

### 2.2 编译 ROS2 工作空间 (仅需一次)
如果代码有修改，或者想要单独手动编译，可以进入项目根目录：
```bash
cd ~/projects/ClaudeCodeAgentsTeamProjects/projects/Lidar_3D_Perception/04_ros2_deployment
colcon build --symlink-install
```
不过在运行一键启动脚本 `scripts/run_ros2_node.sh` 时，系统会自动检查并在必要时进行编译。

---

## 3. 完整启动流程

系统的运行需要同时启动两个终端：一个是 **C++ 推理与可视化节点**，另一个是 **模拟传感器数据的发布节点**。

### 终端 A：启动 C++ 推理节点与 RViz 可视化
此脚本会自动校验编译状态、载入 ROS2 overlay 空间并启动 Launch 程序。

```bash
cd ~/projects/ClaudeCodeAgentsTeamProjects/projects/Lidar_3D_Perception
./scripts/run_ros2_node.sh
```

### 终端 B：启动点云数据发布器
此脚本会自动激活 `lidar3d` conda 虚拟环境与 ROS2 环境变量，并开始以 10Hz 循环回放 KITTI 原始点云面数据体。

```bash
cd ~/projects/ClaudeCodeAgentsTeamProjects/projects/Lidar_3D_Perception
./scripts/run_simulation.sh
```

---

## 4. 预期效果与可视化说明

当两个终端都成功运行后，桌面上会自动弹出 RViz 可视化窗口。

### 视口操作
- 若屏幕只显示网格，请将鼠标移至网格区域，**不断向下滚动鼠标滚轮（缩小视图）**，直到看到大范围的白色点云和检测方块。
- 按住鼠标左键可旋转视角，按住鼠标中键或 Shift+左键可平移视角。

### 元素说明
- **白色小点 (Point Cloud)**：激光雷达传感器扫描到的原始环境 3D 轮廓。
- **绿色 3D 方块**：AI 模型检测出的 **汽车 (Car)**，方块的朝向代表车头的方向。
- **红色 3D 方块**：AI 模型检测出的 **行人 (Pedestrian)**。
- **蓝色 3D 方块**：AI 模型检测出的 **骑行者/自行车 (Cyclist)**。

### 性能监控
观察 **终端 A** 的日志输出，您将看到类似如下的实时性能反馈：
```text
[INFO] [lidar_detection_node]: Pre: 0.23 ms | Infer: 6.35 ms | Post: 0.78 ms | Detections: 11
```
- **Pre (预处理)**：点云体素化 (Voxelization) 耗时，约 `~0.2 ms`。
- **Infer (推理)**：TensorRT FP16 模型执行耗时，约 `~6.0 ms`。
- **Post (后处理)**：C++ 边界框解码与 NMS，约 `~0.8 ms`。
- 极高的处理速度保障了在真实车载环境下的零延迟响应。
