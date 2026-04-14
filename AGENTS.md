# AGENTS.md — AI Agent 工作指南

## 项目概述

书剑 MUD (tj.sjever.net:5555) 的 Tintin++ 自动化脚本。核心功能是地图采集、自动登录、后台运行。

## 技术栈

- **Tintin++ 2.02.00+** — MUD 客户端，执行 `.tt` 脚本
- **tmux** — 终端复用，让 tt++ 后台持久运行
- **Python 3** — 地图数据处理（`map_data/map_navigator.py`、`map_data/map_save.py`）
- **GBK→UTF-8** — MUD 服务器使用 GBK 编码，tt++ 用 `#config charset GBK1TOUTF8` 转换

## 架构

```
外部操作层
  ├── ./tt.sh                      # 一键启动（tmux 前台）
  ├── ./tintin_wrapper.sh          # 完整控制（start/stop/send/attach）
  └── tmux send-keys / capture-pane # 底层交互原语

tmux 层（session: "tintin"）
  └── tt++ main.tt                 # Tintin++ 进程
        ├── #read login.tt         # 自动登录
        ├── alias: conn, login, m_go, m_walk, m_save...
        ├── action: 房间名/出口/NPC/提示符 正则匹配
        └── #session sj            # TCP 连接到 MUD 服务器

网络层
  ├── tj.sjever.net:5555           # 真实 MUD
  └── 127.0.0.1:<port>            # mock_mud_server.py（测试用）

数据层
  ├── map_data/raw/*.exits         # 房间出口（tt++ 自动采集）
  ├── map_data/raw/*.npcs          # NPC 列表（tt++ 自动采集）
  ├── map_data/raw/edges.txt       # 房间间的方向关系
  └── map_data/*.json              # map_save.py 后处理输出
```

## 交互方式

### 发送命令到 tt++

```bash
./tintin_wrapper.sh send 'look'     # 推荐
tmux send-keys -t tintin 'look' C-m # 底层等价
```

### 获取 tt++ 输出

```bash
tmux capture-pane -t tintin -p -S -50  # 获取最近 50 行输出
./tintin_wrapper.sh attach             # 交互式连接（需要 TTY）
```

### 读取持久化数据

tt++ 通过 `#line log` 和 `#system echo` 将数据写入 `map_data/raw/` 目录。
地图数据后处理：`python3 map_data/map_save.py`

## 测试

```bash
./tests/run_all_tests.sh        # 全部测试
./tests/run_mapper_tests.sh     # 地图采集测试
./tests/run_subsystem_tests.sh  # 登录/dream 测试
```

测试原理：用 `mock_mud_server.py` 在本地端口模拟 MUD 服务器，发送预设样本文件，
tt++ 通过 action 正则匹配捕获变量，断开时将变量写入结果文件，测试脚本断言结果。

## 常用操作

```bash
# 启动
./tintin_wrapper.sh start

# 连接 MUD
./tintin_wrapper.sh send 'login'
./tintin_wrapper.sh send 'conn'

# 地图采集
./tintin_wrapper.sh send 'm_go north'
./tintin_wrapper.sh send 'm_save'
./tintin_wrapper.sh send 'm_list'

# 停止
./tintin_wrapper.sh stop
```

## Lint / 验证命令

```bash
python3 map_data/map_navigator.py list      # 列出所有房间
python3 map_data/map_navigator.py unvisited  # 未完全探索的房间
python3 map_data/map_save.py --dry-run       # 预览数据处理
```

## 注意事项

### 同名房间问题
东大街、西大街、北大街、南大街都有多段同名房间。当前系统用房间名做文件名，
同名会互相覆盖。后续需要引入坐标/序号区分。

### GBK 编码陷阱
MUD 发送的 GBK 文本转 UTF-8 后会在行尾残留空格。main.tt 用 `%s` 匹配，
测试脚本用 `-$`，两者行为略有差异。详见 `wiki/capsules/tintin++-gbk-encoding-pitfalls.md`。

### .env 文件
登录凭据存放在项目根目录 `.env`，格式：
```
MUD_USERNAME=your_name
MUD_PASSWORD=your_password
```
**永远不要提交 .env 到 git**。

## 代码风格

- `.tt` 文件：分号分隔语句，`#showme` 用于调试输出
- Python：标准库优先，无第三方依赖
- Shell：`set -eo pipefail`，用 `$(dirname "$0")` 获取路径，不硬编码
