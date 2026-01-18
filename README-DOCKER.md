# Docker Deployment Guide

This guide explains how to deploy AutoCoder as a Docker container on Unraid or any Docker-compatible system.

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Anthropic API key (get one from [console.anthropic.com](https://console.anthropic.com))

### Using Docker Compose (Recommended)

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd autocoder
   ```

2. **Create environment file:**
   ```bash
   cp .env.example .env
   ```

   Edit `.env` and add your API key:
   ```
   ANTHROPIC_API_KEY=sk-ant-...
   ```

3. **Build and start the container:**
   ```bash
   docker-compose up -d
   ```

4. **Access the UI:**
   Open your browser to `http://localhost:8888` (or use your server's IP address)

### Using Docker CLI

If you prefer to use Docker commands directly:

```bash
# Build the image
docker build -t autocoder:latest .

# Run the container
docker run -d \
  --name autocoder \
  -p 8888:8888 \
  -v $(pwd)/config:/config \
  -v $(pwd)/data/projects:/data/projects \
  -e ANTHROPIC_API_KEY=sk-ant-your-key-here \
  -e DOCKER_MODE=true \
  --restart unless-stopped \
  autocoder:latest
```

## Unraid Deployment

### Method 1: Docker Compose Manager (Recommended)

If you have the Docker Compose Manager plugin installed on Unraid:

1. Copy the repository to your Unraid server (e.g., `/mnt/user/appdata/autocoder/`)
2. Create a `.env` file with your `ANTHROPIC_API_KEY`
3. In the Docker Compose Manager UI, add the stack pointing to your `docker-compose.yml`
4. Start the stack

### Method 2: Community Applications Template

1. In Unraid, go to **Apps** tab
2. If a template exists, search for "AutoCoder" and install
3. Configure the API key in the template settings

### Method 3: Manual Docker Container

1. Go to **Docker** tab in Unraid
2. Click **Add Container**
3. Configure as follows:
   - **Name:** `autocoder`
   - **Repository:** Build the image first or use your registry
   - **Network Type:** `bridge`
   - **Port:** `8888` → `8888` (TCP)
   - **Path 1:** Container Path: `/config` | Host Path: `/mnt/user/appdata/autocoder/config`
   - **Path 2:** Container Path: `/data/projects` | Host Path: `/mnt/user/appdata/autocoder/projects`
   - **Variable 1:** Key: `ANTHROPIC_API_KEY` | Value: `your-api-key-here`
   - **Variable 2:** Key: `DOCKER_MODE` | Value: `true`

## Authentication

The Docker container uses **API key authentication** via environment variable - **no user interaction required**!

### How It Works

- ✅ **No `claude login` needed** - The container authenticates automatically using `ANTHROPIC_API_KEY`
- ✅ **No browser interaction** - Set your API key once via environment variable
- ✅ **Works on headless servers** - Perfect for Unraid and other server environments
- ✅ **Automatic detection** - The Claude Agent SDK automatically uses the API key when present

### Get Your API Key

1. Visit [console.anthropic.com](https://console.anthropic.com)
2. Sign up or log in to your account
3. Navigate to API Keys section
4. Create a new API key
5. Add it to your `.env` file or Docker environment variables

**Note:** This is different from the local CLI setup which uses `claude login`. In Docker, the API key method is used instead.

## Environment Variables

| Variable | Required | Description | Default |
|----------|----------|-------------|---------|
| `ANTHROPIC_API_KEY` | **Yes** | Your Anthropic API key from [console.anthropic.com](https://console.anthropic.com) - **No `claude login` needed!** | - |
| `DOCKER_MODE` | **Yes** | Enables external access (automatically set to `true` in Dockerfile) | `true` |
| `DEFAULT_PROJECTS_DIR` | No | Default directory shown in folder browser when creating projects | `/data/projects` |
| `ANTHROPIC_BASE_URL` | No | Custom API endpoint (GLM mode) | - |
| `ANTHROPIC_AUTH_TOKEN` | No | Auth token for custom endpoint | - |

## Volumes

| Container Path | Purpose | Recommended Host Path |
|----------------|---------|----------------------|
| `/config` | Claude Code settings, credentials, registry database | `./config` or `/mnt/user/appdata/autocoder/config` |
| `/data/projects` | Generated application projects | `./data/projects` or `/mnt/user/appdata/autocoder/projects` |

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 8888 | TCP | Web UI and API |

## Health Check

The container includes a built-in health check that monitors the API endpoint:

```bash
# Check container health
docker ps

# View health check logs
docker inspect --format='{{json .State.Health}}' autocoder
```

## Updating

### Docker Compose

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose down
docker-compose up -d --build
```

### Docker CLI

```bash
# Stop and remove old container
docker stop autocoder
docker rm autocoder

# Rebuild image
docker build -t autocoder:latest .

# Start new container (same command as initial run)
docker run -d --name autocoder ...
```

## Troubleshooting

### Container won't start

1. Check logs:
   ```bash
   docker logs autocoder
   ```

2. Verify API key is set correctly:
   ```bash
   docker exec autocoder env | grep ANTHROPIC_API_KEY
   ```

### Can't access UI from other devices

1. Verify `DOCKER_MODE=true` is set
2. Check firewall rules on your server
3. Ensure port 8888 is properly mapped

### Projects not persisting

1. Verify volume mounts:
   ```bash
   docker inspect autocoder | grep -A 10 Mounts
   ```

2. Check directory permissions on host

### Authentication errors or "Not logged in"

**You do NOT need to run `claude login` in the container!** The Docker setup uses API key authentication instead.

1. Verify your API key is set:
   ```bash
   docker exec autocoder env | grep ANTHROPIC_API_KEY
   ```

2. Ensure the API key is valid (starts with `sk-ant-`)

3. If using docker-compose, check your `.env` file has the correct key

4. Restart the container after changing the API key:
   ```bash
   docker-compose restart  # or: docker restart autocoder
   ```

### Claude Code CLI issues

The Claude Code CLI is installed in the container but **authentication is handled automatically via `ANTHROPIC_API_KEY`**.

**Important:** You should NOT need to configure anything in the UI Settings - the API key from the environment variable is used automatically by the Claude Agent SDK.

If you're having issues:
1. Verify `ANTHROPIC_API_KEY` is set correctly (see "Authentication errors" section above)
2. Check container logs for any startup errors: `docker logs autocoder`
3. The `/config` volume persists Claude settings, but API key auth doesn't require `~/.claude` configuration

## Security Notes

- **API Key Protection:** Never commit your `.env` file or expose your API key
- **Network Access:** In Docker mode, the application is accessible from your network. Use reverse proxy with authentication for internet exposure
- **Localhost Override:** The `DOCKER_MODE=true` environment variable disables the localhost-only security check. Only use this in trusted networks.

## Advanced Configuration

### Custom MCP Servers

If you have custom MCP servers, mount them into the container:

```yaml
volumes:
  - ./mcp_server:/app/mcp_server
```

### Using with Reverse Proxy

Example Nginx configuration:

```nginx
server {
    listen 80;
    server_name autocoder.yourdomain.com;

    location / {
        proxy_pass http://localhost:8888;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Resource Limits

In `docker-compose.yml`, you can add resource limits:

```yaml
services:
  autocoder:
    # ... other config ...
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G
```

## Support

For issues and questions:
- Check the main [README.md](README.md) for general usage
- Review [CLAUDE.md](CLAUDE.md) for architecture details
- Open an issue on GitHub
