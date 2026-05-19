#!/bin/bash
set -euo pipefail
echo "============================================"
echo "  阶段 1: 代理配置 + Locale"
echo "============================================"

# ---- 代理配置 ----
# Clash Verge 默认端口 7890，如果你的端口不同请修改下面的数字
PROXY_PORT=7890

echo ""
echo "[1/3] 配置代理环境变量..."
echo "  使用端口: $PROXY_PORT"

# 检查是否已经配置过
if grep -q 'PROXY_PORT=' ~/.bashrc 2>/dev/null; then
    echo "  [跳过] ~/.bashrc 中已存在代理配置"
else
    cat >> ~/.bashrc << PROXY_EOF

# ===== Clash Verge 代理 (mirrored mode) =====
PROXY_PORT=$PROXY_PORT
export http_proxy="http://127.0.0.1:\$PROXY_PORT"
export https_proxy="http://127.0.0.1:\$PROXY_PORT"
export HTTP_PROXY="http://127.0.0.1:\$PROXY_PORT"
export HTTPS_PROXY="http://127.0.0.1:\$PROXY_PORT"
export no_proxy="localhost,127.0.0.1,::1"
export NO_PROXY="localhost,127.0.0.1,::1"
# ===== 代理配置结束 =====
PROXY_EOF
    echo "  [完成] 代理环境变量已写入 ~/.bashrc"
fi

# 立即生效
source ~/.bashrc 2>/dev/null || true
export http_proxy="http://127.0.0.1:$PROXY_PORT"
export https_proxy="http://127.0.0.1:$PROXY_PORT"

echo ""
echo "[2/3] 测试代理连通性..."
HTTP_CODE=$(curl -sI -o /dev/null -w '%{http_code}' --connect-timeout 10 https://github.com 2>/dev/null || echo 'FAIL')
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [成功] GitHub 可访问 (HTTP $HTTP_CODE)"
else
    echo "  [警告] GitHub 不可达 (HTTP $HTTP_CODE)"
    echo "  请确认 Clash Verge 已开启且端口是 $PROXY_PORT"
    echo "  如果端口不同，请编辑 ~/.bashrc 中的 PROXY_PORT 值"
fi

echo ""
echo "[3/3] 配置 Locale..."
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8

# 写入 bashrc
if ! grep -q 'export LANG=en_US.UTF-8' ~/.bashrc 2>/dev/null; then
    echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
fi

echo ""
echo "============================================"
echo "  阶段 1 完成!"
echo "  请运行: source ~/.bashrc"
echo "  然后运行: bash ~/setup-scripts/02-system-tools.sh"
echo "============================================"
