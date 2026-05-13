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
| 🔌 **Plugin Support** | Install and configure plugins via env |
| 📧 **Email/SMTP** | Email notification support |
| 🔐 **LDAP Auth** | Remote authentication support |
| 📈 **Metrics** | Prometheus metrics endpoint |

---

## ⚡ Quick Start

```bash
# Clone/create directory
mkdir -p /home/docker/netbox
cd /home/docker/netbox

# Create docker-compose.yml
cat > docker-compose.yml << 'EOF'
services:
  netbox:
    image: steimerbyte/all-in-one-netbox:latest
    restart: unless-stopped
    environment:
      SECRET_KEY: 'your-secret-key-min-50-chars'
      SUPERUSER_NAME: admin
      SUPERUSER_EMAIL: admin@example.com
      SUPERUSER_PASSWORD: YourAdminPass123!
      API_TOKEN_PEPPER_1: 'your-pepper-min-50-chars'
    ports:
      - "6541:8080"
    volumes:
      - ./media:/opt/netbox/netbox/media
      - ./reports:/opt/netbox/netbox/reports
      - ./scripts:/opt/netbox/netbox/scripts
      - ./postgres:/data/postgres
      - ./redis:/data/redis
      - ./plugins:/opt/netbox/netbox/plugins
EOF

# Start
docker compose up -d

# Wait 2-3 minutes for migrations
docker compose logs -f
```

**Open:** http://localhost:6541

---

## 🐳 Docker Compose (Full Example)

```yaml
services:
  netbox:
    image: steimerbyte/all-in-one-netbox:latest
    restart: unless-stopped
    user: root
    environment:
      # --- Required ---
      SECRET_KEY: 'your-super-secret-key-min-50-characters'
      SUPERUSER_PASSWORD: 'your-admin-password'
      API_TOKEN_PEPPER_1: 'your-pepper-min-50-characters'
      
      # --- Superuser (Optional) ---
      SUPERUSER_NAME: 'admin'
      SUPERUSER_EMAIL: 'admin@example.com'
      SKIP_SUPERUSER: 'false'
      
      # --- Database (Defaults work) ---
      DB_HOST: 'localhost'
      DB_NAME: 'netbox'
      DB_USER: 'netbox'
      DB_PASSWORD: 'netbox'
      DB_PORT: '5432'
      DB_TIMEOUT: '60'
      
      # --- Redis (Defaults work) ---
      REDIS_HOST: 'localhost'
      REDIS_PORT: '6379'
      REDIS_PASSWORD: 'netbox'
      REDIS_DATABASE: '0'
      REDIS_TASKS_DATABASE: '2'
      
      REDIS_CACHE_HOST: 'localhost'
      REDIS_CACHE_PORT: '6379'
      REDIS_CACHE_PASSWORD: 'netbox'
      REDIS_CACHE_DATABASE: '1'
      
      # --- Security ---
      DEBUG: 'false'
      ALLOWED_HOSTS: 'localhost,netbox.example.com'
      
      # --- Network ---
      BANNER_LOGIN: 'Welcome to NetBox'
      BANNER_TOP: ''
      CORS_ORIGIN_ALLOW_ALL: 'false'
      CORS_ORIGINS: 'https://app.example.com'
      
      # --- Email ---
      EMAIL_SERVER: 'smtp.example.com'
      EMAIL_PORT: '587'
      EMAIL_USERNAME: 'netbox@example.com'
      EMAIL_PASSWORD: 'smtp-password'
      EMAIL_FROM: 'netbox@example.com'
      EMAIL_USE_TLS: 'true'
      EMAIL_USE_SSL: 'false'
      
      # --- NAPALM ---
      NAPALM_USERNAME: ''
      NAPALM_PASSWORD: ''
      NAPALM_TIMEOUT: '10'
      
      # --- Remote Auth (LDAP) ---
      REMOTE_AUTH_ENABLED: 'false'
      REMOTE_AUTH_BACKEND: 'netbox.authentication.LDAPBackend'
      AUTH_LDAP_SERVER_URI: 'ldaps://ad.example.com'
      AUTH_LDAP_BIND_DN: 'cn=bind,dc=example,dc=com'
      AUTH_LDAP_BIND_PASSWORD: 'ldap-password'
      AUTH_LDAP_USER_SEARCH_BASEDN: 'ou=users,dc=example,dc=com'
      AUTH_LDAP_USER_SEARCH_ATTR: 'sAMAccountName'
      AUTH_LDAP_GROUP_SEARCH_BASEDN: 'ou=groups,dc=example,dc=com'
      AUTH_LDAP_REQUIRE_GROUP: ''
      AUTH_LDAP_MIRROR_GROUPS: 'false'
      
      # --- Metrics ---
      METRICS_ENABLED: 'false'
      PROMETHEUS_MULTIPROC_DIR: '/tmp/metrics'
      
      # --- Pagination ---
      MAX_PAGE_SIZE: '0'
      
      # --- Housekeeping ---
      HOUSEKEEPING_INTERVAL: '1'
      
      # --- Plugins ---
      PLUGINS: ''
      PLUGINS_CONFIG: '{}'
      
      # --- Logging ---
      LOGLEVEL: 'INFO'
      
    ports:
      - "6541:8080"
    volumes:
      - ./media:/opt/netbox/netbox/media
      - ./reports:/opt/netbox/netbox/reports
      - ./scripts:/opt/netbox/netbox/scripts
      - ./postgres:/data/postgres
      - ./redis:/data/redis
      - ./plugins:/opt/netbox/netbox/plugins
      - ./config:/etc/netbox/config
```

---

## 📁 Volumes

| Volume | Purpose |
|--------|---------|
| `./media` | NetBox media files (uploads, images, exports) |
| `./reports` | Custom reports |
| `./scripts` | Custom scripts |
| `./postgres` | PostgreSQL data (persists DB across restarts) |
| `./redis` | Redis data (optional) |
| `./plugins` | Plugin code |
| `./config` | Custom config files (optional) |

---

## 🔐 Environment Variables (All Supported)

### Required
| Variable | Description |
|----------|-------------|
| `SECRET_KEY` | Django secret key (≥50 chars) |
| `SUPERUSER_PASSWORD` | Admin password |
| `API_TOKEN_PEPPER_1` | Pepper for v2 API tokens (≥50 chars) |

### Superuser
| Variable | Default | Description |
|----------|---------|-------------|
| `SUPERUSER_NAME` | `admin` | Admin username |
| `SUPERUSER_EMAIL` | `admin@example.com` | Admin email |
| `SKIP_SUPERUSER` | `false` | Skip superuser creation |

### Database
| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `localhost` | PostgreSQL host |
| `DB_NAME` | `netbox` | Database name |
| `DB_USER` | `netbox` | Database user |
| `DB_PASSWORD` | `netbox` | Database password |
| `DB_PORT` | `5432` | Database port |
| `DB_TIMEOUT` | `60` | Connection timeout |

### Redis
| Variable | Default | Description |
|----------|---------|-------------|
| `REDIS_HOST` | `localhost` | Redis host |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_PASSWORD` | `netbox` | Redis password |
| `REDIS_DATABASE` | `0` | Default database |
| `REDIS_TASKS_DATABASE` | `2` | Tasks database |
| `REDIS_CACHE_HOST` | `localhost` | Cache host |
| `REDIS_CACHE_PORT` | `6379` | Cache port |
| `REDIS_CACHE_PASSWORD` | `netbox` | Cache password |
| `REDIS_CACHE_DATABASE` | `1` | Cache database |

### Security
| Variable | Default | Description |
|----------|---------|-------------|
| `DEBUG` | `false` | Debug mode |
| `ALLOWED_HOSTS` | `*` | Allowed hosts (comma-separated) |

### Network
| Variable | Default | Description |
|----------|---------|-------------|
| `BANNER_LOGIN` | - | Login page banner |
| `BANNER_TOP` | - | Top banner |
| `CORS_ORIGIN_ALLOW_ALL` | `true` | Allow all CORS origins |
| `CORS_ORIGINS` | - | Allowed origins (comma-separated) |

### Email
| Variable | Default | Description |
|----------|---------|-------------|
| `EMAIL_SERVER` | - | SMTP server |
| `EMAIL_PORT` | `25` | SMTP port |
| `EMAIL_USERNAME` | - | SMTP username |
| `EMAIL_PASSWORD` | - | SMTP password |
| `EMAIL_FROM` | `netbox@localhost` | From address |
| `EMAIL_USE_TLS` | `false` | Use TLS |
| `EMAIL_USE_SSL` | `false` | Use SSL |
| `EMAIL_TIMEOUT` | `30` | Timeout |

### NAPALM
| Variable | Default | Description |
|----------|---------|-------------|
| `NAPALM_USERNAME` | - | NAPALM username |
| `NAPALM_PASSWORD` | - | NAPALM password |
| `NAPALM_TIMEOUT` | `10` | Timeout in seconds |
| `NAPALM_ARGS` | `{}` | Additional args (JSON) |

### Remote Auth (LDAP)
| Variable | Default | Description |
|----------|---------|-------------|
| `REMOTE_AUTH_ENABLED` | `false` | Enable remote auth |
| `REMOTE_AUTH_BACKEND` | - | Auth backend |
| `REMOTE_AUTH_TIMEOUT` | `30` | Auth timeout |
| `AUTH_LDAP_SERVER_URI` | - | LDAP server URI |
| `AUTH_LDAP_BIND_DN` | - | Bind DN |
| `AUTH_LDAP_BIND_PASSWORD` | - | Bind password |
| `AUTH_LDAP_USER_SEARCH_BASEDN` | - | User search base DN |
| `AUTH_LDAP_USER_SEARCH_ATTR` | `uid` | User search attribute |
| `AUTH_LDAP_GROUP_SEARCH_BASEDN` | - | Group search base DN |
| `AUTH_LDAP_REQUIRE_GROUP` | - | Required group |
| `AUTH_LDAP_MIRROR_GROUPS` | `false` | Mirror LDAP groups |

### Metrics
| Variable | Default | Description |
|----------|---------|-------------|
| `METRICS_ENABLED` | `false` | Enable Prometheus metrics |
| `PROMETHEUS_MULTIPROC_DIR` | `/tmp/metrics` | Metrics directory |

### Pagination
| Variable | Default | Description |
|----------|---------|-------------|
| `MAX_PAGE_SIZE` | `0` | Max page size (0=unlimited) |

### Housekeeping
| Variable | Default | Description |
|----------|---------|-------------|
| `HOUSEKEEPING_INTERVAL` | `1` | Days between housekeeping |

### Plugins
| Variable | Default | Description |
|----------|---------|-------------|
| `PLUGINS` | - | Plugin names (comma-separated) |
| `PLUGINS_CONFIG` | `{}` | Plugin config (JSON) |

### Logging
| Variable | Default | Description |
|----------|---------|-------------|
| `LOGLEVEL` | `INFO` | Log level |
| `LOGGING` | - | Logging config (JSON) |

### Release
| Variable | Default | Description |
|----------|---------|-------------|
| `RELEASE_CHANNEL` | `stable` | Release channel |

---

## 🔌 Plugin Example

```yaml
environment:
  PLUGINS: 'netbox-golden-config,netbox-ip-controller'
  PLUGINS_CONFIG: '{"netbox-golden-config": {"enable_backup": true}}'
volumes:
  - ./plugins:/opt/netbox/netbox/plugins
```

---

## 🔐 Generate Secure Secrets

```bash
# SECRET_KEY (required, min 50 chars)
openssl rand -hex 50

# API_TOKEN_PEPPER (required, min 50 chars)
openssl rand -hex 50

# Random passwords
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

| Service | RAM-Limit | Settings |
|---------|-----------|----------|
| PostgreSQL | ~128MB | `shared_buffers=128MB`, `max_connections=50` |
| Redis | 128MB | `allkeys-lru`, no persistence |
| NetBox | - | `GUNICORN_MAX_REQUESTS=1000` |

**Runs on 1GB RAM.**

---

## 🐛 Troubleshooting

### Container won't start

```bash
# Check logs
docker compose logs --tail=50

# Clear stale config
rm ./config/configuration.py
docker compose restart

# Full reset (loses all data!)
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

### Migrations taking too long

First start takes 2-3 minutes. Watch progress:
```bash
docker compose logs -f
```

### API Token errors

Set `API_TOKEN_PEPPER_1` with ≥50 characters in your environment.

---

## 🔗 Links

- [Docker Hub](https://hub.docker.com/r/steimerbyte/all-in-one-netbox)
- [GitHub](https://github.com/steimbyte/all-in-one-netbox)
- [NetBox](https://github.com/netbox-community/netbox)
- [NetBox Docker](https://github.com/netbox-community/netbox-docker)

---

## 📜 License

Apache 2.0
