#!/bin/bash
# Tintin++ 包装脚本 - 使用 tmux 创建持久会话
# 用法: ./tintin_wrapper.sh [start|stop|status|attach]

SESSION_NAME="tintin"
TT_DIR="$(cd "$(dirname "$0")" && pwd)"
TT_BIN="${TT_BIN:-tt++}"

start() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "会话已存在，使用: $0 attach"
        return 1
    fi

    echo "启动 tintin++ tmux 会话..."
    cd "$TT_DIR"

    # 检查 .env 文件
    if [ ! -f .env ]; then
        echo "未找到 .env 文件，从模板创建..."
        cp .env.example .env
        echo "请编辑 .env 文件填入用户名密码"
        return 1
    fi

    # 在 tmux 中启动 tt++
    tmux new-session -d -s "$SESSION_NAME" "$TT_BIN main.tt"

    # 等待启动
    sleep 2

    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "✓ tintin++ 已在后台启动"
        echo "  使用 '$0 attach' 连接到会话"
        echo "  使用 '$0 send <命令>' 发送命令"
        return 0
    else
        echo "✗ 启动失败"
        return 1
    fi
}

stop() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "停止 tintin++ 会话..."
        tmux send-keys -t "$SESSION_NAME" "quit" C-m
        sleep 1
        tmux kill-session -t "$SESSION_NAME" 2>/dev/null
        echo "✓ 会话已停止"
    else
        echo "会话不存在"
        return 1
    fi
}

status() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "✓ tintin++ 正在运行"
        echo ""
        echo "会话信息:"
        tmux list-sessions -F "#{session_name}: #{session_windows} 窗口" | grep "$SESSION_NAME"
        echo ""
        echo "操作:"
        echo "  $0 attach  - 连接到会话"
        echo "  $0 send <cmd> - 发送命令"
        return 0
    else
        echo "✗ tintin++ 未运行"
        echo "  使用 '$0 start' 启动"
        return 1
    fi
}

attach() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux attach-session -t "$SESSION_NAME"
    else
        echo "会话不存在，使用 '$0 start' 先启动"
        return 1
    fi
}

send() {
    if [ -z "$1" ]; then
        echo "用法: $0 send <命令>"
        return 1
    fi

    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux send-keys -t "$SESSION_NAME" "$*" C-m
        echo "✓ 已发送命令: $*"
    else
        echo "会话不存在"
        return 1
    fi
}

# 解析命令
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        sleep 1
        start
        ;;
    status)
        status
        ;;
    attach)
        attach
        ;;
    send)
        shift
        send "$@"
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|attach|send <命令>}"
        echo ""
        echo "示例:"
        echo "  $0 start           - 启动后台会话"
        echo "  $0 status          - 查看运行状态"
        echo "  $0 attach          - 连接到会话"
        echo "  $0 send conn       - 发送 conn 命令"
        echo "  $0 send 'look'     - 发送 look 命令"
        exit 1
        ;;
esac
