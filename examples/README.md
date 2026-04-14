# Examples 目录

这里提供了各种开箱即用的配置示例，帮助你快速上手 Tintin++ MUD 自动化。

## 📁 文件列表

| 文件 | 说明 | 适用场景 |
|-----|------|---------|
| **basic_usage.tt** | 基础使用示例 | 新手入门，学习基本语法 |
| **advanced_mapper.tt** | 高级地图配置 | 需要高级地图功能 |
| **custom_login.tt** | 自定义登录模板 | 多账号、不同 MUD 服务器 |

---

## 🚀 快速使用

### 1. 基础使用示例

适合刚接触 Tintin++ 的玩家：

```bash
# 复制到主目录
cp examples/basic_usage.tt ~/my_mud.tt

# 启动 Tintin++
tt++ ~/my_mud.tt

# 在 tt++ 中查看帮助
help_examples
```

**包含内容**：
- 快捷别名（look_room, status, inventory）
- 简单战斗命令（kill, flee）
- 基础触发（聊天高亮、受伤警告）

### 2. 高级地图配置

需要完整地图功能的玩家：

```bash
# 修改主脚本，加载高级地图配置
echo "#read examples/advanced_mapper.tt" >> main.tt

# 启动后查看帮助
tt++ main.tt
help_mapper
```

**包含内容**：
- 区域标记（安全、危险、重要地点）
- 路径记录与回放
- 自动寻路（需要 Python 导航脚本）
- NPC 追踪功能
- 地图统计与导出

### 3. 自定义登录模板

多账号或不同 MUD 服务器的玩家：

```bash
# 复制并修改模板
cp examples/custom_login.tt ~/my_login.tt

# 编辑模板，修改用户名密码
vim ~/my_login.tt

# 在主脚本中加载
echo "#read ~/my_login.tt" >> main.tt
```

**包含内容**：
- 环境变量登录（推荐，安全）
- 交互式登录（调试用）
- 多账号快速切换
- 不同 MUD 服务器配置
- 自动重连
- 登录后自动执行命令

---

## 📖 使用技巧

### 组合使用示例

你可以组合多个示例：

```tintin
# 主脚本 main.tt
# 读取基础功能
#read examples/basic_usage.tt

# 读取登录配置
#read examples/custom_login.tt

# 读取高级地图
#read examples/advanced_mapper.tt
```

### 自定义修改

所有示例都是可以自由修改的：

1. **复制示例**到你的工作目录
2. **修改内容**满足你的需求
3. **在主脚本中加载**

```tintin
# 在 main.tt 中
#read ~/my_custom_config.tt
```

---

## 🎓 学习路径

**新手建议顺序**：

1. **第一步**：学习 `basic_usage.tt`
   - 理解别名（#ALIAS）
   - 理解触发（#action）
   - 理解变量（#var）

2. **第二步**：尝试 `custom_login.tt`
   - 环境变量管理
   - 条件判断（#if）
   - 脚本执行（#script）

3. **第三步**：探索 `advanced_mapper.tt`
   - 列表操作（#list）
   - 系统调用（#system）
   - 复杂触发链

---

## 💡 常见问题

**Q: 如何在自己的脚本中使用这些示例？**

A: 在你的主脚本中使用 `#read` 命令：
```tintin
#read examples/basic_usage.tt
```

**Q: 可以修改这些示例吗？**

A: 当然！建议先复制到你的目录，然后修改：
```bash
cp examples/basic_usage.tt my_basic.tt
# 然后修改 my_basic.tt
```

**Q: 高级地图功能需要 Python 吗？**

A: 是的，自动寻路和 NPC 追踪需要 Python 3 和 `map_data/` 下的脚本。

**Q: 如何测试我的配置？**

A: 使用 Mock MUD Server 进行测试：
```bash
./tests/run_mapper_tests.sh
```

---

## 📚 更多资源

- [主 README](../README.md) - 项目总览
- [数据胶囊](../wiki/index.md) - 最佳实践知识库
- [测试框架](../tests/) - 自动化测试
- [README_DAEMON](../README_DAEMON.md) - 后台运行说明

---

## 🤝 贡献

有好的示例想分享？欢迎提交 PR！

**贡献指南**：
1. 在 `examples/` 创建新文件
2. 添加详细注释
3. 在本 README 中注册
4. 确保代码可运行

---

<div align="center">

**Happy MUDing! 🎮**

</div>
