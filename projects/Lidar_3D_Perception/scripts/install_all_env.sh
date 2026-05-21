#!/bin/bash
# ==============================================================================
# Lidar 3D Perception - 工业级自动驾驶点云检测全自动环境配置脚本
# 适用系统: Ubuntu 22.04 (包含 WSL2)
# ==============================================================================

set -e
trap 'echo "==========================================="; echo "[错误] 安装脚本在第 $LINENO 行失败，请检查网络或日志。"; echo "==========================================="' ERR

PROJECT_DIR=$(dirname $(dirname $(readlink -f "$0")))
echo "检测到项目根目录: ${PROJECT_DIR}"

echo "==========================================="
echo " 1. 基础系统与构建工具更新"
echo "==========================================="
sudo apt-get update
sudo apt-get install -y build-essential cmake git curl wget g++-11 ninja-build libgl1-mesa-glx libglib2.0-0 software-properties-common

echo "==========================================="
echo " 2. 安装 ROS 2 Humble 及 PCL 依赖"
echo "==========================================="
if ! command -v ros2 &> /dev/null; then
    echo "配置 ROS2 软件源..."
    sudo apt-get update && sudo apt-get install locales
    sudo locale-gen en_US en_US.UTF-8
    sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
    export LANG=en_US.UTF-8

    sudo apt-get install -y curl gnupg lsb-release
    sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(source /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y ros-humble-desktop ros-humble-pcl-conversions python3-colcon-common-extensions
else
    echo "ROS 2 已安装，补充安装 pcl_conversions..."
    sudo apt-get install -y ros-humble-pcl-conversions
fi

echo "==========================================="
echo " 3. 配置 NVIDIA CUDA 源与 TensorRT C++ 依赖"
echo "==========================================="
echo "下载并安装 CUDA keyring..."
wget -c https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -O /tmp/cuda-keyring_1.1-1_all.deb
sudo dpkg -i /tmp/cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y libnvinfer-dev libnvonnxparsers-dev

echo "==========================================="
echo " 4. 安装 Miniconda"
echo "==========================================="
if [ ! -d "$HOME/miniconda3" ]; then
    echo "下载 Miniconda3..."
    wget -c https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
    bash /tmp/miniconda.sh -b -p $HOME/miniconda3
fi
eval "$($HOME/miniconda3/bin/conda shell.bash hook)"

echo "==========================================="
echo " 5. 创建 lidar3d Python 环境"
echo "==========================================="
if ! conda info --envs | grep -q "lidar3d"; then
    conda create -y -n lidar3d python=3.10
fi
conda activate lidar3d

echo "更新 pip..."
pip install --upgrade pip

echo "==========================================="
echo " 6. 安装深度学习框架与 Spconv"
echo "==========================================="
export PIP_DEFAULT_TIMEOUT=1000
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install spconv-cu120 open3d

echo "==========================================="
echo " 7. 安装 TensorRT Python API"
echo "==========================================="
MAX_RETRIES=5
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "尝试安装 TensorRT-cu12 (第 $((RETRY_COUNT+1)) 次)..."
    if pip install tensorrt-cu12 --extra-index-url https://pypi.nvidia.com; then
        echo "TensorRT 安装成功！"
        break
    else
        echo "[警告] TensorRT 下载或安装失败，可能是网络问题。"
        RETRY_COUNT=$((RETRY_COUNT+1))
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "[错误] 达到最大重试次数！"
            exit 1
        fi
        echo "等待 5 秒后重试..."
        sleep 5
    fi
done

echo "==========================================="
echo " 8. 安装 ONNX 工具链"
echo "==========================================="
pip install onnx onnxsim onnxruntime onnxruntime-gpu

echo "==========================================="
echo " 9. 部署 OpenPCDet"
echo "==========================================="
OPENPCDET_DIR="${PROJECT_DIR}/02_model_export/OpenPCDet"
if [ ! -d "$OPENPCDET_DIR" ]; then
    echo "克隆 OpenPCDet 仓库..."
    mkdir -p "${PROJECT_DIR}/02_model_export"
    git clone https://github.com/open-mmlab/OpenPCDet.git "$OPENPCDET_DIR"
fi

cd "$OPENPCDET_DIR"
pip install -r requirements.txt
python setup.py develop

echo "==========================================="
echo " ✅ 环境一键配置完成！"
echo "==========================================="
