#!/usr/bin/env bash
#
# sonoff_control.sh — Control a Sonoff Mini in DIY mode via local HTTP API.
#
# Usage:
#   bash sonoff_control.sh --ip 192.168.1.150 info
#   bash sonoff_control.sh --ip 192.168.1.150 --name "Living Room" switch on
#   bash sonoff_control.sh --ip 192.168.1.150 --name "Living Room" setup
#   bash sonoff_control.sh info                          # reuses saved config
#   bash sonoff_control.sh switch off                    # reuses saved config
#

set -euo pipefail

# ── Config path ────────────────────────────────────────────
# Prefer Hermes skill config directory; fallback to ~/.hermes/skills/sonoff-mini/
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILL_CONFIG_DIR="${SKILL_CONFIG_DIR:-$HERMES_HOME/skills/sonoff-mini}"
CONFIG_FILE="$SKILL_CONFIG_DIR/config.json"

# ── Globals parsed from --flags ─────────────────────────────
CLI_IP=""
CLI_NAME=""

# ── JSON helpers ────────────────────────────────────────────

print_json_error() {
    local msg="$1" details="${2:-}"
    local escaped_msg details_part=""
    escaped_msg=$(echo "$msg" | sed 's/"/\\"/g')
    if [ -n "$details" ]; then
        local escaped_details
        escaped_details=$(echo "$details" | sed 's/"/\\"/g')
        details_part=",\"details\":\"$escaped_details\""
    fi
    local json="{\"status\":\"error\",\"message\":\"$escaped_msg\"$details_part}"
    if command -v jq &>/dev/null; then
        echo "$json" | jq .
    else
        echo "$json"
    fi
}

print_json_success() {
    local action="$1" data="$2" ip name
    ip=$(get_config_val "ip")
    name=$(get_config_val "name")

    local json
    case "$action" in
        info)
            json="{\"status\":\"success\",\"device\":{\"name\":\"$name\",\"ip\":\"$ip\"},\"info\":$data}"
            ;;
        switch)
            json="{\"status\":\"success\",\"device\":{\"name\":\"$name\",\"ip\":\"$ip\"},\"action\":\"switch\",\"state\":\"$data\"}"
            ;;
        setup)
            json="{\"status\":\"success\",\"message\":\"Configuration saved successfully\",\"device\":{\"name\":\"$name\",\"ip\":\"$ip\"}}"
            ;;
        *)
            json="{\"status\":\"success\",\"device\":{\"name\":\"$name\",\"ip\":\"$ip\"}}"
            ;;
    esac
    if command -v jq &>/dev/null; then
        echo "$json" | jq .
    else
        echo "$json"
    fi
}

# ── Config file read helpers ───────────────────────────────

get_config_val() {
    local key="$1"
    if [ ! -f "$CONFIG_FILE" ]; then echo ""; return; fi
    if command -v jq &>/dev/null; then
        jq -r ".$key // empty" "$CONFIG_FILE"
    else
        sed -n 's/.*"'"$key"'"\s*:\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE"
    fi
}

save_config() {
    local ip="$1" name="$2"
    mkdir -p "$SKILL_CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
{
  "ip": "$ip",
  "name": "$name"
}
EOF
    echo "Configuration saved to $CONFIG_FILE" >&2
}

validate_device() {
    local ip="$1"
    local response
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"data": {}}' \
        --connect-timeout 5 \
        "http://${ip}:8081/zeroconf/info" 2>/dev/null) || true
    if [ -z "$response" ]; then
        print_json_error \
            "Could not reach the Sonoff Mini." \
            "Verify IP, power, DIY mode, and network connection."
        exit 1
    fi
    echo "$response"
}

# ── Resolve IP+Name: from --flags or saved config ──────────

resolve_device() {
    # If --ip was passed, save config unconditionally
    if [ -n "$CLI_IP" ]; then
        local name="${CLI_NAME:-Sonoff Mini}"
        validate_device "$CLI_IP" >/dev/null
        save_config "$CLI_IP" "$name"
        return
    fi

    # Try saved config
    if [ ! -f "$CONFIG_FILE" ]; then
        print_json_error \
            "Configuration file not found." \
            "Pass --ip <address> [--name <label>] before the command, or run \`setup\`."
        exit 1
    fi

    local saved_ip
    saved_ip=$(get_config_val "ip")
    if [ -z "$saved_ip" ]; then
        print_json_error \
            "Configuration file is corrupted." \
            "Remove $CONFIG_FILE and run with --ip again."
        exit 1
    fi
}

# ── Commands ────────────────────────────────────────────────

cmd_info() {
    local ip name
    ip=$(get_config_val "ip")
    name=$(get_config_val "name")

    local response
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d '{"data": {}}' \
        "http://${ip}:8081/zeroconf/info") || true

    if [ -z "$response" ]; then
        print_json_error "Could not retrieve info from device $name ($ip)." "Empty response from device."
        exit 1
    fi

    local data_part
    if command -v jq &>/dev/null; then
        data_part=$(echo "$response" | jq -c '.data // .')
    else
        data_part=$(echo "$response" | sed -n 's/.*"data"\s*:\s*\({[^}]*}\).*/\1/p')
        [ -z "$data_part" ] && data_part="$response"
    fi

    print_json_success "info" "$data_part"
}

cmd_switch() {
    local state="$1"
    if [ "$state" != "on" ] && [ "$state" != "off" ]; then
        print_json_error "Invalid state '$state'. Use 'on' or 'off'."
        exit 1
    fi

    local ip name
    ip=$(get_config_val "ip")
    name=$(get_config_val "name")

    local response
    response=$(curl -s -X POST -H "Content-Type: application/json" \
        -d "{\"data\": {\"switch\": \"$state\"}}" \
        "http://${ip}:8081/zeroconf/switch") || true

    if [ -z "$response" ]; then
        print_json_error "Failed to send command to device $name ($ip)." "Empty response from device."
        exit 1
    fi

    local err_code
    if command -v jq &>/dev/null; then
        err_code=$(echo "$response" | jq '.error // -1')
    else
        err_code=$(echo "$response" | sed -n 's/.*"error"\s*:\s*\([0-9]*\).*/\1/p')
        [ -z "$err_code" ] && err_code=-1
    fi

    if [ "$err_code" = "0" ]; then
        print_json_success "switch" "$state"
    else
        print_json_error "Device returned an error." "Code: $err_code, Response: $response"
        exit 1
    fi
}

cmd_setup() {
    local ip="${CLI_IP:-}"
    local name="${CLI_NAME:-}"

    if [ -z "$ip" ]; then
        print_json_error \
            "IP address is required." \
            "Usage: bash sonoff_control.sh --ip <address> [--name <label>] setup"
        exit 1
    fi
    [ -z "$name" ] && name="Sonoff Mini"

    validate_device "$ip" >/dev/null
    save_config "$ip" "$name"
    print_json_success "setup"
}

# ── Usage / help ────────────────────────────────────────────

show_usage() {
    cat >&2 <<'EOF'
sonoff_control.sh — Control a Sonoff Mini in DIY mode

Usage:
  bash sonoff_control.sh [--ip <addr>] [--name <label>] <command> [args]

Flags:
  --ip <address>     Sonoff Mini IP (e.g. 192.168.1.150)
  --name <label>     Friendly name (e.g. "Living Room Light")
                     Saved to config after first successful use.

Commands:
  info               Get device info and status
  switch on|off      Turn the relay on or off
  setup              Force reconfiguration (requires --ip)
  --help             Show this message

Examples:
  bash sonoff_control.sh --ip 192.168.1.150 --name "Living Room" info
  bash sonoff_control.sh switch on
  bash sonoff_control.sh --ip 192.168.1.150 setup
EOF
}

# ── Argument parsing ────────────────────────────────────────

# Consume --flags before the positional command
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ip)
            CLI_IP="$2"
            shift 2
            ;;
        --name)
            CLI_NAME="$2"
            shift 2
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        --*)
            print_json_error "Unknown flag: $1" "See --help for usage."
            exit 1
            ;;
        *)
            # First positional argument = command
            break
            ;;
    esac
done

COMMAND="${1:-}"
shift || true

# ── Dispatch ────────────────────────────────────────────────

case "$COMMAND" in
    info)
        resolve_device
        cmd_info
        ;;
    switch)
        resolve_device
        cmd_switch "${1:-}"
        ;;
    setup)
        cmd_setup
        ;;
    --help|-h|"")
        show_usage
        exit 0
        ;;
    *)
        print_json_error "Unknown command: $COMMAND" "See --help for usage."
        exit 1
        ;;
esac
