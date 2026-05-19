#!/bin/bash
source ~/.bashrc 2>/dev/null || true

echo "========== 系统工具 =========="
echo "gcc:    $(gcc --version 2>/dev/null | head -1 || echo 'NOT INSTALLED')"
echo "cmake:  $(cmake --version 2>/dev/null | head -1 || echo 'NOT INSTALLED')"
echo "git:    $(git --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "ninja:  $(ninja --version 2>/dev/null || echo 'NOT INSTALLED')"

echo ""
echo "========== GPU & CUDA =========="
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>/dev/null || echo "nvidia-smi: FAILED"
echo "nvcc:   $(nvcc --version 2>/dev/null | grep release || echo 'NOT INSTALLED')"
echo "CUDA_HOME=$CUDA_HOME"

echo ""
echo "========== ROS2 =========="
echo "ros2:   $(ros2 --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "colcon: $(which colcon 2>/dev/null || echo 'NOT INSTALLED')"

echo ""
echo "========== Conda =========="
eval "$($HOME/miniconda3/bin/conda shell.bash hook 2>/dev/null)" 2>/dev/null || true
echo "conda:  $(conda --version 2>/dev/null || echo 'NOT INSTALLED')"
echo "envs:"
conda env list 2>/dev/null | grep -v '#' | grep -v '^$' || echo "  none"

echo ""
echo "========== Python (lidar3d) =========="
conda activate lidar3d 2>/dev/null
if command -v python &>/dev/null; then
    echo "python: $(python --version 2>/dev/null)"
    python << 'PYCHECK'
checks = [
    ("PyTorch",      "import torch; print(f'{torch.__version__}, CUDA={torch.cuda.is_available()}')"),
    ("GPU name",     "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'N/A')"),
    ("spconv",       "import spconv.pytorch; print('OK')"),
    ("ONNX",         "import onnx; print(onnx.__version__)"),
    ("ORT",          "import onnxruntime as ort; print(f'{ort.__version__}, GPU={\"CUDAExecutionProvider\" in ort.get_available_providers()}')"),
    ("numpy",        "import numpy; print(numpy.__version__)"),
    ("open3d",       "import open3d; print(open3d.__version__)"),
]
for name, cmd in checks:
    try:
        exec(cmd)
        tag = "OK"
    except Exception as e:
        tag = f"FAILED: {e}"
    # re-print with status
PYCHECK

    # Simpler per-lib check
    for lib in torch spconv.pytorch onnx onnxruntime numpy open3d; do
        python -c "import $lib; print('  ✅ $lib')" 2>/dev/null || echo "  ❌ $lib: not installed"
    done

    echo ""
    echo "PyTorch CUDA detail:"
    python -c "
import torch
print(f'  torch version:  {torch.__version__}')
print(f'  cuda available: {torch.cuda.is_available()}')
print(f'  cuda version:   {torch.version.cuda}')
if torch.cuda.is_available():
    print(f'  gpu name:       {torch.cuda.get_device_name(0)}')
" 2>/dev/null || echo "  PyTorch not working"
else
    echo "python: NOT FOUND (conda activate lidar3d may have failed)"
    echo "  Trying direct path..."
    if [ -f "$HOME/miniconda3/envs/lidar3d/bin/python" ]; then
        echo "  lidar3d python exists at: $HOME/miniconda3/envs/lidar3d/bin/python"
        $HOME/miniconda3/envs/lidar3d/bin/python --version
    else
        echo "  lidar3d environment NOT FOUND"
    fi
fi

echo ""
echo "========== 目录 =========="
for d in ~/ros2_ws ~/datasets ~/projects ~/models; do
    if [ -d "$d" ]; then
        echo "  ✅ $d"
    else
        echo "  ❌ $d: MISSING"
    fi
done

echo ""
echo "========== .bashrc 关键配置 =========="
echo "--- proxy ---"
grep -i proxy ~/.bashrc 2>/dev/null | head -4 || echo "  no proxy config"
echo "--- CUDA ---"
grep -i cuda ~/.bashrc 2>/dev/null | head -3 || echo "  no CUDA config"
echo "--- ROS2 ---"
grep -i ros ~/.bashrc 2>/dev/null | head -2 || echo "  no ROS2 config"
echo "--- conda ---"
grep -i conda ~/.bashrc 2>/dev/null | head -2 || echo "  no conda config"

echo ""
echo "========== 检查完毕 =========="
