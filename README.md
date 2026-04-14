# Tintin++ MUD 自动化脚本

> 为书剑 MUD 打造的 Tintin++ 自动化解决方案 —— 地图采集、自动登录、后台运行，开箱即用

[![Tests](https://img.shields.io/badge/tests-passing-brightgreen)](tests/)
[![Tintin++](https://img.shields.io/badge/Tintin++-2.02.00+-blue)](https://tintin.sourceforge.io/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## ✨ 核心功能

| 功能 | 说明 |
|-----|------|
| 🗺️ **自动地图采集** | 实时采集房间信息、出口、NPC 数据，自动保存为结构化格式 |
| 🔐 **安全登录管理** | 环境变量存储凭据，支持一键登录，避免密码泄露 |
| 🔄 **后台持久运行** | 基于 tmux 的后台运行方案，断线重连无忧 |
| 📊 **结构化日志** | JSON 格式日志输出，便于后续分析和 AI 处理 |
| 🧪 **完整测试框架** | 包含 Mock MUD Server 和自动化测试 |
| 💊 **数据胶囊系统** | AI 友好的知识沉淀，快速获取最佳实践 |

---

## 🚀 快速开始

### 前置要求

- macOS / Linux
- Tintin++ 2.02.00+
- tmux

### 安装

```bash
# 克隆仓库
git clone https://github.com/dr4g00n/drag00n-just4fun.git
cd drag00n-just4fun

# 安装 Tintin++ (macOS)
brew install tintin++

# 或 Linux
sudo apt-get install tintin++
```

### 配置

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑 .env 文件，填入你的 MUD 凭据
vim .env
```

`.env` 文件内容：
```bash
MUD_USER=你的用户名
MUD_PASSWORD=你的密码
```

### 启动

**方式一：一键启动（推荐）**
```bash
./tt.sh
```

**方式二：完整控制**
```bash
# 启动后台会话
./tintin_wrapper.sh start

# 连接 MUD
./tintin_wrapper.sh send 'login'
./tintin_wrapper.sh send 'conn'

# 查看运行状态
./tintin_wrapper.sh status

# 连接到会话（交互）
./tintin_wrapper.sh attach

# 停止会话
./tintin_wrapper.sh stop
```

### 首次连接

```bash
# 启动后，在 tt++ 中执行：
login          # 加载凭据
conn           # 连接书剑 MUD
```

---

## 📁 目录结构

```
drag00n-just4fun/
├── main.tt              # 主脚本入口（地图 action + alias）
├── mapper.tt            # 地图采集子系统
├── login.tt             # 自动登录
├── dream.tt             # 梦见石传送
├── logger_v2.tt         # 日志系统
├── tintin_wrapper.sh    # tmux 后台会话管理
├── .env.example         # 环境变量模板
├── tests/               # 测试框架
│   ├── run_all_tests.sh
│   ├── mock_mud_server.py
│   └── samples/         # 测试样本
├── wiki/                # 数据胶囊
│   ├── index.md         # 胶囊索引
│   └── capsules/        # 经验知识库（6 个胶囊）
├── map_data/            # 地图数据
│   ├── raw/             # tt++ 采集的原始数据（.exits / .npcs / edges.txt）
│   ├── map_navigator.py # BFS 寻路 + NPC 查询引擎
│   └── map_save.py      # raw 数据 → 标准 JSON 后处理
└── README_DAEMON.md     # 后台运行详细说明
```

---

## 📖 使用指南

### 地图采集

地图系统会自动采集以下信息：
- 房间名称
- 可用出口
- NPC 列表（中文名 + 英文 ID）

**查看当前状态**：
```bash
# 在 tt++ 中执行：
map_info
```

**地图数据保存位置**：`map_data/raw/`

### 后台运行

基于 tmux 的后台运行方案，即使关闭终端也会保持连接。

**tmux 快捷键**：
| 按键 | 功能 |
|------|------|
| `Ctrl+B` 然后 `D` | 脱离会话（保持运行） |
| `Ctrl+B` 然后 `[` | 进入滚动模式（查看历史） |
| `Ctrl+B` 然后 `0-9` | 切换窗口 |

详细说明请参考 [README_DAEMON.md](README_DAEMON.md)

---

## 🧪 测试

```bash
# 运行所有测试
./tests/run_all_tests.sh

# 运行地图系统测试
./tests/run_mapper_tests.sh

# 运行子系统测试
./tests/run_subsystem_tests.sh
```

---

## 💡 数据胶囊

数据胶囊是经过验证的经验压缩包，供 AI 快速获取项目特定领域的非显而易见知识。

查看 [数据胶囊索引](wiki/index.md)

| 胶囊 | 主题 |
|------|------|
| [tintin++-macos-testing](wiki/capsules/tintin++-macos-testing.md) | Tintin++ 自动化测试最佳实践 |
| [tintin++-regex-syntax](wiki/capsules/tintin++-regex-syntax.md) | Tintin++ 正则表达式语法与陷阱 |
| [tintin++-mud-display-modes](wiki/capsules/tintin++-mud-display-modes.md) | MUD 显示模式差异 |
| [tintin++-test-framework](wiki/capsules/tintin++-test-framework.md) | 测试框架架构 |
| [tintin++-gbk-encoding-pitfalls](wiki/capsules/tintin++-gbk-encoding-pitfalls.md) | GBK→UTF8 编码转换陷阱（行尾空格、`$` 失效） |
| [tintin++-action-state-management](wiki/capsules/tintin++-action-state-management.md) | Action 时序与状态管理（NPC flush、变量展开、登录保护） |

---

## 🤝 贡献

欢迎贡献！请遵循以下流程：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📝 待办事项

- [x] 自动寻路功能（BFS 最短路径）
- [x] NPC 查询定位
- [ ] 支持更多 MUD 服务器
- [ ] Web 地图可视化界面
- [ ] 战斗自动化
- [ ] 自动探索未知区域

---

## ❓ 常见问题

**Q: 支持哪些 MUD 服务器？**
A: 当前主要支持书剑 MUD (tj.sjever.net:5555)，理论上支持所有标准 MUD 协议的服务器。

**Q: 如何修改 MUD 服务器地址？**
A: 编辑 `main.tt`，修改 `mud_host` 和 `mud_port` 变量。

**Q: 地图数据在哪里？**
A: 保存在 `map_data/raw/` 目录，JSON 格式。

**Q: 可以同时连接多个 MUD 吗？**
A: 可以，复制 `main.tt` 并修改配置，创建多个独立的会话。

---

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- [Tintin++](https://tintin.sourceforge.io/) - 强大的 MUD 客户端
- [书剑 MUD](http://tj.sjever.net/) - 优秀的 MUD 服务器
- 所有贡献者和使用者

---

## 📮 联系方式

- 问题反馈：[GitHub Issues](https://github.com/dr4g00n/drag00n-just4fun/issues)
- 功能建议：[GitHub Discussions](https://github.com/dr4g00n/drag00n-just4fun/discussions)

---

<div align="center">

**如果这个项目对你有帮助，请给一个 ⭐️ Star！**

</div>
