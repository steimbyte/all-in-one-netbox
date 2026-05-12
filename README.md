# 🚀 All-in-One NetBox

[![Docker Pulls](https://img.shields.io/docker/pulls/steimerbyte/all-in-one-netbox?logo=docker)](https://hub.docker.com/r/steimerbyte/all-in-one-netbox)
[![NetBox Version](https://img.shields.io/badge/NetBox-v4.6-blue?style=flat&logo=python)](https://github.com/netbox-community/netbox)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue?style=flat&logo=postgresql)](https://www.postgresql.org/)
[![Redis](https://img.shields.io/badge/Redis-7-blue?style=flat&logo=redis)](https://redis.io/)

> **One container. Everything included.**  
> Single Docker image with PostgreSQL + Redis + NetBox baked in.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📦 **Single Image** | Everything in one container |
| 🔐 **Secure by Default** | All secrets configurable via env |
| 👤 **Auto-Admin** | Creates superuser on first start |
| 💾 **Persistent** | Data survives container restarts |
| 🔄 **Auto-Migrations** | DB migrations run automatically |
| 🏃 **Supervisor** | Manages all processes (Postgres, Redis, NetBox) |

---

## ⚡ Quick Start

```bash
# Pull and run
docker run -d \
  --name netbox \
  -p 8000:8080 \
  -e SECRET_KEY='your-secret-key-min-50-chars' \
  -e DB_PASSWORD='your-db-password' \
  -e SUPERUSER_PASSWORD='YourAdminPass123!' \
  steimerbyte/all-in-one-netbox:latest

# Open browser
open http://localhost:8000
```

**Login:** `admin` / `YourAdminPass123!`

---

## 🐳 Docker Compose (Recommended)

```yaml
services:
  netbox:
    image: steimerbyte/all-in-one-netbox:latest
    container_name: netbox
    environment:
      SECRET_KEY: 'your-secret-key-min-50-chars'
      DB_PASSWORD: 'your-db-password'
      REDIS_PASSWORD: 'your-redis-password'
      SUPERUSER_PASSWORD: 'YourAdminPass123!'
    ports:
      - "8000:8080"
    volumes:
      - ./netbox-data:/data
    restart: unless-stopped
```

```bash
docker compose up -d
```

---

## 📁 Volumes

| Volume | Purpose |
|--------|---------|
| `/var/lib/postgresql/16/main` | PostgreSQL data |
| `/data/redis` | Redis data |
| `/opt/netbox/netbox/media` | Uploaded files |

---

## 🔐 Generate Secure Secrets

```bash
# SECRET_KEY (required, min 50 chars)
openssl rand -hex 50

# Passwords
openssl rand -hex 24
```

---

## 🔒 Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY` | **Yes** | - | Django secret key (≥50 chars) |
| `DB_PASSWORD` | No | `netbox` | PostgreSQL password |
| `REDIS_PASSWORD` | No | `netbox` | Redis password |
| `SUPERUSER_NAME` | No | `admin` | Admin username |
| `SUPERUSER_EMAIL` | No | `admin@example.com` | Admin email |
| `SUPERUSER_PASSWORD` | **Yes** | - | Admin password |

---

## 🏗️ Inside the Container

```
┌─────────────────────────────────────────┐
│         All-in-One Container            │
│                                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐ │
│  │ Postgres│  │  Redis  │  │ NetBox  │ │
│  │   16    │  │   7     │  │  v4.6   │ │
│  └────┬────┘  └────┬────┘  └────┬────┘ │
│       │            │            │        │
│       └────────────┴────────────┘        │
│              Supervisord                 │
└─────────────────────────────────────────┘
         Port 8080 (internal)
              ↓
         Port 8000 (host)
```

---

## 🐛 Troubleshooting

### Container won't start

```bash
# Check logs
docker logs netbox

# Enable debug
docker run -e DEBUG=true ...
```

### Can't login

```bash
# Reset password
docker exec netbox /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py changepassword admin

# Create new superuser
docker exec -it netbox /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py createsuperuser
```

### Database errors

```bash
# Recreate database
docker exec netbox su - postgres -c "/usr/lib/postgresql/16/bin/pg_ctl -D /var/lib/postgresql/16/main stop"
docker exec netbox rm -rf /var/lib/postgresql/16/main/*
docker restart netbox
```

---

## 📜 License

Apache 2.0 - See [LICENSE](LICENSE)

---

## 🔗 Links

- [Docker Hub](https://hub.docker.com/r/steimerbyte/all-in-one-netbox)
- [GitHub](https://github.com/steimbyte/all-in-one-netbox)
- [NetBox](https://github.com/netbox-community/netbox)
