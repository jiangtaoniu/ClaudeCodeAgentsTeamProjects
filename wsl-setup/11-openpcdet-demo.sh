#!/bin/bash
# =============================================
# OpenPCDet Demo 一键配置脚本
# 在 WSL 终端执行: bash ~/setup-scripts/11-openpcdet-demo.sh
# =============================================
set -euo pipefail

echo "============================================"
echo "  OpenPCDet Demo 一键配置"
echo "============================================"

# 激活 conda
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"
conda activate lidar3d
echo "  Python: $(python --version)"
echo "  PyTorch: $(python -c 'import torch; print(torch.__version__, "CUDA:", torch.cuda.is_available())')"

# ========== [1/5] 克隆 OpenPCDet ==========
echo ""
echo "========== [1/5] 准备 OpenPCDet =========="
mkdir -p ~/projects
cd ~/projects

if [ -d "OpenPCDet" ]; then
    echo "  [跳过] OpenPCDet 已存在"
else
    echo "  克隆 OpenPCDet..."
    git clone https://github.com/open-mmlab/OpenPCDet.git
fi

cd OpenPCDet

# ========== [2/5] 安装 OpenPCDet ==========
echo ""
echo "========== [2/5] 安装 OpenPCDet =========="
pip install -r requirements.txt
python setup.py develop

echo "  验证: $(python -c 'import pcdet; print("pcdet OK")' 2>/dev/null || echo 'pcdet FAILED')"

# ========== [3/5] 获取示例点云 ==========
echo ""
echo "========== [3/5] 获取示例点云文件 =========="
mkdir -p ~/projects/OpenPCDet/demo_data

if [ -f ~/projects/OpenPCDet/demo_data/000008.bin ]; then
    echo "  [跳过] 000008.bin 已存在"
else
    echo "  克隆 mmdetection3d 获取示例点云..."
    cd ~/projects
    if [ ! -d "mmdetection3d" ]; then
        # 只克隆最新一层，减少下载量
        git clone --depth 1 https://github.com/open-mmlab/mmdetection3d.git
    fi
    
    if [ -f ~/projects/mmdetection3d/demo/data/kitti/000008.bin ]; then
        cp ~/projects/mmdetection3d/demo/data/kitti/000008.bin ~/projects/OpenPCDet/demo_data/
        echo "  [完成] 000008.bin 已复制到 demo_data/"
    else
        echo "  [警告] mmdetection3d 中未找到 000008.bin"
        echo "  尝试直接从 GitHub 下载..."
        wget -q --show-progress -O ~/projects/OpenPCDet/demo_data/000008.bin \
            "https://raw.githubusercontent.com/open-mmlab/mmdetection3d/main/demo/data/kitti/000008.bin" \
            || echo "  下载失败，请手动获取点云文件"
    fi
fi

echo "  点云文件: $(ls -lh ~/projects/OpenPCDet/demo_data/000008.bin 2>/dev/null || echo 'NOT FOUND')"

# ========== [4/5] 下载 PointPillars 预训练权重 ==========
echo ""
echo "========== [4/5] 下载 PointPillars 预训练权重 =========="
mkdir -p ~/projects/OpenPCDet/checkpoints

if ls ~/projects/OpenPCDet/checkpoints/pointpillar*.pth 1>/dev/null 2>&1; then
    echo "  [跳过] 权重文件已存在"
else
    echo "  从 OpenPCDet Model Zoo 下载 PointPillars 权重..."
    # OpenPCDet 官方提供的 PointPillar KITTI 预训练模型
    wget -q --show-progress -O ~/projects/OpenPCDet/checkpoints/pointpillar_7728.pth \
        "https://drive.usercontent.google.com/download?id=1wMxWTpU1qUoY3DsCH31WJmvJxcjFXKlm&confirm=t" \
        2>/dev/null || {
        echo "  Google Drive 下载可能被限制，尝试备用方式..."
        echo ""
        echo "  ⚠️  请手动下载 PointPillars 权重:"
        echo "  1. 打开 https://github.com/open-mmlab/OpenPCDet"
        echo "  2. 找到 KITTI 3D Object Detection Baselines → PointPillar"
        echo "  3. 下载 model 链接的 .pth 文件"
        echo "  4. 放到: ~/projects/OpenPCDet/checkpoints/pointpillar_7728.pth"
        echo ""
        echo "  或者用 gdown 下载:"
        echo "    pip install gdown"
        echo "    gdown 1wMxWTpU1qUoY3DsCH31WJmvJxcjFXKlm -O ~/projects/OpenPCDet/checkpoints/pointpillar_7728.pth"
    }
fi

echo "  权重文件: $(ls -lh ~/projects/OpenPCDet/checkpoints/pointpillar*.pth 2>/dev/null || echo 'NOT FOUND - 需要手动下载')"

# ========== [5/5] 检查并提供运行命令 ==========
echo ""
echo "========== [5/5] 配置完成 =========="
echo ""
echo "  目录结构:"
echo "  ~/projects/OpenPCDet/"
echo "  ├── demo_data/000008.bin      $(test -f ~/projects/OpenPCDet/demo_data/000008.bin && echo '✅' || echo '❌')"
echo "  ├── checkpoints/pointpillar_7728.pth  $(ls ~/projects/OpenPCDet/checkpoints/pointpillar*.pth 1>/dev/null 2>&1 && echo '✅' || echo '❌ 需手动下载')"
echo "  └── tools/demo.py             $(test -f ~/projects/OpenPCDet/tools/demo.py && echo '✅' || echo '❌')"
echo ""
echo "============================================"
echo "  运行 Demo 的命令:"
echo "============================================"
echo ""
echo "  conda activate lidar3d"
echo "  cd ~/projects/OpenPCDet/tools"
echo ""
echo "  python demo.py \\"
echo "    --cfg_file cfgs/kitti_models/pointpillar.yaml \\"
echo "    --ckpt ../checkpoints/pointpillar_7728.pth \\"
echo "    --data_path ../demo_data/000008.bin"
echo ""
echo "============================================"
