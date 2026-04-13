#!/usr/bin/env bash
# 子系统测试 - login 和 dream
# 用法: ./tests/run_subsystem_tests.sh

set -euo pipefail

TT_BIN="/opt/homebrew/bin/tt++"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$PROJECT_DIR/tests"
SAMPLES_DIR="$TEST_DIR/samples"
MOCK_SERVER="$TEST_DIR/mock_mud_server.py"
WORK_DIR="/tmp/tt_subsystem_tests"

PASS=0
FAIL=0
TOTAL=0

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

BASE_PORT=20400

wait_for_server() {
    local ready_file="$1"
    for i in $(seq 1 30); do
        [ -f "$ready_file" ] && return 0
        sleep 0.2
    done
    return 1
}

run_login_test() {
    local name="$1"
    local sample="$2"
    local port=$BASE_PORT
    BASE_PORT=$((BASE_PORT + 1))
    local result="$WORK_DIR/login_${name}.txt"
    local ready="$WORK_DIR/${name}_ready.txt"
    local tt="$WORK_DIR/${name}.tt"

    TOTAL=$((TOTAL + 1))

    # 样本文件是相对路径
    sample="$TEST_DIR/samples/$sample"

    cat > "$tt" << EOF
#config charset UTF-8
#action {^您的英文名字\\(ID\\)是：\$} {
    #system {echo "username_triggered=Y" > ${result}}
}
#action {^请输入您的英文名字：\$} {
    #system {echo "username_triggered=Y" > ${result}}
}
#action {^请输入您的密码：\$} {
    #system {echo "password_triggered=Y" >> ${result}}
}
#action {^Are you using BIG5 font\\(y/N\\)\\\?\$} {
    #system {echo "big5_triggered=Y" >> ${result}}
}
#session test 127.0.0.1 ${port}
#event {SESSION DISCONNECTED} {
    #system {echo "DONE" >> ${result}};
    #end
}
EOF

    rm -f "$ready" "$result"

    python3 "$MOCK_SERVER" "$port" "$sample" "$ready" &
    local mock_pid=$!

    if ! wait_for_server "$ready"; then
        kill "$mock_pid" 2>/dev/null
        echo "  ✗ login_$name: mock 超时"
        FAIL=$((FAIL + 1))
        return
    fi

    tmux new-session -d -s "l_${name}" "$TT_BIN $tt" 2>&1 || true
    sleep 6

    tmux kill-session -t "l_${name}" 2>/dev/null || true
    kill "$mock_pid" 2>/dev/null || true

    if [ ! -f "$result" ] || ! grep -q "DONE" "$result"; then
        echo "  ✗ login_$name: 测试未完成"
        FAIL=$((FAIL + 1))
        return
    fi

    if grep -q "username_triggered=Y" "$result" && \
       grep -q "password_triggered=Y" "$result"; then
        PASS=$((PASS + 1))
        echo "  ✓ login_$name"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ login_$name: 触发失败"
        cat "$result" | sed 's/^/    /'
    fi
}

run_dream_test() {
    local name="$1"
    local sample="$2"
    local port=$BASE_PORT
    BASE_PORT=$((BASE_PORT + 1))
    local result="$WORK_DIR/dream_${name}.txt"
    local ready="$WORK_DIR/${name}_ready.txt"
    local tt="$WORK_DIR/${name}.tt"

    TOTAL=$((TOTAL + 1))

    # 样本文件是相对路径
    sample="$TEST_DIR/samples/$sample"

    cat > "$tt" << EOF
#config charset UTF-8
#variable {dream_target} {}
#action {^你想梦见何处：\$} {
    #system {echo "dream_confirm=Y" > ${result}}
}
#action {^恍然间，你感觉云里雾里，身心飘到了另外一个地方} {
    #system {echo "dream_success=Y" >> ${result}}
}
#session test 127.0.0.1 ${port}
#event {SESSION DISCONNECTED} {
    #system {echo "DONE" >> ${result}};
    #end
}
EOF

    rm -f "$ready" "$result"

    python3 "$MOCK_SERVER" "$port" "$sample" "$ready" &
    local mock_pid=$!

    if ! wait_for_server "$ready"; then
        kill "$mock_pid" 2>/dev/null
        echo "  ✗ dream_$name: mock 超时"
        FAIL=$((FAIL + 1))
        return
    fi

    tmux new-session -d -s "d_${name}" "$TT_BIN $tt" 2>&1 || true
    sleep 6

    tmux kill-session -t "d_${name}" 2>/dev/null || true
    kill "$mock_pid" 2>/dev/null || true

    if [ ! -f "$result" ] || ! grep -q "DONE" "$result"; then
        echo "  ✗ dream_$name: 测试未完成"
        FAIL=$((FAIL + 1))
        return
    fi

    if grep -q "dream_confirm=Y" "$result" && \
       grep -q "dream_success=Y" "$result"; then
        PASS=$((PASS + 1))
        echo "  ✓ dream_$name"
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ dream_$name: 触发失败"
        cat "$result" | sed 's/^/    /'
    fi
}

echo "========================================"
echo "  子系统测试"
echo "========================================"
echo ""

echo "--- Login 测试 ---"
run_login_test "normal" "login/login_normal.txt"
run_login_test "old" "login/login_old.txt"

echo ""
echo "--- Dream 测试 ---"
run_dream_test "city" "dream/dream_city.txt"

echo ""
echo "========================================"
echo "  结果: $PASS/$TOTAL 通过"
if [ "$FAIL" -gt 0 ]; then
    echo "  失败: $FAIL"
fi
echo "========================================"

[ "$FAIL" -eq 0 ]
