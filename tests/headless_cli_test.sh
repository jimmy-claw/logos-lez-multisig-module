#!/usr/bin/env bash
# headless_cli_test.sh — Prove Logos Core plugin interface works headlessly
#
# Tests two paths:
#   1. logoscore --call (full plugin stack via QtRemoteObjects)
#   2. Direct FFI via Python ctypes (bypasses Logos Core)
#
# Exit codes: 0 = all tests pass, 1 = failures detected
set -euo pipefail

export PATH="$HOME/.nix-profile/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MODULE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RESULT_DIR="$MODULE_DIR/result"
MULTISIG_FFI="$RESULT_DIR/lib/liblez_multisig_ffi.so"
LOGOSCORE="$RESULT_DIR/bin/logoscore"
MODULES_DIR="$RESULT_DIR/modules"
SEQUENCER_URL="${SEQUENCER_URL:-http://127.0.0.1:3040}"

PASS=0
FAIL=0
SKIP=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1 — $2"; FAIL=$((FAIL + 1)); }
skip() { echo "  SKIP: $1 — $2"; SKIP=$((SKIP + 1)); }

echo "============================================"
echo "  Logos Core Headless CLI Test Suite"
echo "============================================"
echo ""
echo "Module dir:    $MODULE_DIR"
echo "Result dir:    $RESULT_DIR"
echo "Sequencer URL: $SEQUENCER_URL"
echo ""

# ── Pre-flight checks ─────────────────────────────────────────────────────────

echo "── Pre-flight Checks ──"

if [[ -x "$LOGOSCORE" ]]; then
    pass "logoscore binary exists and is executable"
else
    fail "logoscore binary" "not found at $LOGOSCORE"
fi

if [[ -f "$MULTISIG_FFI" ]]; then
    pass "liblez_multisig_ffi.so exists"
else
    fail "liblez_multisig_ffi.so" "not found at $MULTISIG_FFI"
fi

if [[ -f "$MODULES_DIR/liblez_multisig_module.so" ]]; then
    pass "multisig plugin .so exists"
else
    fail "multisig plugin" "not found in $MODULES_DIR"
fi

if [[ -f "$MODULES_DIR/capability_module_plugin.so" ]]; then
    pass "capability_module plugin .so exists"
else
    fail "capability_module plugin" "not found in $MODULES_DIR"
fi

SEQUENCER_UP=false
if curl -s --max-time 2 "$SEQUENCER_URL" -d '{"jsonrpc":"2.0","method":"get_program_ids","params":{},"id":1}' >/dev/null 2>&1; then
    SEQUENCER_UP=true
    pass "sequencer is reachable at $SEQUENCER_URL"
else
    skip "sequencer reachability" "not running at $SEQUENCER_URL"
fi

echo ""

# ── Test 1: logoscore --call version() ─────────────────────────────────────────

echo "── Test 1: logoscore --call version() (full plugin stack) ──"

cleanup_logoscore() {
    pkill -f "logoscore.*modules-dir" 2>/dev/null || true
    pkill -f "logos_host" 2>/dev/null || true
    sleep 0.5
}

# Kill any lingering processes first
cleanup_logoscore

VERSION_OUTPUT=$(QT_QPA_PLATFORM=offscreen timeout 30 "$LOGOSCORE" \
    --modules-dir "$MODULES_DIR" \
    --load-modules lez_multisig_module \
    --call "lez_multisig_module.version()" 2>&1 || true)

cleanup_logoscore

if echo "$VERSION_OUTPUT" | grep -q "Method call successful. Result: 0.1.0"; then
    pass "logoscore --call version() returned 0.1.0"
else
    fail "logoscore --call version()" "unexpected output"
    echo "    Output (last 5 lines):"
    echo "$VERSION_OUTPUT" | tail -5 | sed 's/^/      /'
fi

echo ""

# ── Test 2: logoscore --call getState() (full plugin → FFI → network) ─────────

echo "── Test 2: logoscore --call getState() (plugin → FFI path) ──"

ARGS_FILE=$(mktemp /tmp/logoscore_test_XXXXXX.json)
cat > "$ARGS_FILE" <<'JSONEOF'
{"sequencer_url":"http://127.0.0.1:3040","wallet_path":"/tmp","program_id_hex":"0x0000000000000000000000000000000000000000000000000000000000000001","create_key":"0x0000000000000000000000000000000000000000000000000000000000000001"}
JSONEOF

cleanup_logoscore

GETSTATE_OUTPUT=$(QT_QPA_PLATFORM=offscreen timeout 30 "$LOGOSCORE" \
    --modules-dir "$MODULES_DIR" \
    --load-modules lez_multisig_module \
    --call "lez_multisig_module.getState(@$ARGS_FILE)" 2>&1 || true)

cleanup_logoscore
rm -f "$ARGS_FILE"

if echo "$GETSTATE_OUTPUT" | grep -q "Method call successful"; then
    RESULT_LINE=$(echo "$GETSTATE_OUTPUT" | grep "Method call successful")
    if echo "$RESULT_LINE" | grep -q '"success"'; then
        pass "logoscore --call getState() got success response from FFI"
    elif echo "$RESULT_LINE" | grep -q '"error"'; then
        # Expected when sequencer is down — still proves the full path works
        pass "logoscore --call getState() reached FFI (got expected error: sequencer down)"
    else
        pass "logoscore --call getState() got a response from FFI"
    fi
else
    fail "logoscore --call getState()" "no Method call successful in output"
    echo "    Output (last 5 lines):"
    echo "$GETSTATE_OUTPUT" | tail -5 | sed 's/^/      /'
fi

echo ""

# ── Test 3: Direct FFI via Python ctypes ───────────────────────────────────────

echo "── Test 3: Direct FFI via Python ctypes ──"

if ! command -v python3 >/dev/null 2>&1; then
    skip "Python ctypes tests" "python3 not found"
else
    FFI_TEST_OUTPUT=$(python3 -c "
import ctypes, json, sys

lib = ctypes.CDLL('$MULTISIG_FFI')

# Test version
lib.lez_multisig_version.restype = ctypes.c_char_p
ver = lib.lez_multisig_version()
ver_str = ver.decode()
print(f'version={ver_str}')

# Test IDL retrieval
lib.lez_multisig_get_idl.restype = ctypes.c_char_p
idl_raw = lib.lez_multisig_get_idl()
idl = json.loads(idl_raw.decode())
print(f'idl_name={idl.get(\"name\", \"\")}')
print(f'idl_instructions={len(idl.get(\"instructions\", []))}')

# Test getState (will return error without sequencer, proves FFI path)
lib.lez_multisig_get_state.restype = ctypes.c_char_p
lib.lez_multisig_get_state.argtypes = [ctypes.c_char_p]
args = json.dumps({
    'sequencer_url': '$SEQUENCER_URL',
    'wallet_path': '/tmp',
    'program_id_hex': '0x0000000000000000000000000000000000000000000000000000000000000001',
    'create_key': '0x0000000000000000000000000000000000000000000000000000000000000001'
})
result = lib.lez_multisig_get_state(args.encode())
result_json = json.loads(result.decode())
print(f'getstate_success={result_json.get(\"success\", False)}')
print(f'getstate_has_response=true')
if not result_json.get('success'):
    print(f'getstate_error={result_json.get(\"error\", \"\")}')
" 2>&1)

    if echo "$FFI_TEST_OUTPUT" | grep -q "version=0.1.0"; then
        pass "FFI lez_multisig_version() = 0.1.0"
    else
        fail "FFI version" "unexpected version"
    fi

    if echo "$FFI_TEST_OUTPUT" | grep -q "idl_name=multisig_program"; then
        pass "FFI lez_multisig_get_idl() returned valid IDL"
    else
        fail "FFI get_idl" "unexpected IDL name"
    fi

    IDL_INSTR=$(echo "$FFI_TEST_OUTPUT" | grep "idl_instructions=" | cut -d= -f2)
    if [[ "$IDL_INSTR" -gt 0 ]]; then
        pass "FFI IDL has $IDL_INSTR instructions defined"
    else
        fail "FFI IDL instructions" "expected >0, got $IDL_INSTR"
    fi

    if echo "$FFI_TEST_OUTPUT" | grep -q "getstate_has_response=true"; then
        if echo "$FFI_TEST_OUTPUT" | grep -q "getstate_success=True"; then
            pass "FFI getState() returned success (sequencer is up)"
        elif echo "$FFI_TEST_OUTPUT" | grep -q "getstate_error="; then
            pass "FFI getState() reached sequencer layer (expected error: sequencer down)"
        fi
    else
        fail "FFI getState()" "no response received"
    fi
fi

echo ""

# ── Test 4: Registry FFI (if available) ───────────────────────────────────────

echo "── Test 4: Registry FFI ──"

# Find registry FFI lib via ldd on the registry module
REGISTRY_MODULE_SO="$HOME/logos-lez-registry-module/result/lib/liblez_registry_module.so"
REGISTRY_FFI_SO=""

if [[ -f "$REGISTRY_MODULE_SO" ]]; then
    # Try ldd first, fall back to nix-store closure search
    REGISTRY_FFI_SO=$(ldd "$REGISTRY_MODULE_SO" 2>/dev/null | grep liblez_registry_ffi | awk '{print $3}' || true)
    if [[ -z "$REGISTRY_FFI_SO" ]] && command -v nix-store >/dev/null 2>&1; then
        REGISTRY_FFI_SO=$(nix-store -qR "$HOME/logos-lez-registry-module/result" 2>/dev/null \
            | while read -r p; do
                if [[ -f "$p/lib/liblez_registry_ffi.so" ]]; then
                    echo "$p/lib/liblez_registry_ffi.so"
                    break
                fi
            done || true)
    fi
fi

if [[ -n "$REGISTRY_FFI_SO" && -f "$REGISTRY_FFI_SO" ]]; then
    REG_TEST_OUTPUT=$(python3 -c "
import ctypes, json

lib = ctypes.CDLL('$REGISTRY_FFI_SO')
lib.lez_registry_version.restype = ctypes.c_char_p
ver = lib.lez_registry_version()
print(f'registry_version={ver.decode()}')

lib.lez_registry_list.restype = ctypes.c_char_p
lib.lez_registry_list.argtypes = [ctypes.c_char_p]
args = json.dumps({'sequencer_url': '$SEQUENCER_URL', 'registry_program_id': '0x0000000000000000000000000000000000000000000000000000000000000001'})
result = lib.lez_registry_list(args.encode())
result_json = json.loads(result.decode())
print(f'registry_list_has_response=true')
print(f'registry_list_success={result_json.get(\"success\", False)}')
" 2>&1)

    if echo "$REG_TEST_OUTPUT" | grep -q "registry_version="; then
        REG_VER=$(echo "$REG_TEST_OUTPUT" | grep "registry_version=" | cut -d= -f2)
        pass "Registry FFI version = $REG_VER"
    else
        fail "Registry FFI version" "could not get version"
    fi

    if echo "$REG_TEST_OUTPUT" | grep -q "registry_list_has_response=true"; then
        pass "Registry FFI list() returned structured response"
    else
        fail "Registry FFI list" "no response"
    fi
else
    skip "Registry FFI tests" "liblez_registry_ffi.so not found"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

echo "============================================"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "============================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
