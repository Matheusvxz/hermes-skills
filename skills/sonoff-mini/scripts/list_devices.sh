#!/usr/bin/env bash

# Get directory where the script is located to reference config.json
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Helper to print structured JSON error
print_json_error() {
    local MSG=$1
    local DETAILS=$2
    local JSON
    
    local ESCAPED_MSG=$(echo "$MSG" | sed 's/"/\\"/g')
    
    if [ -n "$DETAILS" ]; then
        local ESCAPED_DETAILS=$(echo "$DETAILS" | sed 's/"/\\"/g')
        JSON="{\"status\":\"error\",\"message\":\"$ESCAPED_MSG\",\"details\":\"$ESCAPED_DETAILS\"}"
    else
        JSON="{\"status\":\"error\",\"message\":\"$ESCAPED_MSG\"}"
    fi
    
    if command -v jq &> /dev/null; then
        echo "$JSON" | jq .
    else
        echo "$JSON"
    fi
}

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    print_json_error "Configuration file not found." "Please run the sonoff_control.sh setup script first."
    exit 1
fi

# Output the devices list
if command -v jq &> /dev/null; then
    # Elegant filter checking if a devices array exists, otherwise wrap single device in an array
    jq '{status: "success", devices: (if .devices then .devices else [{"name": .name, "ip": .ip}] end)}' "$CONFIG_FILE"
else
    # Simple fallback using sed
    IP=$(sed -n 's/.*"ip"\s*:\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")
    NAME=$(sed -n 's/.*"name"\s*:\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE")
    
    if [ -z "$IP" ] || [ -z "$NAME" ]; then
        print_json_error "Invalid configuration file format."
        exit 1
    fi
    
    echo "{\"status\":\"success\",\"devices\":[{\"name\":\"$NAME\",\"ip\":\"$IP\"}]}"
fi
