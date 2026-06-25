# Hermes Skills

This repository contains a collection of modular skills designed for AI agents, following the [agentskills.io](https://agentskills.io) specification. Compatible with **Hermes Agent**, **Claude Code**, **Codex CLI**, and other agent frameworks that support SKILL.md.

## Repository Structure

```text
hermes-skills/
├── README.md
├── scripts/                 # General repository scripts
│   ├── update.sh            # Script to update the repository via git pull
│   ├── install_skills.sh    # Script to install skills into a target folder
│   └── raw.sh               # One-liner script for remote web installation
└── skills/
    └── <skill-name>/
        ├── SKILL.md                 # Agent-facing metadata and documentation
        ├── config.json              # Local configurations (created during setup)
        ├── references/              # Supporting documentation
        └── scripts/                 # Executable scripts for the skill
```

---

## Installation

### Hermes Agent

```bash
# Option 1: Add this repo as a tap (full skill catalog)
hermes skills tap add https://github.com/Matheusvxz/hermes-skills

# Option 2: Install a single skill by SKILL.md URL
hermes skills install \
  https://raw.githubusercontent.com/Matheusvxz/hermes-skills/main/skills/sonoff-mini/SKILL.md

# Option 3: Check installed skills
hermes skills list
```

After installation, reload skills in the current session: `/reload-skills` (slash command) or start a new session.

> **Important for terminal sandboxes (Hermes Docker backend):** skills scripts live on the host, not inside the sandbox. The agent must materialize them before execution. See the "Hermes sandbox execution" section inside each skill's `SKILL.md`.

### One-Liner Web Installer (Claude Code / general)

```bash
curl -sL https://raw.githubusercontent.com/Matheusvxz/hermes-skills/main/scripts/raw.sh | bash -s -- -folder ~/.claude/skills
```

To force-overwrite any existing skill folders:

```bash
curl -sL https://raw.githubusercontent.com/Matheusvxz/hermes-skills/main/scripts/raw.sh | bash -s -- -folder ~/.claude/skills -force
```

### Manual Installation

```bash
# Normal interactive execution
./scripts/install_skills.sh

# Non-interactive execution
./scripts/install_skills.sh -folder ~/.claude/skills

# Force installation (overwrites conflicting directories)
./scripts/install_skills.sh -folder ~/.claude/skills --force
```

---

## General Scripts

### Repository Update (`scripts/update.sh`)

```bash
./scripts/update.sh
```

---

## Available Skills

### 1. Sonoff Mini DIY Mode (`skills/sonoff-mini`)

Enables control and status retrieval of a Sonoff Mini smart switch configured in DIY mode on the local network.

**All outputs to `stdout` are formatted as structured JSON.**

#### Prerequisites

- A Sonoff Mini device connected to the local network and configured in **DIY Mode** (listening on port 8081).
- `curl` and `jq` installed on the system.

#### Usage

Supply the device IP on first use. Config auto-saves for subsequent calls:

```bash
# First use — specify IP and name
./skills/sonoff-mini/scripts/sonoff_control.sh --ip 192.168.1.150 --name "Living Room" info

# Later calls — saved config is reused
./skills/sonoff-mini/scripts/sonoff_control.sh info
```

##### Get device info/status:

```bash
./skills/sonoff-mini/scripts/sonoff_control.sh --ip 192.168.1.150 info
```

##### Turn switch ON:

```bash
./skills/sonoff-mini/scripts/sonoff_control.sh switch on
```

##### Turn switch OFF:

```bash
./skills/sonoff-mini/scripts/sonoff_control.sh switch off
```

##### List configured devices:

```bash
./skills/sonoff-mini/scripts/list_devices.sh
```

##### Force setup reconfiguration:

```bash
./skills/sonoff-mini/scripts/sonoff_control.sh --ip 192.168.1.150 --name "Living Room" setup
```
