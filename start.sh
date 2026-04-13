#!/bin/bash
# 书剑 MUD 启动脚本

cd /Users/dr4/tintin

# 检查 .env 文件
if [ ! -f .env ]; then
    echo "未找到 .env 文件，从模板创建..."
    cp .env.example .env
    echo "请编辑 .env 文件填入你的用户名密码，然后重新运行此脚本"
    exit 1
fi

# 启动 tintin++
/opt/homebrew/bin/tt++ main.tt
