# Port Reference Guide

Quick reference for understanding which ports AutoCoder uses in different modes.

## TL;DR

- **Docker/Unraid:** Use port **8888** only
- **Local Development:** Port **5173** (Vite) + **8888** (API)
- **Local Production:** Use port **8888** only

## Detailed Breakdown

### 🐳 Docker Mode (Production)

**Port:** `8888` (TCP)

**What runs:**
- FastAPI server serves:
  - Pre-built React app (static files from `ui/dist/`)
  - REST API endpoints
  - WebSocket connections

**Docker configuration:**
```yaml
ports:
  - "8888:8888"
```

**Access:** `http://your-server-ip:8888`

**Why:** The React app is built during Docker image creation and served as static files by FastAPI.

---

### 💻 Local Development Mode

**Ports:** `5173` (Vite) + `8888` (API)

**What runs:**
- **Port 5173:** Vite development server
  - Hot module replacement (HMR)
  - Instant React updates
  - Proxies API calls to port 8888
- **Port 8888:** FastAPI backend
  - REST API
  - WebSocket
  - Does NOT serve React files in dev mode

**Start command:**
```bash
python start_ui.py --dev
```

**Access:** `http://localhost:5173` (Vite proxies API to 8888)

**Why:** Vite provides fast refresh during React development. API requests are proxied to the FastAPI server.

---

### 🏭 Local Production Mode

**Port:** `8888` only

**What runs:**
- FastAPI server serves:
  - Pre-built React app (static files from `ui/dist/`)
  - REST API endpoints
  - WebSocket connections

**Start command:**
```bash
# Build React app first
cd ui && npm run build && cd ..

# Start production server
python start_ui.py
```

**Access:** `http://localhost:8888`

**Why:** Same as Docker mode - serves the built React app as static files.

---

## Common Confusion

### "Why does README mention 5173 but Docker uses 8888?"

The README's mention of 5173 was for **local development mode only**. I've updated the README to clarify this.

### "Do I need to expose both ports in Docker?"

**No!** Only expose port **8888**. The container runs in production mode where FastAPI serves everything on one port.

### "Can I change the port in Docker?"

Yes! Map to any host port you want:

```bash
# Use host port 3000 instead of 8888
docker run -p 3000:8888 ...

# Access at: http://localhost:3000
```

The **container** always uses 8888 internally, but you can map it to any host port.

---

## Architecture Comparison

### Development Mode (Two Servers)

```
Browser → http://localhost:5173 (Vite)
                ↓
          [Proxies API calls]
                ↓
          http://localhost:8888 (FastAPI)
                ↓
          [Database, MCP Servers, etc.]
```

### Production/Docker Mode (One Server)

```
Browser → http://localhost:8888 (FastAPI)
                ↓
          [Serves static React files]
          [Handles API requests]
          [WebSocket connections]
                ↓
          [Database, MCP Servers, etc.]
```

---

## Environment-Specific Access URLs

| Mode | URL | Notes |
|------|-----|-------|
| **Docker (Unraid)** | `http://UNRAID_IP:8888` | Replace with your Unraid server IP |
| **Docker (Local)** | `http://localhost:8888` | If running Docker on your local machine |
| **Local Dev** | `http://localhost:5173` | Vite dev server with hot reload |
| **Local Prod** | `http://localhost:8888` | Must build React first (`npm run build`) |

---

## Firewall Configuration

If running in Docker and can't access from other devices:

### Unraid
1. Port 8888 is automatically accessible on the local network
2. For internet access, configure reverse proxy or VPN

### Linux
```bash
# Allow port 8888
sudo ufw allow 8888/tcp
```

### Windows (Docker Desktop)
Port forwarding is automatic when using `-p 8888:8888`

---

## Health Check

Test if the server is running:

```bash
# From the same machine
curl http://localhost:8888/api/health

# From another device (replace with server IP)
curl http://192.168.1.100:8888/api/health

# Expected response:
{"status":"healthy"}
```

---

## Vite Configuration (For Developers)

The Vite dev server (port 5173) is configured in `ui/vite.config.ts`:

```typescript
export default defineConfig({
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:8888',  // Proxy API calls
      '/ws': {
        target: 'ws://localhost:8888',   // Proxy WebSocket
        ws: true
      }
    }
  }
})
```

In production/Docker, Vite is not used - only the built output in `ui/dist/`.

---

## Summary

**For Docker/Unraid users:**
- ✅ Expose port **8888**
- ❌ Don't expose port 5173 (not used in Docker)
- ✅ Access at `http://your-server:8888`

**For local developers:**
- 🔧 Dev mode: Port **5173** (Vite) + **8888** (API)
- 🏭 Prod mode: Port **8888** only (build React first)

**Port 8888 is the universal production port** for Docker, Unraid, and local production deployments.
