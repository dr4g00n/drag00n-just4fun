# macOS 下测试 Tintin++ 脚本的完整方案

## 元信息

| 字段 | 值 |
|------|-----|
| 适用环境 | macOS + tt++ 2.02.61（Homebrew） |
| 发现场景 | 为 mapper.tt 的正则编写自动化测试 |
| 验证状态 | ✅ 已通过自动化测试（`tests/run_mapper_tests.sh`） |
| 最后更新 | 2026-04-13 |

## 一句话结论

tt++ 没有 headless 模式，测试必须走 **tmux + Python mock TCP server + `SESSION DISCONNECTED` 事件写出变量** 这条路，其他方案均不可行。

## 关键发现

1. ❌ `tt++ -e` 直接执行 → ✅ 会 crash，不支持非交互模式
2. ❌ `#parse` / `#line parse` 触发 action → ✅ 完全不工作，action 只对 session 数据流生效
3. ❌ 普通 shell 后台运行 `tt++ &` → ✅ 会因缺少 TTY 而 crash，必须用 tmux
4. ❌ `#ticker` 在 session 断开后继续执行 → ✅ session 断开后 tt++ 主循环退出，ticker 不会执行
5. ❌ 先启动 tt++ 再启动 mock server → ✅ 必须先启动 mock server（listen 状态），再启动 tt++ 连接

## 已验证的正确方案

### 架构

```
Python mock server (listen) → tt++ (#session 连接) → action 触发设置变量
                                                       ↓
                                              SESSION DISCONNECTED 事件
                                                       ↓
                                              #system 写变量到文件
```

### Mock Server（Python）

```python
# 监听端口 → 写就绪信号文件 → accept 连接 → 按行发送样本数据 → 关闭
# 完整实现见: tests/mock_mud_server.py
```

关键点：
- 用独立文件（如 `/tmp/mock_server_ready.txt`）做就绪信号
- 每行数据以 `\r\n` 结尾（模拟 telnet 协议）
- 行间加 0.1-0.2s 延迟，避免 tt++ 来不及处理

### 测试 tt++ 脚本模板

```
#config charset UTF-8
#variable {result} {NOT_SET}

#action {匹配模式} {
    #variable {result} {%1}
}

#session test 127.0.0.1 <端口>

#event {SESSION DISCONNECTED} {
    #system {echo "result=$result" > /tmp/结果文件};
    #system {echo "DONE" >> /tmp/结果文件};
    #end
}
```

### 测试运行器流程（Shell）

```bash
# 1. 启动 mock server，等待就绪信号文件
python3 mock_mud_server.py $PORT $SAMPLE_FILE $READY_FILE &
# 2. 等待就绪
while [ ! -f $READY_FILE ]; do sleep 0.2; done
# 3. 在 tmux 中启动 tt++
tmux new-session -d -s test_session "tt++ test_script.tt"
# 4. 等待执行完毕（约 5-6 秒）
sleep 6
# 5. 清理 + 读取结果文件断言
tmux kill-session -t test_session
cat /tmp/result.txt
```

### 端口管理

每个测试用例使用独立端口，从 BASE_PORT 递增。避免端口 TIME_WAIT 冲突。

## 踩过的坑

| 坑 | 耗时 | 原因 |
|----|------|------|
| tt++ crash 于非 TTY 环境 | ~30min | 必须用 tmux 提供 pseudo-TTY |
| `#parse` 不触发 action | ~1h | tt++ 文档未明确说明，action 仅对 session socket 数据流生效 |
| ticker 不执行 | ~30min | session 断开后 gts 激活但主循环状态异常，改用 SESSION DISCONNECTED 事件 |
| 端口 TIME_WAIT | ~20min | 连续测试用相同端口会 Connection refused，必须递增端口 |
| heredoc 转义问题 | ~30min | shell heredoc 中 tt++ 的 `$` `{}` `\` 都需要特殊处理，建议用独立文件生成 |

## 验证方式

```bash
cd /Users/dr4/tintin
./tests/run_mapper_tests.sh
# 预期输出: 4/4 通过
```
