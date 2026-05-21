# 基于 ROS2 + TensorRT 的激光雷达点云 3D 目标检测部署系统

一个完整的自动驾驶点云感知算法工程化部署项目：从 PyTorch 模型训练，经 ONNX 导出与 TensorRT 编译优化，到 C++/ROS2 实时感知节点集成与 RViz 3D 可视化。

## 系统架构

```text
KITTI .bin 点云文件
      │
      ▼
┌─────────────────────────────────────────────────────────┐
│  ROS2 点云发布器 (Python)                                │
│  kitti_to_rosbag.py → /points_raw (PointCloud2, 10Hz)    │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  C++ 推理节点 (lidar_trt_detection)                      │
│                                                         │
│  ① 预处理 (~0.2ms)                                      │
│     范围裁剪 → Pillar 网格划分 → 特征编码                  │
│                                                         │
│  ② TensorRT FP16 推理 (~6ms)                             │
│     PillarVFE → Scatter → 2D Backbone → Detection Head   │
│                                                         │
│  ③ 后处理 (~0.8ms)                                       │
│     Sigmoid → 置信度过滤 → 锚框解码 → 朝向纠偏 → BEV NMS  │
│                                                         │
│  端到端总延迟: ~7ms (140+ FPS)                            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│  RViz 3D 可视化                                          │
│  绿色方块=汽车  红色方块=行人  蓝色方块=骑行者              │
└─────────────────────────────────────────────────────────┘
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 操作系统 | Windows 11 + WSL2 Ubuntu 22.04 |
| 深度学习框架 | PyTorch, ONNX, TensorRT 10.x |
| 点云框架 | OpenPCDet, spconv |
| 机器人中间件 | ROS2 Humble, RViz2 |
| 编程语言 | C++17 (推理节点), Python 3.10 (训练/工具) |
| GPU | NVIDIA RTX 4060, CUDA 12.4 |
| 检测模型 | PointPillars (主力), CenterPoint (扩展) |
| 数据集 | KITTI 3D Object Detection |

---

## 项目结构

```text
Lidar_3D_Perception/
├── 01_environment_setup/              # 阶段1: 环境搭建
│   ├── 00-setup-sudo.sh              #   sudo 免密配置
│   ├── 01-proxy-and-locale.sh        #   代理与语言环境
│   ├── 02-system-tools.sh            #   系统基础工具
│   ├── 03-ros2-humble.sh             #   ROS2 Humble 安装
│   ├── 04-cuda-toolkit.sh            #   CUDA Toolkit 安装
│   ├── 05-miniconda.sh               #   Miniconda + Python 环境
│   ├── 06-openpcdet.sh               #   OpenPCDet + spconv 安装
│   ├── 07-onnx.sh                    #   ONNX Runtime 安装
│   └── 08-final-verify.sh            #   环境验证脚本
│
├── 02_model_export/                   # 阶段2: 模型训练与导出
│   └── OpenPCDet/                     #   OpenPCDet 完整框架
│       ├── pcdet/models/              #     PointPillars 网络模块
│       │   ├── backbones_3d/vfe/      #       PillarVFE 特征编码器
│       │   ├── backbones_2d/          #       BEV 骨干网络 + Scatter
│       │   └── dense_heads/           #       检测头 (分类/回归/朝向)
│       ├── pcdet/datasets/            #     数据集加载与预处理
│       ├── tools/                     #     训练/评估/推理脚本
│       └── demo_data/                 #     示例点云数据
│
├── 03_tensorrt_build/                 # 阶段3: TensorRT 引擎构建
│   ├── build_engine.py                #   ONNX → TensorRT 转换脚本
│   └── build_engine.sh                #   命令行构建脚本
│
├── 04_ros2_deployment/                # 阶段4: ROS2 实时部署
│   └── src/lidar_trt_detection/       #   ROS2 Package
│       ├── src/
│       │   ├── lidar_detection_node.cpp    # 主节点: 订阅/推理/发布
│       │   ├── pointcloud_preprocess.cpp   # C++ 点云预处理
│       │   ├── tensorrt_infer.cpp          # TensorRT C++ API 推理
│       │   └── postprocess.cpp             # 检测框解码 + NMS
│       ├── include/                        # 头文件
│       ├── launch/detection.launch.py      # ROS2 Launch 文件
│       └── rviz/detection.rviz             # RViz 可视化配置
│
├── 05_simulation_data/                # 阶段5: 仿真数据
│   └── kitti_to_rosbag.py             #   KITTI 点云 → ROS2 话题发布
│
├── 06_docs_and_results/               # 阶段6: 文档与报告
│   ├── 项目说明书.md                    #   项目整体设计说明
│   ├── PointPillars模型架构详解.md      #   PointPillars 网络逐层拆解
│   ├── TensorRT模型编译优化详解.md       #   TensorRT 编译优化原理
│   ├── 部署与启动指南.md                #   系统启动与运行手册
│   └── 基于 ROS2 + TensorRT 的...md    #   系统设计文档
│
├── scripts/                           # 核心运行与安装脚本
│   ├── install_all_env.sh            #   环境一键安装包 (全自动多层重试机制)
│   ├── build_engine.sh               #   TensorRT FP16 加速引擎一键编译
│   ├── run_simulation.sh             #   KITTI 模拟数据发布一键启动
│   └── run_ros2_node.sh              #   ROS2 推理节点与可视界面一键启动
│
└── install_all_env.sh                 # 一键环境安装脚本入口
```
```

---

## 核心流水线详解

### 阶段 1：环境搭建

**目标**：在 WSL2 Ubuntu 22.04 上配置完整开发环境。

8 个脚本按顺序执行，依次安装系统工具、ROS2 Humble、CUDA Toolkit、Miniconda、OpenPCDet + spconv、ONNX Runtime，最后统一验证。也可以在根目录下直接调用 `./install_all_env.sh` 一键执行全部安装。

**为什么用 WSL2 而不是原生 Windows**：ROS2 生态、Autoware、TensorRT 的工具链都围绕 Linux 展开。NVIDIA 官方支持 WSL2 下运行 CUDA/TensorRT，兼顾了 Windows 开发体验和 Linux 运行环境。

---

### 阶段 2：模型训练与 ONNX 导出

**目标**：在 OpenPCDet 框架上训练 PointPillars 模型，导出 ONNX。

#### PointPillars 模型架构

PointPillars 的核心思想：**将 3D 稀疏点云转化为 2D 鸟瞰图伪图像，然后用高效的 2D CNN 做密集检测**。

```text
原始点云 [M, 4]
    │
    ▼  预处理: 按 0.16m×0.16m 网格划分为 Pillar (点柱)
Pillar 张量 [N, 32, 4]  (N个非空Pillar, 每个最多32点)
    │
    ▼  ① PillarVFE: 特征增强(4→10维) → Linear(10→64) → BN → ReLU → MaxPool
点柱特征 [N, 64]
    │
    ▼  ② Scatter: 按坐标索引填充到 BEV 画布 (零计算量)
BEV 伪图像 [1, 64, 496, 432]
    │
    ▼  ③ 2D Backbone: 3级下采样 + 3级反卷积上采样 + 通道拼接
融合特征图 [1, 384, 248, 216]
    │
    ▼  ④ Detection Head: 3个1×1卷积并行输出
分类 [1,248,216,18] + 回归 [1,248,216,42] + 朝向 [1,248,216,12]
```

#### 模块 1：PillarVFE（点柱特征编码器）

**代码**：`pcdet/models/backbones_3d/vfe/pillar_vfe.py`

每个 Pillar 内的点被增强为 10 维特征：原始 4 维 (x,y,z,intensity) + 3 维聚类偏移 (到 Pillar 质心的距离) + 3 维网格中心偏移 (到格子物理中心的距离)。然后通过一层 PFN (Linear → BatchNorm → ReLU → MaxPool) 压缩为 64 维向量。

- **MaxPool 保证排列不变性**：激光点的采集顺序随机，MaxPool 是对称函数，输出不受点顺序影响
- **补零掩码**：不满 32 点的 Pillar 用零填充，通过掩码矩阵将假点特征清零，避免污染 BatchNorm 统计量
- **单层 PFN 设计**：论文实验表明增加更多层对精度几乎无提升，但会让嵌入式平台延迟翻倍

#### 模块 2：PointPillarScatter（BEV 伪图像散射）

**代码**：`pcdet/models/backbones_2d/map_to_bev/pointpillar_scatter.py`

在显存中创建全零的 2D 画布 `[64, 496, 432]`，根据每个 Pillar 的网格坐标，将其 64 维特征向量填入画布对应位置。这个操作本身**几乎无计算量**（纯索引赋值），但实现了从"稀疏 3D 处理"到"稠密 2D 处理"的范式转换。

- **画布尺寸**：X 方向 69.12m ÷ 0.16m = 432 像素，Y 方向 79.36m ÷ 0.16m = 496 像素
- **核心价值**：让后续所有计算都变成标准 2D CNN，可以直接使用 TensorRT 的卷积融合和 Tensor Core 加速

#### 模块 3：BaseBEVBackbone（多尺度 2D 骨干网络）

**代码**：`pcdet/models/backbones_2d/base_bev_backbone.py`

贡献了全网络 95%+ 的计算量，但因为全部是标准 Conv2d + BN + ReLU，GPU 并行效率极高。

- **下采样**：3 个 Block 逐步缩小分辨率 (496×432 → 248×216 → 124×108 → 62×54)，通道从 64 扩到 256
- **上采样**：3 个反卷积层将不同深度的特征图统一上采样到 248×216，各输出 128 通道
- **通道拼接**：128×3 = 384 通道的融合特征图，同时包含精确空间位置（浅层，检测小目标）和全局语义（深层，检测远处目标）

#### 模块 4：AnchorHeadSingle（检测头）

**代码**：`pcdet/models/dense_heads/anchor_head_single.py`

在 248×216 特征图上，每个像素位置放置 3 类 × 2 朝向 = 6 个先验锚框（全图共 321,408 个），通过 3 个并行的 1×1 卷积分支输出：

| 分支 | 输出形状 | 含义 |
|------|----------|------|
| `cls_preds` | [1, 248, 216, 18] | 每个锚框属于 Car/Ped/Cyc 的分类得分 |
| `box_preds` | [1, 248, 216, 42] | 每个锚框的 7 维位置残差 (Δx,Δy,Δz,Δlog(dx),Δlog(dy),Δlog(dz),Δθ) |
| `dir_cls_preds` | [1, 248, 216, 12] | 每个锚框的朝向二分类 (解决车头车尾 180° 二义性) |

关键设计：分类偏置初始化为 -4.6，使 Sigmoid 输出初始为 0.01（"默认全是背景"），防止 99.9% 的负样本梯度淹没正样本学习信号。

---

### 阶段 3：TensorRT 引擎构建

**目标**：将 ONNX 模型编译为 TensorRT FP16 推理引擎。

**代码**：`03_tensorrt_build/build_engine.py`

```python
# 核心流程
builder = trt.Builder(TRT_LOGGER)
config.set_flag(trt.BuilderFlag.FP16)         # 启用 FP16 半精度

# 动态维度配置 (点云 Pillar 数量帧间变化)
profile.set_shape('voxels',
    min=(1, 32, 4),          # 空旷场景保底
    opt=(16000, 32, 4),      # 常规场景最优
    max=(40000, 32, 4))      # 拥堵路口上限

engine_bytes = builder.build_serialized_network(network, config)
```

TensorRT 编译器在构建过程中自动执行：
- **层融合**：Conv + BN + ReLU 合并为单个高效 kernel
- **FP16 混合精度**：利用 Tensor Core 加速，速度提升 2-3 倍，精度损失 < 0.5%
- **Kernel 自动调优**：针对目标 GPU 架构选择最优计算核函数

**注意**：engine 文件绑定 GPU 架构和 TensorRT 版本，不能跨平台/跨版本使用。

---

### 阶段 4：ROS2 实时部署

**目标**：用 C++ 封装完整推理管线，集成为 ROS2 感知节点。

#### ROS2 Package 结构

```text
lidar_trt_detection/
├── src/
│   ├── lidar_detection_node.cpp       # 主节点: 订阅 PointCloud2 → 推理 → 发布 MarkerArray
│   ├── pointcloud_preprocess.cpp      # C++ 点云预处理 (范围裁剪 + Pillar 构建)
│   ├── tensorrt_infer.cpp             # TensorRT C++ API (加载 engine + GPU 推理)
│   └── postprocess.cpp                # 检测框解码 + 置信度过滤 + BEV NMS
├── launch/detection.launch.py         # 一键启动: 推理节点 + RViz
└── rviz/detection.rviz                # 可视化预设配置
```

#### 数据流

```
/points_raw (PointCloud2)
    → pointcloud_preprocess.cpp: 范围裁剪 + Pillar 体素化
    → tensorrt_infer.cpp: cudaMemcpy H→D + enqueue + cudaMemcpy D→H
    → postprocess.cpp: Sigmoid + 解码 + NMS
    → /detection_markers (MarkerArray) → RViz 显示
```

---

### 阶段 5：仿真数据回放

**目标**：将 KITTI 点云文件按帧发布为 ROS2 话题，模拟真实 LiDAR 传感器。

**代码**：`05_simulation_data/kitti_to_rosbag.py`

```python
class KittiPublisher(Node):
    # 以 10Hz 频率循环发布 .bin 点云文件到 /points_raw 话题
    self.publisher_ = self.create_publisher(PointCloud2, '/points_raw', 10)
    self.timer = self.create_timer(0.1, self.timer_callback)
```

无需真实激光雷达硬件即可运行完整感知流程。

---

### 阶段 6：性能分析与文档

#### 实时性能指标

| 阶段 | 典型耗时 |
|------|----------|
| 预处理 (Voxelization) | ~0.2 ms |
| TensorRT FP16 推理 | ~6.0 ms |
| 后处理 (Decode + NMS) | ~0.8 ms |
| **端到端总延迟** | **~7 ms (140+ FPS)** |

#### 推理后端对比

| 推理后端 | 精度 | 单帧耗时 | FPS |
|----------|------|----------|-----|
| PyTorch FP32 | 基线 | ~30-50 ms | ~20-33 |
| ONNX Runtime | FP32 | ~20-40 ms | ~25-50 |
| TensorRT FP32 | FP32 | ~8-15 ms | ~67-125 |
| TensorRT FP16 | FP16 | ~4-8 ms | ~125-250 |

#### 技术文档

| 文档 | 内容 |
|------|------|
| [项目说明书](06_docs_and_results/项目说明书.md) | 项目定位、技术路线、模块设计、开发计划 |
| [PointPillars 模型架构详解](06_docs_and_results/PointPillars模型架构详解.md) | 网络每一层的数据流、数学原理、设计动机 |
| [TensorRT 模型编译优化详解](06_docs_and_results/TensorRT模型编译优化详解.md) | 层融合、混合精度、Kernel 调优原理 |
| [部署与启动指南](06_docs_and_results/部署与启动指南.md) | 系统启动步骤、RViz 操作说明、性能监控 |

---

## 快速启动

### 环境要求

- Windows 11 + WSL2 Ubuntu 22.04
- NVIDIA GPU (RTX 4060 或同级)
- CUDA Toolkit 12.4
- ROS2 Humble
- Miniconda (Python 3.10)
- PyTorch cu124 + spconv-cu120

### 一键安装

```bash
cd projects/Lidar_3D_Perception
chmod +x install_all_env.sh
./install_all_env.sh
```

### 启动系统

**终端 A** — 启动推理节点与 RViz：

```bash
cd projects/Lidar_3D_Perception
./scripts/run_ros2_node.sh
```

**终端 B** — 启动点云数据发布：

```bash
cd projects/Lidar_3D_Perception
./scripts/run_simulation.sh
```

启动后 RViz 窗口自动弹出，滚动鼠标滚轮缩小视图即可看到点云和 3D 检测框。

---

## 开发计划

| 阶段 | 内容 | 状态 |
|------|------|------|
| 第 1 周 | 环境搭建 (WSL2 + ROS2 + CUDA + PyTorch) | 已完成 |
| 第 2 周 | 跑通 PointPillars 点云推理 | 已完成 |
| 第 3 周 | ONNX 导出与验证 | 已完成 |
| 第 4 周 | TensorRT engine 构建 (FP32/FP16) | 已完成 |
| 第 5 周 | C++ 推理模块 | 已完成 |
| 第 6 周 | ROS2 节点集成 + RViz 可视化 | 已完成 |
| 第 7 周 | 性能优化与基准测试 | 已完成 |
| 第 8 周 | 文档整理与项目总结 | 已完成 |

## 许可证

本项目学习用途。OpenPCDet 遵循 Apache-2.0 许可证。
