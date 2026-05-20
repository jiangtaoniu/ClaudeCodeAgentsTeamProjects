#!/bin/bash
set -euo pipefail
source ~/.bashrc 2>/dev/null || true

echo "============================================"
echo "  阶段 2: 系统基础开发工具"
echo "============================================"

echo ""
echo "[1/3] 更新系统包..."
sudo apt update
sudo apt upgrade -y

echo ""
echo "[2/3] 安装开发工具..."
sudo apt install -y \
  build-essential \
  git \
  curl \
  wget \
  vim \
  unzip \
  zip \
  htop \
  tree \
  net-tools \
  software-properties-common \
  cmake \
  ninja-build \
  pkg-config \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  gdb \
  lsb-release \
  gnupg \
  locales \
  ca-certificates

echo ""
echo "[3/3] 验证安装..."
echo "  gcc:     $(gcc --version | head -1)"
echo "  g++:     $(g++ --version | head -1)"
echo "  cmake:   $(cmake --version | head -1)"
echo "  git:     $(git --version)"
echo "  python3: $(python3 --version)"
echo "  ninja:   $(ninja --version)"

echo ""
echo "============================================"
echo "  阶段 2 完成!"
echo "  请运行: bash ~/setup-scripts/03-ros2-humble.sh"
echo "============================================"
