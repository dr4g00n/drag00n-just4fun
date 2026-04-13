# 数据胶囊索引

> 数据胶囊是经过验证的经验压缩包，供 AI 快速获取项目特定领域的非显而易见知识。
> 读取对应胶囊即可跳过试错阶段。

## 使用方式

1. 根据任务关键词在下表找到匹配胶囊
2. 读取对应 `.md` 文件
3. 直接使用"已验证的正确方案"部分

## 胶囊列表

| 胶囊 | 关键词 | 一句话结论 |
|------|--------|-----------|
| [tintin++-macos-testing](capsules/tintin++-macos-testing.md) | tt++ 测试、自动化测试、mock server、tmux | tt++ 没有 headless 模式，测试必须走 tmux + Python mock TCP server + `SESSION DISCONNECTED` 事件 |
| [tintin++-regex-syntax](capsules/tintin++-regex-syntax.md) | tt++ 正则、action、分组、中文匹配、转义、NPC | 分组用 `{}` 不是 `()`，前导空格被 strip，NPC 格式不固定，action 顺序影响匹配 |
| [tintin++-mud-display-modes](capsules/tintin++-mud-display-modes.md) | MUD 显示模式、brief、完整模式、移动、look、NPC 格式 | 移动时 brief 模式（房间+出口同行、NPC 无 ◎），look 时完整模式（分多行、NPC 有 ◎），action 必须同时覆盖 |
| [tintin++-test-framework](capsules/tintin++-test-framework.md) | 测试框架、mock server、测试样本、run_all_tests | 统一测试架构：mock server + tt++ session + shell 断言 |

## 新增胶囊

复制 `capsules/_template.md`，写完后在此表注册一行。
