#!/bin/bash
set -euo pipefail

IPSET_V4="id_v4"
IPSET_V6="id_v6"

OUT_V4="/etc/unbound/id_v4.conf"
OUT_V6="/etc/unbound/id_v6.conf"

TMP_V4="/tmp/id_v4.conf.tmp"
TMP_V6="/tmp/id_v6.conf.tmp"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ===============================
# GENERATE IPv4
# ===============================
{
    echo "# auto-generated from ipset $IPSET_V4"
    ipset list "$IPSET_V4" 2>/dev/null | \
    grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}(/[0-9]{1,2})?' | \
    sort -u | \
    awk '{print "access-control: "$1" allow"}'
} > "$TMP_V4"

# ===============================
# GENERATE IPv6 (prefix fix)
# ===============================
{
    echo "# auto-generated from ipset $IPSET_V6"
    ipset save "$IPSET_V6" 2>/dev/null | \
    awk '/^add/ {print $3}' | \
    sort -u | \
    awk '{print "access-control: "$1" allow"}'
} > "$TMP_V6"

# ===============================
# UPDATE FILE FUNCTION
# ===============================
update_file() {
    local TMP=$1
    local OUT=$2

    if [ ! -f "$OUT" ] || ! cmp -s "$TMP" "$OUT"; then
        mv "$TMP" "$OUT"
        log "[UPDATED] $OUT"
    else
        rm -f "$TMP"
        log "[NO CHANGE] $OUT"
    fi
}

update_file "$TMP_V4" "$OUT_V4"
update_file "$TMP_V6" "$OUT_V6"