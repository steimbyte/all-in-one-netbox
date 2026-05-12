#!/bin/bash
# All-in-One NetBox EntryPoint - With Migration Status Page

set -e

# Migration Status HTML
mkdir -p /var/www/status
cat > /var/www/status/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>NetBox - Starting...</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #fff;
            min-height: 100vh;
            margin: 0;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        .container { text-align: center; padding: 40px; }
        .spinner {
            width: 60px; height: 60px;
            border: 4px solid rgba(255,255,255,0.1);
            border-top-color: #4dabf7;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin: 0 auto 30px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }
        h1 { font-size: 28px; margin-bottom: 10px; }
        p { color: #adb5bd; font-size: 16px; margin-bottom: 20px; }
        .progress {
            width: 300px; height: 4px;
            background: rgba(255,255,255,0.1);
            border-radius: 2px;
            margin: 0 auto;
            overflow: hidden;
        }
        .progress-bar {
            height: 100%;
            background: linear-gradient(90deg, #4dabf7, #69db7c);
            animation: progress 2s ease-in-out infinite;
            width: 30%;
        }
        @keyframes progress {
            0% { width: 0%; margin-left: 0%; }
            50% { width: 60%; margin-left: 20%; }
            100% { width: 0%; margin-left: 100%; }
        }
        .log {
            margin-top: 30px;
            text-align: left;
            background: rgba(0,0,0,0.3);
            border-radius: 8px;
            padding: 15px;
            max-height: 200px;
            overflow-y: auto;
            font-family: 'Monaco', 'Menlo', monospace;
            font-size: 12px;
            color: #69db7c;
        }
        .log-entry { margin: 2px 0; opacity: 0.9; }
    </style>
</head>
<body>
    <div class="container">
        <div class="spinner"></div>
        <h1>NetBox Starting...</h1>
        <p>Database migrations are running. This may take a few minutes.</p>
        <div class="progress"><div class="progress-bar"></div></div>
        <div class="log" id="log"><div class="log-entry">Initializing...</div></div>
    </div>
    <script>
        async function updateLog() {
            try {
                const resp = await fetch('/status.log');
                const text = await resp.text();
                const lines = text.split('\n').slice(-15);
                document.getElementById('log').innerHTML = lines.map(l => 
                    '<div class="log-entry">' + l + '</div>'
                ).join('');
            } catch(e) {}
        }
        setInterval(updateLog, 2000);
        updateLog();
    </script>
</body>
</html>
HTML

echo "Starting status page server..."
python3 -m http.server 8080 --directory /var/www/status &
STATUS_PID=$!

log_msg() {
    echo "[$(date +'%H:%M:%S')] $1" >> /var/www/status/status.log
}

log_msg "========================================="
log_msg "All-in-One NetBox Starting..."
log_msg "========================================="

# Generate unique PG data directory
PGDATA="/tmp/pgdata_$$_$(date +%s)"
log_msg "Using PG data dir: $PGDATA"

# Verzeichnisse erstellen
log_msg "Creating directories..."
rm -rf /var/run/postgresql /data/redis /var/log/supervisor /etc/supervisor/conf.d
mkdir -p /var/run/postgresql /data/redis /var/log/supervisor /etc/supervisor/conf.d

# PostgreSQL initialisieren - WICHTIG: Verzeichnis als postgres user erstellen
log_msg "Running initdb..."
# initdb versucht das Verzeichnis zu chownen - das geht nur wenn es als postgres erstellt wird
sudo -u postgres mkdir -p $PGDATA
sudo -u postgres /usr/lib/postgresql/18/bin/initdb -D $PGDATA
log_msg "initdb complete"

# Memory-optimierte PostgreSQL Config
log_msg "Writing PostgreSQL config..."
cat >> $PGDATA/postgresql.conf << EOF
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

cat >> $PGDATA/pg_hba.conf << 'EOF'
# Local connections
local   all             postgres                                trust
local   all             all                                     trust
host    all             all             127.0.0.1/32            trust
host    all             all             ::1/128                 trust
host    all             all             0.0.0.0/0               md5
EOF

chmod 777 /var/run/postgresql

# Supervisor config
log_msg "Writing Supervisor config..."
cat > /etc/supervisor/conf.d/supervisord.conf << 'SUPERVISOR'
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[program:postgres]
command=/usr/lib/postgresql/18/bin/postgres -D PGDATA_PLACEHOLDER
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
command=bash -c "export GUNICORN_MAX_REQUESTS=1000 && export GUNICORN_MAX_REQUESTS_JITTER=50 && /opt/netbox/docker-entrypoint.sh /opt/netbox/launch-netbox.sh"
priority=30
autostart=true
autorestart=true
stdout_logfile=/var/log/supervisor/netbox.log
stderr_logfile=/var/log/supervisor/netbox_err.log
SUPERVISOR

# Replace placeholder with actual path
sed -i "s|PGDATA_PLACEHOLDER|$PGDATA|g" /etc/supervisor/conf.d/supervisord.conf

log_msg "Init complete, starting services..."

# PostgreSQL fuer DB-Setup starten
log_msg "Starting PostgreSQL..."
sudo -u postgres /usr/lib/postgresql/18/bin/postgres -D $PGDATA &
sleep 3

# Status pruefen
sudo -u postgres psql -c 'SELECT version();' 2>/dev/null && log_msg "PostgreSQL ready" || log_msg "PostgreSQL failed"

# DB/User erstellen
log_msg "Creating DB user..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='netbox'" | grep -q 1 || sudo -u postgres psql -c "CREATE USER netbox WITH PASSWORD 'netbox' CREATEDB;" 2>/dev/null
log_msg "Creating DB..."
sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='netbox'" | grep -q 1 || sudo -u postgres psql -c "CREATE DATABASE netbox OWNER netbox;" 2>/dev/null

log_msg "Database ready"

# PostgreSQL sauber beenden
log_msg "Stopping PostgreSQL for clean restart..."
sudo -u postgres /usr/lib/postgresql/18/bin/pg_ctl stop -D $PGDATA -m fast 2>/dev/null || true
sleep 2

log_msg "Starting NetBox (migrations may take 2-3 min)..."

# Stop status server
kill $STATUS_PID 2>/dev/null || true

# Supervisor starten
exec /usr/bin/supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
