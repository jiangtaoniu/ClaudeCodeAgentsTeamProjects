#!/bin/bash
set -euo pipefail
source ~/.bashrc 2>/dev/null || true

echo "============================================"
echo "  阶段 5: Miniconda + lidar3d 环境"
echo "============================================"

# ---- Miniconda 安装 ----
echo ""
echo "[1/6] 安装 Miniconda3..."
if command -v conda &>/dev/null; then
    echo "  [跳过] conda 已安装: $(conda --version)"
else
    mkdir -p ~/tools
    cd ~/tools
    wget -q --show-progress https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p $HOME/miniconda3
    
    # 初始化 conda
    $HOME/miniconda3/bin/conda init bash
    
    echo "  [完成] Miniconda 安装完成"
    rm -f miniconda.sh
fi

# 重新加载
source ~/.bashrc 2>/dev/null || true
eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true

echo ""
echo "[2/6] 配置 conda..."
conda config --set auto_activate_base false

# 如果有代理，配置 conda 代理
if [ -n "${http_proxy:-}" ]; then
    conda config --set proxy_servers.http "$http_proxy"
    conda config --set proxy_servers.https "${https_proxy:-$http_proxy}"
    echo "  [完成] conda 代理已配置"
fi

echo ""
echo "[3/6] 创建 lidar3d 环境 (Python 3.10)..."
if conda env list | grep -q 'lidar3d'; then
    echo "  [跳过] lidar3d 环境已存在"
else
    conda create -n lidar3d python=3.10 -y
fi

conda activate lidar3d
python -m pip install --upgrade pip setuptools wheel

echo ""
echo "[4/6] 安装 PyTorch cu124..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

echo ""
echo "[5/6] 安装科学计算库..."
pip install \
  numpy \
  scipy \
  pandas \
  matplotlib \
  opencv-python \
  pyyaml \
  tqdm \
  easydict \
  scikit-learn \
  numba \
  llvmlite \
  open3d

echo ""
echo "[6/6] 验证 PyTorch GPU..."
python - << 'PY'
import torch
print(f"  torch:          {torch.__version__}")
print(f"  cuda available: {torch.cuda.is_available()}")
print(f"  torch cuda:     {torch.version.cuda}")
if torch.cuda.is_available():
    print(f"  gpu:            {torch.cuda.get_device_name(0)}")
else:
    print("  [错误] CUDA 不可用! 请检查 CUDA Toolkit 和驱动")
PY

echo ""
echo "============================================"
echo "  阶段 5 完成!"
echo "  验证: conda activate lidar3d && python -c 'import torch; print(torch.cuda.is_available())'"
echo "  然后运行: bash ~/setup-scripts/06-openpcdet.sh"
echo "============================================"
