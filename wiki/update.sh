#!/usr/bin/env bash
# 胶囊更新流程
# 用法: ./wiki/update.sh <胶囊名称>
#
# 流程：
#   1. 检查胶囊验证状态
#   2. 如果验证失败，生成更新建议文件
#   3. 等待用户确认
#   4. 用户同意后，更新胶囊和 index

set -euo pipefail

WIKI_DIR="$(cd "$(dirname "$0")" && pwd)"
CAPSULES_DIR="$WIKI_DIR/capsules"
ISSUES_FILE="$WIKI_DIR/_issues.md"
CAPSULE_NAME="${1:-}"

if [ -z "$CAPSULE_NAME" ]; then
    echo "用法: $0 <胶囊名称>"
    echo ""
    echo "示例:"
    echo "  $0 tintin++-macos-testing"
    exit 1
fi

CAPSULE_FILE="$CAPSULES_DIR/${CAPSULE_NAME}.md"

if [ ! -f "$CAPSULE_FILE" ]; then
    echo "错误: 胶囊不存在: $CAPSULE_FILE"
    exit 1
fi

# 颜色
YELLOW='\033[0;33m'
NC='\033[0m'

# 检查是否有问题记录
has_issue() {
    grep -q "$CAPSULE_NAME" "$ISSUES_FILE" 2>/dev/null
}

# 生成更新建议
generate_suggestion() {
    local suggestion_file="$WIKI_DIR/_update_suggestions/${CAPSULE_NAME}.md"
    mkdir -p "$WIKI_DIR/_update_suggestions"

    cat > "$suggestion_file" << EOF
# 胶囊更新建议: $CAPSULE_NAME

## 当前问题

\`\`\`
$(grep "$CAPSULE_NAME" "$ISSUES_FILE" | tail -1)
\`\`\`

## 建议修改

> 请在下面填写修改建议，完成后使用 \`./wiki/apply_update.sh $CAPSULE_NAME\` 应用

### 关键发现

(需要修改的条目)

### 已验证的正确方案

(需要修改的内容)

### 踩过的坑

(需要调整的内容)

## 验证方式

更新后请运行:

\`\`\`bash
cd /Users/dr4/tintin
./wiki/check.sh $CAPSULE_NAME
\`\`\`

确认验证通过。
EOF

    echo "更新建议已生成: $suggestion_file"
    echo ""
    echo "下一步:"
    echo "  1. 编辑 $suggestion_file 填写修改建议"
    echo "  2. 运行 \`./wiki/apply_update.sh $CAPSULE_NAME\` 应用更新"
}

# ============================================================

echo "========================================"
echo "  胶囊更新检查: $CAPSULE_NAME"
echo "========================================"
echo ""

if has_issue; then
    echo -e "${YELLOW}⚠ 检测到验证失败记录${NC}"
    echo ""
    echo "问题详情:"
    grep "$CAPSULE_NAME" "$ISSUES_FILE" | tail -1
    echo ""
    echo "是否需要更新此胶囊? (y/n)"
    read -r confirm

    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        generate_suggestion
    else
        echo "取消更新"
    fi
else
    echo "✓ 验证通过，无需更新"
    exit 0
fi
