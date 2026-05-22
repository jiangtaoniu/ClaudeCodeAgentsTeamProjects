# 工业级 3D 激光雷达感知算法端到端部署工程 (ROS2 + TensorRT)

## 📌 项目定位 (Executive Summary)
本项目是一个面向自动驾驶/移动机器人场景的 **高性能 3D 激光雷达点云感知系统**。
项目旨在解决深度学习 3D 目标检测模型（如 PointPillars）在 Python/PyTorch 实验环境中存在的**强依赖、高延迟、难以融入车规控制系统**等痛点。通过剥离训练框架，采用 ONNX 作为中间表示，利用 NVIDIA TensorRT 进行底层算子优化与 FP16 混合精度编译，最终使用现代 C++17 与 ROS2 (DDS) 框架在系统级层面进行物理并行封装。

**核心成果**：将原本在 Python 环境下耗时约 30~50ms 的推理流程，极致压缩至 **~7ms (140+ FPS)**，在保障 mAP 精度极少量波动的工况下，实现了可用在算力受限边缘计算设备（Edge Device）上的工业级实时感知流水线。

---

## 🛠 技术栈与工程关键词 (Tech Stack)

*   **部署与通信中间件**: ROS2 (Humble), DDS 通信协议
*   **计算加速后端**: NVIDIA TensorRT 10.x, CUDA C++ API, cuDNN
*   **深度学习前沿**: OpenPCDet, PointPillars, ONNX 算子导出转换
*   **语言与工程基建**: Modern C++17 / Python 3.10, CMake, Colcon Build
*   **关键处理技术**: 
    *   CUDA 确定性显存池管理 (Deterministic GPU Memory Pooling)
    *   非极大值抑制的纯 C++ 实现 (Greedy 3D BEV NMS)
    *   TensorRT 动态极值张量配置 (Dynamic Shape Profile Optimization)
    *   FP16 混合精度与层融合加速 (Layer Fusion & Mixed Precision)

---

## 🚀 系统全景架构设计 (Architecture Design)

系统从工程落地角度严格划分为五个独立解耦的生命周期：

### Phase 1: 算法预备与脱维 (Model Decoupling & Export)
*   **模型基座**：依托 OpenPCDet 框架完成网络权重的冻结。
*   **ONNX 转换**：打破 PyTorch 动态图局限，将 PillarVFE 特征编码器、2D Backbone 及三头检测器导出为静态结构的 ONNX 计算图，实现深度学习框架与部署环节的彻底解耦。

### Phase 2: 硬件极限编译 (Hardware-Specific Compilation)
*   **自动混合精度**：授权 TensorRT 编译器实施 FP16 与 FP32 混合精度策略，使计算密集型的 Conv 算子充分激活 NVIDIA Tensor Core 物理加速单元，并在 Sigmoid/分类头处保留高精度以防止数值下溢。
*   **动态 Profile 调优**：针对自动驾驶点云密度的随机性，非粗暴指定静态 Batch，而是配置了 `Min(1) / Opt(16000) / Max(40000)` 的有效 Pillar 数量优化区间。确保了面对 99% 的典型场景（~16k pillars）时达到纳秒级延迟，同时面对极端信噪比场景（40k pillars）系统依然不崩溃（无 OOM）。

### Phase 3: CPU / GPU 异构数据管控 (Heterogeneous Pipeline)
在 C++ 端严格管理数据的生命周期，禁止运行时的动态内存申请：
*   **零时延预分配内存池**：在 `loadEngine()` 初始化阶段，基于 `MAX_VOXELS` 参数，通过 `cudaMalloc` 在 GPU / CPU 上锁定所有前向与反向传输所需的大块连续内存缓冲区 (`cls_preds_`, `box_preds_` 等)。
*   **C++ 空间几何预处理**：于 CPU 端执行高速 Voxelization，使用指针位移实现超快点云填零过滤 (Padding)，将极不规则的三维点云空间重组成尺寸绝对规整的 `[N, 32, 4]` 张量。

### Phase 4: 极速推理与后处理清洗 (Execution & Post-processing)
*   **GPU 异步触发**：通过 `enqueueV2()` / `enqueueV3()` API 接管控制流，在底层驱动层执行内核算子融合，推理过程与 CPU 主线程异步。
*   **C++ 等效检测头解码**：手动实现 PointPillars 回归方程的 C++ 解析。
*   **贪心 BEV NMS (纯 C++ 实现)**：摒弃重依赖的 PCL 后处理库，完全自定义实现基于 2D BEV 伪交并比的局部最优贪心过滤，将 30 万个候选极速收敛至几百个置信度极高的真实 3D 边界框。

### Phase 5: ROS2 高可用通信互联 (ROS2 Ecosystem Integration)
*   **软硬件解耦接入**：利用 `rclcpp::Node` 及 `create_subscription` 建立标准数据总线，无论是真实速腾/禾赛雷达的以太网报文，还是基于 `.bin` 的 Python 离线回放数据源（`sensor_msgs/PointCloud2`），均可做到代码级“零修改”即插即用。
*   **可视化与数据出口**：将最终的坐标系打包为 `MarkerArray` 消息低延迟发往总线，实现 RViz 实景高帧率渲染，无缝衔接自动驾驶堆栈下游的 PnC（规划与控制）系统。

---

## 📈 性能与延迟基准测试 (Performance Benchmarks)
*(Test Config: WSL2 Ubuntu 22.04 / NVIDIA RTX 4060 Laptop / Intel Core i7)*

| 处理子模块 (Sub-module) | 耗时/性能 (Latency) | 核心运作设备 (Device) |
| :--- | :--- | :--- |
| **点云提取与网络转换 (Voxelization)** | `~ 0.23 ms` | CPU |
| **CPU -> GPU 数据入栈 (H2D Memory Copy)** | `~ 0.15 ms` | PCIe Bus |
| **TensorRT FP16 前向推理网络 (Inference)** | `~ 5.86 ms` | GPU Tensor Core |
| **GPU -> CPU 预测取回 (D2H Memory Copy)** | `~ 0.10 ms` | PCIe Bus |
| **Anchor 解码与 NMS 贪心过滤 (Post-process)** | `~ 0.81 ms` | CPU |
| **端到端总延迟 (End-to-End Total Latency)** | **`~ 7.15 ms`** | **Sys Total** |
| **吞吐量 (Throughput)** | **`140 fps`** | - |

*(结论：远超绝大多数固态雷达物理刷新率极限的 10Hz/20Hz，完美满足车规级 L4 系统感知节点的实时性硬指标)*

---

## 💡 工程实践理念 (Engineering Philosophy)
本项目在开发过程中，严格遵循自动驾驶车规级感知模块的工程标准：
1. **追求极致的确定性 (Determinism)**：在 C++ 中避免内存碎片，预见并规避由于频繁内存分配引发的系统抖动 (Jitter)，保证感知延迟的强一致性。
2. **硬件感知设计 (Hardware-Awareness)**：不仅仅停留在关注模型理论 FLOPs，深入理解并应用了内存对齐、Tensor Core 物理加速特性以及算子图融合等底层调度策略。
3. **架构大局观的取舍之道 (Trade-offs)**：在 NMS 计算简化策略与 Dynamic Shape 的 Opt Batch 锚定值选择上，优先保障 99% 核心行驶场景的绝对响应速度，同时通过静态最大内存池为极端（Long-tail）长尾场景提供安全冗余，展现了兼顾“性能爆发”与“系统安全”的工业化折中哲学。
4. **系统级全栈连通性 (System-level Full-Stack)**：打破算法模型实验环境的壁垒，具备从数据分发 (ROS2 Publisher)、底层高速通信 (DDS 域)、通用内存管控至异构 GPU 显存压榨的一整套系统级交付能力。

