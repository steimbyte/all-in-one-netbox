# All-in-One NetBox - Lean Build
FROM netboxcommunity/netbox:latest

USER root

# Lean: Install only what's needed
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql \
    redis-server \
    supervisor \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create directories
RUN mkdir -p /var/lib/postgresql/18/main /var/run/postgresql /data/redis /var/log/supervisor /etc/supervisor/conf.d

# PostgreSQL init (als postgres user für korrekte permissions)
USER postgres
RUN /usr/lib/postgresql/18/bin/initdb -D /var/lib/postgresql/18/main 2>/dev/null || true
USER root
RUN echo "listen_addresses='*'" >> /var/lib/postgresql/18/main/postgresql.conf && \
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/18/main/pg_hba.conf && \
    echo "host all all ::0/0 md5" >> /var/lib/postgresql/18/main/pg_hba.conf && \
    chown -R postgres:postgres /var/lib/postgresql/18/main /var/run/postgresql && \
    chmod 700 /var/lib/postgresql/18/main

# Supervisor config (Redis ohne --daemonize, dafür mit tail -f)
RUN printf '[supervisord]\nnodaemon=true\nlogfile=/var/log/supervisor/supervisord.log\npidfile=/var/run/supervisord.pid\n\n[program:postgres]\ncommand=/usr/lib/postgresql/18/bin/postgres -D /var/lib/postgresql/18/main\npriority=10\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/supervisor/postgres.log\nstderr_logfile=/var/log/supervisor/postgres_err.log\nuser=postgres\n\n[program:redis]\ncommand=sh -c "redis-server --dir /data/redis --requirepass redis || true"\npriority=20\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/supervisor/redis.log\nstderr_logfile=/var/log/supervisor/redis_err.log\n\n[program:netbox]\ncommand=/opt/netbox/launch-netbox.sh\npriority=30\nautostart=true\nautorestart=true\nstdout_logfile=/var/log/supervisor/netbox.log\nstderr_logfile=/var/log/supervisor/netbox_err.log\n' > /etc/supervisor/conf.d/supervisord.conf

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD curl -f http://localhost:8080/login/ || exit 1

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
