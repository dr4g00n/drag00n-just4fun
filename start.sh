#!/bin/bash
# 书剑 MUD 启动脚本（裸终端模式，不使用 tmux）
# 推荐使用 ./tt.sh 或 ./tintin_wrapper.sh start 代替

cd "$(dirname "$0")"

TT_BIN="${TT_BIN:-tt++}"

if [ ! -f .env ]; then
    echo "未找到 .env 文件，从模板创建..."
    cp .env.example .env
    echo "请编辑 .env 文件填入你的用户名密码，然后重新运行此脚本"
    exit 1
fi

"$TT_BIN" main.tt
