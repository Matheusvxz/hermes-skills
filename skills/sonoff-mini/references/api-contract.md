# Sonoff Mini API Contract

Every Sonoff Mini skill script writes structured JSON to stdout. Interactive/verbose output goes to stderr.

## Successful commands

### `scripts/sonoff_control.sh info`

```json
{
  "status": "success",
  "device": { "name": "<device-name>", "ip": "<device-ip>" },
  "info": {
    "switch": "on" | "off",
    "startup": "stay" | "off" | "on",
    "pulse": "on" | "off",
    "pulseWidth": 500,
    "ssid": "<wifi-ssid>",
    "otaState": "NO_OTA" | "OTA_ING",
    "rssi": -55
  }
}
```

### `scripts/sonoff_control.sh switch on|off`

```json
{
  "status": "success",
  "device": { "name": "<device-name>", "ip": "<device-ip>" },
  "action": "switch",
  "state": "on" | "off"
}
```

### `scripts/sonoff_control.sh --ip <ip> [--name <name>] setup`

```json
{
  "status": "success",
  "message": "Configuration saved successfully",
  "device": { "name": "<device-name>", "ip": "<device-ip>" }
}
```

### `scripts/list_devices.sh`

```json
{
  "status": "success",
  "devices": [
    { "name": "<device-name>", "ip": "<device-ip>" }
  ]
}
```

## Error responses

Every error has exit code 1 and this shape:

```json
{
  "status": "error",
  "message": "Human-readable error summary",
  "details": "Optional extended diagnostic"
}
```

Known error messages and details:

| Script | Message (`message`) | Details (`details`) | Likely Cause |
|---|---|---|---|
| `sonoff_control.sh` | `Could not reach the Sonoff Mini.` | `Verify IP, power, DIY mode, and network connection.` | Wrong IP, device powered off, DIY mode disabled, or network routing issue |
| `sonoff_control.sh` | `Configuration file not found.` | `Pass --ip <address> [--name <label>] before the command, or run \`setup\`.` | No saved configuration exists yet, and command was run without `--ip` |
| `sonoff_control.sh` | `Configuration file is corrupted.` | `Remove <config-file-path> and run with --ip again.` | JSON parse failure or invalid keys in `config.json` |
| `sonoff_control.sh` | `Could not retrieve info from device <name> (<ip>).` | `Empty response from device.` | Connection established but device failed to respond (network timeout/crash) |
| `sonoff_control.sh` | `Invalid state '<state>'. Use 'on' or 'off'.` | *(none)* | Wrong state argument passed to the `switch` command |
| `sonoff_control.sh` | `Failed to send command to device <name> (<ip>).` | `Empty response from device.` | Switch command sent but connection timed out/failed |
| `sonoff_control.sh` | `Device returned an error.` | `Code: <err_code>, Response: <raw-response>` | Sonoff Mini HTTP API returned a non-zero error code |
| `sonoff_control.sh` | `IP address is required.` | `Usage: bash sonoff_control.sh --ip <address> [--name <label>] setup` | Run `setup` command without `--ip` |
| `sonoff_control.sh` | `Unknown flag: <flag>` | `See --help for usage.` | Invalid CLI flag passed |
| `sonoff_control.sh` | `Unknown command: <command>` | `See --help for usage.` | Invalid positional command passed |
| `list_devices.sh` | `Configuration file not found.` | `Please run sonoff_control.sh with --ip first.` | Listing devices before any configuration has been saved |
| `list_devices.sh` | `Invalid configuration file format.` | *(none)* | Config file exists but has invalid format and `jq` fallback parser failed |
