#!/bin/bash
set -euo pipefail
source ~/.bashrc 2>/dev/null || true
eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
conda activate lidar3d

echo "============================================"
echo "  阶段 6: spconv + OpenPCDet"
echo "============================================"

echo ""
echo "[1/4] 安装 spconv-cu120..."
pip install spconv-cu120

echo ""
echo "[2/4] 验证 spconv..."
python - << 'PY'
import spconv.pytorch as spconv
print("  [成功] spconv 导入正常")
PY

echo ""
echo "[3/4] 克隆并安装 OpenPCDet..."
mkdir -p ~/projects
cd ~/projects

if [ -d "OpenPCDet" ]; then
    echo "  [跳过] OpenPCDet 目录已存在"
    cd OpenPCDet
else
    git clone https://github.com/open-mmlab/OpenPCDet.git
    cd OpenPCDet
fi

pip install -r requirements.txt
python setup.py develop

echo ""
echo "[4/4] 验证 OpenPCDet..."
python - << 'PY'
import torch
import spconv.pytorch as spconv
import pcdet
print(f"  torch cuda:  {torch.cuda.is_available()}")
print(f"  spconv:      OK")
print(f"  pcdet:       OK")
PY

echo ""
echo "创建数据集目录..."
mkdir -p ~/datasets/KITTI/training/{velodyne,calib,label_2,image_2}
mkdir -p ~/models

echo ""
echo "============================================"
echo "  阶段 6 完成!"
echo "  数据集目录: ~/datasets/KITTI/"
echo "  模型目录:   ~/models/"
echo "  然后运行: bash ~/setup-scripts/07-onnx.sh"
echo "============================================"
