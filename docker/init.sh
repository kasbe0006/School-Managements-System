#!/bin/bash
set -e

export PATH="${NVM_DIR}/versions/node/v${NODE_VERSION_DEVELOP}/bin/:${PATH}"

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, skipping init"
    cd /home/frappe/frappe-bench

    # Re-sync local education app changes on every restart
    if [ -d "/workspace/education" ]; then
        echo "Syncing local education app..."
        rsync -av --delete \
            --exclude '__pycache__' \
            --exclude '*.pyc' \
            --exclude 'node_modules' \
            /workspace/ /home/frappe/frappe-bench/apps/education/
    fi

    bench start
    exit 0
fi

echo "Creating new bench..."
bench init --skip-redis-config-generation frappe-bench

cd /home/frappe/frappe-bench

# Use containers instead of localhost
bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379

# Remove redis, watch from Procfile
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

bench get-app erpnext

# Install education from local workspace copy
echo "Copying local education app..."
cp -r /workspace /home/frappe/frappe-bench/apps/education
echo "education" >> /home/frappe/frappe-bench/apps/apps.txt
./env/bin/pip install -e apps/education

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

bench start
