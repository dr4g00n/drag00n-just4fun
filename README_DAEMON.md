# Tintin++ 后台运行解决方案

## 问题

Tintin++ 需要交互式 TTY 终端运行，无法直接后台执行：
```bash
tt++ main.tt &          # ❌ 失败: tcsetattr 错误
nohup tt++ main.tt &    # ❌ 失败: reset_terminal 错误
```

## 解决方案：使用 tmux

### 方式1：快捷启动 (推荐)

```bash
./tt.sh
```

**功能**：
- 自动检查会话是否存在
- 如果存在则连接，不存在则创建
- 按 `Ctrl+B` 然后 `D` 脱离会话

### 方式2：完整控制脚本

```bash
# 启动后台会话
./tintin_wrapper.sh start

# 查看运行状态
./tintin_wrapper.sh status

# 连接到会话
./tintin_wrapper.sh attach

# 发送命令到会话
./tintin_wrapper.sh send conn
./tintin_wrapper.sh send 'look'

# 停止会话
./tintin_wrapper.sh stop
```

### 方式3：直接使用 tmux

```bash
# 创建并启动
tmux new -s tintin /opt/homebrew/bin/tt++ main.tt

# 脱离会话（保持运行）
按 Ctrl+B 然后 D

# 重新连接
tmux attach -t tintin

# 列出所有会话
tmux ls

# 杀死会话
tmux kill-session -t tintin
```

## tmux 快捷键

| 按键 | 功能 |
|------|------|
| `Ctrl+B D` | 脱离会话（保持运行） |
| `Ctrl+B [` | 进入滚动模式（查看历史） |
| `Ctrl+B C` | 创建新窗口 |
| `Ctrl+B N` | 切换到下一个窗口 |
| `Ctrl+B P` | 切换到上一个窗口 |
| `Ctrl+B 0-9` | 切换到指定窗口 |
| `exit` | 关闭当前窗口/会话 |

## 工作流程示例

```bash
# 1. 启动后台会话
./tintin_wrapper.sh start

# 2. 发送命令连接 MUD
./tintin_wrapper.sh send 'login'
./tintin_wrapper.sh send 'conn'

# 3. 需要交互时连接会话
./tintin_wrapper.sh attach

# 4. 完成后脱离会话
# 按 Ctrl+B 然后 D

# 5. 停止会话
./tintin_wrapper.sh stop
```

## AI 集成使用

AI 可以通过 `tintin_wrapper.sh send` 命令向运行中的 tt++ 发送命令：

```bash
# AI 发送命令
./tintin_wrapper.sh send 'look'
./tintin_wrapper.sh send 'get sword'

# AI 读取日志
tail -f tintin_log.txt
```

## 为什么选择 tmux

1. ✅ 持久化：会话在网络断开后仍保持运行
2. ✅ 多窗口：可以在同一会话中打开多个窗口
3. ✅ 远程访问：可以通过 SSH 远程连接到会话
4. ✅ 滚动历史：可以查看过去的输出
5. ✅ 成熟稳定：广泛使用的终端复用工具
