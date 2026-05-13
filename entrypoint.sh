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

# NetBox Config erstellen
if [ ! -f /etc/netbox/config/configuration.py ]; then
    echo "Creating NetBox configuration..."
    cat > /etc/netbox/config/configuration.py << 'EOF'
import os
import json
from netbox.settings import *

# --- Network ---
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '*').split()
BANNER_LOGIN = os.environ.get('BANNER_LOGIN', '')
BANNER_TOP = os.environ.get('BANNER_TOP', '')
CORS_ORIGIN_ALLOW_ALL = os.environ.get('CORS_ORIGIN_ALLOW_ALL', 'True').lower() == 'true'
CORS_ORIGINS = [x.strip() for x in os.environ.get('CORS_ORIGINS', '').split(',') if x.strip()]

# --- Database ---
DATABASE = {
    'NAME': os.environ.get('DB_NAME', 'netbox'),
    'USER': os.environ.get('DB_USER', 'netbox'),
    'PASSWORD': os.environ.get('DB_PASSWORD', 'netbox'),
    'HOST': os.environ.get('DB_HOST', 'localhost'),
    'PORT': os.environ.get('DB_PORT', '5432'),
    'CONN_MAX_AGE': int(os.environ.get('DB_TIMEOUT', '60')),
}

# --- Redis ---
_redis_pass = os.environ.get('REDIS_PASSWORD', '')
REDIS = {
    'default': {
        'HOST': os.environ.get('REDIS_HOST', 'localhost'),
        'PORT': os.environ.get('REDIS_PORT', '6379'),
        'PASSWORD': _redis_pass or None,
        'DATABASE': os.environ.get('REDIS_DATABASE', '0'),
    },
    'tasks': {
        'HOST': os.environ.get('REDIS_HOST', 'localhost'),
        'PORT': os.environ.get('REDIS_PORT', '6379'),
        'PASSWORD': _redis_pass or None,
        'DATABASE': os.environ.get('REDIS_TASKS_DATABASE', '2'),
    },
    'caching': {
        'HOST': os.environ.get('REDIS_CACHE_HOST', os.environ.get('REDIS_HOST', 'localhost')),
        'PORT': os.environ.get('REDIS_CACHE_PORT', os.environ.get('REDIS_PORT', '6379')),
        'PASSWORD': os.environ.get('REDIS_CACHE_PASSWORD', _redis_pass) or None,
        'DATABASE': os.environ.get('REDIS_CACHE_DATABASE', '1'),
    },
}
REDIS_CACHE = REDIS['caching'].copy()

_cache_host = os.environ.get('REDIS_CACHE_HOST', os.environ.get('REDIS_HOST', 'localhost'))
_cache_port = os.environ.get('REDIS_CACHE_PORT', os.environ.get('REDIS_PORT', '6379'))
_cache_db = os.environ.get('REDIS_CACHE_DATABASE', '1')
_cache_pass = os.environ.get('REDIS_CACHE_PASSWORD', _redis_pass)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': f"redis://{_cache_host}:{_cache_port}/{_cache_db}",
        'PASSWORD': _cache_pass or None,
    }
}
SESSION_CACHE = f"redis://{os.environ.get('REDIS_HOST', 'localhost')}:{os.environ.get('REDIS_PORT', '6379')}/2"

# --- Security ---
SECRET_KEY = os.environ.get('SECRET_KEY', os.environ.get('SECRET_KEY_AUTO', 'changeme'))
DEBUG = os.environ.get('DEBUG', 'False').lower() == 'true'
if DEBUG:
    ALLOWED_HOSTS = ['*']

# API Token Peppers
_pepper = os.environ.get('API_TOKEN_PEPPER_1', '')
if _pepper:
    API_TOKEN_PEPPERS = [_pepper]

# --- NAPALM ---
NAPALM_USERNAME = os.environ.get('NAPALM_USERNAME', '')
NAPALM_PASSWORD = os.environ.get('NAPALM_PASSWORD', '')
NAPALM_TIMEOUT = int(os.environ.get('NAPALM_TIMEOUT', '10'))
NAPALM_ARGS = json.loads(os.environ.get('NAPALM_ARGS', '{}'))

# --- Email ---
EMAIL_HOST = os.environ.get('EMAIL_SERVER', '')
EMAIL_PORT = int(os.environ.get('EMAIL_PORT', '25'))
EMAIL_USERNAME = os.environ.get('EMAIL_USERNAME', '')
EMAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD', '')
EMAIL_USE_SSL = os.environ.get('EMAIL_USE_SSL', 'False').lower() == 'true'
EMAIL_USE_TLS = os.environ.get('EMAIL_USE_TLS', 'False').lower() == 'true'
EMAIL_FROM = os.environ.get('EMAIL_FROM', 'netbox@localhost')
EMAIL_TIMEOUT = int(os.environ.get('EMAIL_TIMEOUT', '30'))
if os.environ.get('EMAIL_SSL_CERTFILE', ''):
    EMAIL_SSL_CERTFILE = os.environ.get('EMAIL_SSL_CERTFILE')
if os.environ.get('EMAIL_SSL_KEYFILE', ''):
    EMAIL_SSL_KEYFILE = os.environ.get('EMAIL_SSL_KEYFILE')

# --- Remote Auth (LDAP) ---
REMOTE_AUTH_ENABLED = os.environ.get('REMOTE_AUTH_ENABLED', 'False').lower() == 'true'
REMOTE_AUTH_BACKEND = os.environ.get('REMOTE_AUTH_BACKEND', '')
REMOTE_AUTH_TIMEOUT = int(os.environ.get('REMOTE_AUTH_TIMEOUT', '30'))

# LDAP Settings
_AUTH_LDAP_SERVER = os.environ.get('AUTH_LDAP_SERVER_URI', '')
if _auth_ldap_server:
    AUTH_LDAP_SERVER_URI = _auth_ldap_server
    AUTH_LDAP_BIND_DN = os.environ.get('AUTH_LDAP_BIND_DN', '')
    AUTH_LDAP_BIND_PASSWORD = os.environ.get('AUTH_LDAP_BIND_PASSWORD', '')
    AUTH_LDAP_USER_SEARCH_BASEDN = os.environ.get('AUTH_LDAP_USER_SEARCH_BASEDN', '')
    AUTH_LDAP_USER_SEARCH_ATTR = os.environ.get('AUTH_LDAP_USER_SEARCH_ATTR', 'uid')
    AUTH_LDAP_GROUP_SEARCH_BASEDN = os.environ.get('AUTH_LDAP_GROUP_SEARCH_BASEDN', '')
    AUTH_LDAP_REQUIRE_GROUP = os.environ.get('AUTH_LDAP_REQUIRE_GROUP', '')
    AUTH_LDAP_GROUP_TYPES = os.environ.get('AUTH_LDAP_GROUP_TYPES', '')
    AUTH_LDAP_USER_ATTR_MAP_FIRST_NAME = os.environ.get('AUTH_LDAP_USER_ATTR_MAP_FIRST_NAME', 'first_name')
    AUTH_LDAP_USER_ATTR_MAP_LAST_NAME = os.environ.get('AUTH_LDAP_USER_ATTR_MAP_LAST_NAME', 'last_name')
    AUTH_LDAP_USER_ATTR_MAP_EMAIL = os.environ.get('AUTH_LDAP_USER_ATTR_MAP_EMAIL', 'email')
    AUTH_LDAP_DEFAULT_GROUPS = os.environ.get('AUTH_LDAP_DEFAULT_GROUPS', '')
    AUTH_LDAP_MIRROR_GROUPS = os.environ.get('AUTH_LDAP_MIRROR_GROUPS', 'False').lower() == 'true'

# --- Metrics ---
METRICS_ENABLED = os.environ.get('METRICS_ENABLED', 'False').lower() == 'true'
if METRICS_ENABLED:
    PROMETHEUS_MULTIPROC_DIR = os.environ.get('PROMETHEUS_MULTIPROC_DIR', '/tmp/metrics')

# --- Pagination ---
MAX_PAGE_SIZE = int(os.environ.get('MAX_PAGE_SIZE', '0'))

# --- Housekeeping ---
HOUSEKEEPING_INTERVAL = int(os.environ.get('HOUSEKEEPING_INTERVAL', '1'))

# --- Release Channel ---
RELEASE_CHANNEL = os.environ.get('RELEASE_CHANNEL', 'stable')

# --- Plugins ---
_plugins = os.environ.get('PLUGINS', '')
if _plugins:
    PLUGINS = [p.strip() for p in _plugins.split(',')]
    _plugins_config = os.environ.get('PLUGINS_CONFIG', '{}')
    if _plugins_config:
        PLUGINS_CONFIG = json.loads(_plugins_config)

# --- Logging ---
_loglevel = os.environ.get('LOGLEVEL', 'INFO')
if _loglevel:
    LOGLEVEL = _loglevel
if os.environ.get('LOGGING', ''):
    LOGGING = json.loads(os.environ.get('LOGGING'))
EOF
    chmod 644 /etc/netbox/config/configuration.py
    echo "NetBox configuration created"
fi

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
sleep 3

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
