#!/usr/bin/env bash
#
# list_devices.sh — List all Sonoff Mini devices stored in the Hermes skill config.
# Reads config from ~/.hermes/skills/sonoff-mini/config.json
#

set -euo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SKILL_CONFIG_DIR="${SKILL_CONFIG_DIR:-$HERMES_HOME/skills/sonoff-mini}"
CONFIG_FILE="$SKILL_CONFIG_DIR/config.json"

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

if [ ! -f "$CONFIG_FILE" ]; then
    print_json_error "Configuration file not found." "Please run sonoff_control.sh with --ip first."
    exit 1
fi

if command -v jq &>/dev/null; then
    jq '{status: "success", devices: (if .devices then .devices else [{name: .name, ip: .ip}] end)}' "$CONFIG_FILE"
else
    ip=$(sed -n 's/.*"ip"\s*:\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")
    name=$(sed -n 's/.*"name"\s*:\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")
    if [ -z "$ip" ] || [ -z "$name" ]; then
        print_json_error "Invalid configuration file format."
        exit 1
    fi
    echo "{\"status\":\"success\",\"devices\":[{\"name\":\"$name\",\"ip\":\"$ip\"}]}"
fi
