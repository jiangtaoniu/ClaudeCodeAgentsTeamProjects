#!/bin/bash
# ==============================================================================
# Lidar 3D Perception - ROS2 目标检测推理节点与 RViz 一键启动脚本
# ==============================================================================

set -euo pipefail

# 载入 ROS 2 Humble 基础环境
source /opt/ros/humble/setup.bash 2>/dev/null || {
    echo "[错误] 无法定位 ROS2 安装，请确认已运行 source /opt/ros/humble/setup.bash"
    exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
WORK_SPACE="$PROJECT_DIR/04_ros2_deployment"

echo "============================================"
echo "  启动 C++ TensorRT 激光雷达点云检测推理节点"
echo "  寻找工作空间: $WORK_SPACE"
echo "============================================"

# 如果工作空间还没编译，自动进行编译
if [ ! -d "$WORK_SPACE/install" ]; then
    echo "未检测到编译目录，开始编译 ROS2 工作空间..."
    cd "$WORK_SPACE"
    colcon build --symlink-install
fi

# 载入工作空间 Overlay 环境
source "$WORK_SPACE/install/setup.bash"

# 启动 3D 检测主节点及配套 RViz 可视化界面
ros2 launch lidar_trt_detection detection.launch.py
