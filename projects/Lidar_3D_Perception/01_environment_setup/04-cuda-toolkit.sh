#!/bin/bash
set -euo pipefail
source ~/.bashrc 2>/dev/null || true

echo "============================================"
echo "  阶段 4: CUDA Toolkit 12.4"
echo "============================================"

echo ""
echo "[注意] WSL 中不要安装 nvidia-driver-xxx!"
echo "       Windows 侧已负责驱动，这里只装 CUDA Toolkit"

echo ""
echo "[1/4] 检查 nvidia-smi..."
nvidia-smi | head -5
DRIVER_CUDA=$(nvidia-smi | grep "CUDA Version" | awk '{print $9}')
echo "  驱动支持的 CUDA 版本: $DRIVER_CUDA"

echo ""
echo "[2/4] 下载 CUDA keyring..."
cd ~
wget -q https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt update

echo ""
echo "[3/4] 安装 CUDA Toolkit 12.4 (约3GB)..."
sudo apt install -y cuda-toolkit-12-4

echo ""
echo "[4/4] 配置环境变量..."
if ! grep -q 'CUDA_HOME=/usr/local/cuda-12.4' ~/.bashrc 2>/dev/null; then
    cat >> ~/.bashrc << 'CUDA_EOF'

# ===== CUDA Toolkit 12.4 =====
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}
# ===== CUDA 配置结束 =====
CUDA_EOF
    echo "  [完成] CUDA 环境变量已写入 ~/.bashrc"
else
    echo "  [跳过] ~/.bashrc 中已存在 CUDA 配置"
fi

source ~/.bashrc 2>/dev/null || true
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH

echo ""
echo "[验证]"
echo "  nvcc:       $(nvcc --version 2>/dev/null | grep release || echo 'NOT FOUND')"
echo "  nvidia-smi: $(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null || echo 'NOT FOUND')"

# 清理下载文件
rm -f ~/cuda-keyring_1.1-1_all.deb 2>/dev/null

echo ""
echo "============================================"
echo "  阶段 4 完成!"
echo "  请运行: source ~/.bashrc"
echo "  验证: nvcc --version"
echo "  然后运行: bash ~/setup-scripts/05-miniconda.sh"
echo "============================================"
