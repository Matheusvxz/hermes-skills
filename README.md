# Hermes Skills

This repository contains a collection of modular skills designed for AI agents, following the [agentskills.io](https://agentskills.io) specification.

## Repository Structure

The repository is modularly structured, allowing each skill to reside in its own directory inside the `skills/` folder, alongside general-purpose utility scripts at the root level.

```
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
        └── scripts/                 # Executable scripts for the skill
```

---

## Installation

### One-Liner Web Installer (Recommended)
You can install all skills in a single command without cloning the repository manually. This fetches the script and clones the `main` branch into a temporary directory to perform the install:

```bash
curl -sL https://raw.githubusercontent.com/Matheusvxz/hermes-skills/main/scripts/raw.sh | bash -s -- -folder ~/.claude/skills
```

To force-overwrite any existing skill folders:
```bash
curl -sL https://raw.githubusercontent.com/Matheusvxz/hermes-skills/main/scripts/raw.sh | bash -s -- -folder ~/.claude/skills -force
```

### Manual Installation
If you have already cloned the repository, you can run the installer script directly:

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
Executes `git pull` to fetch the latest commits from the remote repository.

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

#### Usage & Initial Setup
On the first execution of any command, the control script validates connection to the local device and prompts for its IP address and name. These values are saved to `config.json` inside the skill's folder.

*Note: All interactive configuration prompts are outputted to `stderr` to avoid polluting the JSON stdout parser.*

##### Get device info/status:
```bash
./skills/sonoff-mini/scripts/sonoff_control.sh info
```

##### Turn switch ON:
```bash
./skills/sonoff-mini/scripts/sonoff_control.sh switch on
```

##### Turn switch OFF:
```bash
./skills/sonoff-mini/scripts/sonoff_control.sh switch off
```

##### Force setup reconfiguration:
```bash
./skills/sonoff-mini/scripts/sonoff_control.sh setup
```