#!/bin/bash
set -euo pipefail

# Activate conda environment and set CUDA path
eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
conda activate lidar3d
export CUDA_HOME=/usr/local/cuda-12.4
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ONNX_MODEL="$ROOT_DIR/models/onnx/pointpillar.onnx"
TRT_ENGINE="$ROOT_DIR/models/engine/pointpillar.engine"

echo "============================================"
echo "  Building TensorRT Engine"
echo "============================================"

if [ ! -f "$ONNX_MODEL" ]; then
    echo "Error: ONNX model not found at $ONNX_MODEL"
    echo "Please run export_onnx.py first."
    exit 1
fi

mkdir -p "$(dirname "$TRT_ENGINE")"

# We use trtexec to build the engine. 
# PointPillars has dynamic inputs for voxels, voxel_num_points, voxel_coords.
# Shape format is: N x Channels x Height (or similar)
# We will set min, opt, max shapes to accommodate different point cloud densities.

# minShapes: 1 voxel
# optShapes: 16000 voxels
# maxShapes: 40000 voxels

MIN_SHAPES="voxels:1x32x4,voxel_num_points:1,voxel_coords:1x4"
OPT_SHAPES="voxels:16000x32x4,voxel_num_points:16000,voxel_coords:16000x4"
MAX_SHAPES="voxels:40000x32x4,voxel_num_points:40000,voxel_coords:40000x4"

echo "Running trtexec..."
trtexec \
    --onnx="$ONNX_MODEL" \
    --saveEngine="$TRT_ENGINE" \
    --minShapes="$MIN_SHAPES" \
    --optShapes="$OPT_SHAPES" \
    --maxShapes="$MAX_SHAPES" \
    --fp16 \
    --workspace=4096

echo "============================================"
echo "  Engine built successfully!"
echo "  Engine saved to: $TRT_ENGINE"
echo "============================================"
