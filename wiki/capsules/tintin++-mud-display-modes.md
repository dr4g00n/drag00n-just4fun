# 书剑 MUD 两种显示模式

## 元信息

| 字段 | 值 |
|------|-----|
| 适用环境 | 书剑 MUD（sjever.net）+ tt++ 2.02.61 |
| 发现场景 | 实际连接 MUD 后发现移动和 look 输出格式不同 |
| 验证状态 | ✅ 已通过自动化测试 + 实际 MUD 连接验证 |
| 最后更新 | 2026-04-13 |

## 一句话结论

MUD 移动时输出 brief 模式（房间+出口同行、NPC 无 ◎），look 时输出完整模式（分多行、NPC 有 ◎）。action 必须同时支持两种格式。

## 关键发现

### 1. 两种显示格式

| | brief 模式（移动时） | 完整模式（look 命令） |
|---|---|---|
| 房间+出口 | `武馆大门 - enter、south`（同行） | 房间 `武馆大门 -` 单独一行，出口 `    这里明显的出口是 enter 和 south.` 单独一行 |
| NPC | `  武馆门卫(Men wei)`（两空格缩进，无 ◎） | `◎武馆门卫(Men wei)` |
| 触发时机 | `south`/`north` 等移动命令 | 输入 `look` |
| 频率 | 高（每次移动） | 低（主动查看） |

### 2. ❌ 只处理完整模式 → ✅ 同时处理两种模式

只写 `^{.+} -$` 的话，brief 模式下房间名和出口在同一行，不会被这条 action 匹配。

### 3. ❌ 假设 NPC 始终有 ◎ → ✅ 区分两种 NPC 格式

brief 模式下 NPC 是 `  名字(ID)` 格式，没有 ◎ 符号。

## 已验证的正确方案

### mapper action 完整写法

```
; brief 模式：房间名和出口在同一行
#action {^{.+} - {.+}$} {
    #variable {current_room} {%1};
    #variable {current_room_exits_brief} {%2}
}

; 完整模式：房间名单独一行
#action {^{.+} -$} {
    #variable {current_room} {%1}
}

; 完整模式：出口单独一行（tt++ strip 前导空格）
#action {^这里明显的出口是 {.+}\.$} {
    #variable {current_room_exits} {%1}
}

; brief 模式：NPC 无 ◎ 前缀
#action {^  {.+} \({.+}\)$} {
    #list {current_npcs} {add} {%1(%2)}
}

; 完整模式：NPC 有 ◎ 前缀
#action {^◎{.+} \({.+}\)$} {
    #list {current_npcs} {add} {%1(%2)}
}
```

### 出口变量合并策略

用两个变量 `current_room_exits_brief` 和 `current_room_exits` 分别存储，显示时优先 brief：

```
#if {"$current_room_exits_brief" != ""} {
    #showme <138>  当前出口: $current_room_exits_brief
} {
    #showme <138>  当前出口: $current_room_exits
}
```

### 注意事项

- brief 模式的 action `^{.+} - {.+}$` 必须放在 `^{.+} -$` **之前**，否则 `^{.+} -$` 会先匹配把出口吞掉
- tt++ 的 `{.+}` 分组：`^{.+} - {.+}$` 中 `%1` = `-` 前部分，`%2` = `-` 后部分，可正确分离
- 完整模式的出口行有 4 个前导空格，但 tt++ 会 strip，所以用 `^这里明显的出口是` 而不是 `^    这里明显的出口是`

## 踩过的坑

| 坑 | 耗时 | 原因 |
|----|------|------|
| 只处理完整模式 | ~2h | mock 测试用的是完整模式数据，实际 MUD 移动时是 brief 格式 |
| 假设 NPC 都有 ◎ | ~1h | 实际 MUD 连接后才发现 brief 模式下 NPC 格式不同 |
| action 顺序错误 | ~30min | `^{.+} -$` 放前面会先匹配 brief 数据，导致出口丢失 |
| 完整模式出口有前导空格 | 已在 regex-syntax 胶囊覆盖 | tt++ strip 前导空格 |

## 验证方式

```bash
cd /Users/dr4/tintin
./tests/run_mapper_tests.sh
# 预期: 4/4 通过

# 实际 MUD 连接验证
./tintin_wrapper.sh start
# 等 3 秒后: ./tintin_wrapper.sh send 'conn'
# 等 6 秒后: ./tintin_wrapper.sh send 'N'
# 登录后: ./tintin_wrapper.sh send 'map_info'
# 移动: ./tintin_wrapper.sh send 'south'
# 移动后: ./tintin_wrapper.sh send 'map_info'
# 预期: 房间名、出口、NPC 均正确捕获
```
