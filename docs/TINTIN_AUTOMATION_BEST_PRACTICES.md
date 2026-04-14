# Tintin++ 自动化最佳实践

> 从零开始构建可靠的 MUD 自动化脚本

发布于：2026-04-14 | 标签：#tutorial #automation #tintin

---

## 前言

Tintin++ 是最强大的 MUD 客户端之一，但它的学习曲线陡峭。本文总结了我在构建书剑 MUD 自动化脚本时学到的经验和教训，帮助你避免常见的陷阱。

---

## 核心原则

### 1. 安全第一

**永远不要在脚本中硬编码密码。**

```tintin
# ❌ 错误：密码明文存储
#var {password} {my_secret_password}

# ✅ 正确：使用环境变量
#script {python3} {
import os
tintin.eval(f"#var {{password}} {{{os.environ.get('MUD_PASSWORD')}}}")
}
```

### 2. 模块化设计

将功能拆分成独立的模块，每个模块负责一件事：

```
main.tt           -- 主入口，协调各模块
├── login.tt      -- 登录管理
├── mapper.tt     -- 地图采集
├── combat.tt     -- 战斗系统
└── logger.tt     -- 日志记录
```

### 3. 渐进式开发

不要一开始就追求完美。先让基础功能跑起来，再逐步优化：

1. **Week 1**: 基础别名和触发
2. **Week 2**: 登录自动化
3. **Week 3**: 地图采集
4. **Week 4+**: 高级功能（寻路、战斗自动化）

---

## 常见陷阱与解决方案

### 陷阱 1：正则表达式分组

Tintin++ 使用 `{}` 而非 `()` 进行分组：

```tintin
# ❌ 错误：括号分组
#action {^你看到了 ([A-Z][a-z]+)$} {
    #showme NPC: %1
}

# ✅ 正确：花括号分组
#action {^你看到了 ({%w+})$} {
    #showme NPC: %1
}
```

### 陷阱 2：前导空格被 strip

MUD 输出的前导空格会被 Tintin++ 移除：

```tintin
# ❌ 这个永远不会匹配（因为前导空格没了）
#action {^  (%*)({%w+})$} {
    #list {npcs} {add} {%1(%2)}
}

# ✅ 改为匹配行尾
#action {^{%*}({%w%S%*})$} {
    #list {npcs} {add} {%1}
}
```

### 陷阱 3：GBK 编码问题

中文 MUD 使用 GBK 编码，需要转换：

```tintin
# 在脚本开头设置
#config charset GBK1TOUTF8

# 但要注意：行尾空格会影响转换
# $ 在行尾时可能无法正确匹配
```

### 陷阱 4：Action 顺序很重要

更具体的模式要先匹配：

```tintin
# ✅ 正确顺序：具体 → 通用
#action {^店小二笑着说(.*)$} {
    #showme 店小二: %1
}
#action {^(%*)说(.*)$} {
    #showme %1 说: %2
}

# ❌ 错误顺序：通用模式会吞噬所有
#action {^(%*)说(.*)$} { ... }
#action {^店小二笑着说(.*)$} { ... }  # 永远不会触发
```

---

## 测试策略

### 单元测试

使用 Mock MUD Server 测试触发和动作：

```python
# mock_mud_server.py
import socket
import threading

def send_room_output(client):
    client.send(b"这里是中央广场。\n")
    client.send(b"这里明显的出口是 north south east west。\n")
    client.send(b"店小二(shopkeeper)\n")
```

```bash
# 测试脚本
#session test localhost 9999
#delay 1
look
#wait 5
#end
```

### 集成测试

完整流程测试：

```bash
./tests/run_all_tests.sh
```

---

## 性能优化

### 1. 减少不必要的触发

```tintin
# ❌ 每行都检查
#action {%*} {
    #if {"$map_active" == "1"} {
        #do_something
    }
}

# ✅ 只在需要时激活
#action {^你来到了 (.+)$} {
    #if {"$map_active" == "1"} {
        #do_something
    }
}
```

### 2. 使用 gag 隐藏垃圾输出

```tintin
#gag {^☆ 这是系统消息}
#gag {^○ 这是提示}
```

### 3. 批量处理

```tintin
# ❌ 逐个发送
north; east; south; west

# ✅ 使用循环
#loop {4} {#showme $i}
```

---

## 调试技巧

### 1. 使用 #showme 输出调试信息

```tintin
#action {^你来到了 (.+)$} {
    #showme <158>[DEBUG] 进入房间: %1
    #showme <158>[DEBUG] prev_room: $prev_room
}
```

### 2. 使用 #line capture 捕获输出

```tintin
#line capture {debug}
look
#line capture {debug} off

#showme <158>捕获到的内容：
#list {debug} {show}
```

### 3. 分阶段启用功能

```tintin
# 开发阶段注释掉不需要的功能
#read login.tt
#read mapper.tt
#read combat.tt
```

---

## 后台运行最佳实践

使用 tmux 保持会话持久化：

```bash
# 启动后台会话
tmux new -s tintin tt++ main.tt

# 脱离会话
# 按 Ctrl+B 然后 D

# 重新连接
tmux attach -t tintin
```

**关键点**：
- ✅ 使用 tmux 而非 nohup
- ✅ 定期保存地图数据
- ✅ 设置自动重连
- ✅ 监控日志文件

---

## 地图系统设计

### 数据结构

使用图结构表示地图：

```json
{
  "room": "中央广场",
  "exits": ["north", "south", "east", "west"],
  "edges": {
    "north": "书店",
    "south": "城门",
    "east": "客栈",
    "west": "兵器铺"
  },
  "npcs": ["店小二(shopkeeper)"]
}
```

### 自动寻路

使用 BFS 算法：

```python
from collections import deque

def bfs_shortest_path(graph, start, end):
    queue = deque([(start, [])])
    visited = set()

    while queue:
        room, path = queue.popleft()
        if room == end:
            return path

        for direction, neighbor in graph[room]["edges"].items():
            if neighbor not in visited:
                visited.add(neighbor)
                queue.append((neighbor, path + [direction]))
```

---

## 进阶技巧

### 1. 状态机

使用状态机管理复杂流程：

```tintin
#variable {state} {IDLE}
#variable {state} {HUNTING}
#variable {state} {FLEEING}

#action {^你战胜了敌人！$} {
    #if {"$state" == "HUNTING"} {
        #var {state} {IDLE};
        loot
    }
}
```

### 2. 定时器

```tintin
#delay 60 {
    #showme <138>已连接 60 分钟
    save
}
```

### 3. 事件系统

```tintin
#action {^世界频道：(.*)$} {
    #format {world_chat} {%1} {%time};
    #list {chat_history} {add} {%1}
}
```

---

## 资源推荐

### 官方文档
- [Tintin++ 官网](https://tintin.sourceforge.io/)
- [Tintin++ 手册](https://tintin.sourceforge.io/manual/)

### 本项目资源
- [数据胶囊](wiki/capsules/) - 经过验证的经验
- [Examples](examples/) - 开箱即用的配置
- [测试框架](tests/) - 学习如何测试

### 社区
- [GitHub Issues](https://github.com/dr4g00n/drag00n-just4fun/issues) - 提问
- [GitHub Discussions](https://github.com/dr4g00n/drag00n-just4fun/discussions) - 讨论

---

## 结语

Tintin++ 自动化是一个持续改进的过程。从简单的别名开始，逐步构建复杂的系统。记住：

> **完美是完成的敌人。**

先让它跑起来，再优化。

---

**有问题？** 在 [Issues](https://github.com/dr4g00n/drag00n-just4fun/issues) 提问

**有想法？** 在 [Discussions](https://github.com/dr4g00n/drag00n-just4fun/discussions) 讨论

**喜欢这个项目？** 给个 ⭐️ Star！

---

<div align="center">

**Happy MUDing! 🎮**

</div>
