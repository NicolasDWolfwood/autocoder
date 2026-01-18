# AutoCoder

[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/leonvanzyl)

A long-running autonomous coding agent powered by the Claude Agent SDK. This tool can build complete applications over multiple sessions using a two-agent pattern (initializer + coding agent). Includes a React-based UI for monitoring progress in real-time.

## 🐳 Docker Deployment

AutoCoder can be deployed as a Docker container for easy setup on Unraid, NAS, or any Docker-compatible system:

```bash
docker run -d \
  --name autocoder \
  -p 8888:8888 \
  -v ./config:/config \
  -v ./data/projects:/data/projects \
  -e ANTHROPIC_API_KEY=sk-ant-your-key-here \
  johnreijmer/autocoder:latest
```

**See [README-DOCKER.md](README-DOCKER.md) for complete Docker deployment guide including:**
- Docker Compose setup
- Unraid installation
- Volume persistence
- Environment variables

---

## Video Tutorial

[![Watch the tutorial](https://img.youtube.com/vi/lGWFlpffWk4/hqdefault.jpg)](https://youtu.be/lGWFlpffWk4)

> **[Watch the setup and usage guide →](https://youtu.be/lGWFlpffWk4)**

---

## Prerequisites

### Claude Code CLI (Required)

This project requires the Claude Code CLI to be installed. Install it using one of these methods:

**macOS / Linux:**
```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://claude.ai/install.ps1 | iex
```

### Authentication

You need one of the following:

- **Claude Pro/Max Subscription** - Use `claude login` to authenticate (recommended)
- **Anthropic API Key** - Pay-per-use from https://console.anthropic.com/

---

## Quick Start

### Option 1: Web UI (Recommended)

**Windows:**
```cmd
start_ui.bat
```

**macOS / Linux:**
```bash
./start_ui.sh
```

This launches the React-based web UI with:
- Project selection and creation
- Kanban board view of features
- Real-time agent output streaming
- Start/pause/stop controls

**Note:** The UI runs on port **8888** in production mode (pre-built React app served by FastAPI). If running in development mode with `--dev` flag, it uses port **5173** (Vite dev server with hot reload).

### Option 2: CLI Mode

**Windows:**
```cmd
start.bat
```

**macOS / Linux:**
```bash
./start.sh
```

The start script will:
1. Check if Claude CLI is installed
2. Check if you're authenticated (prompt to run `claude login` if not)
3. Create a Python virtual environment
4. Install dependencies
5. Launch the main menu

### Creating or Continuing a Project

You'll see options to:
- **Create new project** - Start a fresh project with AI-assisted spec generation
- **Continue existing project** - Resume work on a previous project

For new projects, you can use the built-in `/create-spec` command to interactively create your app specification with Claude's help.

---

## How It Works

### Two-Agent Pattern

1. **Initializer Agent (First Session):** Reads your app specification, creates features in a SQLite database (`features.db`), sets up the project structure, and initializes git.

2. **Coding Agent (Subsequent Sessions):** Picks up where the previous session left off, implements features one by one, and marks them as passing in the database.

### Feature Management

Features are stored in SQLite via SQLAlchemy and managed through an MCP server that exposes tools to the agent:
- `feature_get_stats` - Progress statistics
- `feature_get_next` - Get highest-priority pending feature
- `feature_get_for_regression` - Random passing features for regression testing
- `feature_mark_passing` - Mark feature complete
- `feature_skip` - Move feature to end of queue
- `feature_create_bulk` - Initialize all features (used by initializer)

### Session Management

- Each session runs with a fresh context window
- Progress is persisted via SQLite database and git commits
- The agent auto-continues between sessions (3 second delay)
- Press `Ctrl+C` to pause; run the start script again to resume

---

## Important Timing Expectations

> **Note: Building complete applications takes time!**

- **First session (initialization):** The agent generates feature test cases. This takes several minutes and may appear to hang - this is normal.

- **Subsequent sessions:** Each coding iteration can take **5-15 minutes** depending on complexity.

- **Full app:** Building all features typically requires **many hours** of total runtime across multiple sessions.

**Tip:** The feature count in the prompts determines scope. For faster demos, you can modify your app spec to target fewer features (e.g., 20-50 features for a quick demo).

---

## Project Structure

### Repository Structure

```
autocoder/
├── 🚀 Launcher Scripts
│   ├── start.bat                   # Windows CLI launcher
│   ├── start.sh                    # macOS/Linux CLI launcher
│   ├── start_ui.bat                # Windows Web UI launcher
│   └── start_ui.sh                 # macOS/Linux Web UI launcher
│
├── 🐳 Docker Files
│   ├── Dockerfile                  # Multi-stage Docker build
│   ├── docker-compose.yml          # Local Docker Compose setup
│   ├── docker-compose.hub.yml      # Docker Hub image example
│   ├── docker-build-push.sh        # Build & push script (multi-arch)
│   ├── docker-build-push.bat       # Build & push script (Windows)
│   ├── .dockerignore               # Docker build exclusions
│   └── unraid-template.xml         # Unraid Community Apps template
│
├── 📚 Documentation
│   ├── README.md                   # This file
│   ├── README-DOCKER.md            # Docker deployment guide
│   ├── DOCKER-HUB.md               # Publishing to Docker Hub
│   ├── DOCKER-VOLUMES.md           # Volume persistence guide
│   ├── PORT-REFERENCE.md           # Port configuration reference
│   └── CLAUDE.md                   # Architecture and patterns
│
├── 🐍 Python Backend
│   ├── start.py                    # CLI menu system
│   ├── start_ui.py                 # Web UI launcher (FastAPI)
│   ├── autonomous_agent_demo.py    # Agent entry point
│   ├── agent.py                    # Agent session loop
│   ├── client.py                   # Claude SDK client with security
│   ├── security.py                 # Bash command allowlist
│   ├── progress.py                 # Progress tracking & webhooks
│   ├── prompts.py                  # Prompt template loading
│   ├── registry.py                 # Project registry (SQLite)
│   ├── parallel_orchestrator.py    # Multi-agent coordination
│   └── requirements.txt            # Python dependencies
│
├── 🗄️ Database & API
│   └── api/
│       ├── database.py             # SQLAlchemy models (Feature)
│       └── dependency_resolver.py  # Dependency graph validation
│
├── 🔌 MCP Server
│   └── mcp_server/
│       └── feature_mcp.py          # Feature management MCP tools
│
├── 🌐 FastAPI Server
│   └── server/
│       ├── main.py                 # FastAPI app & static file serving
│       ├── websocket.py            # Real-time WebSocket handler
│       ├── schemas.py              # Pydantic models
│       ├── routers/                # API endpoints
│       │   ├── projects.py         # Project CRUD
│       │   ├── features.py         # Feature management
│       │   ├── agent.py            # Agent control
│       │   ├── filesystem.py       # Folder browser
│       │   ├── spec_creation.py   # Interactive spec creation
│       │   └── ...
│       └── services/               # Business logic
│           ├── process_manager.py  # Agent subprocess management
│           ├── dev_server_manager.py # Dev server lifecycle
│           └── ...
│
├── ⚛️ React Frontend
│   └── ui/
│       ├── src/
│       │   ├── App.tsx             # Main app component
│       │   ├── components/         # UI components
│       │   │   ├── ProjectSelector.tsx
│       │   │   ├── KanbanBoard.tsx
│       │   │   ├── DependencyGraph.tsx
│       │   │   ├── AgentMissionControl.tsx
│       │   │   └── ...
│       │   ├── hooks/              # React Query & WebSocket
│       │   ├── lib/                # API client & types
│       │   └── styles/             # Tailwind CSS v4 config
│       ├── package.json
│       ├── vite.config.ts
│       └── dist/                   # Built production files (served by FastAPI)
│
├── 🎨 Claude Code Configuration
│   └── .claude/
│       ├── commands/
│       │   ├── create-spec.md      # /create-spec command
│       │   └── expand-project.md   # /expand-project command
│       ├── skills/
│       │   └── frontend-design/    # Distinctive UI design skill
│       └── templates/              # Prompt templates
│           ├── initializer_prompt.template.md
│           └── coding_prompt.template.md
│
└── 📁 Runtime Data (not in repo)
    ├── config/                     # Docker: /config volume
    │   └── .autocoder/
    │       └── registry.db         # Project registry database
    ├── data/projects/              # Docker: /data/projects volume
    │   └── my-app/                 # Your generated projects
    │       ├── features.db
    │       ├── prompts/
    │       └── src/
    └── venv/                       # Python virtual environment (local)
```

---

## Generated Project Structure

After the agent runs, each generated project will contain:

```
my-app/                       # Your project (in /data/projects in Docker)
├── features.db               # SQLite database (feature test cases & progress)
├── prompts/
│   ├── app_spec.txt          # Your application specification (XML format)
│   ├── initializer_prompt.md # First session prompt (reads spec, creates features)
│   └── coding_prompt.md      # Continuation session prompt (implements features)
├── .autocoder/
│   └── config.json           # Project-specific configuration (dev server settings)
├── .agent.lock               # Lock file (prevents multiple agents, auto-removed)
├── .claude_settings.json     # Security settings (auto-generated per session)
├── package.json              # Node.js dependencies (if applicable)
├── src/                      # Your generated application code
│   ├── App.tsx               # Main component (example for React apps)
│   ├── components/           # UI components
│   └── ...                   # Other source files
├── public/                   # Static assets
├── README.md                 # Generated project documentation
└── ...                       # Other files created by the agent
```

**Local development:** Projects are stored where you specify (e.g., `d:\my-projects\my-app`)
**Docker deployment:** Projects are stored in `/data/projects` (mapped to host volume)

---

## Running the Generated Application

After the agent completes (or pauses), you can run the generated application:

### Local Development

```bash
# Navigate to your project
cd /path/to/my-app

# Install dependencies (typically for Node.js apps)
npm install

# Start the development server
npm run dev
```

### Docker Deployment

```bash
# Access your project files on the host
cd /mnt/user/appdata/autocoder/projects/my-app  # Unraid
# or
cd d:\testdocker\data\projects\my-app           # Windows Docker

# Install and run (same as local)
npm install
npm run dev
```

The application will typically be available at `http://localhost:3000` or similar.

**Note:** The AutoCoder UI includes a built-in dev server launcher that can start your app's dev server directly from the web interface!

---

## Security Model

This project uses a defense-in-depth security approach (see `security.py` and `client.py`):

1. **OS-level Sandbox:** Bash commands run in an isolated environment
2. **Filesystem Restrictions:** File operations restricted to the project directory only
3. **Bash Allowlist:** Only specific commands are permitted:
   - File inspection: `ls`, `cat`, `head`, `tail`, `wc`, `grep`
   - Node.js: `npm`, `node`
   - Version control: `git`
   - Process management: `ps`, `lsof`, `sleep`, `pkill` (dev processes only)

Commands not in the allowlist are blocked by the security hook.

---

## Web UI Development

The React UI is located in the `ui/` directory.

### Development Mode

```bash
cd ui
npm install
npm run dev      # Development server with hot reload
```

### Building for Production

```bash
cd ui
npm run build    # Builds to ui/dist/
```

**Note:** The `start_ui.bat`/`start_ui.sh` scripts serve the pre-built UI from `ui/dist/`. After making UI changes, run `npm run build` to see them when using the start scripts.

### Tech Stack

- React 18 with TypeScript
- TanStack Query for data fetching
- Tailwind CSS v4 with neobrutalism design
- Radix UI components
- WebSocket for real-time updates

### Real-time Updates

The UI receives live updates via WebSocket (`/ws/projects/{project_name}`):
- `progress` - Test pass counts
- `agent_status` - Running/paused/stopped/crashed
- `log` - Agent output lines (streamed from subprocess stdout)
- `feature_update` - Feature status changes

---

## Configuration (Optional)

### N8N Webhook Integration

The agent can send progress notifications to an N8N webhook. Create a `.env` file:

```bash
# Optional: N8N webhook for progress notifications
PROGRESS_N8N_WEBHOOK_URL=https://your-n8n-instance.com/webhook/your-webhook-id
```

When test progress increases, the agent sends:

```json
{
  "event": "test_progress",
  "passing": 45,
  "total": 200,
  "percentage": 22.5,
  "project": "my_project",
  "timestamp": "2025-01-15T14:30:00.000Z"
}
```

### Using GLM Models (Alternative to Claude)

To use Zhipu AI's GLM models instead of Claude, add these variables to your `.env` file in the AutoCoder directory:

```bash
ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
ANTHROPIC_AUTH_TOKEN=your-zhipu-api-key
API_TIMEOUT_MS=3000000
ANTHROPIC_DEFAULT_SONNET_MODEL=glm-4.7
ANTHROPIC_DEFAULT_OPUS_MODEL=glm-4.7
ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-4.5-air
```

This routes AutoCoder's API requests through Zhipu's Claude-compatible API, allowing you to use GLM-4.7 and other models. **This only affects AutoCoder** - your global Claude Code settings remain unchanged.

Get an API key at: https://z.ai/subscribe

---

## Customization

### Changing the Application

Use the `/create-spec` command when creating a new project, or manually edit the files in your project's `prompts/` directory:
- `app_spec.txt` - Your application specification
- `initializer_prompt.md` - Controls feature generation

### Modifying Allowed Commands

Edit `security.py` to add or remove commands from `ALLOWED_COMMANDS`.

---

## Troubleshooting

### Local Development Issues

**"Claude CLI not found"**
Install the Claude Code CLI using the instructions in the Prerequisites section.

**"Not authenticated with Claude"**
Run `claude login` to authenticate. The start script will prompt you to do this automatically.

**"Appears to hang on first run"**
This is normal. The initializer agent is generating detailed test cases, which takes significant time. Watch for `[Tool: ...]` output to confirm the agent is working.

**"Command blocked by security hook"**
The agent tried to run a command not in the allowlist. This is the security system working as intended. If needed, add the command to `ALLOWED_COMMANDS` in `security.py`.

### Docker Deployment Issues

**"Projects created in /config instead of /data/projects"**
This was a bug in versions prior to 0.0.2. Update to the latest image: `docker pull johnreijmer/autocoder:latest`

**"Can't access UI from other devices"**
1. Verify `DOCKER_MODE=true` is set
2. Check firewall rules on your server
3. Ensure port 8888 is properly mapped

**"Container won't start"**
Check logs: `docker logs autocoder` or `docker-compose logs`

**For more Docker troubleshooting, see [README-DOCKER.md](README-DOCKER.md#troubleshooting)**

---

## Quick Reference

### Deployment Comparison

| Feature | Local Development | Docker (Unraid/NAS) |
|---------|------------------|---------------------|
| **Installation** | Clone repo, run `start_ui.bat` | `docker pull johnreijmer/autocoder:latest` |
| **Authentication** | `claude login` or API key | API key via environment variable |
| **UI Port** | 8888 (production) or 5173 (dev) | 8888 |
| **Project Storage** | Anywhere on your system | `/data/projects` (mapped to host) |
| **Config Storage** | `~/.autocoder/` | `/config` (mapped to host) |
| **Access** | `http://localhost:8888` | `http://your-server-ip:8888` |
| **Updates** | `git pull` | `docker pull` + restart |
| **Best For** | Active development, testing | Always-on server, team access |

### Key Paths

| Context | Projects Location | Registry Database | Docker Volume |
|---------|------------------|-------------------|---------------|
| **Local Windows** | User-specified | `C:\Users\YourName\.autocoder\registry.db` | N/A |
| **Local Linux/Mac** | User-specified | `~/.autocoder/registry.db` | N/A |
| **Docker Container** | `/data/projects` | `/config/.autocoder/registry.db` | Yes |
| **Unraid Host** | `/mnt/user/appdata/autocoder/projects` | `/mnt/user/appdata/autocoder/config/.autocoder/registry.db` | Mapped |

### Important Links

- 🐳 **Docker Deployment:** [README-DOCKER.md](README-DOCKER.md)
- 📦 **Docker Hub:** [Publishing Guide](DOCKER-HUB.md)
- 💾 **Volume Persistence:** [DOCKER-VOLUMES.md](DOCKER-VOLUMES.md)
- 🔌 **Port Configuration:** [PORT-REFERENCE.md](PORT-REFERENCE.md)
- 🏗️ **Architecture:** [CLAUDE.md](CLAUDE.md)

---

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE.md](LICENSE.md) file for details.
Copyright (C) 2026 Leon van Zyl (https://leonvanzyl.com)
