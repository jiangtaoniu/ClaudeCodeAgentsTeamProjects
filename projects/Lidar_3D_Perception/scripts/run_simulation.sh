#!/bin/bash
# ==============================================================================
# Lidar 3D Perception - 仿真点云数据发布一键启动脚本
# ==============================================================================

set -euo pipefail

# 载入 ROS 2 Humble 环境
source /opt/ros/humble/setup.bash 2>/dev/null || {
    echo "[错误] 无法定位 ROS2 安装，请确认已运行 source /opt/ros/humble/setup.bash"
    exit 1
}

# 载入 Miniconda 与 conda 环境
eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
conda activate lidar3d

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "  启动 KITTI 仿真点云数据发布节点 (10Hz)"
echo "  发布话题: /points_raw [sensor_msgs/PointCloud2]"
echo "============================================"

# 执行数据回放 Python 脚本
python3 "$PROJECT_DIR/05_simulation_data/kitti_to_rosbag.py"
