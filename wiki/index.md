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
| [tintin++-regex-syntax](capsules/tintin++-regex-syntax.md) | tt++ 正则、action、分组、中文匹配、转义 | 分组用 `{}` 不是 `()`，前导空格被 strip，shell 中需要双重转义 |

## 新增胶囊

复制 `capsules/_template.md`，写完后在此表注册一行。
