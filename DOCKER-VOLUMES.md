# Docker Volume Persistence Guide

This document explains what data needs to be persisted in the AutoCoder Docker container and the recommended volume mappings.

## Overview

The AutoCoder container generates and stores several types of data that should persist across container restarts. Understanding these paths is crucial for proper Docker deployment.

## Critical Persistent Data

### 1. `/config` - Configuration & Registry (CRITICAL)

**Container Path:** `/config`
**What's stored:**
- `~/.autocoder/registry.db` - Project registry database (maps project names to paths)
- `~/.claude/` - Claude Code CLI settings (if needed, though API key is preferred)
- Other user-specific configuration

**Why it's important:**
- Contains the **project registry** - without this, the system won't know where your projects are
- Stores settings and preferences
- Losing this means losing all project registrations

**Recommended Host Path:**
- Unraid: `/mnt/user/appdata/autocoder/config`
- Docker Compose: `./config`

**Note:** The Dockerfile sets `ENV HOME=/config` so that `~/.autocoder` resolves to `/config/.autocoder` inside the container.

### 2. `/data/projects` - Generated Applications (CRITICAL)

**Container Path:** `/data/projects`
**What's stored:**
- All generated application code (your actual projects!)
- Each project contains:
  - `features.db` - SQLite database with feature tests and progress
  - `prompts/` - App specs and prompt templates
  - `.autocoder/config.json` - Project-specific configuration
  - `.agent.lock` - Lock file (temporary, prevents multiple agents)
  - `.claude_settings.json` - Security settings (temporary)
  - All generated source code files

**Why it's important:**
- **This is your actual work!** All the code the agent generates
- Contains feature tracking and test results
- Losing this means losing all your generated applications

**Recommended Host Path:**
- Unraid: `/mnt/user/appdata/autocoder/projects`
- Docker Compose: `./data/projects`

## Optional Persistent Data

### 3. `/app/mcp_server` - Custom MCP Servers (OPTIONAL)

**Container Path:** `/app/mcp_server`
**What's stored:**
- Custom MCP (Model Context Protocol) server implementations
- By default, the container includes `feature_mcp.py` for feature management

**Why you might persist it:**
- If you create custom MCP servers
- Most users won't need this

**Note:** The built-in MCP servers are baked into the container image.

## Data Structure Breakdown

### Inside `/config`

```
/config/
├── .autocoder/
│   └── registry.db          # Project registry (SQLite database)
└── .claude/                 # Claude CLI config (optional with API key)
    └── settings.json
```

### Inside `/data/projects`

```
/data/projects/
├── my-app-1/                # Your first project
│   ├── features.db          # Feature tracking database
│   ├── prompts/
│   │   ├── app_spec.txt     # Application specification
│   │   ├── initializer_prompt.md
│   │   └── coding_prompt.md
│   ├── .autocoder/
│   │   └── config.json      # Project dev server settings
│   ├── .agent.lock          # Temporary lock file
│   ├── .claude_settings.json # Temporary security settings
│   ├── src/                 # Your generated code!
│   ├── package.json
│   └── ...
├── my-app-2/                # Your second project
│   └── ...
└── my-app-3/
    └── ...
```

## Temporary Files (No Need to Persist)

These files are **temporary** and will be recreated by the container:

- `{project}/.agent.lock` - Lock file (removed when agent stops)
- `{project}/.claude_settings.json` - Generated each run
- `{project}/.claude_assistant_settings.json` - Generated each run
- `{project}/.claude_settings.expand.*.json` - Temporary expand session settings

## Recommended Volume Configurations

### Docker Compose (Development/Local)

```yaml
version: '3.8'
services:
  autocoder:
    image: johnreijmer/autocoder:latest
    volumes:
      # Critical: Config and registry
      - ./config:/config

      # Critical: Your generated projects
      - ./data/projects:/data/projects

      # Optional: Custom MCP servers (uncomment if needed)
      # - ./mcp_server:/app/mcp_server
```

### Unraid Template

```xml
<Config Name="Config Directory" Target="/config"
        Default="/mnt/user/appdata/autocoder/config"
        Mode="rw" Type="Path" Display="always" Required="true">
  /mnt/user/appdata/autocoder/config
</Config>

<Config Name="Projects Directory" Target="/data/projects"
        Default="/mnt/user/appdata/autocoder/projects"
        Mode="rw" Type="Path" Display="always" Required="true">
  /mnt/user/appdata/autocoder/projects
</Config>
```

### Docker CLI

```bash
docker run -d \
  --name autocoder \
  -p 8888:8888 \
  -v /mnt/user/appdata/autocoder/config:/config \
  -v /mnt/user/appdata/autocoder/projects:/data/projects \
  -e ANTHROPIC_API_KEY=sk-ant-your-key-here \
  johnreijmer/autocoder:latest
```

## Database Files Explained

### Registry Database (`~/.autocoder/registry.db`)

- **Location in container:** `/config/.autocoder/registry.db`
- **Purpose:** Maps project names to filesystem paths
- **Schema:** SQLAlchemy with `Project` model (name, path, model, yolo_mode, timestamps)
- **Access:** Thread-safe with connection pooling
- **Critical:** Without this, the web UI won't find your projects

### Project Database (`{project}/features.db`)

- **Location:** Inside each project directory
- **Purpose:** Stores feature test cases, dependencies, and progress
- **Schema:** SQLAlchemy with `Feature` model (priority, category, name, description, steps, status, dependencies)
- **Access:** Via MCP server (feature_mcp.py)
- **Critical:** Without this, the agent doesn't know what to build

## Migration Between Hosts

If moving your AutoCoder setup to a new server:

### Step 1: Backup volumes
```bash
# Stop container
docker stop autocoder

# Archive volumes
tar -czf autocoder-backup.tar.gz \
  /mnt/user/appdata/autocoder/config \
  /mnt/user/appdata/autocoder/projects
```

### Step 2: Transfer to new host
```bash
# Copy to new server
scp autocoder-backup.tar.gz newserver:/tmp/

# Extract on new server
ssh newserver
cd /mnt/user/appdata/autocoder
tar -xzf /tmp/autocoder-backup.tar.gz
```

### Step 3: Update registry paths (if needed)

If your project paths changed (e.g., different mount points), update the registry:

```bash
# Enter the container
docker exec -it autocoder bash

# Use Python to update paths
python3 << 'EOF'
from pathlib import Path
from registry import list_projects, update_project

# List all projects
projects = list_projects()

for proj in projects:
    # Update path if needed (example)
    old_path = Path(proj['path'])
    new_path = Path('/data/projects') / old_path.name

    if old_path != new_path:
        update_project(
            proj['name'],
            path=str(new_path),
            model=proj['model'],
            yolo_mode=proj['yolo_mode']
        )
        print(f"Updated {proj['name']}: {old_path} -> {new_path}")
EOF
```

## Troubleshooting

### "No projects found" after restore

**Cause:** Registry database is missing or corrupt
**Solution:**
```bash
# Verify registry exists
docker exec autocoder ls -la /config/.autocoder/

# If missing, check your volume mount
docker inspect autocoder | grep -A 10 Mounts
```

### Projects exist but aren't registered

**Cause:** Projects were copied manually without updating registry
**Solution:** Register them via the UI or use the registry CLI

### "Database is locked" errors

**Cause:** Multiple processes accessing SQLite simultaneously
**Solution:**
- Ensure only one agent runs per project (check for stale `.agent.lock` files)
- SQLite has built-in timeout and retry logic (30s timeout, 3 retries)

### Lost all my projects!

**Cause:** Didn't mount `/data/projects` volume
**Prevention:**
- **ALWAYS** mount both `/config` and `/data/projects`
- Test with a dummy project first
- Set up regular backups

## Backup Strategy

### Automated Backup Script

```bash
#!/bin/bash
# Save as: backup-autocoder.sh

BACKUP_DIR="/mnt/user/backups/autocoder"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/autocoder-$DATE.tar.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Stop container for consistent backup (optional)
# docker stop autocoder

# Create archive
tar -czf "$BACKUP_FILE" \
  /mnt/user/appdata/autocoder/config \
  /mnt/user/appdata/autocoder/projects

# Restart container (if stopped)
# docker start autocoder

# Keep only last 7 backups
ls -t "$BACKUP_DIR"/autocoder-*.tar.gz | tail -n +8 | xargs -r rm

echo "Backup complete: $BACKUP_FILE"
```

### Add to Unraid User Scripts

1. Install "User Scripts" plugin
2. Add new script
3. Paste the backup script above
4. Set schedule (e.g., daily at 2 AM)

## Best Practices

1. **Always mount both critical volumes** (`/config` and `/data/projects`)
2. **Use absolute paths** in volume mounts (e.g., `/mnt/user/appdata/...`)
3. **Set up regular backups** of both volumes
4. **Test restore procedure** before you need it
5. **Don't manually edit database files** - use the API/UI
6. **Check disk space** - generated projects can grow large
7. **Use named volumes** for production deployments (better Docker integration)

## Named Volumes (Alternative Approach)

Instead of bind mounts, you can use Docker named volumes:

```yaml
version: '3.8'
services:
  autocoder:
    image: johnreijmer/autocoder:latest
    volumes:
      - autocoder-config:/config
      - autocoder-projects:/data/projects

volumes:
  autocoder-config:
    driver: local
  autocoder-projects:
    driver: local
```

**Advantages:**
- Docker manages volume lifecycle
- Better performance on Windows/Mac
- Easier to backup with `docker volume` commands

**Disadvantages:**
- Less visible on host filesystem
- Harder to manually inspect files

**Backup named volumes:**
```bash
docker run --rm \
  -v autocoder-config:/source \
  -v $(pwd):/backup \
  alpine tar -czf /backup/config-backup.tar.gz -C /source .
```

## Summary

**Minimum Required Volumes:**
1. `/config` → Stores registry.db and settings
2. `/data/projects` → Stores all your generated code

**Without these volumes, you will lose:**
- Project registrations (can't find projects)
- All generated application code
- Feature tracking and progress
- Project configurations

**Always backup both volumes regularly!**
