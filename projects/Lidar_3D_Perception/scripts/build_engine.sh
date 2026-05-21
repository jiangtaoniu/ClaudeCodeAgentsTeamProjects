#!/bin/bash
# ==============================================================================
# Lidar 3D Perception - TensorRT Engine 一键编译与构建脚本
# ==============================================================================

set -euo pipefail

# 载入 Miniconda 与 conda 环境
eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
conda activate lidar3d

# 配置 CUDA 环境
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

ONNX_MODEL="$PROJECT_DIR/models/onnx/pointpillar.onnx"
TRT_ENGINE="$PROJECT_DIR/models/engine/pointpillar.engine"

echo "============================================"
echo "  开始构建 TensorRT Engine"
echo "  项目根目录: $PROJECT_DIR"
echo "============================================"

# 验证 ONNX 是否已导出
if [ ! -f "$ONNX_MODEL" ]; then
    echo "[错误] 未在 $ONNX_MODEL 找到 ONNX 格式模型。"
    echo "请首先通过 python $PROJECT_DIR/02_model_export/export_onnx.py 导出模型！"
    exit 1
fi

mkdir -p "$(dirname "$TRT_ENGINE")"

# 配置编译时的动态 Dimension profile (min/opt/max shapes)
MIN_SHAPES="voxels:1x32x4,voxel_num_points:1,voxel_coords:1x4"
OPT_SHAPES="voxels:16000x32x4,voxel_num_points:16000,voxel_coords:16000x4"
MAX_SHAPES="voxels:40000x32x4,voxel_num_points:40000,voxel_coords:40000x4"

echo "启动 trtexec 编译..."
trtexec \
    --onnx="$ONNX_MODEL" \
    --saveEngine="$TRT_ENGINE" \
    --minShapes="$MIN_SHAPES" \
    --optShapes="$OPT_SHAPES" \
    --maxShapes="$MAX_SHAPES" \
    --fp16 \
    --workspace=4096

echo "============================================"
echo "  TensorRT Engine 构建成功！"
echo "  已保存至: $TRT_ENGINE"
echo "============================================"
