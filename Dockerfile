# syntax=docker/dockerfile:1
FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git \
    nodejs npm \
    ripgrep \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Claude Code CLI (required by project) :contentReference[oaicite:5]{index=5}
RUN curl -fsSL https://claude.ai/install.sh | bash \
 && ln -sf /root/.local/bin/claude /usr/local/bin/claude || true
ENV PATH="/root/.local/bin:${PATH}"

# Create a venv like the scripts describe :contentReference[oaicite:6]{index=6}
RUN python -m venv /app/venv
ENV PATH="/app/venv/bin:${PATH}"

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Build React UI for production (start_ui scripts serve ui/dist) :contentReference[oaicite:7]{index=7}
RUN if [ -f ui/package.json ]; then \
      cd ui && npm ci && npm run build; \
    fi

# Persist Claude settings + generated projects
# Claude Code settings live under ~/.claude/settings.json
ENV HOME=/config
VOLUME ["/config", "/data/projects"]

# Expose the web UI port (FastAPI serves the built React app)
EXPOSE 8888

# Set environment variables
ENV ANTHROPIC_API_KEY=""
ENV DOCKER_MODE=true
ENV DEFAULT_PROJECTS_DIR=/data/projects

# Start the FastAPI server (serves built UI from ui/dist)
CMD ["python", "-m", "uvicorn", "server.main:app", "--host", "0.0.0.0", "--port", "8888"]
