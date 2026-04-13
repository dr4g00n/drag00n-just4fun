#!/bin/bash
# 快捷启动脚本 - 一键启动 tintin++ 后台会话

SESSION="tintin"
DIR="/Users/dr4/tintin"

cd "$DIR"

# 检查是否已有会话
if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "会话已存在，正在连接..."
    tmux attach -t "$SESSION"
    exit 0
fi

# 检查 .env
if [ ! -f .env ]; then
    echo "未找到 .env，创建模板..."
    cp .env.example .env
    nano .env
fi

# 创建新会话并启动 tt++
echo "启动 tintin++..."
tmux new-session -s "$SESSION" /opt/homebrew/bin/tt++ main.tt
