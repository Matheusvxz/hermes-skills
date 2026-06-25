# Sonoff Mini API Contract

Every Sonoff Mini skill script writes structured JSON to stdout. Interactive/verbose output goes to stderr.

## Successful commands

### `sonoff_control.sh info`

```json
{
  "status": "success",
  "device": { "name": "<device-name>", "ip": "<device-ip>" },
  "info": {
    "switch": "on" | "off",
    "startup": "stay" | "off",
    "rssi": -55
  }
}
```

### `sonoff_control.sh switch on|off`

```json
{
  "status": "success",
  "device": { "name": "<device-name>", "ip": "<device-ip>" },
  "action": "switch",
  "state": "on" | "off"
}
```

### `sonoff_control.sh --ip <ip> --name <name> setup`

```json
{
  "status": "success",
  "message": "Configuration saved successfully",
  "device": { "name": "<device-name>", "ip": "<device-ip>" }
}
```

### `list_devices.sh`

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

Known error messages:

| message | likely cause |
|---------|--------------|
| `Could not reach the Sonoff Mini.` | Wrong IP, device off, DIY mode disabled |
| `Empty response from device.` | Network timeout or device crashed |
| `Device returned an error.` | Sonoff rejected the command |
| `Invalid state. Use 'on' or 'off'.` | Wrong argument passed to `switch` |
| `Configuration file not found.` | No saved config and no `--ip` provided |
| `IP address is required when no config exists.` | Missing `--ip` on first use |
| `Configuration file is corrupted.` | JSON parse failure in config.json |
