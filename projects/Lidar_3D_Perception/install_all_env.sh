#!/bin/bash
# ==============================================================================
# Lidar 3D Perception - 环境配置一键启动入口 (重定向脚本)
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPT="$SCRIPT_DIR/scripts/install_all_env.sh"

if [ -f "$TARGET_SCRIPT" ]; then
    chmod +x "$TARGET_SCRIPT"
    exec "$TARGET_SCRIPT" "$@"
else
    echo "[错误] 找不到目标安装脚本: $TARGET_SCRIPT"
    exit 1
fi
