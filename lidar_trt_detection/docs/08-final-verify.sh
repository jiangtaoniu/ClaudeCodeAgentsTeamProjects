#!/bin/bash
source ~/.bashrc 2>/dev/null || true
eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
conda activate lidar3d

echo "============================================"
echo "  阶段 8: 最终环境验证"
echo "============================================"

PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    local result
    result=$(eval "$cmd" 2>&1) && {
        echo "  ✅ $name: $result"
        PASS=$((PASS+1))
    } || {
        echo "  ❌ $name: FAILED ($result)"
        FAIL=$((FAIL+1))
    }
}

echo ""
echo "=== 系统工具 ==="
check "gcc"    "gcc --version | head -1"
check "cmake"  "cmake --version | head -1"
check "git"    "git --version"
check "ninja"  "ninja --version"

echo ""
echo "=== GPU & CUDA ==="
check "nvidia-smi"  "nvidia-smi --query-gpu=name,driver_version --format=csv,noheader"
check "nvcc"        "nvcc --version | grep release"

echo ""
echo "=== ROS2 ==="
check "ros2"    "ros2 --version 2>/dev/null || ros2 doctor --report 2>/dev/null | head -1"
check "colcon"  "colcon version-check 2>/dev/null | head -1 || echo 'installed'"

echo ""
echo "=== Python 环境 (lidar3d) ==="
check "conda"   "conda --version"
check "python"  "python --version"

echo ""
echo "=== 深度学习框架 ==="
check "PyTorch"       "python -c 'import torch; print(torch.__version__)'"
check "PyTorch CUDA"  "python -c 'import torch; print(torch.cuda.is_available())'"
check "GPU 名称"      "python -c 'import torch; print(torch.cuda.get_device_name(0))'"
check "spconv"        "python -c 'import spconv.pytorch; print(\"OK\")'"
check "OpenPCDet"     "python -c 'import pcdet; print(\"OK\")'"
check "ONNX"          "python -c 'import onnx; print(onnx.__version__)'"
check "ONNX Runtime"  "python -c 'import onnxruntime as ort; print(ort.__version__)'"

echo ""
echo "=== 目录结构 ==="
check "ros2_ws"   "test -d ~/ros2_ws/src && echo 'EXISTS' || echo 'MISSING'"
check "datasets"  "test -d ~/datasets/KITTI && echo 'EXISTS' || echo 'MISSING'"
check "projects"  "test -d ~/projects/OpenPCDet && echo 'EXISTS' || echo 'MISSING'"
check "models"    "test -d ~/models && echo 'EXISTS' || echo 'MISSING'"

echo ""
echo "============================================"
echo "  验证结果: $PASS 通过 / $FAIL 失败"
echo "============================================"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "  🎉 所有组件安装成功!"
    echo ""
    echo "  你的环境已就绪:"
    echo "    conda activate lidar3d"
    echo "    cd ~/ros2_ws"
    echo ""
    echo "  下一步建议:"
    echo "    1. 写 ROS2 点云发布节点"
    echo "    2. 在 RViz2 中显示 KITTI 点云"
    echo "    3. 跑 OpenPCDet PointPillars 离线推理"
    echo ""
else
    echo ""
    echo "  ⚠️  有 $FAIL 个组件未通过验证"
    echo "  请把上面的失败信息发给我，我帮你排查"
fi
