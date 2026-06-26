---
name: sonoff-mini
description: Control Sonoff Mini smart switches in DIY mode locally.
author: Matheusvxz
version: 2.0.0
license: MIT
supporting_files:
  scripts:
    - sonoff_control.sh — Main control script (info, switch on/off, setup)
    - list_devices.sh — List all configured Sonoff Mini devices
  references:
    - api-contract.md — JSON output schema for all commands
metadata:
  hermes:
    category: home-automation
    tags: [sonoff, iot, home-automation, bash, smart-switch]
    related_skills: [embedded-lab]
---

# Sonoff Mini DIY Mode

Control and retrieve status of a Sonoff Mini smart switch running in DIY mode on the local network via HTTP POST requests.

## When to Use

Use this skill when you need to:

- Turn a Sonoff Mini smart switch ON or OFF.
- Check the current power state, startup behavior, or signal strength (RSSI) of a device.
- List all configured Sonoff Mini devices on the local network.
- Configure or update the local IP/name of a Sonoff Mini device.

Do NOT use this skill if the device is connected to the eWeLink cloud or is not configured in DIY mode (listening on local network port 8081).

## Quick Reference

| Action          | Command                                                  | Expected Output                                |
| --------------- | -------------------------------------------------------- | ---------------------------------------------- |
| Get Device Info | `bash scripts/sonoff_control.sh --ip <ip> info`           | JSON with relay status, startup behavior, RSSI |
| Turn ON Switch  | `bash scripts/sonoff_control.sh switch on`               | JSON confirming relay is `on` (uses saved IP)  |
| Turn OFF Switch | `bash scripts/sonoff_control.sh switch off`              | JSON confirming relay is `off` (uses saved IP) |
| List Devices    | `bash scripts/list_devices.sh`                           | JSON array of all configured devices           |

## Procedure

To execute Sonoff Mini controls, follow these steps using the `terminal` tool:

1. **Hermes Sandbox Script Materialization (Docker/Modal backends):**
   - Since the Docker container or remote sandbox does not automatically see host skill files, you must materialize the scripts into the active workspace before running them:
     ```bash
     mkdir -p /workspace/.hermes/skills/sonoff-mini/scripts
     # The agent loads script contents via skill_view and writes them to the workspace path above
     ```
   - For all subsequent executions, run commands from the materialized path (e.g., `bash /workspace/.hermes/skills/sonoff-mini/scripts/sonoff_control.sh`).

2. **Initial Configuration:**
   - Supply the device IP and name on the first invocation to auto-save the configuration (the name defaults to "Sonoff Mini" if not specified):
     ```bash
     bash scripts/sonoff_control.sh --ip 192.168.1.150 --name "Living Room Light" info
     ```
   - To force reconfiguration:
     ```bash
     bash scripts/sonoff_control.sh --ip 192.168.1.150 --name "Living Room Light" setup
     ```

3. **General Control Commands:**
   - **Info:** `bash scripts/sonoff_control.sh info` (reuses saved configuration).
   - **Relay Control:** 
     - To control the saved/configured device:
       ```bash
       bash scripts/sonoff_control.sh switch on
       bash scripts/sonoff_control.sh switch off
       ```
     - To control a specific device and save it as the default configuration:
       ```bash
       bash scripts/sonoff_control.sh --ip 192.168.1.150 --name "Living Room Light" switch on
       ```
     > [!IMPORTANT]
     > The scripts do not support filtering or targeting a device by passing only `--name <label>` without an `--ip`. To control a device, you must either use the currently saved active configuration (by omitting `--ip`), or pass `--ip` directly.
   - **List Configured Devices:** `bash scripts/list_devices.sh`.

## Pitfalls

- **DIY Mode Inactive:** If the physical relay is connected to the eWeLink cloud, the local HTTP API (port 8081) is disabled. Press and hold the physical button on the switch for 5 seconds to toggle DIY mode.
- **Docker Sandbox Network Limits:** The terminal sandbox running inside Docker might not reach local LAN IP addresses (like `192.168.x.x`). If command queries time out, you must execute the scripts directly on the host machine.
- **Dependency Fallback:** If `jq` is not installed, scripts fall back to `sed` for parsing, but output validation is more robust when `jq` is present.
- **Missing Materialization:** Failing to copy the scripts to `/workspace` before invoking them inside a Docker backend will cause `No such file or directory` errors.

## Verification

Validate that commands executed successfully by checking the stdout JSON response:

- A successful command returns `"status": "success"` and the corresponding action details.
- To verify a switch state change, ensure `"state"` matches your target command (`"on"` or `"off"`).
- All command schemas are strictly defined in `references/api-contract.md`.
