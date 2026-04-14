# Tintin++ GBK→UTF8 编码陷阱

## 元信息

| 字段 | 值 |
|------|-----|
| 适用环境 | tt++ 2.02.61 + `#config charset GBK1TOUTF8` |
| 发现场景 | 书剑 MUD（GB18030 编码）连接后 action `$` 锚定失效 |
| 验证状态 | ✅ 已通过实际 MUD 连接验证（hex dump 确认） |
| 最后更新 | 2026-04-14 |

## 一句话结论

`GBK1TOUTF8` 编码转换后行尾会残留一个空格（0x20），导致 `$` 锚定永远匹配不到；出口列表中方向名之间夹杂 GBK 控制字符（0x81）；`()` 在 action 正则中是字面量，不需要 `\(` 转义。

## 关键发现

### 1. 行尾残留空格 → `$` 锚定失效

MUD 发送 `中央广场 -\r\n`，经 `GBK1TOUTF8` 转换后变成 `中央广场 - \n`（`-` 后多了 0x20 空格）。

❌ `#action {^{.+} -$}` → 不匹配（`-` 后有空格，`$` 前不是 `-`）
✅ `#action {^{.+} -%s}` → 匹配（`%s` 吞掉尾部空格）

**验证方式**：用 `#log {append} {文件名}` 记录原始数据，`xxd` 或 `cat -v` 检查字节。

```
# hex dump 证据
offset 0x40: e5b9bf e59c ba e58d97 20 2d 20 0a
                         广场南  [空格] - [空格] [LF]
```

### 2. 出口分隔符中的 GBK 控制字符

书剑 MUD 的出口列表 `east、north、south、west` 中，`、`（中文顿号）旁边的某些字节在 GBK→UTF8 转换后变成 0x81 控制字符。hex dump 中可见：

```
1meast e380 816e 6f72 7468 e380 8173 6f75 7468
```

`e380 81` 是 UTF-8 的 `、`（U+3001）。不影响 action 匹配（因为 action 匹配的是转换后的文本），但在 Python 后处理时 `re.split(r"[、\s,]+", ...)` 能正确处理。

### 3. `()` 是字面量，`\(` 反而是错误的

在 tt++ action 正则中：
- `{}` = 分组/捕获
- `()` = **字面量**括号字符

❌ `#action {^  {.+} \({.+}\)$}` → 语法可能报错或行为异常
✅ `#action {^  {.+}({.+})$}` → 正确匹配 `  NPC名(English ID)`

这和标准正则完全相反。NPC 匹配 `  当铺老板(Lao ban)` 的正确写法：
```
#action {^  {.+}({.+})$} {
    ; %1 = 当铺老板, %2 = Lao ban
    #list {current_npcs} {add} {%1(%2)}
}
```

### 4. Brief 模式出口行也有尾部空格

`广场南 - east、north、south、west` 的 `-` 两侧都有空格（这是 MUD 本身的格式），但行尾的空格不影响 `{.+}$` 匹配，因为 `{.+}` 贪婪匹配会吞掉尾部空格。

### 5. `#config color off` 不能解决空格问题

关闭颜色模式后行尾空格依然存在。这不是 ANSI 颜色代码的问题，而是 GBK→UTF8 编码转换的副作用。

## 已验证的正确方案

```tt
; 完整模式：房间名单独一行（look 触发）
; 注意 -%s 而不是 -$，因为行尾有空格
#action {^{.+} -%s} {
    #variable {temp_room} {%1}
}

; brief 模式：房间名和出口在同一行
; $ 在这里能工作因为 {.+} 贪婪匹配吞掉了尾部空格
#action {^{.+} - {.+}$} {
    #variable {current_room} {%1};
    #variable {current_room_exits_brief} {%2}
}

; NPC 匹配：() 是字面量，不需要转义
#action {^  {.+}({.+})$} {
    #list {current_npcs} {add} {%1(%2)}
}
```

Python 后处理出口数据时：
```python
import re
exits = re.split(r"[、\s,]+", exits_str)  # 兼容中文顿号、空格、英文逗号
exits = [e for e in exits if e]            # 过滤空串
```

## 踩过的坑

| 坑 | 耗时 | 表现 |
|----|------|------|
| `^{.+} -$` 不匹配完整模式房间行 | ~3h | 完整模式 action 从未触发，`current_room` 始终为空 |
| NPC 正则用 `\(` 转义括号 | ~2h | 语法错误或匹配失败，`()` 在 tt++ 中本就是字面量 |
| 怀疑 ANSI 颜色代码干扰 | ~1h | `#config color off` 后问题不变，真正原因是编码转换 |
| 未用 hex dump 验证原始数据 | ~2h | 靠猜测调试，走了大量弯路 |

## 验证方式

```bash
# 启动 tt++ 后连接 MUD，记录原始数据
# 在 tt++ 中: #log {append} {/tmp/tt_raw.log}
# 执行: look
# 然后: #log {off}
xxd /tmp/tt_raw.log | head -30
# 确认行尾 0x20 空格的存在
```
