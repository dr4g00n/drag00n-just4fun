# 测试框架文档

## 测试覆盖

| 模块 | 测试文件 | 状态 | 说明 |
|------|----------|------|------|
| Mapper 正则 | `run_mapper_tests.sh` | ✅ 4/4 通过 | 测试房间名、出口、NPC 捕获的正则匹配 |
| Login 子系统 | `run_subsystem_tests.sh` | ✅ 2/2 通过 | 测试新版和旧版登录流程的 action 触发 |
| Dream 传送系统 | `run_subsystem_tests.sh` | ✅ 1/1 通过 | 测试传送命令和确认流程 |

## 目录结构

```
tests/
├── mock_mud_server.py        # Mock MUD 服务器（Python）
├── run_mapper_tests.sh       # Mapper 正则测试
├── run_subsystem_tests.sh    # 子系统测试（login, dream）
├── run_all_tests.sh          # 运行所有测试
└── samples/
    ├── mapper/               # Mapper 测试样本
    │   ├── 武馆大门.txt
    │   ├── 青龙门内街.txt
    │   ├── 广场.txt
    │   └── 南城巷.txt
    ├── login/                # Login 测试样本
    │   ├── login_normal.txt
    │   └── login_old.txt
    └── dream/               # Dream 测试样本
        └── dream_city.txt
```

## 使用方式

### 运行所有测试

```bash
cd /Users/dr4/tintin
./tests/run_all_tests.sh
```

### 运行单个测试套件

```bash
# Mapper 测试
./tests/run_mapper_tests.sh

# 子系统测试
./tests/run_subsystem_tests.sh
```

### 添加新测试

1. 在对应子目录添加样本文件（`samples/<模块>/<文件名>.txt`）
2. 在对应的测试脚本中添加 `run_test` 调用

## 测试原理

所有测试采用统一架构：

```
Python Mock Server (listen) → tt++ (#session 连接) → action 触发
                                                      ↓
                                              SESSION DISCONNECTED 事件
                                                      ↓
                                              写变量到结果文件
                                                      ↓
                                              Shell 脚本断言验证
```

### Mock Server

- 监听指定端口
- 发送样本文件中的每一行（以 `\r\n` 结尾）
- 行间加延迟避免 tt++ 处理不过来
- 写就绪信号文件通知测试脚本可以连接

### tt++ 测试脚本

```tintin
#config charset UTF-8
#variable {test_result} {NOT_SET}

#action {匹配模式} {
    #variable {test_result} {%1}
}

#session test 127.0.0.1 <端口>

#event {SESSION DISCONNECTED} {
    #system {echo "result=$test_result" > /tmp/result.txt};
    #end
}
```

### 验证流程

1. 启动 mock server，等待就绪信号
2. 启动 tt++（在 tmux 中）
3. 等待连接断开
4. 读取结果文件断言变量值

## 已知问题和修复

### 1. mapper.tt 正则语法错误

**问题**：使用 `(.+)` 分组在 session 模式下无法匹配
**修复**：改为 `{.+}`，使用 tt++ 的花括号分组语法

### 2. 前导空格 strip 问题

**问题**：`^    这里明显的出口是` 永远匹配不到
**修复**：去掉前导空格，改为 `^这里明显的出口是`

### 3. 路口 TIME_WAIT

**问题**：连续测试相同端口会 Connection refused
**修复**：每个测试用例使用递增端口

## 性能

- 单个测试耗时：约 6 秒
- Mapper 测试套件：约 24 秒（4 个测试）
- 子系统测试套件：约 18 秒（3 个测试）
- 完整测试：约 45 秒
