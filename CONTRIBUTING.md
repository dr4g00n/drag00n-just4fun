# 贡献指南

感谢你考虑为 Tintin++ MUD 自动化脚本项目做出贡献！🎉

---

## 🤝 如何贡献

### 报告 Bug

如果你发现了 Bug：

1. 检查 [Issues](https://github.com/dr4g00n/drag00n-just4fun/issues) 是否已有相同问题
2. 如果没有，创建新 Issue，使用 **Bug 报告** 模板
3. 提供详细信息：
   - 复现步骤
   - 预期行为 vs 实际行为
   - 环境信息（OS、Tintin++ 版本）
   - 相关日志或截图

### 提出功能建议

1. 先在 [Discussions](https://github.com/dr4g00n/drag00n-just4fun/discussions) 讨论你的想法
2. 创建 Issue，使用 **功能请求** 模板
3. 说明：
   - 这个功能解决什么问题
   - 你希望的实现方式
   - 是否愿意自己实现

### 提交代码

1. **Fork** 本仓库
2. **创建分支** (`git checkout -b feature/AmazingFeature`)
3. **提交更改** (`git commit -m 'Add some AmazingFeature'`)
4. **推送到分支** (`git push origin feature/AmazingFeature`)
5. **开启 Pull Request**

---

## 📝 代码规范

### Tintin++ 脚本规范

```tintin
# 1. 使用详细的注释
# 这是一个很好的示例，说明了这个 alias 的用途
#ALIAS look {
    look
}

# 2. 使用有意义的变量名
# ✅ 好
#variable {current_room_name} {中央广场}

# ❌ 不好
#variable {x} {中央广场}

# 3. 复杂逻辑添加调试输出
#action {^你来到了 (.+)$} {
    #showme <158>[DEBUG] 进入房间: %1;
    #处理房间信息
}

# 4. 提供帮助命令
#ALIAS help_my_feature {
    #showme <138>我的功能说明...
}
```

### Python 脚本规范

```python
# 1. 添加文档字符串
def bfs_shortest_path(graph, start, end):
    """
    使用 BFS 算法查找最短路径

    Args:
        graph: 地图图结构
        start: 起点房间名
        end: 终点房间名

    Returns:
        list: 方向列表，如 ['north', 'east']
    """
    pass

# 2. 添加类型提示
from typing import Dict, List

def find_npc(npcs: List[str], keyword: str) -> List[str]:
    """查找包含关键词的 NPC"""
    pass

# 3. 使用有意义的变量名
# ✅ 好
current_room_exits = room_data.get("exits", [])

# ❌ 不好
x = room_data.get("exits", [])
```

---

## 🧪 测试

### 修改代码前

1. 运行现有测试确保通过：
   ```bash
   ./tests/run_all_tests.sh
   ```

2. 如果添加新功能，编写对应的测试

### 测试框架

- **Mock MUD Server**：`tests/mock_mud_server.py`
- **测试样本**：`tests/samples/`
- **测试脚本**：`tests/run_*.sh`

---

## 📚 文档

### 修改文档时

1. 保持格式一致
2. 使用清晰的标题结构
3. 添加示例代码
4. 更新相关链接

### 文档位置

- **README.md**：项目总览
- **examples/README.md**：示例说明
- **wiki/**：数据胶囊
- **docs/**：技术文章

---

## 💡 Good First Issues

适合新手的任务（标记为 `good first issue`）：

- 添加新的 MUD 服务器配置示例
- 修复文档错别字或格式问题
- 添加新的别名示例
- 补充测试用例
- 翻译文档到其他语言

查看 [Issues](https://github.com/dr4g00n/drag00n-just4fun/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)

---

## 🎯 贡献类型

欢迎以下类型的贡献：

| 类型 | 说明 | 示例 |
|-----|------|------|
| **代码** | 修复 Bug、添加功能 | 修复登录问题 |
| **文档** | 改进说明、添加示例 | 补充 README |
| **测试** | 增加测试覆盖 | 添加边界情况测试 |
| **翻译** | 多语言支持 | 英文版 README |
| **示例** | 新增配置示例 | 不同 MUD 的配置 |
| **Bug 报告** | 发现问题 | 提交详细 Issue |
| **功能建议** | 改进想法 | Discussions 讨论 |

---

## 📧 联系方式

- **Issues**：[https://github.com/dr4g00n/drag00n-just4fun/issues](https://github.com/dr4g00n/drag00n-just4fun/issues)
- **Discussions**：[https://github.com/dr4g00n/drag00n-just4fun/discussions](https://github.com/dr4g00n/drag00n-just4fun/discussions)

---

## 📜 行为准则

1. **尊重他人**：友善、包容
2. **建设性沟通**：关注问题，不是人
3. **接受反馈**：虚心接受建议
4. **乐于助人**：帮助新贡献者

---

## ✍️ License

贡献的代码将采用与项目相同的 [MIT License](LICENSE)

---

## 🌟 致谢

感谢所有贡献者！你的贡献让这个项目变得更好。

---

<div align="center">

** Happy Contributing! **

**有问题？** [开启 Issue](https://github.com/dr4g00n/drag00n-just4fun/issues/new)

**想讨论？** [加入 Discussions](https://github.com/dr4g00n/drag00n-just4fun/discussions/new)

</div>
