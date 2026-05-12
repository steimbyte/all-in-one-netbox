#!/bin/bash
# All-in-One NetBox EntryPoint - Debug Mode

set -x  # Debug mode ON
PS4='DEBUG:$(date +"%H:%M:%S") '

echo "=========================================="
echo "🚀 All-in-One NetBox DEBUG EntryPoint"
echo "=========================================="

# Env Debug
echo "[DEBUG] SECRET_KEY=${SECRET_KEY:0:10}..."
echo "[DEBUG] DB_HOST=$DB_HOST"
echo "[DEBUG] DB_NAME=$DB_NAME"
echo "[DEBUG] DB_USER=$DB_USER"
echo "[DEBUG] DB_PASSWORD=${DB_PASSWORD:+***}"
echo "[DEBUG] REDIS_HOST=$REDIS_HOST"
echo "[DEBUG] REDIS_PASSWORD=${REDIS_PASSWORD:+***}"
echo "[DEBUG] SUPERUSER_PASSWORD=${SUPERUSER_PASSWORD:+***}"

# Alte PG-Config verschieben
if [ -d /var/lib/postgresql/18/main ] && [ -f /var/lib/postgresql/18/main/postgresql.conf ]; then
    echo "[DEBUG] Moving old PG data..."
    mv /var/lib/postgresql/18/main /var/lib/postgresql/18/main_old_$$ 2>/dev/null || true
fi

# Verzeichnisse erstellen
echo "[DEBUG] Creating directories..."
rm -rf /var/run/postgresql /data/redis /var/log/supervisor /etc/supervisor/conf.d
mkdir -p /var/lib/postgresql/18/main /var/run/postgresql /data/redis /var/log/supervisor /etc/supervisor/conf.d
ls -la /var/lib/postgresql/18/main/

# PostgreSQL initialisieren
echo "[DEBUG] Running initdb..."
mkdir -p /var/run/postgresql
chown postgres:postgres /var/run/postgresql
su postgres -c "/usr/lib/postgresql/18/bin/initdb -D /var/lib/postgresql/18/main"
echo "[DEBUG] initdb complete"

# Memory-optimierte PostgreSQL Config
echo "[DEBUG] Writing PostgreSQL config..."
cat >> /var/lib/postgresql/18/main/postgresql.conf << 'EOF'
# Memory-Optimized Settings
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

cat >> /var/lib/postgresql/18/main/pg_hba.conf << 'EOF'
# Local connections
local   all             postgres                                trust
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               md5
EOF

chown -R postgres:postgres /var/lib/postgresql/18/main /var/run/postgresql
chmod 700 /var/lib/postgresql/18/main
echo "[DEBUG] PG config done"

# Supervisor config
echo "[DEBUG] Writing Supervisor config..."
cat > /etc/supervisor/conf.d/supervisord.conf << 'SUPERVISOR'
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid
loglevel=debug

[program:postgres]
command=/usr/lib/postgresql/18/bin/postgres -D /var/lib/postgresql/18/main -d 5
priority=10
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/postgres.log
stderr_logfile=/var/log/supervisor/postgres_err.log
user=postgres
group=postgres

[program:redis]
command=sh -c "redis-server --dir /data/redis --requirepass netbox --maxmemory 128mb --maxmemory-policy allkeys-lru --maxmemory-samples 5 --save '' --appendonly no --loglevel debug --logfile /var/log/supervisor/redis_debug.log"
priority=20
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/redis.log
stderr_logfile=/var/log/supervisor/redis_err.log

[program:netbox]
command=bash -c "export GUNICORN_MAX_REQUESTS=1000 && export GUNICORN_MAX_REQUESTS_JITTER=50 && export DB_WAIT_DEBUG=1 && /opt/netbox/docker-entrypoint.sh /opt/netbox/launch-netbox.sh"
priority=30
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/netbox.log
stderr_logfile=/var/log/supervisor/netbox_err.log
SUPERVISOR

echo "[DEBUG] Supervisor config written"
echo "=========================================="
echo "✅ Init complete, starting services..."
echo "=========================================="

# PostgreSQL für DB-Setup starten
echo "[DEBUG] Starting PostgreSQL for setup..."
su postgres -c "/usr/lib/postgresql/18/bin/postgres -D /var/lib/postgresql/18/main -d 5 &"
sleep 5

# Status prüfen
echo "[DEBUG] PostgreSQL status:"
su postgres -c "psql -c 'SELECT version();'" || echo "[ERROR] PG not responding"

# DB/User erstellen
echo "[DEBUG] Creating DB user..."
su postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname='netbox'\" | grep -q 1 || psql -c \"CREATE USER netbox WITH PASSWORD 'netbox' CREATEDB;\""
echo "[DEBUG] Creating DB..."
su postgres -c "psql -tc \"SELECT 1 FROM pg_database WHERE datname='netbox'\" | grep -q 1 || psql -c \"CREATE DATABASE netbox OWNER netbox;\""

# PostgreSQL sauber beenden
echo "[DEBUG] Stopping PostgreSQL..."
su postgres -c "/usr/lib/postgresql/18/bin/pg_ctl stop -D /var/lib/postgresql/18/main -m fast" 2>/dev/null || true
sleep 2
rm -f /var/lib/postgresql/18/main/postmaster.pid
echo "[DEBUG] PostgreSQL stopped"

echo "=========================================="
echo "✅ PostgreSQL DB ready"
echo "=========================================="

# Supervisor starten
echo "[DEBUG] Starting Supervisor..."
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
