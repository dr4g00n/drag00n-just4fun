# Tintin++ 房间 UID 系统与同名房间处理

## 元信息

| 字段 | 值 |
|------|-----|
| 适用环境 | tt++ 2.02.61 + 中文 MUD 自动采集（书剑） |
| 发现场景 | 同名房间被错误标记 `~1`、`~2`，edges.txt 记录错误 |
| 验证状态 | ✅ 已通过实际 MUD 连接验证（往返 + 同名房间区分） |
| 最后更新 | 2026-04-16 |

## 一句话结论

用 **房间名 + 出口签名** 做唯一标识，统一 brief/完整模式出口格式（`和 ` → `、`，`。` → 空，去除连续 `、`），引入 `old_room` 区别于 `prev_room`，在 `m_resolve_uid` 之前保存旧房间 UID。

## 关键发现

### 1. 原邻居指纹系统根本无法处理回访

原设计：记录 `(prev_room, prev_direction) → room_uid`，回访时查找 `(prev_room, prev_direction)`。问题：

```
从 A 向 north 到 B：记录 (A, north) → B
从 B 向 south 回 A：查找 (B, south) ❌ 不匹配
```

反向移动的方向完全不同，回访永远失败，导致同名房间被错误标记 `~1`、`~2`。

### 2. brief 模式和完整模式出口格式不一致

| 模式 | 出口格式 | 规范化后 |
|------|---------|---------|
| brief | `east、north、south、west` | `east、north、south、west` |
| 完整 | `east、north、south 和 west。` | `east、north、south、west` ✓ |

完整模式用 `和 ` 连接最后一个方向 + 句号，brief 用顿号。如果不统一，相同房间被识别为不同 UID。

**规范化步骤**：
```tt
#replace {uid_exits} {和 } {、};
#replace {uid_exits} {。} {};
#replace {uid_exits} { } {、};
#replace {uid_exits} {、、} {、};
```

**坑点**：`south 和 west` → `south、west`（空格被替换为顿号），但如果原文 `east、north、south、southeast 和 west` 中的 `southeast` 前面已有顿号，替换后会产生 `southeast、、west`（连续顿号），需要再去除。

### 3. `prev_room` 在 `m_resolve_uid` 之前被更新

原始代码流程：
```tt
#action {^{.+} - {.+}$} {
    m_flush_npcs {$room_uid};
    #variable {prev_room} {$room_uid};  ← 先更新
    m_resolve_uid {%1};                 ← 此时 prev_room 已经是新值
    m_autosave;                         ← prev_room == room_uid，永远为真
}
```

`m_record_edge` 检查 `prev_room != room_uid` 永远失败，edges.txt 永远不记录。

**修复**：引入 `old_room` 变量，在 `m_resolve_uid` 之前保存：
```tt
#variable {old_room} {$room_uid};
m_resolve_uid {%1};
m_autosave;
#variable {prev_room} {$room_uid}
```

### 4. 完整模式出口行在 `m_resolve_uid` 之后才收到

完整模式的时序：
```
[服务器] 房间名 -                         ← 房间 action 触发，但出口未知
[服务器] 这里明显的出口是 east、north...  ← 出口 action 触发
```

如果在房间 action 中调用 `m_resolve_uid`，`current_room_exits_brief` 还为空，只能用 `current_room_exits`（空），导致 `uid_exits` 为空字符串，所有同名房间都匹配失败。

**修复**：完整模式暂存房间名到 `pending_room`，在出口 action 中才调用 `m_resolve_uid`：
```tt
#action {^{.+} -%s} {
    #if {"$map_active" == "1"} {
        #variable {pending_room} {%1}
    }
}

#action {这里明显的出口是 {.+}} {
    #variable {current_room_exits} {%1};
    #if {"$map_active" == "1"} {
        #variable {old_room} {$room_uid};
        m_resolve_uid {$pending_room};  ← 此时 exits 已设置
        m_autosave
    }
}
```

### 5. 同名房间通过出口差异区分

| 房间名 | 出口 | UID |
|--------|------|-----|
| 东大街 | `east、north、south、southeast、west` | 东大街 |
| 东大街 | `east、north、south、west` | 东大街~1 |

**局限**：出口完全相同的同名房间仍会被识别为同一房间。这是当前设计的可接受限制（需要坐标/序号才能彻底解决）。

## 已验证的正确方案

```tt
; 变量初始化
#variable {room_uid} {}
#variable {old_room} {}
#variable {pending_room} {}
#variable {uid_map_count} {0}

; UID 解析：使用房间名+出口签名
#ALIAS m_resolve_uid {
    #variable {raw_name} {%1};
    #if {"$raw_name" == ""} {
        #variable {room_uid} {};
        #return
    };
    #variable {uid_exits} {};
    #if {"$current_room_exits_brief" != ""} {
        #variable {uid_exits} {$current_room_exits_brief}
    } {
        #variable {uid_exits} {$current_room_exits}
    };
    #replace {uid_exits} {和 } {、};
    #replace {uid_exits} {。} {};
    #replace {uid_exits} { } {、};
    #replace {uid_exits} {、、} {、};
    #math {uid_total} {$uid_map_count};
    #loop {1} {$uid_total} {i} {
        #if {"$uid_map[$i][1]" == "$raw_name" && "$uid_map[$i][2]" == "$uid_exits"} {
            #variable {room_uid} {$uid_map[$i][3]};
            #return
        }
    };
    #math {name_count} {0};
    #loop {1} {$uid_total} {i} {
        #if {"$uid_map[$i][1]" == "$raw_name"} {
            #math {name_count} {$name_count + 1}
        }
    };
    #if {"$name_count" == "0"} {
        #variable {room_uid} {$raw_name}
    } {
        #format {room_uid} {%s~%d} {$raw_name} {$name_count}
    };
    #math {uid_map_count} {$uid_map_count + 1};
    #math {idx} {$uid_map_count};
    #variable {uid_map[$idx][1]} {$raw_name};
    #variable {uid_map[$idx][2]} {$uid_exits};
    #variable {uid_map[$idx][3]} {$room_uid}
}

; brief 模式
#action {^{.+} - {.+}$} {
    #if {"$map_active" == "1"} {
        m_flush_npcs {$room_uid};
        #variable {old_room} {$room_uid};
        #variable {current_room_exits_brief} {%2};
        m_resolve_uid {%1};
        #showme <158>[地图] 房间: %1 → $room_uid (brief模式);
        #showme <158>[地图] 出口: %2;
        m_autosave;
        #variable {prev_room} {$room_uid}
    }
}

; 完整模式：暂存房间名
#action {^{.+} -%s} {
    #if {"$map_active" == "1"} {
        #variable {pending_room} {%1}
    }
}

; 完整模式出口行：此时才调用 m_resolve_uid
#action {这里明显的出口是 {.+}} {
    #variable {current_room_exits} {%1};
    #if {"$map_active" == "1"} {
        #variable {old_room} {$room_uid};
        m_resolve_uid {$pending_room};
        m_autosave;
        #variable {prev_room} {$room_uid}
    }
}

#action {这里唯一的出口是 {.+}} {
    #variable {current_room_exits} {%1};
    #if {"$map_active" == "1"} {
        #variable {old_room} {$room_uid};
        m_resolve_uid {$pending_room};
        m_autosave;
        #variable {prev_room} {$room_uid}
    }
}

; 边记录：用 old_room 而不是 prev_room
#ALIAS m_record_edge {
    #if {"$old_room" != "" && "$old_room" != "$room_uid"} {
        #line log {map_data/raw/edges.txt} {$old_room|$prev_direction|$room_uid}
    }
}
```

## 踩过的坑

| 坑 | 耗时 | 表现 |
|----|------|------|
| 邻居指纹回访逻辑 | ~3h | `(prev_room, prev_direction)` 无法处理反向移动，所有回访都变成新房间 `~1` |
| 完整/ brief 出口格式不统一 | ~2h | `和` vs `、` + `。` 导致相同房间 UID 不匹配 |
| `southeast、、west` 连续顿号 | ~1h | `和 ` 替换为 `、` 时，如果前面已有顿号会产生连续顿号 |
| `prev_room` 先于 `m_resolve_uid` 更新 | ~30min | `m_record_edge` 永远不记录（`prev_room == room_uid`） |
| 完整模式在房间行立即 resolve | ~20min | `current_room_exits` 为空，`uid_exits` 为空字符串，匹配失败 |
| edges.txt 不记录边 | ~40min | 检查了半天才发现是 `prev_room` 时机问题 |

## 验证方式

```bash
# 连接 MUD，往返移动几次
./tintin_wrapper.sh start
./tintin_wrapper.sh send conn
./tintin_wrapper.sh send 'm_go north'
./tintin_wrapper.sh send 'm_go north'
./tintin_wrapper.sh send 'm_go south'
./tintin_wrapper.sh send 'm_go south'

# 检查 edges.txt
cat map_data/raw/edges.txt
# 期望输出：
# 广场南|north|中央广场
# 中央广场|north|广场北
# 广场北|south|中央广场
# 中央广场|south|广场南  ← 回访，UID 一致

# 检查 exits 文件
ls map_data/raw/*.exits
cat map_data/raw/*.exits
# 期望：无 `~1` 等错误后缀（除非出口真的不同）

# 停止
./tintin_wrapper.sh stop
```
