# 🚀 All-in-One NetBox

[![Docker Pulls](https://img.shields.io/docker/pulls/steimerbyte/all-in-one-netbox?logo=docker)](https://hub.docker.com/r/steimerbyte/all-in-one-netbox)
[![NetBox Version](https://img.shields.io/badge/NetBox-v4.1-blue?style=flat&logo=python)](https://github.com/netbox-community/netbox)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-blue?style=flat&logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-blue?style=flat&logo=redis)](https://redis.io/)

> **One container. Everything included.**  
> Single Docker image with PostgreSQL 18 + Redis + NetBox baked in.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📦 **Single Image** | Everything in one container (~1GB) |
| 🔐 **Secure by Default** | All secrets configurable via env |
| 👤 **Auto-Admin** | Creates superuser on first start |
| 💾 **Memory Optimized** | PostgreSQL/Redis mit RAM-Limits |
| 🔄 **Auto-Migrations** | DB migrations run automatically |
| 🏃 **Supervisor** | Manages all processes (Postgres, Redis, NetBox) |
| 📊 **Migration Status** | Status page while migrations run |

---

## ⚡ Quick Start

```bash
# Run with docker compose
cd /home/docker/netbox
docker compose up -d

# Open browser
open http://localhost:6541
```

**Login:** `bsteimer` / `2HWTu3slg35OKYb275UCyVhwRkXukmW0`

---

## 🐳 Docker Compose

```yaml
services:
  netbox:
    image: steimerbyte/all-in-one-netbox:latest
    restart: unless-stopped
    environment:
      SECRET_KEY: 'your-secret-key-min-50-chars'
      SUPERUSER_NAME: admin
      SUPERUSER_EMAIL: admin@example.com
      SUPERUSER_PASSWORD: YourAdminPass123!
      SKIP_SUPERUSER: 'false'
      DB_HOST: localhost
      DB_NAME: netbox
      DB_USER: netbox
      DB_PASSWORD: netbox
      REDIS_HOST: localhost
      REDIS_PASSWORD: netbox
      REDIS_CACHE_HOST: localhost
      REDIS_CACHE_PASSWORD: netbox
    ports:
      - "6541:8080"
    volumes:
      - ./media:/opt/netbox/netbox/media
      - ./reports:/opt/netbox/netbox/reports
      - ./scripts:/opt/netbox/netbox/scripts
```

---

## 📁 Volumes

| Volume | Purpose |
|--------|---------|
| `./media` | NetBox media files (uploads, etc.) |
| `./reports` | Custom reports |
| `./scripts` | Custom scripts |
| `/data/postgres` | PostgreSQL data (in container) |
| `/data/redis` | Redis data (in container) |

---

## 🔐 Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY` | **Yes** | - | Django secret key (≥50 chars) |
| `DB_HOST` | No | `localhost` | PostgreSQL host |
| `DB_NAME` | No | `netbox` | Database name |
| `DB_USER` | No | `netbox` | Database user |
| `DB_PASSWORD` | No | `netbox` | Database password |
| `REDIS_HOST` | No | `localhost` | Redis host |
| `REDIS_PASSWORD` | No | `netbox` | Redis password |
| `REDIS_CACHE_HOST` | No | `localhost` | Redis cache host |
| `REDIS_CACHE_PASSWORD` | No | `netbox` | Redis cache password |
| `SUPERUSER_NAME` | No | `admin` | Admin username |
| `SUPERUSER_EMAIL` | No | `admin@example.com` | Admin email |
| `SUPERUSER_PASSWORD` | **Yes** | - | Admin password |
| `SKIP_SUPERUSER` | No | `false` | Skip superuser creation |

---

## 🔐 Generate Secure Secrets

```bash
# SECRET_KEY (required, min 50 chars)
openssl rand -hex 50

# Passwords
openssl rand -hex 24
```

---

## 🏗️ Inside the Container

```
┌─────────────────────────────────────────┐
│         All-in-One Container            │
│                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ Postgres│  │  Redis  │  │ NetBox  │ │
│  │   18    │  │   7     │  │  v4.1   │ │
│  └────┬────┘  └────┬────┘  └────┬────┘ │
│       │            │            │        │
│       └────────────┴────────────┘        │
│              Supervisord                 │
└─────────────────────────────────────────┘
         Port 8080 (internal)
              ↓
         Port 6541 (host)
```

---

## ⚙️ Memory Optimizations

Das Image ist für ressourcenschonenden Betrieb optimiert:

| Service | RAM-Limit | Einstellungen |
|---------|-----------|--------------|
| PostgreSQL | ~128MB | `shared_buffers=128MB`, `max_connections=50` |
| Redis | 128MB | `allkeys-lru`, keine Persistence |
| NetBox | - | `GUNICORN_MAX_REQUESTS=1000` |

Mit 1GB RAM lauffähig.

---

## 🐛 Troubleshooting

### Container won't start

```bash
# Check logs
docker compose logs --tail=50

# Rebuild from scratch
docker compose down -v
docker compose up -d
```

### Can't login

```bash
# Reset password
docker exec netbox-netbox-1 /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py changepassword admin

# Create new superuser
docker exec -it netbox-netbox-1 /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py createsuperuser
```

### Database errors

Migrations dauern beim ersten Start 2-3 Minuten. Bitte warten.

---

## 🔗 Links

- [Docker Hub](https://hub.docker.com/r/steimerbyte/all-in-one-netbox)
- [GitHub](https://github.com/steimbyte/all-in-one-netbox)
- [NetBox](https://github.com/netbox-community/netbox)

---

## 📜 License

Apache 2.0
