#!/bin/bash
PATH=/usr/sbin:/usr/bin:/sbin:/bin

LOGFILE="/tmp/ufw-autodisable.log"
echo "START $(date)" >> "$LOGFILE"

if /bin/ping -4 -c 1 -W 2 google.com >/dev/null 2>&1; then
    echo "Ping google.com OK â†’ Tidak ada tindakan" >> "$LOGFILE"
else
    echo "Ping google.com GAGAL â†’ Disabling UFW" >> "$LOGFILE"
    /usr/sbin/ufw disable >> "$LOGFILE" 2>&1
fi
