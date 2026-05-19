# 基于 ROS2 与 TensorRT 的激光雷达点云 3D 目标检测部署系统

## 项目简介

围绕自动驾驶点云感知部署场景，构建从 KITTI 点云数据读取、PointPillars/CenterPoint 模型推理、ONNX 导出、TensorRT FP16 加速到 ROS2 节点集成的完整工程流程。

## 技术栈

- **操作系统**: Windows 11 + WSL2 Ubuntu 22.04
- **深度学习**: PyTorch, ONNX, TensorRT
- **点云框架**: OpenPCDet, spconv
- **机器人框架**: ROS2 Humble, RViz2
- **编程语言**: C++17, Python 3.10
- **GPU**: NVIDIA RTX 4060, CUDA 12.4

## 项目结构

```text
lidar_trt_detection/
├── README.md                    # 项目说明
├── docs/                        # 文档
│   ├── 项目说明书.md             # 完整项目规划
│   └── *.sh                     # WSL 环境配置脚本
├── ros2_ws/                     # ROS2 工作空间
│   └── src/
│       └── lidar_trt_detection/ # ROS2 感知节点 (待开发)
├── models/                      # 模型文件
│   ├── onnx/                    # ONNX 模型
│   └── engine/                  # TensorRT engine
├── scripts/                     # 工具脚本
├── third_party/                 # 第三方依赖
│   └── OpenPCDet/               # 点云检测框架
└── assets/                      # 演示资源
    └── result_images/
```

## 开发计划

| 阶段 | 内容 | 状态 |
|------|------|------|
| 第1周 | 环境搭建 (WSL2 + ROS2 + CUDA + PyTorch) | 🔄 进行中 |
| 第2周 | 跑通 PointPillars 点云推理 | ⏳ 待开始 |
| 第3周 | ONNX 导出与验证 | ⏳ 待开始 |
| 第4周 | TensorRT engine 构建 | ⏳ 待开始 |
| 第5周 | C++ 推理模块 | ⏳ 待开始 |
| 第6周 | ROS2 节点集成 + RViz 显示 | ⏳ 待开始 |
| 第7周 | 性能优化 (FP16/INT8) | ⏳ 待开始 |
| 第8周 | 整理文档 + 演示 | ⏳ 待开始 |

## 环境要求

- Windows 11 + WSL2 Ubuntu 22.04
- NVIDIA GPU (RTX 4060 或同级)
- CUDA Toolkit 12.4
- ROS2 Humble
- Miniconda (Python 3.10)
- PyTorch cu124 + spconv-cu120

详细环境配置见 [docs/项目说明书.md](docs/项目说明书.md)

## 许可证

本项目学习用途。OpenPCDet 遵循 Apache-2.0 许可证。
