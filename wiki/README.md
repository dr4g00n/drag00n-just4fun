# 胶囊检查机制

## 目标

确保 wiki 中的胶囊内容始终与实际情况一致，避免过期或错误的指导信息。

## 工作流程

```
定期/手动检查 → 发现问题 → 记录到 _issues.md → 用户决定 → 更新胶囊 → 验证通过 → 移除问题记录
```

## 使用方式

### 1. 运行检查

```bash
# 检查所有胶囊
./wiki/check.sh

# 检查单个胶囊
./wiki/check.sh tintin++-macos-testing
```

输出示例：
```
✓ tintin++-macos-testing
✓ tintin++-regex-syntax

========================================
  验证结果: 2/2 通过
========================================
```

### 2. 处理问题

如果验证失败，会生成 `wiki/_issues.md`：

```markdown
| 胶囊 | 验证命令 | 失败原因 | 时间 |
|------|----------|----------|------|
| tintin++-xxx | `./tests/run_tests.sh` | 验证失败: ... | 2026-04-13 10:30:00 |
```

运行更新流程：

```bash
./wiki/update.sh tintin++-xxx
```

这会：
1. 检查问题记录
2. 生成更新建议文件 `wiki/_update_suggestions/tintin++-xxx.md`
3. 等待用户确认

### 3. 应用更新

确认更新后：

```bash
./wiki/apply_update.sh tintin++-xxx
```

目前为半自动流程，需要手动编辑胶囊内容。

### 4. 验证更新

```bash
./wiki/check.sh tintin++-xxx
```

## 胶囊编写规范

### 验证方式必须可执行

胶囊中的 "## 验证方式" 区块必须是可执行的 bash 命令：

```markdown
## 验证方式

```bash
cd /Users/dr4/tintin
./tests/run_mapper_tests.sh
# 预期: 4/4 通过
```
```

**注意事项**：
- 使用 ```bash 代码块包裹
- 每条命令必须是完整路径或相对路径
- 注释用 `#` 开头（会被提取时自动跳过）

### 验证失败的表现

当 `check.sh` 运行失败时，可能是：
1. 命令不存在/路径错误
2. 命令执行返回非 0 退出码
3. 实际行为与胶囊描述不符

## 自动化集成

建议将检查脚本加入定时任务或 CI/CD：

```bash
# 每天检查一次
0 0 * * * cd /Users/dr4/tintin && ./wiki/check.sh || echo "胶囊检查失败" | mail user@example.com
```
