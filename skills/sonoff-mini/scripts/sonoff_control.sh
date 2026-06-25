#!/usr/bin/env bash

# Get directory where the script is located to reference config.json
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config.json"

# Helper to read values from JSON
get_config_val() {
    local KEY=$1
    if command -v jq &> /dev/null; then
        jq -r ".$KEY" "$CONFIG_FILE"
    else
        # Simple fallback using sed if jq is not installed
        sed -n 's/.*"'"$KEY"'"\s*:\s*"\([^"]*\)".*/\1/p' "$CONFIG_FILE"
    fi
}

# Helper to print structured JSON error
print_json_error() {
    local MSG=$1
    local DETAILS=$2
    local ESCAPED_MSG
    local ESCAPED_DETAILS
    
    ESCAPED_MSG=$(echo "$MSG" | sed 's/"/\\"/g')
    
    if [ -n "$DETAILS" ]; then
        ESCAPED_DETAILS=$(echo "$DETAILS" | sed 's/"/\\"/g')
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

# Helper to print structured JSON success
print_json_success() {
    local ACTION=$1
    local DATA=$2
    local IP
    local NAME
    
    IP=$(get_config_val "ip")
    NAME=$(get_config_val "name")
    
    local JSON
    if [ "$ACTION" = "info" ]; then
        JSON="{\"status\":\"success\",\"device\":{\"name\":\"$NAME\",\"ip\":\"$IP\"},\"info\":$DATA}"
    elif [ "$ACTION" = "switch" ]; then
        JSON="{\"status\":\"success\",\"device\":{\"name\":\"$NAME\",\"ip\":\"$IP\"},\"action\":\"switch\",\"state\":\"$DATA\"}"
    elif [ "$ACTION" = "setup" ]; then
        JSON="{\"status\":\"success\",\"message\":\"Configuration saved successfully\",\"device\":{\"name\":\"$NAME\",\"ip\":\"$IP\"}}"
    fi
    
    if command -v jq &> /dev/null; then
        echo "$JSON" | jq .
    else
        echo "$JSON"
    fi
}

# Initial Configuration Flow (Interactive inputs are routed to stderr)
run_setup() {
    echo "==========================================================" >&2
    echo "       SONOFF MINI SKILL INITIAL CONFIGURATION            " >&2
    echo "==========================================================" >&2
    echo "WARNING: This skill requires your Sonoff Mini to be" >&2
    echo "configured in DIY (Do-It-Yourself) mode and connected to" >&2
    echo "the same local network as this computer." >&2
    echo "----------------------------------------------------------" >&2
    echo >&2
    
    echo -n "Enter your Sonoff Mini's IP address (e.g., 192.168.1.150): " >&2
    read IP
    if [ -z "$IP" ]; then
        print_json_error "IP address cannot be empty."
        exit 1
    fi
    
    echo -n "Enter a name to identify the device (e.g., Living Room Light): " >&2
    read NAME
    if [ -z "$NAME" ]; then
        NAME="Sonoff Mini"
    fi
    
    echo >&2
    echo "Validating connection and DIY mode with $IP..." >&2
    
    # Test connection to the Sonoff Mini in DIY mode
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
         -d '{"deviceid": "", "data": {}}' \
         --connect-timeout 5 \
         "http://${IP}:8081/zeroconf/info")
         
    CURL_STATUS=$?
    
    if [ $CURL_STATUS -ne 0 ] || [ -z "$RESPONSE" ]; then
        echo "----------------------------------------------------------" >&2
        echo "CONNECTION ERROR: Could not reach the Sonoff Mini." >&2
        echo "----------------------------------------------------------" >&2
        print_json_error "Could not reach the Sonoff Mini." "Verify IP, power, DIY mode, and network connection."
        exit 1
    fi
    
    # Create configuration json file
    cat <<EOF > "$CONFIG_FILE"
{
  "ip": "$IP",
  "name": "$NAME"
}
EOF
    echo "----------------------------------------------------------" >&2
    echo "Configuration successfully saved." >&2
    echo "----------------------------------------------------------" >&2
    echo >&2
    
    print_json_success "setup"
}

# Load configuration file and trigger setup if necessary
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        run_setup
    fi
    
    IP=$(get_config_val "ip")
    NAME=$(get_config_val "name")
    
    if [ -z "$IP" ]; then
        echo "Invalid configuration found. Restarting setup..." >&2
        run_setup
        IP=$(get_config_val "ip")
        NAME=$(get_config_val "name")
    fi
}

# Get device info
get_info() {
    local RESPONSE
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
         -d '{"deviceid": "", "data": {}}' \
         "http://${IP}:8081/zeroconf/info")
         
    if [ -z "$RESPONSE" ]; then
        print_json_error "Could not retrieve info from device $NAME ($IP)." "Empty response from device."
        exit 1
    fi
    
    local DATA_PART
    if command -v jq &> /dev/null; then
        DATA_PART=$(echo "$RESPONSE" | jq -c '.data')
    else
        # Simple extraction of the data JSON object using sed if jq is not present
        DATA_PART=$(echo "$RESPONSE" | sed -n 's/.*"data"\s*:\s*\({[^}]*}\).*/\1/p')
        if [ -z "$DATA_PART" ]; then
            DATA_PART="$RESPONSE"
        fi
    fi
    
    print_json_success "info" "$DATA_PART"
}

# Change switch state (on/off)
set_switch() {
    local STATE=$1
    if [ "$STATE" != "on" ] && [ "$STATE" != "off" ]; then
        print_json_error "Invalid state '$STATE'. Use 'on' or 'off'."
        exit 1
    fi
    
    local RESPONSE
    RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
         -d "{\"deviceid\": \"\", \"data\": {\"switch\": \"$STATE\"}}" \
         "http://${IP}:8081/zeroconf/switch")
         
    if [ -z "$RESPONSE" ]; then
        print_json_error "Failed to send command to device $NAME ($IP)." "Empty response from device."
        exit 1
    fi
    
    # Check if Sonoff returned success (error 0)
    local ERR_CODE
    if command -v jq &> /dev/null; then
        ERR_CODE=$(echo "$RESPONSE" | jq '.error')
    else
        ERR_CODE=$(echo "$RESPONSE" | sed -n 's/.*"error"\s*:\s*\([0-9]*\).*/\1/p')
    fi
    
    if [ "$ERR_CODE" = "0" ]; then
        print_json_success "switch" "$STATE"
    else
        print_json_error "Device returned an error." "Code: $ERR_CODE, Response: $RESPONSE"
        exit 1
    fi
}

# JSON Usage document
show_usage() {
    local USAGE_JSON='{
  "status": "error",
  "message": "Invalid command or usage.",
  "usage": {
    "command": "./sonoff_control.sh <action> [arguments]",
    "actions": {
      "info": "Returns device information in JSON",
      "switch <on|off>": "Turns the device on or off",
      "setup": "Forces reconfiguration of the skill"
    }
  }
}'
    if command -v jq &> /dev/null; then
        echo "$USAGE_JSON" | jq .
    else
        echo "$USAGE_JSON"
    fi
}

# Entry point
case "$1" in
    info)
        load_config
        get_info
        ;;
    switch)
        load_config
        set_switch "$2"
        ;;
    setup)
        run_setup
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
