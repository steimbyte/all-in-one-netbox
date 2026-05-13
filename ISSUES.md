# Common Bugs & Fixes

## HTTP 400/500 Errors on Login

### Problem
```
ValueError: not enough values to unpack (expected 2, got 1)
```

### Cause
Wrong configuration format for NetBox 4.x

### Fix
Use the correct netbox-docker configuration format:

```python
# Database - must be DATABASES (plural) with 'default' key
DATABASES = {
    'default': {
        'NAME': os.environ.get('DB_NAME', 'netbox'),
        'USER': os.environ.get('DB_USER', 'netbox'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'netbox'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', ''),
    }
}

# Redis - must have 'tasks' and 'caching' sections
REDIS = {
    'tasks': {
        'HOST': os.environ.get('REDIS_HOST', 'localhost'),
        'PORT': int(os.environ.get('REDIS_PORT', '6379')),
        'PASSWORD': os.environ.get('REDIS_PASSWORD', '') or None,
        'DATABASE': int(os.environ.get('REDIS_TASKS_DATABASE', '2')),
    },
    'caching': {
        'HOST': os.environ.get('REDIS_CACHE_HOST', 'localhost'),
        'PORT': int(os.environ.get('REDIS_CACHE_PORT', '6379')),
        'PASSWORD': os.environ.get('REDIS_CACHE_PASSWORD', '') or None,
        'DATABASE': int(os.environ.get('REDIS_CACHE_DATABASE', '1')),
    },
}

SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
```

---

## HTTP 400 After Config Change

### Problem
Config changes not applied, old broken config persists.

### Cause
Config was only created if it didn't exist.

### Fix
Config is now recreated on every container start.

---

## PostgreSQL Recovery Fails on Start

### Problem
```
FATAL: the database system is starting up
```

### Cause
PostgreSQL recovery takes longer than the wait loop.

### Fix
Wait loop in entrypoint:
```bash
for i in {1..30}; do
    if sudo -u postgres psql -c "SELECT 1" &>/dev/null; then
        break
    fi
    sleep 2
done
```

---

## ALLOWED_HOSTS Error

### Problem
HTTP 400 Bad Request when accessing via domain.

### Cause
`ALLOWED_HOSTS` doesn't include your domain.

### Fix
```yaml
environment:
  ALLOWED_HOSTS: 'netbox.example.com'
```

---

## API Token v2 Warning

### Problem
```
UserWarning: API_TOKEN_PEPPERS is not defined. v2 API tokens cannot be used.
```

### Cause
Missing or incorrectly formatted `API_TOKEN_PEPPERS`.

### Fix
```yaml
environment:
  API_TOKEN_PEPPER_1: 'your-pepper-min-50-chars'
```

The pepper must be ≥50 characters and formatted as integer key dict:
```python
API_TOKEN_PEPPERS = {1: 'pepper-string'}
```

---

## REDIS Section Missing Subsection

### Problem
```
django.core.exceptions.ImproperlyConfigured: REDIS section in configuration.py is missing the 'tasks' subsection.
```

### Cause
Missing required `tasks` and `caching` subsections in REDIS dict.

### Fix
See the Redis configuration in the Login fix section above.

---

## Wrong Redis Password Format

### Problem
Redis connection fails with password

### Cause
Password stored as empty string instead of None

### Fix
```python
_redis_pass = os.environ.get('REDIS_PASSWORD', '') or None
```

---

## First Start Very Slow (Migrations)

### Problem
Container takes 2-3 minutes to start.

### Cause
Database migrations run on first start.

### Solution
This is expected. Watch progress:
```bash
docker compose logs -f
```

---

## Docker Exec Commands

```bash
# View logs
docker compose logs -f

# View error logs
docker exec netbox-netbox-1 cat /var/log/supervisor/netbox_err.log | tail -20

# Reset password
docker exec netbox-netbox-1 /opt/netbox/venv/bin/python /opt/netbox/netbox/manage.py changepassword admin

# Full reset (loses all data!)
docker compose down -v
docker compose up -d
```

---

## Required Environment Variables

| Variable | Required | Min Length |
|----------|----------|-----------|
| `SECRET_KEY` | Yes | 50 chars |
| `SUPERUSER_PASSWORD` | Yes | - |
| `API_TOKEN_PEPPER_1` | Recommended | 50 chars |
| `ALLOWED_HOSTS` | Yes (for non-local) | - |

---

## Quick Reference

```bash
# Generate secrets
openssl rand -hex 50

# Check container status
docker compose ps

# Restart container
docker compose restart

# View real-time logs
docker compose logs -f --tail=100

# Force pull new image
docker compose pull
docker compose up -d
```

---

## Current Image Version

**Image:** `steimerbyte/all-in-one-netbox:latest`
**Digest:** `sha256:d10463b036c0a82579d2fa0dd8e2472a2053c054945d59c44cbfcc14e4170acd`

See also: [GitHub Repository](https://github.com/steimbyte/all-in-one-netbox)
