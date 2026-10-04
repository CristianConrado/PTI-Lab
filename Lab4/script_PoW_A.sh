#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

if [[ -f prbc/bin/activate ]]; then
    source prbc/bin/activate
fi

PYTHON_BIN="${PYTHON_BIN:-python3}"
command -v "$PYTHON_BIN" >/dev/null || {
    echo "Python executable not found: $PYTHON_BIN" >&2
    exit 1
}

node1_pid=""
node2_pid=""
node1_log=""
node2_log=""

cleanup_pair() {
    if [[ -n "$node1_pid" ]]; then
        kill "$node1_pid" 2>/dev/null || true
        wait "$node1_pid" 2>/dev/null || true
        node1_pid=""
    fi
    if [[ -n "$node2_pid" ]]; then
        kill "$node2_pid" 2>/dev/null || true
        wait "$node2_pid" 2>/dev/null || true
        node2_pid=""
    fi
    if [[ -n "$node1_log" ]]; then
        rm -f "$node1_log"
        node1_log=""
    fi
    if [[ -n "$node2_log" ]]; then
        rm -f "$node2_log"
        node2_log=""
    fi
}
trap cleanup_pair EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

wait_for_node() {
    local url="$1"
    local pid="$2"
    local log="$3"
    for _ in {1..30}; do
        if ! kill -0 "$pid" 2>/dev/null; then
            echo "Node process exited while starting at $url" >&2
            cat "$log" >&2
            return 1
        fi
        if curl --silent --fail "$url/chain" >/dev/null; then
            return
        fi
        sleep 1
    done
    echo "Node failed to start at $url" >&2
    cat "$log" >&2
    return 1
}

post_json() {
    curl --fail --silent --show-error \
        -X POST \
        -H "Content-Type: application/json" \
        -d "$2" \
        "$1" >/dev/null
}

assert_chain_length() {
    local url="$1"
    local expected="$2"
    curl --fail --silent --show-error "$url/chain" |
        "$PYTHON_BIN" -c \
        'import json,sys; actual=json.load(sys.stdin)["length"]; expected=int(sys.argv[1]); assert actual == expected, f"expected chain length {expected}, got {actual}"' \
        "$expected"
}

assert_validation() {
    local url="$1"
    local expected="$2"
    curl --fail --silent --show-error "$url/validate" |
        "$PYTHON_BIN" -c \
        'import json,sys; actual=json.load(sys.stdin)["message"]; expected=sys.argv[1]; assert actual == expected, f"expected {expected!r}, got {actual!r}"' \
        "$expected"
}

assert_resolution() {
    local url="$1"
    local expected="$2"
    curl --fail --silent --show-error "$url/nodes/resolve" |
        "$PYTHON_BIN" -c \
        'import json,sys; actual=json.load(sys.stdin)["message"]; expected=sys.argv[1]; assert actual == expected, f"expected {expected!r}, got {actual!r}"' \
        "$expected"
}

run_two_node_test() {
    local title="$1"
    local program="$2"
    local mode="$3"
    local port1="$4"
    local port2="$5"
    local url1="http://localhost:$port1"
    local url2="http://localhost:$port2"
    local authorities="localhost:$port1,localhost:$port2"

    if [[ "$port1" == "$port2" ]]; then
        echo "Node ports must be different for $title." >&2
        return 1
    fi

    node1_log="$(mktemp)"
    node2_log="$(mktemp)"
    if [[ "$mode" == "pow" ]]; then
        "$PYTHON_BIN" "$program" -p "$port1" >"$node1_log" 2>&1 &
        node1_pid=$!
        "$PYTHON_BIN" "$program" -p "$port2" >"$node2_log" 2>&1 &
        node2_pid=$!
    else
        env BLOCKCHAIN_CONSENSUS="$mode" BLOCKCHAIN_AUTHORITIES="$authorities" \
            "$PYTHON_BIN" "$program" -p "$port1" >"$node1_log" 2>&1 &
        node1_pid=$!
        env BLOCKCHAIN_CONSENSUS="$mode" BLOCKCHAIN_AUTHORITIES="$authorities" \
            "$PYTHON_BIN" "$program" -p "$port2" >"$node2_log" 2>&1 &
        node2_pid=$!
    fi

    wait_for_node "$url1" "$node1_pid" "$node1_log"
    wait_for_node "$url2" "$node2_pid" "$node2_log"

    echo "$title: submitting a transaction and mining on both nodes..."
    post_json "$url1/transactions/new" \
        '{"sender":"A","recipient":"B","amount":8,"order":1}'
    curl --fail --silent --show-error "$url1/mine" >/dev/null
    curl --fail --silent --show-error "$url1/mine" >/dev/null
    curl --fail --silent --show-error "$url2/mine" >/dev/null
    assert_chain_length "$url1" 3
    assert_chain_length "$url2" 2

    echo "$title: registering peers and synchronizing the shorter chain..."
    post_json "$url1/nodes/register" "{\"nodes\":\"$url2\"}"
    post_json "$url2/nodes/register" "{\"nodes\":\"$url1\"}"
    assert_resolution "$url2" "Our chain was replaced"
    assert_chain_length "$url2" 3

    echo "$title: checking validation, node listing, and tamper detection..."
    assert_validation "$url1" "The blockchain is valid"
    assert_validation "$url2" "The blockchain is valid"
    curl --fail --silent --show-error "$url1/nodes/list" |
        "$PYTHON_BIN" -c \
        'import json,sys; assert sys.argv[1] in json.load(sys.stdin)["total_nodes"]' \
        "localhost:$port2"
    post_json "$url2/nodes/manipulate" \
        '{"index":2,"new_data":[{"tampered":true}]}'
    assert_validation "$url2" "The blockchain is invalid"
    cleanup_pair
    echo "PASS: $title"
}

POW_NODE1_PORT="${POW_NODE1_PORT:-5100}"
POW_NODE2_PORT="${POW_NODE2_PORT:-5101}"
MULTIPO_NODE1_PORT="${MULTIPO_NODE1_PORT:-5200}"
MULTIPO_NODE2_PORT="${MULTIPO_NODE2_PORT:-5201}"

run_two_node_test \
    "Proof of Work (blockchain.py)" \
    "blockchain.py" \
    "pow" \
    "$POW_NODE1_PORT" \
    "$POW_NODE2_PORT"

run_two_node_test \
    "Proof of Authority (blockchain_multiPo.py)" \
    "blockchain_multiPo.py" \
    "poa" \
    "$MULTIPO_NODE1_PORT" \
    "$MULTIPO_NODE2_PORT"

echo "PASS: both blockchain implementations passed the two-node integration test."
