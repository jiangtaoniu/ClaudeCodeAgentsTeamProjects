#!/bin/bash
set -euo pipefail
source ~/.bashrc 2>/dev/null || true
eval "$($HOME/miniconda3/bin/conda shell.bash hook)" 2>/dev/null || true
conda activate lidar3d

echo "============================================"
echo "  阶段 7: ONNX + ONNX Runtime"
echo "============================================"

echo ""
echo "[1/2] 安装 ONNX 工具链..."
pip install onnx onnxsim onnxruntime onnxruntime-gpu

echo ""
echo "[2/2] 验证..."
python - << 'PY'
import onnx
import onnxruntime as ort
print(f"  onnx:           {onnx.__version__}")
print(f"  onnxruntime:    {ort.__version__}")
print(f"  providers:      {ort.get_available_providers()}")
if 'CUDAExecutionProvider' in ort.get_available_providers():
    print("  [成功] ONNX Runtime GPU 可用!")
else:
    print("  [警告] CUDAExecutionProvider 不可用，可能需要重新安装 onnxruntime-gpu")
PY

echo ""
echo "============================================"
echo "  阶段 7 完成!"
echo "  请运行: bash ~/setup-scripts/08-final-verify.sh"
echo "============================================"
