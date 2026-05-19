#!/bin/bash
# =============================================
# WSL 环境一键修复脚本
# 修复: CUDA Toolkit + conda lidar3d + PyTorch + 目录
# 
# 使用方法: 在 WSL 终端中执行
#   bash ~/setup-scripts/09-fix-all.sh
# =============================================
set -euo pipefail

echo "============================================"
echo "  WSL 环境修复脚本 - 一键安装"
echo "============================================"

# ========== [1/5] CUDA Toolkit 12.4 ==========
echo ""
echo "========== [1/5] 安装 CUDA Toolkit 12.4 =========="
if command -v nvcc &>/dev/null; then
    echo "  [跳过] nvcc 已安装: $(nvcc --version | grep release)"
else
    cd ~
    echo "  下载 CUDA keyring..."
    wget -q --show-progress https://developer.download.nvidia.com/compute/cuda/repos/wsl-ubuntu/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    sudo apt update
    echo ""
    echo "  安装 CUDA Toolkit 12.4 (约 3GB，请耐心等待)..."
    sudo apt install -y cuda-toolkit-12-4
    rm -f ~/cuda-keyring_1.1-1_all.deb

    # 写入环境变量
    if ! grep -q 'CUDA_HOME=/usr/local/cuda-12.4' ~/.bashrc; then
        cat >> ~/.bashrc << 'CUDA_ENV'

# ===== CUDA Toolkit 12.4 =====
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}
# ===== CUDA 配置结束 =====
CUDA_ENV
    fi
    echo "  [完成] CUDA Toolkit 12.4 安装完毕"
fi

# 立即生效
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}
echo "  nvcc: $(nvcc --version 2>/dev/null | grep release || echo 'NOT FOUND')"

# ========== [2/5] conda lidar3d ==========
echo ""
echo "========== [2/5] 创建 conda lidar3d 环境 =========="
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"

if conda env list | grep -q 'lidar3d'; then
    echo "  [跳过] lidar3d 环境已存在"
else
    conda create -n lidar3d python=3.10 -y
    echo "  [完成] lidar3d 环境已创建"
fi

conda activate lidar3d
echo "  python: $(python --version)"
python -m pip install --upgrade pip setuptools wheel -q

# ========== [3/5] PyTorch + 深度学习库 ==========
echo ""
echo "========== [3/5] 安装 PyTorch + 深度学习库 =========="

if python -c "import torch; print('PyTorch', torch.__version__)" 2>/dev/null; then
    echo "  [跳过] PyTorch 已安装"
else
    echo "  安装 PyTorch cu124 (约 2GB)..."
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124
fi

echo "  安装科学计算库..."
pip install numpy scipy pandas matplotlib opencv-python pyyaml tqdm easydict \
  scikit-learn numba llvmlite open3d

echo "  安装 spconv..."
pip install spconv-cu120

echo "  安装 ONNX..."
pip install onnx onnxsim onnxruntime onnxruntime-gpu

# ========== [4/5] 创建项目目录 ==========
echo ""
echo "========== [4/5] 创建项目目录 =========="
mkdir -p ~/ros2_ws/src
mkdir -p ~/datasets/KITTI/training/{velodyne,calib,label_2,image_2}
mkdir -p ~/projects
mkdir -p ~/models

if ! grep -q 'source ~/ros2_ws/install/setup.bash' ~/.bashrc; then
    echo 'source ~/ros2_ws/install/setup.bash 2>/dev/null || true' >> ~/.bashrc
fi

echo "  [完成] 目录已创建"

# ========== [5/5] 最终验证 ==========
echo ""
echo "========== [5/5] 最终验证 =========="
echo ""
echo "--- 系统工具 ---"
echo "  gcc:   $(gcc --version | head -1)"
echo "  cmake: $(cmake --version | head -1)"
echo "  ninja: $(ninja --version)"
echo ""
echo "--- GPU & CUDA ---"
echo "  GPU:   $(nvidia-smi --query-gpu=name,driver_version --format=csv,noheader)"
echo "  nvcc:  $(nvcc --version | grep release)"
echo ""
echo "--- ROS2 ---"
echo "  ros2:  $(ros2 --version 2>/dev/null || echo 'check with: source /opt/ros/humble/setup.bash')"
echo ""
echo "--- Python (lidar3d) ---"
echo "  python: $(python --version)"
python - << 'PYCHECK'
import sys
checks = {
    "PyTorch": "import torch; v=torch.__version__; print(f'{v}, CUDA={torch.cuda.is_available()}')",
    "GPU":     "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')",
    "spconv":  "import spconv.pytorch; print('OK')",
    "ONNX":    "import onnx; print(onnx.__version__)",
    "ORT":     "import onnxruntime as ort; print(f'{ort.__version__}, GPU={\"CUDAExecutionProvider\" in ort.get_available_providers()}')",
}
for name, cmd in checks.items():
    try:
        exec(f"result = None; {cmd.replace('print(', 'result = str(')}")
        print(f"  ✅ {name}: {result}")
    except Exception as e:
        print(f"  ❌ {name}: {e}")
PYCHECK

echo ""
echo "--- 目录 ---"
for d in ~/ros2_ws ~/datasets/KITTI ~/projects ~/models; do
    test -d "$d" && echo "  ✅ $d" || echo "  ❌ $d"
done

echo ""
echo "============================================"
echo "  修复完成! 请执行: source ~/.bashrc"
echo "============================================"
