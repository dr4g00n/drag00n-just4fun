#!/usr/bin/env bash
# 运行所有测试
# 用法: ./tests/run_all_tests.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$PROJECT_DIR/tests"

echo "========================================"
echo "  Tintin++ 项目完整测试套件"
echo "========================================"
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0

# 测试 1: Mapper 正则测试
echo "--- 1. Mapper 正则测试 ---"
if bash "$TEST_DIR/run_mapper_tests.sh"; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
fi
echo ""

# 测试 2: 子系统测试 (login, dream)
echo "--- 2. 子系统测试 ---"
if bash "$TEST_DIR/run_subsystem_tests.sh"; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
fi
echo ""

echo "========================================"
echo "  总结果: $TOTAL_PASS/2 测试套件通过"
if [ "$TOTAL_FAIL" -gt 0 ]; then
    echo "  失败: $TOTAL_FAIL"
fi
echo "========================================"

[ "$TOTAL_FAIL" -eq 0 ]
