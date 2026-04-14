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

### 6. `^` 锚定在 ANSI 颜色前缀行上失效

完整模式的出口行实际到达 tt++ 时带 ANSI 颜色代码：

```
[0;0m    这里明显的出口是 [1meast、north、south[0;0m 和 [1mwest[0;0m。
```

tt++ 的"前导空格被 strip"行为**只对无颜色代码的行生效**。有 ANSI 代码时，空格在代码之后、文本之前，`^` 匹配的是 ANSI 转义序列而非文本行首。

❌ `#action {^这里明显的出口是 {.+}}` → 不匹配（`^` 后期望文本，但行首是 `[0;0m    `）
✅ `#action {这里明显的出口是 {.+}}` → 匹配（去掉 `^`，在行中任意位置匹配）

**注意**：去掉 `^` 意味着任何包含该文本的行都会触发，需确保措辞足够独特。

### 7. MUD 出口行有两种措辞

书剑 MUD 的完整模式出口行不是固定格式：

| 出口数 | 措辞 | 示例 |
|--------|------|------|
| 多个 | `这里明显的出口是` | `这里明显的出口是 east、north、south 和 west。` |
| 单个 | `这里唯一的出口是` | `这里唯一的出口是 north。` |

❌ 只写 `#action {这里明显的出口是 {.+}}` → 单出口房间捕获不到
✅ 两个 action 都写：
```tt
#action {这里明显的出口是 {.+}} { ... }
#action {这里唯一的出口是 {.+}} { ... }
```

Python 端需清理捕获内容中的中文句号 `。`、连词 `和`、ANSI 颜色代码：
```python
ANSI_RE = re.compile(r'\x1b\[[0-9;]*m')

def parse_exits(exits_str):
    exits_str = ANSI_RE.sub('', exits_str)
    exits_str = re.sub(r'[。.和]', '', exits_str)
    exits = re.split(r"[、\s,]+", exits_str)
    return [e for e in exits if e]
```

## 已验证的正确方案

```tt
; 完整模式：房间名单独一行（look 触发）
; 注意 -%s 而不是 -$，因为行尾有空格
#action {^{.+} -%s} {
    #variable {temp_room} {%1}
}

; 完整模式出口行：不用 ^（ANSI 颜色代码导致前导空格不被 strip）
; 两种措辞：多出口用"明显的"，单出口用"唯一的"
#action {这里明显的出口是 {.+}} {
    #variable {current_room_exits} {%1}
}
#action {这里唯一的出口是 {.+}} {
    #variable {current_room_exits} {%1}
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
ANSI_RE = re.compile(r'\x1b\[[0-9;]*m')

def parse_exits(exits_str):
    exits_str = ANSI_RE.sub('', exits_str)      # 清理 ANSI 颜色代码
    exits_str = re.sub(r'[。.和]', '', exits_str) # 清理中文句号、英文句号、连词
    exits = re.split(r"[、\s,]+", exits_str)     # 按顿号、空格、逗号分割
    return [e for e in exits if e]
```

## 踩过的坑

| 坑 | 耗时 | 表现 |
|----|------|------|
| `^{.+} -$` 不匹配完整模式房间行 | ~3h | 完整模式 action 从未触发，`current_room` 始终为空 |
| NPC 正则用 `\(` 转义括号 | ~2h | 语法错误或匹配失败，`()` 在 tt++ 中本就是字面量 |
| 怀疑 ANSI 颜色代码干扰 | ~1h | `#config color off` 后问题不变，真正原因是编码转换 |
| 未用 hex dump 验证原始数据 | ~2h | 靠猜测调试，走了大量弯路 |
| `^` 锚定出口行但前导空格因 ANSI 代码未被 strip | ~1h | 完整模式出口 action 从不触发，`#showme` 测试确认去掉 `^` 后匹配 |
| 只写"明显的出口是"遗漏单出口房间 | ~30min | 当铺等单出口房间 exits 为空 |

## 验证方式

```bash
# 启动 tt++ 后连接 MUD，记录原始数据
# 在 tt++ 中: #log {append} {/tmp/tt_raw.log}
# 执行: look
# 然后: #log {off}
xxd /tmp/tt_raw.log | head -30
# 确认行尾 0x20 空格的存在
```
