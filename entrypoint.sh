#!/bin/bash
# All-in-One NetBox EntryPoint

echo "========================================="
echo "All-in-One NetBox Starting..."
echo "========================================="

PGDATA="/data/postgres"

# Alte PG-Prozesse killen
echo "Stopping old PostgreSQL processes..."
pkill -9 postgres 2>/dev/null || true
sleep 2

# Verzeichnisse erstellen
echo "Creating directories..."
mkdir -p /data /var/run/postgresql /data/redis /var/log/supervisor /etc/supervisor/conf.d /etc/netbox/config
chmod 777 /data /var/run/postgresql /data/redis

# Plugins erstmal deaktiviert (müssen ins NetBox venv)
# Plugin-Installation später möglich wenn Dockerfile angepasst

# NetBox Config erstellen
echo "Creating NetBox configuration..."
cat > /etc/netbox/config/configuration.py << 'PYEOF'
import os
import re
from netbox.settings import *

# --- Network ---
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split()
BANNER_LOGIN = os.environ.get('BANNER_LOGIN', '')
BANNER_TOP = os.environ.get('BANNER_TOP', '')
CORS_ORIGIN_ALLOW_ALL = os.environ.get('CORS_ORIGIN_ALLOW_ALL', 'True').lower() == 'true'

# --- Database ---
DATABASES = {
    'default': {
        'NAME': os.environ.get('DB_NAME', 'netbox'),
        'USER': os.environ.get('DB_USER', 'netbox'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'netbox'),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', ''),
        'CONN_MAX_AGE': int(os.environ.get('DB_TIMEOUT', '300')),
    }
}

# --- Redis (NetBox 4.x format from netbox-docker) ---
_redis_host = os.environ.get('REDIS_HOST', 'localhost')
_redis_port = int(os.environ.get('REDIS_PORT', '6379'))
_redis_pass = os.environ.get('REDIS_PASSWORD', '') or None
_redis_username = os.environ.get('REDIS_USERNAME', '')
_redis_tasks_db = int(os.environ.get('REDIS_TASKS_DATABASE', '2'))
_redis_cache_host = os.environ.get('REDIS_CACHE_HOST', _redis_host)
_redis_cache_port = int(os.environ.get('REDIS_CACHE_PORT', '6379'))
_redis_cache_pass = os.environ.get('REDIS_CACHE_PASSWORD', '') or None
_redis_cache_db = int(os.environ.get('REDIS_CACHE_DATABASE', '1'))

REDIS = {
    'tasks': {
        'HOST': _redis_host,
        'PORT': _redis_port,
        'USERNAME': _redis_username,
        'PASSWORD': _redis_pass,
        'DATABASE': _redis_tasks_db,
    },
    'caching': {
        'HOST': _redis_cache_host,
        'PORT': _redis_cache_port,
        'USERNAME': _redis_username,
        'PASSWORD': _redis_cache_pass,
        'DATABASE': _redis_cache_db,
    },
}

# SESSION_ENGINE for Django sessions
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'

# --- Security ---
SECRET_KEY = os.environ.get('SECRET_KEY', os.environ.get('SECRET_KEY_AUTO', 'changeme'))
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'
if DEBUG:
    ALLOWED_HOSTS = ['*']

# API Token Peppers
_pepper = os.environ.get('API_TOKEN_PEPPER_1', '')
if _pepper:
    API_TOKEN_PEPPERS = {1: _pepper}

# NAPALM
NAPALM_USERNAME = os.environ.get('NAPALM_USERNAME', '')
NAPALM_PASSWORD = os.environ.get('NAPALM_PASSWORD', '')

# Email
EMAIL_HOST = os.environ.get('EMAIL_SERVER', '')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '25'))
EMAIL_USERNAME = os.environ.get('EMAIL_USERNAME', '')
EMAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD', '')
EMAIL_USE_SSL = os.environ.get('EMAIL_USE_SSL', 'False').lower() == 'true'
EMAIL_USE_TLS = os.environ.get('EMAIL_USE_TLS', 'False').lower() == 'true'
EMAIL_FROM = os.environ.get('EMAIL_FROM', 'netbox@localhost')

# Metrics
METRICS_ENABLED = os.environ.get('METRICS_ENABLED', 'False').lower() == 'true'

# Max page size
MAX_PAGE_SIZE = int(os.environ.get('MAX_PAGE_SIZE', '0'))

# Plugins
PLUGINS = ["netbox_topology_views"]

# Housekeeping
HOUSEKEEPING_INTERVAL = int(os.environ.get('HOUSEKEEPING_INTERVAL', '1'))

# Logging
_loglevel = os.environ.get('LOGLEVEL', 'INFO')
LOGLEVEL = _loglevel
PYEOF

chmod 644 /etc/netbox/config/configuration.py
echo "NetBox configuration created"

# PostgreSQL init
echo "Checking PostgreSQL..."
if [ ! -f "$PGDATA/postgresql.conf" ]; then
    echo "Running initdb (fresh setup)..."
    mkdir -p $PGDATA
    chown postgres:postgres $PGDATA
    sudo -u postgres /usr/lib/postgresql/18/bin/initdb -D $PGDATA
    
    cat >> $PGDATA/postgresql.conf << 'EOF'
max_connections = 50
shared_buffers = 128MB
effective_cache_size = 256MB
work_mem = 4MB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
checkpoint_timeout = 15min
min_wal_size = 256MB
max_wal_size = 1GB
wal_compression = on
autovacuum_max_workers = 1
listen_addresses='*'
EOF

    cat >> $PGDATA/pg_hba.conf << 'EOF'
local   all             postgres                                trust
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               md5
EOF
    
    echo "PostgreSQL init complete"
else
    echo "Using existing PostgreSQL data"
fi

chmod 700 $PGDATA

# Supervisor Config
echo "Writing Supervisor config..."
cat > /etc/supervisor/conf.d/supervisord.conf << 'SUPERVISOR'
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:postgres]
command=/usr/lib/postgresql/18/bin/postgres -D /data/postgres
priority=10
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/postgres.log
stderr_logfile=/var/log/supervisor/postgres_err.log
user=postgres
group=postgres

[program:redis]
command=sh -c "redis-server --dir /data/redis --requirepass netbox --maxmemory 128mb --maxmemory-policy allkeys-lru --maxmemory-samples 5 --save '' --appendonly no"
priority=20
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/redis.log
stderr_logfile=/var/log/supervisor/redis_err.log

[program:netbox]
command=bash -c "export GUNICORN_MAX_REQUESTS=1000 && export GUNICORN_MAX_REQUESTS_JITTER=50 && /opt/netbox/docker-entrypoint.sh /opt/netbox/launch-netbox.sh 2>&1 | tee /proc/1/fd/1"
priority=30
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/netbox.log
stderr_logfile=/var/log/supervisor/netbox_err.log
SUPERVISOR

# PG starten
echo "Starting PostgreSQL..."
sudo -u postgres /usr/lib/postgresql/18/bin/postgres -D $PGDATA &

# Warten bis PG bereit ist
echo "Waiting for PostgreSQL to be ready..."
for i in {1..30}; do
    if sudo -u postgres psql -c "SELECT 1" &>/dev/null; then
        echo "PostgreSQL is ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

# DB erstellen
echo "Creating database..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='netbox'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER netbox WITH PASSWORD 'netbox' CREATEDB;" 2>&1 | tee /proc/1/fd/1
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='netbox'" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE netbox OWNER netbox;" 2>&1 | tee /proc/1/fd/1

# PG beenden
echo "Stopping PostgreSQL..."
sudo -u postgres /usr/lib/postgresql/18/bin/pg_ctl stop -D $PGDATA -m fast 2>/dev/null || true
pkill -9 postgres 2>/dev/null || true
sleep 2

echo "========================================="
echo "Starting NetBox (migrations may take 2-3 min)..."
echo "========================================="

exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
