# Common Bugs & Fixes

## HTTP 400/500 Errors on Login

### Problem
```
ValueError: not enough values to unpack (expected 2, got 1)
```

### Cause
`SESSION_CACHE` must be a dictionary in NetBox 4.x, not a string.

### Fix
```python
# Wrong (string)
SESSION_CACHE = "redis://localhost:6379/2"

# Correct (dictionary)
SESSION_CACHE = {
    'HOST': 'localhost',
    'PORT': '6379',
    'PASSWORD': 'netbox',
    'DATABASE': '2',
}
```

---

## HTTP 500 After Config Change

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
Increase wait time in entrypoint:
```bash
for i in {1..60}; do
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

The pepper must be ≥50 characters.

---

## Redis Connection Error

### Problem
```
ImproperlyConfigured: REDIS section in configuration.py is missing...
```

### Cause
Missing `default`, `tasks`, or `caching` subsections.

### Fix
```python
REDIS = {
    'default': {
        'HOST': 'localhost',
        'PORT': '6379',
        'PASSWORD': 'netbox',
        'DATABASE': '0',
    },
    'tasks': {
        'HOST': 'localhost',
        'PORT': '6379',
        'PASSWORD': 'netbox',
        'DATABASE': '2',
    },
    'caching': {
        'HOST': 'localhost',
        'PORT': '6379',
        'PASSWORD': 'netbox',
        'DATABASE': '1',
    },
}
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
```
