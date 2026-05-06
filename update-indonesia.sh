#!/bin/bash
set -euo pipefail

# ===== CONFIG =====
URL4="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/IPLists/indonesia-ipv4.txt"
URL6="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/IPLists/indonesia-ipv6.txt"

SET4="id_v4"
SET6="id_v6"

TMP4="${SET4}_tmp"
TMP6="${SET6}_tmp"

LOGFILE="/var/log/ipset-id.log"

IPV4_REGEX='^([0-9]{1,3}\.){3}[0-9]{1,3}(/([0-9]|[12][0-9]|3[0-2]))?$'
IPV6_REGEX='^([0-9a-fA-F:]+)(/[0-9]{1,3})?$'

# ===== FUNCTIONS =====
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# Download IPv4 list
fetch_ipv4() {
    TMPFILE=$(mktemp)

    curl -fsSL "$URL4" | grep -Ev '^\s*#|^\s*$' \
        | grep -E "$IPV4_REGEX" \
        | sort -u > "$TMPFILE"

    echo "$TMPFILE"
}

# Download IPv6 list
fetch_ipv6() {
    TMPFILE=$(mktemp)

    curl -fsSL "$URL6" | grep -Ev '^\s*#|^\s*$' \
        | grep -E "$IPV6_REGEX" \
        | sort -u > "$TMPFILE"

    echo "$TMPFILE"
}

# Apply ipset safely
apply_set() {
    local TMPSET="$1"
    local SET="$2"
    local TMPFILE="$3"
    local FAMILY="$4"

    ipset destroy "$TMPSET" 2>/dev/null || true

    TMPRESTORE=$(mktemp)
    echo "create $TMPSET hash:net family $FAMILY hashsize 1048576 maxelem 2000000" > "$TMPRESTORE"

    while read -r ip; do
        echo "add $TMPSET $ip" >> "$TMPRESTORE"
    done < "$TMPFILE"

    ipset restore < "$TMPRESTORE"
    rm -f "$TMPRESTORE"

    log "Tmp set $TMPSET siap (family $FAMILY)"

    if ipset list "$SET" &>/dev/null; then
        ipset swap "$TMPSET" "$SET"
        ipset destroy "$TMPSET"
        log "Swap $TMPSET -> $SET sukses"
    else
        ipset rename "$TMPSET" "$SET"
        log "Set $SET dibuat pertama kali"
    fi
}

# ===== MAIN =====
log "Mulai update ipset Indonesia"

TMPFILE4=$(fetch_ipv4)
TMPFILE6=$(fetch_ipv6)

log "IPv4 valid: $(wc -l < "$TMPFILE4")"
apply_set "$TMP4" "$SET4" "$TMPFILE4" "inet"
rm -f "$TMPFILE4"

log "IPv6 valid: $(wc -l < "$TMPFILE6")"
apply_set "$TMP6" "$SET6" "$TMPFILE6" "inet6"
rm -f "$TMPFILE6"

ipset save > /etc/ipset.conf
log "ipset.conf disimpan"

# Reload UFW agar ipset terbaru aktif
log "Reload UFW untuk menerapkan ipset terbaru"
sudo ufw reload && log "UFW reload sukses ✅"

log "Update ipset Indonesia selesai ✅"
