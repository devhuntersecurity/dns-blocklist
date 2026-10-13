#!/usr/bin/env bash

set -Eeuo pipefail

echo "=========================================="
echo " DevHunter Security Update"
echo " Started : $(date)"
echo "=========================================="

echo
echo "[1/5] Parsing Blocklist..."

if /usr/local/bin/parsing-blocklist; then
    echo "[✓] Blocklist selesai."
else
    echo "[ERROR] Parsing Blocklist gagal!"
    exit 1
fi

echo
echo "[2/5] Parsing Whitelist..."

if /usr/local/bin/parsing-whitelist; then
    echo "[✓] Whitelist selesai."
else
    echo "[ERROR] Parsing Whitelist gagal!"
    exit 1
fi

echo
echo "[3/5] Validating Blocklist..."

find /etc/unbound/unbound.conf.d \
    -type f -name "*.conf" \
    -exec sed -i 's/\.\."/."/g' {} +

echo "[✓] Double dot diperbaiki."

echo
echo "[4/5] Sync Filesystem..."

sync

echo "[✓] Sinkronisasi selesai."

echo
echo "[5/5] Reloading Unbound..."

for i in {1..5}; do

    if unbound-control reload_keep_cache >/dev/null 2>&1; then
        echo "[✓] Reload berhasil."
        break
    fi

    if [[ $i -eq 5 ]]; then
        echo
        echo "[ERROR] Reload gagal!"
        echo
        journalctl -u unbound -n 50 --no-pager
        exit 1
    fi

    echo "Retry ${i}/5..."
    sleep 2
done

echo
echo "=========================================="
echo " Finished : $(date)"
echo "=========================================="