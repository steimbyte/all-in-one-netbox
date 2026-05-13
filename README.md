# All-in-One NetBox Docker Image

**PostgreSQL 18 + Redis + NetBox 4.x** - Alles in einem Container.

## Quick Start

```yaml
# docker-compose.yml
services:
  netbox:
    image: steimerbyte/all-in-one-netbox:latest
    restart: unless-stopped
    environment:
      SECRET_KEY: 'your-secret-key-min-50-chars'
      SUPERUSER_NAME: admin
      SUPERUSER_PASSWORD: 'your-password'
      API_TOKEN_PEPPER_1: 'your-pepper-min-50-chars'
      ALLOWED_HOSTS: 'netbox.example.com'
    ports:
      - "6541:8080"
    volumes:
      - ./media:/opt/netbox/netbox/media
      - ./reports:/opt/netbox/netbox/reports
      - ./scripts:/opt/netbox/netbox/scripts
      - ./postgres:/data/postgres
      - ./redis:/data/redis
```

```bash
docker compose up -d
```

**Login:** `http://localhost:6541`

---

## Features

- **PostgreSQL 18** - Integriert, persistent via `./postgres`
- **Redis** - Integriert, persistent via `./redis`
- **Supervisor** - Verwaltet alle Prozesse
- **netbox-topology-views** Plugin - Vorinstalliert

---

## Plugins

### Vorinstalliert
- `netbox-topology-views` - Topology Views für Verkabelung

### Weitere Plugins hinzufügen

1. `plugin_requirements.txt` bearbeiten:
```
netbox-topology-views
netbox-golden-config
```

2. `Dockerfile-Plugins` neu bauen:
```bash
docker build -f Dockerfile-Plugins -t steimerbyte/all-in-one-netbox:latest .
docker push steimerbyte/all-in-one-netbox:latest
```

3. Cloud neu starten:
```bash
docker compose pull && docker compose up -d
```

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY` | Yes | - | Django secret key (≥50 chars) |
| `SUPERUSER_NAME` | Yes | admin | Admin username |
| `SUPERUSER_PASSWORD` | Yes | - | Admin password |
| `API_TOKEN_PEPPER_1` | Recommended | - | Pepper for API tokens (≥50 chars) |
| `ALLOWED_HOSTS` | For production | * | Allowed FQDNs, space-separated |
| `DB_NAME` | No | netbox | PostgreSQL database name |
| `DB_USER` | No | netbox | PostgreSQL username |
| `DB_PASSWORD` | No | netbox | PostgreSQL password |
| `DEBUG` | No | false | Enable debug mode |
| `EMAIL_FROM` | No | netbox@localhost | Email sender |
| `METRICS_ENABLED` | No | false | Enable Prometheus metrics |

---

## Volumes

| Volume | Description |
|--------|-------------|
| `./media` | NetBox media files |
| `./reports` | Custom reports |
| `./scripts` | Custom scripts |
| `./postgres` | PostgreSQL data |
| `./redis` | Redis data |

---

## API

**Token holen:** NetBox UI → User → API Tokens → Create

```bash
# Status prüfen
curl -H "Authorization: Token YOUR_TOKEN" https://netbox.example.com/api/status/

# Devices abrufen
curl -H "Authorization: Token YOUR_TOKEN" https://netbox.example.com/api/dcim/devices/

# GraphQL
curl -X POST -H "Authorization: Token YOUR_TOKEN" \
  -d '{"query": "{ site_list { id name } }"}' \
  https://netbox.example.com/graphql/
```

**API Docs:** `https://netbox.example.com/api/docs/`

---

## Troubleshooting

### HTTP 500 nach Neustart
```bash
# Logs anschauen
docker compose logs -f

# Container neustarten
docker compose restart
```

### Passwort vergessen
```bash
docker exec -it netbox-netbox-1 /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py changepassword admin
```

### Full Reset (verliert alle Daten)
```bash
docker compose down -v
docker compose up -d
```

### PostgreSQL startet nicht
```bash
# Alte Daten löschen
rm -rf ./postgres
docker compose up -d
```

---

## Image Details

- **Base:** `netboxcommunity/netbox:latest`
- **Digest:** `sha256:d3c719ed9497415ccdee7314e6f4f90b5329afbb61655c8a5f327ebd8b761045`
- **Ports:** 8080 (internal) → 6541 (mapped)
- **Healthcheck:** `/login/` endpoint

---

## GitHub

https://github.com/steimbyte/all-in-one-netbox

---

## Credits

- NetBox: https://github.com/netbox-community/netbox
- netbox-docker: https://github.com/netbox-community/netbox-docker
- netbox-topology-views: https://github.com/mattieserver/netbox-topology-views
