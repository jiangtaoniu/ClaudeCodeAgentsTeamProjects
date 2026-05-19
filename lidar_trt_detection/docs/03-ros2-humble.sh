#!/bin/bash
set -euo pipefail
source ~/.bashrc 2>/dev/null || true

echo "============================================"
echo "  阶段 3: ROS2 Humble Desktop"
echo "============================================"

echo ""
echo "[1/5] 添加 universe 仓库..."
sudo add-apt-repository universe -y
sudo apt update

echo ""
echo "[2/5] 添加 ROS2 GPG key..."
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
  -o /usr/share/keyrings/ros-archive-keyring.gpg

echo ""
echo "[3/5] 添加 ROS2 apt 源..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" \
  | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update

echo ""
echo "[4/5] 安装 ROS2 Humble Desktop (这会比较大，约2GB)..."
sudo apt install -y ros-humble-desktop ros-dev-tools python3-colcon-common-extensions

echo ""
echo "[5/5] 配置环境变量..."
if ! grep -q 'source /opt/ros/humble/setup.bash' ~/.bashrc 2>/dev/null; then
    echo 'source /opt/ros/humble/setup.bash' >> ~/.bashrc
    echo "  [完成] ROS2 setup.bash 已写入 ~/.bashrc"
else
    echo "  [跳过] ~/.bashrc 中已存在 ROS2 配置"
fi

source /opt/ros/humble/setup.bash 2>/dev/null || true

echo ""
echo "[验证] ROS2 版本:"
ros2 --version 2>/dev/null || echo "  [警告] ros2 命令不可用，请先 source ~/.bashrc"

echo ""
echo "创建 ROS2 工作空间..."
mkdir -p ~/ros2_ws/src
cd ~/ros2_ws
source /opt/ros/humble/setup.bash
colcon build 2>/dev/null || true

if ! grep -q 'source ~/ros2_ws/install/setup.bash' ~/.bashrc 2>/dev/null; then
    echo 'source ~/ros2_ws/install/setup.bash 2>/dev/null || true' >> ~/.bashrc
fi

echo ""
echo "============================================"
echo "  阶段 3 完成!"
echo "  请运行: source ~/.bashrc"
echo "  验证: ros2 --version"
echo "  然后运行: bash ~/setup-scripts/04-cuda-toolkit.sh"
echo "============================================"
