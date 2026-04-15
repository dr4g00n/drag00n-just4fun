# Tintin++ 注释格式与命令字符陷阱

## 元信息

| 字段 | 值 |
|------|-----|
| 适用环境 | tt++ 2.02.61 + `#read` 多文件加载 |
| 发现场景 | 启动时报 `#WARNING` + `#ERROR`，`/* */` 注释污染命令字符 |
| 验证状态 | ✅ 已验证（零 WARNING，零 ERROR 启动） |
| 最后更新 | 2026-04-16 |

## 一句话结论

被 `#read` 的文件**第一个字符决定命令字符**；`/* */` 会把 `/` 设为命令字符导致后续代码混乱；用 `#nop` 做行内注释；`#ALIAS #mapper` 的 `#` 被误识别为命令前缀；`#script` 内的 `*.exits` 会触发 `/*` 注释。

## 关键发现

### 1. 命令字符由第一个被 #read 的文件的第一个字符决定

tt++ 的命令字符（默认 `#`）由以下顺序决定：

1. **启动时第一个非空、非注释的字符**（如 `main.tt` 第一个字符）
2. 如果有 `#config command_char`，用它（但 tt++ 不支持此配置！）
3. 否则默认为 `#`

**关键行为**：tt++ 读取 `login.tt` 时，如果 `login.tt` 第一个字符是 `;`，后续代码中的 `;` 全变成命令字符（导致 WARNING）；如果第一个字符是 `/`，则 `/` 变成命令字符（导致所有 `#` 开头的东西报错）。

### 2. `/* */` 注释污染命令字符

login.tt 原版本：
```tt
/* ============================================================ */
/* 自动登录系统 - 从 .env 文件读取凭据                             */
/* ============================================================ */
```

第一个字符是 `/`，tt++ 把 `/` 设为命令字符。导致：
- `#variable` 变成语法错误（命令字符是 `/`，`#` 未知）
- main.tt 中的 `;` 注释正常（不是命令字符）
- 但 main.tt 中用 `#` 的命令全部失败

**修复**：改用 `#nop` 注释（`#nop` 不会被识别为命令字符定义）：
```tt
#nop 自动登录系统 - 从 .env 文件读取凭据
#nop ============================================================
```

### 3. `;` 注释在命令字符为 `#` 时触发 WARNING

当命令字符是 `#` 时，`;` 是**语句分隔符**。行首的 `;` 会被 tt++ 解释为"前面缺少语句"：

```
#WARNING: #READ {main.tt}: MISSING SEMICOLON ON LINE 104.
```

虽然功能正常（`;` 后面的内容被忽略），但 WARNING 污染日志。

**两种解决方案**：

**方案 A**：删除所有 `;` 注释（推荐）— tt++ 不支持传统注释，直接删掉

**方案 B**：用 `#nop {内容}` 格式（不推荐，容易出错）：
```tt
#nop { 这是注释 }
```

**坑点**：`#nop` 后的内容如果包含特殊字符（中文、空格、`=` 等）必须用大括号包起来，否则会触发语法错误：
```tt
#nop { 加载子系统 }     ✓ 正确
#nop  加载子系统       ❌ 错误（会报 MISSING SEMICOLON）
```

### 4. `#ALIAS #mapper` 中的 `#` 被误识别

```tt
#ALIAS #mapper {
    look
}
```

tt++ 解释为：
- `#ALIAS` 正确
- `#mapper` 被当成命令 `#` + 参数 `mapper`（未知命令）

**修复**：去掉 `#` 前缀：
```tt
#ALIAS mapper {
    look
}
```

### 5. `#script` 内的 `*.exits` 触发 `/*` 注释

```tt
#script {files} {ls map_data/raw/*.exits 2>/dev/null | wc -l || echo 0};
```

tt++ 在解析 `#script` 的内容时，会把 `raw/*.exits` 中的 `/*`（`/` 后跟 `*`）识别为注释开始：
```
#ERROR: #READ {main.tt}: MISSING 1 '*/'
```

**修复**：改用 `grep -c '.exits$'` 避免通配符和 `/` 连用：
```tt
#script {files} {ls map_data/raw/ 2>/dev/null | grep -c '.exits$' || echo 0};
```

### 6. 命令字符改变的行为差异

| 命令字符 | `;` 注释行为 | `#ALIAS #name` 行为 |
|---------|--------------|-------------------|
| `#`（默认） | 语句分隔符，行首 `;` 报 WARNING | `#name` 被误识别为 `#` 命令 |
| `/` | 普通字符，不报 WARNING | `#name` 语法错误（`#` 未知） |

## 已验证的正确方案

### login.tt（用 `#nop` 注释）

```tt
#nop 自动登录系统 - 从 .env 文件读取凭据
#nop ============================================================

#ALIAS load_credentials {
    #script {username} {source .env 2>/dev/null; echo "$MUD_USERNAME"};
    #script {password} {source .env 2>/dev/null; echo "$MUD_PASSWORD"};
    
    #variable {mud_username} {$username[1]};
    #variable {mud_password} {$password[1]};
    
    #showme <138>[登录] 已加载凭据: $mud_username;
    #showme <138>[登录] 用户名: $mud_username, 密码: $mud_password
}

#nop 自动登录 - 发送用户名
#action {^您的英文名字(ID)是：%s} {
    #showme <138>[登录] 触发用户名输入;
    #if {"$mud_username" != ""} {
        #showme <138>[登录] 发送用户名: $mud_username;
        #send $mud_username;
        #showme <138>[登录] 已发送
    }
}
```

### main.tt（删除所有 `;` 注释，修复通配符）

```tt
#variable {mud_host} {tj.sjever.net}
#variable {mud_port} {5555}

; ✗ 删除这行注释（避免 WARNING）

#config charset GBK1TOUTF8

; ✗ 删除这行注释

#variable {current_room} {}

; brief 模式：房间名和出口在同一行
#action {^{.+} - {.+}$} {
    ...
}

; ✗ 删除所有这类注释行

#ALIAS m_list {
    #script {files} {ls map_data/raw/ 2>/dev/null | grep -c '.exits$' || echo 0};
    #showme <138>[地图] 已保存 $files 个房间
}

; ✗ 删除这行注释

#ALIAS mapper {    ← 去掉 # 前缀
    look
}
```

### 启动验证检查清单

```bash
# 重启 tt++
tmux kill-session -t tintin 2>/dev/null
tmux new-session -d -s tintin -x 200 -y 50 'tt++ main.tt'
sleep 2

# 检查输出（应该零 WARNING，零 ERROR）
tmux capture-pane -t tintin -p -S -30 | grep -E '#WARNING|#ERROR'

# 期望：无任何输出
```

## 踩过的坑

| 坑 | 耗时 | 表现 |
|----|------|------|
| `/* */` 导致命令字符变为 `/` | ~1h | 所有 `#variable`、`#action` 报 `UNKNOWN COMMAND` |
| 删除 `/* */` 后留 `*/` 残留 | ~30min | 报 `MISSING 1 '*/'` |
| `#nop` 后的内容不用大括号 | ~20min | 报 `MISSING SEMICOLON`（tt++ 期望 `{`） |
| `#ALIAS #mapper` 无法调用 | ~10min | 报 `UNKNOWN TINTIN COMMAND 'mapper'` |
| `ls *.exits` 触发 `/*` 注释 | ~40min | 报 `MISSING 1 '*/'`，排查了很久 |
| 删除注释不完全 | ~15min | 还有残留 `;` 注释报 WARNING |
| `sed -i 's/^;/#nop /'` 语法错误 | ~10min | 导致 `#nop {#nop {` 重复嵌套 |

## 验证方式

```bash
# 1. 检查 tt++ 启动是否无 WARNING 和 ERROR
./tintin_wrapper.sh start
sleep 2
tmux capture-pane -t tintin -p -S -50 | grep -E '#WARNING|#ERROR'
# 期望：无输出

# 2. 确认 alias 可以正常调用
./tintin_wrapper.sh send 'mapper'
sleep 1
tmux capture-pane -t tintin -p -S -10
# 期望：看到 look 的结果，不是 "UNKNOWN COMMAND"

# 3. 确认变量正常
./tintin_wrapper.sh send 'map_info'
sleep 1
tmux capture-pane -t tintin -p -S -20
# 期望：看到地图系统状态输出

# 4. 停止
./tintin_wrapper.sh stop
```
