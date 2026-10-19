#!/bin/bash
set -e

export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"

BENCH_DIR="/home/frappe/frappe-bench"

if [ -d "${BENCH_DIR}/apps/frappe" ]; then
    echo "=== Bench already exists, syncing education app and starting ==="
    cd "${BENCH_DIR}"

    # Re-sync local education app changes on every restart
    if [ -d "/workspace/education" ]; then
        echo "Syncing local education app..."
        rsync -av --delete \
            --exclude '__pycache__' \
            --exclude '*.pyc' \
            --exclude 'node_modules' \
            --exclude '.git' \
            /workspace/education/ "${BENCH_DIR}/apps/education/education/"
        
        # Sync top-level app files (hooks.py, setup.py, pyproject.toml, etc.)
        for f in /workspace/education/*.py /workspace/pyproject.toml /workspace/setup.py /workspace/setup.cfg; do
            [ -f "$f" ] && cp "$f" "${BENCH_DIR}/apps/education/" || true
        done
    fi

    bench start
    exit 0
fi

echo "=== Creating new Frappe bench (first-time setup — this takes 5-10 min) ==="
bench init --skip-redis-config-generation frappe-bench

cd "${BENCH_DIR}"

# Point bench at Docker service hostnames
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Remove redis & watch from Procfile (handled by Docker services)
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

echo "=== Fetching ERPNext app ==="
bench get-app --branch version-15 erpnext

echo "=== Installing local education app ==="
# Create proper app directory structure
mkdir -p apps/education
# Copy workspace root files (pyproject.toml, setup.py, etc.)
cp -r /workspace/. apps/education/
# Remove docker folder from inside app (not needed)
rm -rf apps/education/docker apps/education/frontend

echo "education" >> apps/apps.txt
./env/bin/pip install -e apps/education

echo "=== Creating site: education.localhost ==="
bench new-site education.localhost \
    --force \
    --mariadb-root-password 123 \
    --admin-password admin \
    --no-mariadb-socket

bench --site education.localhost install-app erpnext
bench --site education.localhost install-app education
bench --site education.localhost set-config developer_mode 1
bench --site education.localhost enable-scheduler
bench --site education.localhost clear-cache
bench use education.localhost

echo "=== Setup complete! Starting bench... ==="
echo ""
echo "  🌐 App URL:   http://localhost:8000"
echo "  👤 Login:     Administrator / admin"
echo ""

bench start
