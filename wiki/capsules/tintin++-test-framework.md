# Tintin++ 项目测试框架

## 元信息

| 字段 | 值 |
|------|-----|
| 适用环境 | macOS + tt++ 2.02.61（Homebrew） |
| 发现场景 | 为 Tintin++ 自动化项目建立完整测试框架 |
| 验证状态 | ✅ 已通过所有测试（`./tests/run_all_tests.sh`） |
| 最后更新 | 2026-04-13 |

## 一句话结论

统一测试架构：Python mock server → tt++ session 连接 → action 触发 → SESSION DISCONNECTED 事件写出变量 → shell 断言，适用于所有 tt++ 脚本模块测试。

## 关键发现

1. ❌ 每个模块单独写测试逻辑 → ✅ 统一 mock server + 模板化 tt++ 脚本
2. ❌ 混用不同样本目录 → ✅ 分类样本目录（samples/mapper, samples/login, samples/dream）
3. ❌ 固定端口导致冲突 → ✅ 递增端口（BASE_PORT + N）
4. ❌ 测试套件分散运行 → ✅ `run_all_tests.sh` 统一调度

## 已验证的正确方案

### 测试架构

```
tests/
├── mock_mud_server.py        # 通用 mock server
├── run_mapper_tests.sh       # Mapper 测试套件
├── run_subsystem_tests.sh    # 子系统测试套件（login, dream）
├── run_all_tests.sh          # 总调度
└── samples/                 # 样本分类目录
    ├── mapper/
    ├── login/
    └── dream/
```

### Mock Server（Python）

```python
# 监听端口 → 写就绪信号 → accept → 按行发送样本 → 关闭
# 通用实现: tests/mock_mud_server.py
```

关键点：
- 支持任意样本文件（命令行参数）
- 每行 `\r\n` 结尾
- 行间 0.1-0.2s 延迟

### tt++ 测试脚本模板

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

### 验证流程（Shell）

```bash
# 1. 启动 mock server
python3 mock_mud_server.py $port $sample $ready_file &
# 2. 等待就绪信号
while [ ! -f $ready_file ]; do sleep 0.2; done
# 3. 启动 tt++（tmux）
tmux new-session -d -s test "tt++ test.tt"
# 4. 等待执行完毕
sleep 6
# 5. 断言结果
grep "result=expected_value" /tmp/result.txt
```

## 测试覆盖

| 模块 | 测试套件 | 覆盖点 | 状态 |
|------|----------|--------|------|
| Mapper 正则 | run_mapper_tests.sh | 房间名、出口、NPC 捕获 | ✅ 4/4 |
| Login 子系统 | run_subsystem_tests.sh | 新版/旧版登录流程 | ✅ 2/2 |
| Dream 传送 | run_subsystem_tests.sh | 传送命令 + 自动确认 | ✅ 1/1 |

## 踩过的坑

| 坑 | 耗时 | 原因 |
|----|------|------|
| 样本文件混乱 | ~20min | login/dream 样本被 mapper 测试扫描到，误触发断言失败 |
| 样本路径问题 | ~15min | 测试脚本中样本路径硬编码，迁移后失效 |
| 路口 TIME_WAIT | ~10min | 并发测试时端口复用导致 Connection refused |

## 验证方式

```bash
cd /Users/dr4/tintin
./tests/run_all_tests.sh
# 预期: 2/2 测试套件通过
```
