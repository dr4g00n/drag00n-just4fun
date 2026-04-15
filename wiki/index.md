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
| [tintin++-regex-syntax](capsules/tintin++-regex-syntax.md) | tt++ 正则、action、分组、中文匹配、转义、NPC | 分组用 `{}` 不是 `()`，前导空格被 strip，GBK→UTF8 后 `$` 锚定失效，`()` 是字面量不需转义 |
| [tintin++-mud-display-modes](capsules/tintin++-mud-display-modes.md) | MUD 显示模式、brief、完整模式、移动、look、NPC 格式 | 移动时 brief 模式（房间+出口同行、NPC 无 ◎），look 时完整模式（分多行、NPC 有 ◎），action 必须同时覆盖 |
| [tintin++-test-framework](capsules/tintin++-test-framework.md) | 测试框架、mock server、测试样本、run_all_tests | 统一测试架构：mock server + tt++ session + shell 断言 |
| [tintin++-gbk-encoding-pitfalls](capsules/tintin++-gbk-encoding-pitfalls.md) | GBK、UTF8、编码转换、行尾空格、charset、hex dump | `GBK1TOUTF8` 转换后行尾残留 0x20 空格导致 `$` 锚定失效，用 `-%s` 替代 `-$`，`()` 是字面量 |
| [tintin++-action-state-management](capsules/tintin++-action-state-management.md) | action 时序、变量展开、NPC flush、map_active、登录保护 | NPC 行晚于房间行到达需延迟 flush，`#line log` 变量延迟展开用 `%1` 传参，`map_active` 隔离登录垃圾 |
| [tintin++-room-uid-system](capsules/tintin++-room-uid-system.md) | UID 系统、同名房间、出口签名、old_room、格式规范化 | 用 房间名+出口签名 做唯一标识，统一 brief/完整模式出口格式，引入 `old_room` 在 resolve 前保存旧 UID |
| [tintin++-comment-and-command-char-pitfalls](capsules/tintin++-comment-and-command-char-pitfalls.md) | 命令字符、`/* */`、`#nop`、WARNING、`#ALIAS #mapper`、通配符 | 被 `#read` 的文件第一个字符决定命令字符，用 `#nop` 替代 `/* */`，删除 `;` 注释避免 WARNING |

## 新增胶囊

复制 `capsules/_template.md`，写完后在此表注册一行。
