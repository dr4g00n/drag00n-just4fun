# Tintin++ 自动化最佳实践分享 🎮

刚完成了一个 Tintin++ MUD 自动化脚本项目，想分享一些经验，帮助新手避免常见陷阱。

## 项目简介

为书剑 MUD 打造的自动化解决方案：
- 🗺️ 自动地图采集
- 🔐 环境变量登录
- 🔄 后台持久运行（tmux）
- 🧪 完整测试框架
- 💊 数据胶囊系统

仓库：https://github.com/dr4g00n/drag00n-just4fun

---

## 核心经验

### 1. 安全第一

❌ 不要硬编码密码：
```tintin
#var {password} {my_secret}
```

✅ 使用环境变量：
```tintin
#script {python3} {
import os
tintin.eval(f"#var {{password}} {{{os.environ.get('MUD_PASSWORD')}}}")
}
```

### 2. 注意正则语法

Tintin++ 用 `{}` 分组，不是 `()`：

```tintin
# ✅ 正确
#action {^你看到了 ({%w+})$} {
    #showme NPC: %1
}
```

### 3. 前导空格被 strip

```tintin
# 这个不会匹配（空格被移除了）
#action {^  (%*)({%w+})$} { ... }

# 改为匹配行尾
#action {^{%*}({%w%S%*})$} { ... }
```

### 4. Action 顺序重要

具体模式要先匹配：

```tintin
# ✅ 正确顺序
#action {^店小二笑着说(.*)$} { ... }
#action {^(%*)说(.*)$} { ... }
```

### 5. 后台运行用 tmux

```bash
# 启动
tmux new -s tintin tt++ main.tt

# 脱离（保持运行）
# Ctrl+B 然后 D

# 重连
tmux attach -t tintin
```

---

## 常见问题

**Q: 如何测试触发？**

A: 用 Mock Server：
```python
# mock_mud_server.py
import socket
server = socket.socket()
server.bind(('localhost', 9999))
server.listen(1)
# ... 发送测试数据
```

**Q: 中文乱码？**

A: 设置编码：
```tintin
#config charset GBK1TOUTF8
```

**Q: 如何调试？**

A: 用 #showme：
```tintin
#action {^你来到了 (.+)$} {
    #showme <158>[DEBUG] 房间: %1
}
```

---

## 项目特色

### 完整测试框架
业界罕见的 Tintin++ 自动化测试

### 数据胶囊系统
AI 友好的知识沉淀，快速获取最佳实践

### 开箱即用
```bash
git clone https://github.com/dr4g00n/drag00n-just4fun.git
cd drag00n-just4fun
cp .env.example .env
# 编辑 .env 填入凭据
./tt.sh
```

---

## 下一步计划

- [ ] Web 地图可视化
- [ ] 战斗自动化
- [ ] 支持更多 MUD 服务器

欢迎贡献！🤝

---

**相关链接**

- 项目：https://github.com/dr4g00n/drag00n-just4fun
- Examples：https://github.com/dr4g00n/drag00n-just4fun/tree/main/examples
- 数据胶囊：https://github.com/dr4g00n/drag00n-just4fun/tree/main/wiki

---

**有疑问？** 欢迎留言讨论！ 👇

标签：`#tutorial` `#automation` `#tintin` `#mud`
