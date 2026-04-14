# Tintin++ Action 状态管理与时序陷阱

## 元信息

| 字段 | 值 |
|------|-----|
| 适用环境 | tt++ 2.02.61，中文 MUD 自动化 |
| 发现场景 | 地图自动采集系统 — NPC 归属错误、数据丢失、登录阶段垃圾数据 |
| 验证状态 | ✅ 已通过实际 MUD 连接验证 |
| 最后更新 | 2026-04-14 |

## 一句话结论

NPC 行在 brief 房间行**之后**才到达，必须在**下一次** brief action 时 flush；`#line log`/`#foreach` 中变量可能延迟展开，用 alias `%1` 参数传值比 `$variable` 可靠；登录阶段的非房间数据会被贪婪 action 误匹配，必须用 `map_active` flag 隔离。

## 关键发现

### 1. NPC 行晚于房间行到达 — 延迟 flush 模式

MUD 在移动后先发送房间行（brief），然后逐行发送 NPC。时序如下：

```
[服务器发送] 广场南 - east、north、south、west   ← brief action 触发
[服务器发送]   张巡捕(Zhang xunbu)               ← NPC action 触发（后到）
[服务器发送] >                                    ← 提示符
```

如果在 brief action 中立即 flush NPC，`current_npcs` list 是空的（NPC 还没到）。

✅ 正确做法：brief action 中 flush **上一个房间的** NPC（此时 NPC 已经全部到达），然后开始收集当前房间的 NPC。

```tt
#action {^{.+} - {.+}$} {
    m_flush_npcs {$current_room};    ; 写上一个房间的 NPC
    #variable {current_room} {%1};    ; 更新到新房间
    ...
    m_autosave                        ; 保存新房间 exits
}
; NPC action 持续向 current_npcs 追加
#action {^  {.+}({.+})$} {
    #list {current_npcs} {add} {%1(%2)}
}
```

### 2. `#line log` / `#foreach` 中变量展开时机不确定

在 `#foreach` 循环内使用 `#line log {path/$current_room.npcs} {$npc}` 时，`$current_room` 可能在实际写文件时已经被后续代码修改。

❌ 依赖外层变量：
```tt
#ALIAS m_flush_npcs {
    #foreach {$current_npcs[]} {npc} {
        #line log {map_data/raw/$current_room.npcs} {$npc}
    }
}
; 调用时 current_room 可能已被修改
m_flush_npcs
#variable {current_room} {%1}  ; current_room 变了
```

✅ 通过 alias 参数传值：
```tt
#ALIAS m_flush_npcs {
    ; %1 是 alias 参数，在调用时已固定
    #foreach {$current_npcs[]} {npc} {
        #line log {map_data/raw/%1.npcs} {$npc}
    }
}
m_flush_npcs {$current_room}  ; 参数在调用时求值
```

### 3. 登录阶段垃圾数据 → `map_active` 隔离

MUD 登录过程输出大量非房间数据（欢迎屏、规则说明、ASCII art 等），贪婪 action `^{.+} - {.+}$` 会误匹配：

- `FluffOS 3.0-alpha9.0 - xxx` 被当成房间
- `(' o o ')` 被当成 NPC
- `#showme` 的输出（如 `[地图] 房间: xxx`）被自己的 action 重新匹配（递归）

✅ 用 `map_active` flag 控制：

```tt
#variable {map_active} {0}

; 只记录 temp_room，不保存数据
#action {^{.+} - {.+}$} {
    #variable {temp_room} {%1};       ; 始终记录
    #if {"$map_active" == "1"} {      ; 只在激活后保存
        m_flush_npcs {$current_room};
        #variable {current_room} {%1};
        m_autosave
    }
}

; 在第一个提示符时激活
#action {^> $} {
    #if {"$map_active" == "0" && "$temp_room" != ""} {
        #variable {map_active} {1};
        #variable {current_room} {$temp_room}
    }
}
```

### 4. `#system {echo}` vs `#line log` 行为差异

| 特性 | `#system {echo ... > file}` | `#line log {file} {text}` |
|------|---------------------------|--------------------------|
| 模式 | 覆盖（`>`）或追加（`>>`） | 总是追加 |
| 变量展开 | `echo` 时展开 | 可能延迟展开 |
| 中文支持 | 依赖 shell locale | tt++ 内部处理，更可靠 |
| 适用场景 | exits 文件（每次覆盖） | NPC 文件（逐行追加）、edges 文件（追加） |

### 5. 第一个房间的 NPC 不可避免地丢失

登录时 MUD 先发 brief 行（`广场南 - east、north、south、west`），然后发 NPC。但 `map_active` 在 `> ` 提示符时才激活。此时 NPC 已经全部到达过了，但被 `map_active == 0` 过滤掉了。

这是可接受的 — 后续 `look` 或移动时会重新采集。

### 6. `m_go` vs 直接方向命令

直接发送 `north`/`south` 不会设置 `prev_direction`，导致 `edges.txt` 缺少方向信息：

```
广场南||中央广场       ← 直接 north，方向为空
广场南|north|中央广场  ← 用 m_go north，方向正确
```

如果需要寻路时输出方向序列，必须使用 `m_go`。

## 已验证的正确方案

完整的状态管理流程：

```tt
; 初始化
#variable {current_room} {}
#variable {current_npcs} {}
#variable {map_active} {0}

; brief 行：始终记录 temp_room，激活后才保存
#action {^{.+} - {.+}$} {
    #variable {temp_room} {%1};
    #if {"$map_active" == "1"} {
        m_flush_npcs {$current_room};
        #variable {prev_room} {$current_room};
        #variable {current_room} {%1};
        m_autosave
    }
}

; NPC：只在激活后收集
#action {^  {.+}({.+})$} {
    #if {"$map_active" == "1"} {
        #list {current_npcs} {add} {%1(%2)}
    }
}

; 提示符：激活 + 初始化 current_room
#action {^> $} {
    #if {"$map_active" == "0" && "$temp_room" != ""} {
        #variable {map_active} {1};
        #variable {current_room} {$temp_room}
    }
}

; flush NPC：用 %1 参数避免变量延迟展开
#ALIAS m_flush_npcs {
    #if {"%1" != "" && &current_npcs[] > 0} {
        #system {rm -f map_data/raw/%1.npcs};
        #foreach {$current_npcs[]} {npc} {
            #line log {map_data/raw/%1.npcs} {$npc}
        };
        #list {current_npcs} {clear}
    }
}
```

## 踩过的坑

| 坑 | 耗时 | 表现 |
|----|------|------|
| brief action 中立即 flush NPC | ~2h | NPC list 为空，`.npcs` 文件不生成 |
| `#line log` 用 `$current_room` 做路径 | ~1h | NPC 写到下一个房间的文件里（变量已变） |
| 去掉 `map_active` 保护 | ~1h | 登录垃圾数据被匹配，`#showme` 输出递归触发 action |
| 第一个房间 `current_room` 为空 | ~1h | `m_flush_npcs` 跳过（`%1 == ""`），`m_record_edge` 跳过 |
| 不用 `m_go` 直接发方向 | ~30min | `edges.txt` 方向列为空，寻路无法输出方向序列 |

## 验证方式

```bash
# 连接 MUD，走几步，检查 raw 数据
cd /Users/dr4/tintin
./tintin_wrapper.sh start
./tintin_wrapper.sh send conn
# ... 登录后移动几步 ...
ls map_data/raw/
cat map_data/raw/edges.txt
cat map_data/raw/*.npcs
# 确认：NPC 归属正确，edges 有方向信息（如果用了 m_go）
```
