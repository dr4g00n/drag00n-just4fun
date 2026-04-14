# GitHub Issues 创建指南

由于 GitHub CLI 不可用，请手动在网页创建 Issues。

---

## Issue 1: 添加更多 MUD 服务器配置

**链接**：https://github.com/dr4g00n/drag00n-just4fun/issues/new?labels=enhancement,good+first+issue,help+wanted&title=[Good+First+Issue]+添加更多+MUD+服务器登录配置示例

**内容**：

```markdown
## 任务描述

当前 `examples/custom_login.tt` 只有 3 个 MUD 服务器的登录配置（书剑、西游记、侠客行）。希望添加更多常见的 MUD 服务器配置示例。

## 建议添加的服务器

- 金庸群侠传 (jyx.net)
- 风云 
- 天龙八部
- 泥巴 (mud.cn)

或你熟悉的其他 MUD 服务器。

## 如何做

1. 研究目标 MUD 的连接方式
2. 参考 `examples/custom_login.tt` 格式
3. 添加新的登录别名
4. 更新帮助文本

## 预期结果

- 新增 2-3 个 MUD 服务器配置
- 格式保持一致
- 添加必要注释

**难度**：⭐ 初级 | **时间**：30-60 分钟
```

---

## Issue 2: 补充 README 常见问题

**链接**：https://github.com/dr4g00n/drag00n-just4fun/issues/new?labels=documentation,good+first+issue&title=[Good+First+Issue]+补充+README+常见问题

**内容**：

```markdown
## 任务描述

README 当前只有 4 个常见问题，补充更多玩家可能遇到的问题。

## 建议添加的问题

- 如何修改 MUD 服务器地址？
- 地图数据保存在哪里？
- 可以同时连接多个 MUD 吗？
- 如何备份我的地图数据？
- 遇到编码问题怎么办？
- 如何禁用某些触发？
- 可以和其他人共享地图数据吗？

## 如何做

1. 在 `README.md` 的 `常见问题` 部分添加新条目
2. 保持格式一致（问答对）
3. 如果有解决步骤，给出具体命令
4. 添加相关链接（如有）

## 预期结果

- 新增 3-5 个常见问题
- 格式与现有问答一致
- 答案准确有用

**难度**：⭐ 初级 | **时间**：30 分钟
```

---

## Issue 3: 添加基础战斗别名示例

**链接**：https://github.com/dr4g00n/drag00n-just4fun/issues/new?labels=enhancement,good+first+issue&title=[Good+First+Issue]+添加基础战斗别名示例

**内容**：

```markdown
## 任务描述

`examples/basic_usage.tt` 只有基础的 `kill` 和 `flee`，添加更多战斗相关别名。

## 建议添加的别名

- `attack <目标>` - 攻击目标（可带技能）
- `flee <方向>` - 向指定方向逃跑
- `use_item <物品>` - 使用物品
- `check_status` - 检查战斗状态
- `auto_loot` - 自动拾取战利品

## 如何做

1. 创建新文件 `examples/combat.tt` 或扩展 `basic_usage.tt`
2. 添加战斗相关别名
3. 添加详细注释
4. 添加 `help_combat` 帮助命令
5. 更新 `examples/README.md`

## 预期结果

- 新增 5+ 个战斗别名
- 包含帮助命令
- 有详细注释

**难度**：⭐ 初级 | **时间**：1 小时
```

---

## 快速创建步骤

1. 点击上面每个链接
2. 标题已自动填充
3. 复制对应的 Markdown 内容到正文
4. 选择标签（enhancement, good first issue, help wanted）
5. 点击 "Submit new issue"

---

## 或者批量创建

如果想创建更多 Issues，参考 `docs/GOOD_FIRST_ISSUES.md` 中的其他任务。

---

完成后告诉我，我们开始渠道推广！ 🚀
