#!/usr/bin/env bash
# 应用胶囊更新
# 用法: ./wiki/apply_update.sh <胶囊名称>

set -euo pipefail

WIKI_DIR="$(cd "$(dirname "$0")" && pwd)"
CAPSULES_DIR="$WIKI_DIR/capsules"
CAPSULE_NAME="${1:-}"

if [ -z "$CAPSULE_NAME" ]; then
    echo "用法: $0 <胶囊名称>"
    exit 1
fi

CAPSULE_FILE="$CAPSULES_DIR/${CAPSULE_NAME}.md"
SUGGESTION_FILE="$WIKI_DIR/_update_suggestions/${CAPSULE_NAME}.md"

if [ ! -f "$SUGGESTION_FILE" ]; then
    echo "错误: 更新建议不存在: $SUGGESTION_FILE"
    echo "请先运行: ./wiki/update.sh $CAPSULE_NAME"
    exit 1
fi

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "========================================"
echo "  应用更新: $CAPSULE_NAME"
echo "========================================"
echo ""
echo "当前胶囊:"
cat "$CAPSULE_FILE"
echo ""
echo "---"
echo "更新建议:"
cat "$SUGGESTION_FILE"
echo ""
echo "========================================"
echo "确认应用更新? (y/n)"
read -r confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "取消更新"
    exit 0
fi

# 这里需要根据更新建议的内容更新胶囊
# 由于更新建议的结构化解析比较复杂，暂时提供手动更新路径
echo ""
echo -e "${YELLOW}⚠ 自动更新功能需要人工介入${NC}"
echo ""
echo "请按以下步骤手动更新:"
echo "  1. 打开 $CAPSULE_FILE"
echo "  2. 参考 $SUGGESTION_FILE 中的'建议修改'部分"
echo "  3. 修改胶囊内容"
echo "  4. 运行 ./wiki/check.sh $CAPSULE_NAME 验证"
echo "  5. 验证通过后，如果 index 需要更新，手动编辑 wiki/index.md"
echo ""
echo "完成后，删除建议文件:"
echo "  rm $SUGGESTION_FILE"
