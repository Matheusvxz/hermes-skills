---
name: sonoff-mini
description: Control and retrieve status of a Sonoff Mini smart switch in DIY mode on the local network. Use this skill when you need to turn the device on/off or check its current power state and connection info.
license: MIT
compatibility: Local network access, Bash, curl, jq
---

# Sonoff Mini DIY Mode Skill

This skill allows the agent to communicate with a Sonoff Mini device running in DIY mode on the local network. All command outputs are returned as structured JSON.

## Prerequisite: DIY Mode
The Sonoff Mini must be configured in DIY mode and connected to the same local network. If the device is connected to the eWeLink app or cloud, the local HTTP API will not be active.

## Configuration
On the first execution of the controller script, it checks for a `config.json` file. If not found or empty, the script will:
1. Explain that the Sonoff Mini must be in DIY mode.
2. Prompt for the device's IP address.
3. Prompt for the device's name.
4. Perform an HTTP POST to `http://<IP>:8081/zeroconf/info` to check if DIY mode is active.
5. If active, save these configurations to `config.json` inside the skill directory.

*Note: All interactive prompts and warnings are outputted to `stderr`, while the final setup result is printed as structured JSON to `stdout`.*

## Usage
Run the controller script inside `scripts/sonoff_control.sh`:

- **Get Device Info:**
  ```bash
  ./scripts/sonoff_control.sh info
  ```
  Returns a JSON containing the current switch status, signal strength (RSSI), and device details.
  Example output:
  ```json
  {
    "status": "success",
    "device": {
      "name": "Living Room Light",
      "ip": "192.168.1.150"
    },
    "info": {
      "switch": "off",
      "startup": "stay",
      "rssi": -55
    }
  }
  ```

- **Turn ON the Switch:**
  ```bash
  ./scripts/sonoff_control.sh switch on
  ```
  Example output:
  ```json
  {
    "status": "success",
    "device": {
      "name": "Living Room Light",
      "ip": "192.168.1.150"
    },
    "action": "switch",
    "state": "on"
  }
  ```

- **Turn OFF the Switch:**
  ```bash
  ./scripts/sonoff_control.sh switch off
  ```

- **List Configured Devices:**
  ```bash
  ./scripts/list_devices.sh
  ```
  Returns a JSON list of all devices stored in the configuration file.
  Example output:
  ```json
  {
    "status": "success",
    "devices": [
      {
        "name": "Living Room Light",
        "ip": "192.168.1.150"
      }
    ]
  }
  ```

- **JSON Error Output:**
  If a connection or execution error occurs, the script returns a structured JSON error to `stdout` (exit code 1).
  Example output:
  ```json
  {
    "status": "error",
    "message": "Could not reach the Sonoff Mini.",
    "details": "Verify IP, power, DIY mode, and network connection."
  }
  ```
