#!/usr/bin/env bash
# Mapper 正则测试运行器
# 用法: ./tests/run_mapper_tests.sh

set -eo pipefail

TT_BIN="/opt/homebrew/bin/tt++"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEST_DIR="$PROJECT_DIR/tests"
SAMPLES_DIR="${1:-$TEST_DIR/samples/mapper}"
MOCK_SERVER="$TEST_DIR/mock_mud_server.py"
RESULT_DIR="/tmp/tt_mapper_tests"

PASS=0
FAIL=0
TOTAL=0

rm -rf "$RESULT_DIR"
mkdir -p "$RESULT_DIR"

BASE_PORT=20300

wait_for_server() {
    local ready_file="$1"
    for i in $(seq 1 30); do
        [ -f "$ready_file" ] && return 0
        sleep 0.2
    done
    return 1
}

get_var() {
    local result_file="$1" var_name="$2"
    grep "^${var_name}=" "$result_file" 2>/dev/null | head -1 | cut -d= -f2-
}

assert_eq() {
    local result_file="$1" var_name="$2" expected="$3"
    local actual
    actual=$(get_var "$result_file" "$var_name")
    if [ "$actual" = "$expected" ]; then
        return 0
    else
        echo "      断言失败: $var_name"
        echo "        期望: $expected"
        echo "        实际: ${actual:-<空>}"
        return 1
    fi
}

assert_contains() {
    local result_file="$1" var_name="$2" needle="$3"
    local actual
    actual=$(get_var "$result_file" "$var_name")
    if echo "$actual" | grep -q "$needle"; then
        return 0
    else
        echo "      断言失败: $var_name 应包含 '$needle'"
        echo "        实际: ${actual:-<空>}"
        return 1
    fi
}

run_test() {
    local name="$1"
    local sample_file="$2"
    local port="$3"
    local result_file="$RESULT_DIR/${name}.txt"
    local ready_file="$RESULT_DIR/${name}_ready.txt"
    local tt_file="$RESULT_DIR/${name}.tt"

    TOTAL=$((TOTAL + 1))

    # 生成 tt++ 测试脚本（支持 brief 和完整模式）
    cat > "$tt_file" << 'TTEOF'
#config charset UTF-8

#variable {current_room} {NOT_SET}
#variable {current_room_exits} {NOT_SET}
#variable {current_room_exits_brief} {NOT_SET}
#variable {current_npcs} {}

#action {^{.+} - {.+}$} {
    #variable {current_room} {%1};
    #variable {current_room_exits_brief} {%2}
}

#action {^{.+} -$} {
    #variable {current_room} {%1}
}

#action {^这里明显的出口是 {.+}\.$} {
    #variable {current_room_exits} {%1}
}

#action {^◎{.+} \({.+}\)$} {
    #list {current_npcs} {add} {%1(%2)}
}

#action {^  {.+} \({.+}\)$} {
    #list {current_npcs} {add} {%1(%2)}
}

TTEOF

    # 需要动态插入端口和结果文件路径，用 sed 替换
    cat >> "$tt_file" << EOF
#session test 127.0.0.1 ${port}

#event {SESSION DISCONNECTED} {
    #if {"\$current_room_exits_brief" != "NOT_SET"} {
        #system {echo "current_room=\$current_room" > ${result_file}};
        #system {echo "current_room_exits=\$current_room_exits_brief" >> ${result_file}}
    } {
        #system {echo "current_room=\$current_room" > ${result_file}};
        #system {echo "current_room_exits=\$current_room_exits" >> ${result_file}}
    };
    #system {echo "current_npcs=\$current_npcs" >> ${result_file}};
    #system {echo "DONE" >> ${result_file}};
    #end
}
EOF

    rm -f "$ready_file" "$result_file"

    # 启动 mock server
    python3 "$MOCK_SERVER" "$port" "$sample_file" "$ready_file" &
    local mock_pid=$!

    # 等待 server 就绪
    if ! wait_for_server "$ready_file"; then
        kill "$mock_pid" 2>/dev/null
        echo "  ✗ $name: mock server 启动超时"
        FAIL=$((FAIL + 1))
        return
    fi

    # 启动 tt++
    tmux new-session -d -s "tt_${name}" "$TT_BIN $tt_file" 2>&1 || true
    sleep 6

    # 清理
    tmux kill-session -t "tt_${name}" 2>/dev/null || true
    kill "$mock_pid" 2>/dev/null || true
    wait "$mock_pid" 2>/dev/null || true

    # 验证结果
    if [ ! -f "$result_file" ] || ! grep -q "DONE" "$result_file"; then
        echo "  ✗ $name: 测试未完成"
        FAIL=$((FAIL + 1))
        cat "$result_file" 2>/dev/null | sed 's/^/      /'
        return
    fi

    local test_fail=0
    local room exits npcs

    # 断言房间名
    room=$(get_var "$result_file" "current_room")
    if [ "$room" = "NOT_SET" ] || [ -z "$room" ]; then
        echo "      房间名未捕获"
        test_fail=1
    fi

    # 断言出口（brief 或完整模式）
    exits=$(get_var "$result_file" "current_room_exits")
    if [ "$exits" = "NOT_SET" ] || [ -z "$exits" ]; then
        echo "      出口未捕获"
        test_fail=1
    fi

    if [ "$test_fail" -eq 0 ]; then
        PASS=$((PASS + 1))
        echo "  ✓ $name"
        echo "      房间: $room"
        echo "      出口: $exits"
        npcs=$(get_var "$result_file" "current_npcs")
        if [ -n "$npcs" ] && [ "$npcs" != "{}" ]; then
            echo "      NPC:  $npcs"
        fi
    else
        FAIL=$((FAIL + 1))
        echo "  ✗ $name: 断言失败"
        cat "$result_file" | sed 's/^/      /'
    fi
}

echo "========================================"
echo "  Mapper 正则测试"
echo "========================================"
echo ""

port=$BASE_PORT

for sample in "$SAMPLES_DIR"/*.txt; do
    [ -f "$sample" ] || continue
    name=$(basename "$sample" .txt)
    run_test "$name" "$sample" "$port"
    port=$((port + 1))
    echo ""
done

echo "========================================"
echo "  结果: $PASS/$TOTAL 通过"
if [ "$FAIL" -gt 0 ]; then
    echo "  失败: $FAIL"
fi
echo "========================================"

[ "$FAIL" -eq 0 ]
