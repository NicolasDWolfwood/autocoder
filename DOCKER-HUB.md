# Publishing to Docker Hub

This guide explains how to build and publish the AutoCoder Docker image to Docker Hub.

## Prerequisites

1. **Docker Hub Account**
   - Create a free account at [hub.docker.com](https://hub.docker.com)
   - Choose a username (e.g., `yourusername`)

2. **Docker Installed**
   - Ensure Docker is installed and running on your machine

3. **Login to Docker Hub**
   ```bash
   docker login
   # Enter your Docker Hub username and password
   ```

## Quick Publishing

### Option 1: Using the Build Script (Recommended)

1. **Edit the build script:**
   - Open `docker-build-push.sh` (Linux/Mac) or `docker-build-push.bat` (Windows)
   - Update `DOCKER_USERNAME` to your Docker Hub username
   - Update `IMAGE_NAME` if desired (default: `autocoder`)

2. **Run the script:**
   ```bash
   # Linux/Mac
   chmod +x docker-build-push.sh
   ./docker-build-push.sh

   # Windows
   docker-build-push.bat
   ```

### Option 2: Manual Publishing

1. **Build the image:**
   ```bash
   docker build -t yourusername/autocoder:latest .
   ```

2. **Tag with version (optional but recommended):**
   ```bash
   docker tag yourusername/autocoder:latest yourusername/autocoder:1.0.0
   ```

3. **Push to Docker Hub:**
   ```bash
   docker push yourusername/autocoder:latest
   docker push yourusername/autocoder:1.0.0
   ```

## Best Practices

### 1. Multi-Architecture Builds (Recommended)

Build images for multiple architectures (AMD64, ARM64) using buildx:

```bash
# Create a new builder (one-time setup)
docker buildx create --name multiarch --use
docker buildx inspect --bootstrap

# Build and push for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t yourusername/autocoder:latest \
  -t yourusername/autocoder:1.0.0 \
  --push \
  .
```

**Benefits:**
- Works on Intel/AMD servers (amd64)
- Works on ARM servers like Raspberry Pi, Apple Silicon Macs (arm64)
- Unraid supports both architectures

### 2. Version Tagging Strategy

Use semantic versioning for your tags:

```bash
# Major.Minor.Patch
docker tag yourusername/autocoder:latest yourusername/autocoder:1.0.0
docker tag yourusername/autocoder:latest yourusername/autocoder:1.0
docker tag yourusername/autocoder:latest yourusername/autocoder:1

# Always update 'latest'
docker push yourusername/autocoder:latest
docker push yourusername/autocoder:1.0.0
docker push yourusername/autocoder:1.0
docker push yourusername/autocoder:1
```

This allows users to:
- Pin to a specific version: `yourusername/autocoder:1.0.0`
- Auto-update minor versions: `yourusername/autocoder:1.0`
- Auto-update major versions: `yourusername/autocoder:1`
- Always get latest: `yourusername/autocoder:latest`

### 3. Automated Builds with GitHub Actions

See `.github/workflows/docker-publish.yml` for automated building and publishing on every release.

## Using Your Published Image

### Update docker-compose.yml

Replace the `build: .` section with your published image:

```yaml
services:
  autocoder:
    image: yourusername/autocoder:latest  # Use your Docker Hub image
    # Remove: build: .
    container_name: autocoder
    # ... rest of config
```

### Pull and Run

```bash
# Pull the latest image
docker pull yourusername/autocoder:latest

# Run with docker-compose
docker-compose up -d

# Or run directly
docker run -d \
  --name autocoder \
  -p 8888:8888 \
  -v ./config:/config \
  -v ./data/projects:/data/projects \
  -e ANTHROPIC_API_KEY=sk-ant-your-key-here \
  yourusername/autocoder:latest
```

## Creating a Docker Hub Repository Description

When you push your image, Docker Hub will create a repository. Add a good description:

### Example Description

```markdown
# AutoCoder - Autonomous Coding Agent

A long-running autonomous coding agent powered by the Claude Agent SDK. Build complete applications over multiple sessions with a React-based UI for monitoring progress in real-time.

## Features

- 🤖 Two-agent pattern (initializer + coding agent)
- 📊 Real-time progress tracking with Kanban board
- 🔄 Automatic session continuation
- 🎯 Feature dependency management
- 🧪 Regression testing
- 🎨 Beautiful React UI with neobrutalism design

## Quick Start

```yaml
version: '3.8'
services:
  autocoder:
    image: yourusername/autocoder:latest
    ports:
      - "8888:8888"
    volumes:
      - ./config:/config
      - ./data/projects:/data/projects
    environment:
      - ANTHROPIC_API_KEY=sk-ant-your-key-here
      - DOCKER_MODE=true
```

Access at: http://localhost:8888

## Requirements

- Anthropic API key from [console.anthropic.com](https://console.anthropic.com)

## Documentation

Full documentation: [GitHub Repository](https://github.com/yourusername/autocoder)

## Support

- GitHub Issues: [Report bugs](https://github.com/yourusername/autocoder/issues)
- Documentation: [README](https://github.com/yourusername/autocoder/blob/main/README.md)
```

## Unraid Community Applications Template

Once your image is on Docker Hub, you can submit a template to Unraid Community Applications:

1. Fork the [Community Applications repository](https://github.com/Squidly271/docker-templates)
2. Create a new XML template file (see `unraid-template.xml` example)
3. Submit a pull request

Users will then be able to install AutoCoder directly from the Unraid Apps tab!

## Image Size Optimization

Current image size: ~1-2 GB (includes Node.js, Python, React build, Claude CLI)

To reduce size:
- Use multi-stage builds (already implemented)
- Clean up build artifacts (already implemented)
- Use alpine-based images (trade-off: compatibility issues)

The current size is reasonable for an all-in-one development environment.

## Automated Publishing with CI/CD

See `.github/workflows/docker-publish.yml` for a complete GitHub Actions workflow that:

1. Builds on every push to main
2. Creates multi-architecture images (amd64, arm64)
3. Publishes to Docker Hub with version tags
4. Runs on release creation

## Security Considerations

### Docker Hub Credentials in CI/CD

If using GitHub Actions:

1. Go to your GitHub repository → Settings → Secrets and variables → Actions
2. Add secrets:
   - `DOCKERHUB_USERNAME`: Your Docker Hub username
   - `DOCKERHUB_TOKEN`: Your Docker Hub access token (not password!)

To create an access token:
1. Log in to Docker Hub
2. Go to Account Settings → Security → Access Tokens
3. Create a new token with "Read & Write" permissions

### Image Scanning

Docker Hub automatically scans images for vulnerabilities. Check your repository's "Security" tab.

## Troubleshooting

### "denied: requested access to the resource is denied"

- Ensure you're logged in: `docker login`
- Verify the image name includes your username: `yourusername/autocoder`
- Check you have permission to push to that repository

### "manifest for linux/arm64 not found"

- The image wasn't built for ARM64 architecture
- Use `docker buildx` with `--platform linux/amd64,linux/arm64`

### Build fails during npm/Node.js installation

- Ensure you have enough disk space
- Try building with `--no-cache` flag: `docker build --no-cache -t yourusername/autocoder:latest .`

## Next Steps

1. **Test your image:** Pull and run it on a different machine to ensure it works
2. **Write documentation:** Update README.md with Docker Hub installation instructions
3. **Create releases:** Tag your Git repository and create GitHub releases
4. **Monitor usage:** Check Docker Hub analytics to see pull statistics
