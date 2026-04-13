#!/usr/bin/env bash
# 胶囊验证脚本
# 用法: ./wiki/check.sh [胶囊名称]
#
# 功能：
#   1. 读取胶囊中 "## 验证方式" 区块的可执行命令
#   2. 切换到项目根目录执行验证命令
#   3. 记录验证结果到 issues.md
#   4. 失败时打印提示，成功时静默通过

set -euo pipefail

WIKI_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$WIKI_DIR/.." && pwd)"
CAPSULES_DIR="$WIKI_DIR/capsules"
ISSUES_FILE="$WIKI_DIR/_issues.md"

CAPSULE_NAME="${1:-}"
PASS=0
FAIL=0
TOTAL=0

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 创建 issues 文件头（如果不存在）
init_issues() {
    if [ ! -f "$ISSUES_FILE" ]; then
        cat > "$ISSUES_FILE" << 'EOF'
# 胶囊验证问题记录

> 本文件由 `wiki/check.sh` 自动生成，记录验证失败的胶囊。

| 胶囊 | 验证命令 | 失败原因 | 时间 |
|------|----------|----------|------|

EOF
    fi
}

# 记录失败问题
record_issue() {
    local capsule="$1" cmd="$2" reason="$3" timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # 生成唯一 ID 避免重复
    local issue_id="${capsule}_$(date +%s)"

    # 检查是否已存在相同问题（过去 1 小时内）
    if grep -q "$capsule" "$ISSUES_FILE" 2>/dev/null; then
        return 0
    fi

    echo "| $capsule | \`$cmd\` | $reason | $timestamp |" >> "$ISSUES_FILE"
}

# 提取验证命令
extract_verify_cmd() {
    local capsule_file="$1"
    local in_verify=0 in_code_block=0 cmd=""

    while IFS= read -r line; do
        # 进入验证方式区块
        if [[ "$line" == "## 验证方式"* ]]; then
            in_verify=1
            continue
        fi

        # 离开验证方式区块（遇到下一个 ##）
        if [ "$in_verify" = 1 ] && [[ "$line" == "##"* ]]; then
            break
        fi

        # 在验证方式区块内
        if [ "$in_verify" = 1 ]; then
            # 检测代码块开始
            if [[ "$line" == "\`\`\`bash"* ]]; then
                in_code_block=1
                continue
            fi

            # 检测代码块结束
            if [ "$in_code_block" = 1 ] && [[ "$line" == "\`\`\`"* ]]; then
                break
            fi

            # 收集代码块内的命令
            if [ "$in_code_block" = 1 ]; then
                # 跳过注释行
                if [[ "$line" =~ ^[[:space:]]*# ]]; then
                    continue
                fi
                cmd="${cmd}${line}"$'\n'
            fi
        fi
    done < "$capsule_file"

    # 去掉空行
    cmd=$(echo "$cmd" | grep -v '^$')
    echo "$cmd"
}

# 验证单个胶囊
verify_capsule() {
    local name="$1"
    local capsule_file="$CAPSULES_DIR/${name}.md"

    if [ ! -f "$capsule_file" ]; then
        echo -e "${RED}✗ 胶囊不存在: $capsule_file${NC}"
        return 1
    fi

    TOTAL=$((TOTAL + 1))

    local verify_cmd
    verify_cmd=$(extract_verify_cmd "$capsule_file")

    if [ -z "$verify_cmd" ]; then
        echo -e "${YELLOW}⚠ $name: 无验证命令，跳过${NC}"
        return 0
    fi

    cd "$PROJECT_DIR"
    local output
    if output=$(eval "$verify_cmd" 2>&1); then
        PASS=$((PASS + 1))
        echo -e "${GREEN}✓ $name${NC}"
        # 验证成功时移除旧问题记录（如果有）
        sed -i '' "/$name/d" "$ISSUES_FILE" 2>/dev/null || true
    else
        FAIL=$((FAIL + 1))
        echo -e "${RED}✗ $name${NC}"
        record_issue "$name" "$verify_cmd" "验证失败: $output"
    fi
}

# ============================================================

init_issues

if [ -n "$CAPSULE_NAME" ]; then
    # 验证单个胶囊
    verify_capsule "$CAPSULE_NAME"
else
    # 验证所有胶囊（排除模板）
    for capsule in "$CAPSULES_DIR"/*.md; do
        [ -f "$capsule" ] || continue
        name=$(basename "$capsule" .md)
        [ "$name" = "_template" ] && continue
        verify_capsule "$name"
    done
fi

echo ""
echo "========================================"
echo "  验证结果: $PASS/$TOTAL 通过"
if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}  失败: $FAIL${NC}"
    echo ""
    echo "问题已记录到: $ISSUES_FILE"
    echo "请查看并决定是否更新胶囊"
fi
echo "========================================"

[ "$FAIL" -eq 0 ]
