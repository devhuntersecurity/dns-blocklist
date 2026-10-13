#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# TELEGRAM NOTIFICATION CONFIG
# ============================================================
TELEGRAM_ENABLED="true" # Ubah ke "false" jika sedang tidak ingin pakai
TELEGRAM_BOT_TOKEN="8926755244:AAHg0s6ruUUaGXOP2e_8OdBfau8f5DpHBbM"
TELEGRAM_CHAT_ID="7615918777"

send_telegram() {
    local message="$1"
    if [[ "$TELEGRAM_ENABLED" != "true" ]]; then
        return
    fi

    # Format pesan menggunakan HTML/Markdown ringan
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        -d "parse_mode=HTML" \
        --data-urlencode "text=$message" >/dev/null 2>&1 || true
}

# ============================================================
# DevHunter Security - IDGuard DNS Status
# Production Monitoring Dashboard
# ============================================================

BLOCKLIST_LINKS="/usr/local/bin/link-domains.txt"
WHITELIST_LINKS="/usr/local/bin/whitelist-domains.txt"

BLOCKLIST_FILE="/etc/unbound/unbound.conf.d/malware/blocklist.conf"
WHITELIST_FILE="/etc/unbound/unbound.conf.d/zzz-whitelist/zzzz-whitelist.conf"

BLOCKLIST_META="/var/lib/unbound/blocklist-stats"
WHITELIST_META="/var/lib/unbound/whitelist-stats"

# ============================================================
# COLORS & TTY DETECTION
# ============================================================

if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'
    C_RED=$'\033[31m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_BLUE=$'\033[34m'
    C_CYAN=$'\033[36m'
    C_WHITE=$'\033[37m'
    C_BOLD=$'\033[1m'
    clear 2>/dev/null || true
else
    C_RESET=''
    C_RED=''
    C_GREEN=''
    C_YELLOW=''
    C_BLUE=''
    C_CYAN=''
    C_WHITE=''
    C_BOLD=''
fi

# ============================================================
# NUMBER FORMAT & HELPERS
# ============================================================

fmt() {
    local n="${1:-0}"
    LC_NUMERIC=C.UTF-8 printf "%'d" "$n" 2>/dev/null || \
    printf "%s" "$n" | sed -e :a -e 's/\(.*[0-9]\)\([0-9]\{3\}\)/\1,\2/;ta'
}

percent() {
    local a="${1:-0}"
    local b="${2:-0}"
    awk -v a="$a" -v b="$b" '
    BEGIN {
        if (b > 0) printf "%.2f", (a / b) * 100
        else printf "0.00"
    }'
}

bytes_to_mb() {
    local bytes="${1:-0}"
    awk -v b="$bytes" 'BEGIN { printf "%.2f", b / 1024 / 1024 }'
}

# ============================================================
# UI HELPERS
# ============================================================

line() { printf '%s\n' "============================================================"; }
subline() { printf '%s\n' "------------------------------------------------------------"; }

section() {
    echo
    printf "%b\n" "${C_BOLD}${C_BLUE}$1${C_RESET}"
    subline
}

row() { printf "%-30s : %s\n" "$1" "$2"; }
row_color() { printf "%-30s : %b%s%b\n" "$1" "$2" "$3" "$C_RESET"; }
ok() { printf "%b\n" "${C_GREEN}[✓]${C_RESET} $1"; }
warn() { printf "%b\n" "${C_YELLOW}[!]${C_RESET} $1"; }
error() { printf "%b\n" "${C_RED}[✗]${C_RESET} $1"; }

# ============================================================
# HEADER
# ============================================================

echo
line
printf "%b\n" "${C_BOLD}${C_CYAN}        DEVHUNTER SECURITY - IDGUARD DNS${C_RESET}"
printf "%b\n" "${C_BOLD}${C_WHITE}            SYSTEM STATUS MONITOR${C_RESET}"
line

row "Waktu" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
row "Hostname" "$(hostname)"
row "Kernel" "$(uname -r)"

# ============================================================
# SYSTEM & RESOURCE
# ============================================================

section "SYSTEM & RESOURCE"

read -r RAM_TOTAL RAM_USED RAM_FREE RAM_AVAIL <<< "$(free -h | awk '/^Mem:/ {print $2,$3,$4,$7}')"
RAM_PERCENT="$(free | awk '/^Mem:/ {if ($2 > 0) printf "%.1f", ($3 / $2) * 100; else print "0.0"}')"
CPU_CORES="$(nproc 2>/dev/null || echo 0)"
LOAD_AVG="$(uptime | awk -F'load average:' '{gsub(/^ /, "", $2); print $2}')"

row "CPU Cores" "$CPU_CORES"
row "Total RAM" "$RAM_TOTAL"
row "RAM Terpakai" "$RAM_USED (${RAM_PERCENT}%)"
row "RAM Bebas" "$RAM_FREE"
row "RAM Tersedia" "$RAM_AVAIL"
row "System Load" "${LOAD_AVG:-N/A}"

# ============================================================
# UNBOUND SERVICE
# ============================================================

section "UNBOUND SERVICE"

UNBOUND_STATUS="$(systemctl is-active unbound 2>/dev/null || echo "inactive")"

case "$UNBOUND_STATUS" in
    active) SERVICE_TEXT="RUNNING"; SERVICE_COLOR="$C_GREEN" ;;
    inactive) SERVICE_TEXT="STOPPED"; SERVICE_COLOR="$C_YELLOW" ;;
    failed) SERVICE_TEXT="FAILED"; SERVICE_COLOR="$C_RED" ;;
    *) SERVICE_TEXT="UNKNOWN"; SERVICE_COLOR="$C_YELLOW" ;;
esac

UNBOUND_VERSION="$(unbound -V 2>/dev/null | awk '/Version/ {print $2; exit}')"
UNBOUND_VERSION="${UNBOUND_VERSION:-Unknown}"
START_TIME="$(systemctl show unbound -p ActiveEnterTimestamp --value 2>/dev/null || echo "Unknown")"

row_color "Service Status" "$SERVICE_TEXT" "$SERVICE_COLOR"
row "Unbound Version" "$UNBOUND_VERSION"
row "Service Started" "$START_TIME"

# ============================================================
# UNBOUND STATISTICS
# ============================================================

section "UNBOUND CACHE & PERFORMANCE"

UPTIME=0

if command -v unbound-control >/dev/null 2>&1; then
    STATS="$(unbound-control stats_noreset 2>/dev/null || true)"

    if [[ -n "$STATS" ]]; then
        MSG=0; RR=0; INFRA=0; HIT=0; MISS=0; QUERY=0; MM=0; MR=0
        RECUR_AVG=0; RECURSIVE=0; EXPIRED=0; PREFETCH=0; TCP=0
        UDP_OUT=0; QUEUE=0; EVICTIONS=0

        while IFS='=' read -r KEY VALUE; do
            case "$KEY" in
                msg.cache.count) MSG="${VALUE:-0}" ;;
                rrset.cache.count) RR="${VALUE:-0}" ;;
                infra.cache.count) INFRA="${VALUE:-0}" ;;
                total.num.cachehits) HIT="${VALUE:-0}" ;;
                total.num.cachemiss) MISS="${VALUE:-0}" ;;
                total.num.queries) QUERY="${VALUE:-0}" ;;
                mem.cache.message) MM="${VALUE:-0}" ;;
                mem.cache.rrset) MR="${VALUE:-0}" ;;
                time.up) UPTIME="${VALUE:-0}" ;;
                total.recursion.time.avg) RECUR_AVG="${VALUE:-0}" ;;
                total.num.recursivereplies) RECURSIVE="${VALUE:-0}" ;;
                total.num.expired) EXPIRED="${VALUE:-0}" ;;
                total.num.prefetch) PREFETCH="${VALUE:-0}" ;;
                num.query.tcp) TCP="${VALUE:-0}" ;;
                num.query.udpout) UDP_OUT="${VALUE:-0}" ;;
                total.requestlist.current.all) QUEUE="${VALUE:-0}" ;;
                msg.cache.evictions) EVICTIONS="${VALUE:-0}" ;;
            esac
        done <<< "$STATS"

        THREADS="$(grep -Ec '^thread[0-9]+\.num\.queries=' <<< "$STATS" || true)"
        TOTAL_CACHE=$((MSG + RR))
        TOTAL_CACHE_BYTES=$((MM + MR))
        REQUESTS=$((HIT + MISS))

        HIT_RATE="$(percent "$HIT" "$REQUESTS")"
        CACHE_MB="$(bytes_to_mb "$TOTAL_CACHE_BYTES")"

        AVG_QPS="$(awk -v q="$QUERY" -v u="$UPTIME" 'BEGIN {if (u > 0) printf "%.2f", q / u; else print "0.00"}')"
        RECUR_MS="$(awk -v t="$RECUR_AVG" 'BEGIN {printf "%.2f", t * 1000}')"

        row "Message Cache" "$(fmt "$MSG") entries"
        row "RRset Cache" "$(fmt "$RR") entries"
        row "Infra Cache" "$(fmt "$INFRA") entries"
        row "Total Cache" "$(fmt "$TOTAL_CACHE") entries"
        row "Cache Memory" "$CACHE_MB MB"
        row "Cache Hits" "$(fmt "$HIT") queries"
        row "Cache Misses" "$(fmt "$MISS") queries"
        row "Cache Hit Rate" "${HIT_RATE}%"
        row "Total Queries" "$(fmt "$QUERY") queries"
        row "Average QPS" "$AVG_QPS qps"
        row "Average Recursion" "$RECUR_MS ms"
        row "Recursive Replies" "$(fmt "$RECURSIVE")"
        row "Expired Cache Served" "$(fmt "$EXPIRED")"
        row "Prefetch Queries" "$(fmt "$PREFETCH")"
        row "Upstream UDP Lookups" "$(fmt "$UDP_OUT")"
        row "Client TCP Queries" "$(fmt "$TCP")"
        row "Worker Threads" "$THREADS"
        row "Current Query Queue" "$QUEUE"

        # ============================================================
        # INFRASTRUCTURE & EXTENDED METRICS
        # ============================================================

        section "UNBOUND INFRASTRUCTURE & EXTENDED METRICS"

        DNSSEC_SEC="$(grep -E 'num\.answer\.secure=' <<< "$STATS" | awk -F'=' '{s+=$2} END {print s+0}' || echo 0)"
        DNSSEC_BOG="$(grep -E 'num\.answer\.bogus=' <<< "$STATS" | awk -F'=' '{s+=$2} END {print s+0}' || echo 0)"

        row "Cache Evictions" "$(fmt "$EVICTIONS") entries"
        row "DNSSEC Validated (Secure)" "$(fmt "$DNSSEC_SEC")"
        row "DNSSEC Blocked (Bogus)" "$(fmt "$DNSSEC_BOG")"

        echo
        printf "%b\n" "${C_BOLD}[+] Top Query Types:${C_RESET}"
        
        grep -E 'num\.(query\.)?type\.[A-Z0-9]+=' <<< "$STATS" | \
            sed -E 's/.*type\.//' | \
            awk -F'=' '{types[$1]+=$2} END {for (t in types) if (types[t]>0) printf "    %-10s : %d\n", t, types[t]}' | \
            sort -k3 -nr | head -n 5 || echo "    Data query type tidak tersedia."

        echo
        printf "%b\n" "${C_BOLD}[+] Upstream Server Latency & Infrastructure (dump_infra):${C_RESET}"
        INFRA_DUMP="$(unbound-control dump_infra 2>/dev/null || true)"

        if [[ -n "$INFRA_DUMP" ]]; then
            echo "$INFRA_DUMP" | grep -v '^$' | head -n 10 | awk '{
                ip = $1
                rtt = 0
                rto = 0

                for (i=2; i<=NF; i++) {
                    if ($i ~ /^rtt=/) { split($i, a, "="); rtt = a[2] }
                    else if ($i == "rtt" && (i+1) <= NF) { rtt = $(i+1) }
                    
                    if ($i ~ /^rto=/) { split($i, b, "="); rto = b[2] }
                    else if ($i == "rto" && (i+1) <= NF) { rto = $(i+1) }
                }

                if (rtt > 0) {
                    printf "    IP: %-28s | RTT: %-4d ms | RTO: %-4d\n", ip, rtt, rto
                } else {
                    printf "    IP: %-28s | Status: Active (Cached / Idle Probe)\n", ip
                }
            }' || true
        else
            printf "    %b\n" "${C_YELLOW}Infra cache kosong atau perintah dump_infra gagal.${C_RESET}"
        fi

    else
        error "Tidak dapat mengambil statistik Unbound."
    fi
else
    error "unbound-control tidak tersedia."
fi

# ============================================================
# ROOT SERVERS LATENCY MONITORING (A-M: IPv4 & IPv6 - Parallel)
# ============================================================

section "ROOT SERVERS LATENCY (IPv4 & IPv6)"

declare -A ROOT_V4=(
    ["A"]="198.41.0.4"
    ["B"]="170.247.170.2"
    ["C"]="192.33.4.12"
    ["D"]="199.7.91.13"
    ["E"]="192.203.230.10"
    ["F"]="192.5.5.241"
    ["G"]="192.112.36.4"
    ["H"]="198.97.190.53"
    ["I"]="192.36.148.17"
    ["J"]="192.58.128.30"
    ["K"]="193.0.14.129"
    ["L"]="199.7.83.42"
    ["M"]="202.12.27.33"
)

declare -A ROOT_V6=(
    ["A"]="2001:503:ba3e::2:30"
    ["B"]="2801:1b8:10::b"
    ["C"]="2001:500:2::c"
    ["D"]="2001:500:2d::d"
    ["E"]="2001:500:a8::e"
    ["F"]="2001:500:2f::f"
    ["G"]="2001:500:12::d0d"
    ["H"]="2001:500:1::53"
    ["I"]="2001:7fe::53"
    ["J"]="2001:503:c27::2:30"
    ["K"]="2001:7fd::1"
    ["L"]="2001:500:9f::42"
    ["M"]="2001:dc3::35"
)

printf "%-12s | %-20s | %-12s\n" "Root" "RTT (IPv4)" "RTT (IPv6)"
subline

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

for key in {A..M}; do
    (
        ip4="${ROOT_V4[$key]}"
        ip6="${ROOT_V6[$key]}"
        
        rtt4=$(ping -c 1 -W 1 "$ip4" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
        rtt6=$(ping -6 -c 1 -W 1 "$ip6" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
        
        if [[ -n "$rtt4" ]]; then
            str4="$(printf "%b%6.2f ms%b" "${C_GREEN}" "$rtt4" "${C_RESET}")"
        else
            str4="$(printf "%bTIMEOUT%b" "${C_RED}" "${C_RESET}")"
        fi
        
        if [[ -n "$rtt6" ]]; then
            str6="$(printf "%b%6.2f ms%b" "${C_GREEN}" "$rtt6" "${C_RESET}")"
        else
            str6="$(printf "%bTIMEOUT%b" "${C_RED}" "${C_RESET}")"
        fi
        
        printf "Root-%-7s | %-20s | %-12s\n" "$key" "$str4" "$str6" > "$TMP_DIR/$key"
    ) &
done

wait

for key in {A..M}; do
    if [[ -f "$TMP_DIR/$key" ]]; then
        cat "$TMP_DIR/$key"
    fi
done

# ============================================================
# ACTIVE STUB-ZONE ROOT SERVERS (Custom Ping - IPv4 & IPv6 Separated)
# ============================================================

section "ACTIVE STUB-ZONE ROOT SERVERS (Custom Ping)"

STUB_CONF_FILE="/etc/unbound/root-stub.conf"

if [[ -f "$STUB_CONF_FILE" ]]; then
    mapfile -t STUB_TARGETS < <(grep -E '^[[:space:]]*stub-addr:' "$STUB_CONF_FILE" | sed -E 's/^[[:space:]]*stub-addr:[[:space:]]*//')

    if (( ${#STUB_TARGETS[@]} > 0 )); then
        STUB_TMP_DIR="$(mktemp -d)"
        trap 'rm -rf "$STUB_TMP_DIR"' EXIT

        for i in "${!STUB_TARGETS[@]}"; do
            (
                line_data="${STUB_TARGETS[$i]}"
                ip_addr="$(echo "$line_data" | awk '{print $1}')"
                comment="$(echo "$line_data" | cut -d'#' -f2- | xargs)"
                [[ -z "$comment" ]] && comment="Custom IP"

                # Tentukan jenis IP (v4 atau v6)
                if [[ "$ip_addr" =~ : ]]; then
                    family="IPv6"
                    rtt=$(ping -6 -c 1 -W 1 "$ip_addr" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
                else
                    family="IPv4"
                    rtt=$(ping -c 1 -W 1 "$ip_addr" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
                fi

                if [[ -n "$rtt" ]]; then
                    if (( $(awk -v v="$rtt" 'BEGIN {print (v < 10) ? 1 : 0}') )); then
                        str_rtt="$(printf "%b%6.2f ms (Ultra-Fast)%b" "${C_GREEN}" "$rtt" "${C_RESET}")"
                    else
                        str_rtt="$(printf "%b%6.2f ms%b" "${C_YELLOW}" "$rtt" "${C_RESET}")"
                    fi
                else
                    str_rtt="$(printf "%bTIMEOUT%b" "${C_RED}" "${C_RESET}")"
                fi

                # Format output dan simpan dengan urutan family untuk sorting
                printf "%s | %-32s | %-15s\n" "$family" "$ip_addr ($comment)" "$str_rtt" > "$STUB_TMP_DIR/$i"
            ) &
        done

        wait

        # Cetak Kategori IPv4
        printf "%b\n" "${C_BOLD}[+] IPv4 Root Servers:${C_RESET}"
        printf "%-35s | %-15s\n" "Target (Stub-Addr)" "RTT (Latency)"
        subline
        for i in "${!STUB_TARGETS[@]}"; do
            if [[ -f "$STUB_TMP_DIR/$i" ]]; then
                read -r fam line_out < <(cat "$STUB_TMP_DIR/$i")
                if [[ "$fam" == "IPv4" ]]; then
                    printf "%s\n" "$line_out"
                fi
            fi
        done

        echo
        # Cetak Kategori IPv6
        printf "%b\n" "${C_BOLD}[+] IPv6 Root Servers:${C_RESET}"
        printf "%-35s | %-15s\n" "Target (Stub-Addr)" "RTT (Latency)"
        subline
        for i in "${!STUB_TARGETS[@]}"; do
            if [[ -f "$STUB_TMP_DIR/$i" ]]; then
                read -r fam line_out < <(cat "$STUB_TMP_DIR/$i")
                if [[ "$fam" == "IPv6" ]]; then
                    printf "%s\n" "$line_out"
                fi
            fi
        done

    else
        warn "Tidak ada stub-addr yang ditemukan di dalam $STUB_CONF_FILE."
    fi
else
    warn "File konfigurasi root-stub.conf tidak ditemukan di jalur standar."
fi

# ============================================================
# DATABASE
# ============================================================

section "IDGUARD DATABASE"

BLOCKLIST_SOURCES=0
WHITELIST_SOURCES=0

if [[ -f "$BLOCKLIST_LINKS" ]]; then
    BLOCKLIST_SOURCES="$(grep -Ev '^[[:space:]]*(#|$)' "$BLOCKLIST_LINKS" | wc -l || echo 0)"
fi

if [[ -f "$WHITELIST_LINKS" ]]; then
    WHITELIST_SOURCES="$(grep -Ev '^[[:space:]]*(#|$)' "$WHITELIST_LINKS" | wc -l || echo 0)"
fi

if [[ -f "$BLOCKLIST_FILE" ]]; then
    BLOCK_FILE_COUNT="$(grep -c '^local-zone:' "$BLOCKLIST_FILE" || echo 0)"
    BLOCK_FILE_SIZE="$(du -h "$BLOCKLIST_FILE" 2>/dev/null | awk '{print $1}')"
else
    BLOCK_FILE_COUNT=0
    BLOCK_FILE_SIZE="N/A"
fi

if [[ -f "$WHITELIST_FILE" ]]; then
    WHITE_FILE_COUNT="$(grep -c '^local-zone:' "$WHITELIST_FILE" || echo 0)"
    WHITE_FILE_SIZE="$(du -h "$WHITELIST_FILE" 2>/dev/null | awk '{print $1}')"
else
    WHITE_FILE_COUNT=0
    WHITE_FILE_SIZE="N/A"
fi

BLOCK_RAW=0; BLOCK_UNIQUE=0; BLOCK_DUP=0
WHITE_RAW=0; WHITE_UNIQUE=0; WHITE_DUP=0

if [[ -f "$BLOCKLIST_META" ]]; then
    while IFS='=' read -r KEY VALUE; do
        case "$KEY" in
            TOTAL_RAW) BLOCK_RAW="${VALUE:-0}" ;;
            TOTAL_UNIQUE) BLOCK_UNIQUE="${VALUE:-0}" ;;
            DUPLICATE) BLOCK_DUP="${VALUE:-0}" ;;
        esac
    done < "$BLOCKLIST_META"
fi

if [[ -f "$WHITELIST_META" ]]; then
    while IFS='=' read -r KEY VALUE; do
        case "$KEY" in
            TOTAL_RAW) WHITE_RAW="${VALUE:-0}" ;;
            TOTAL_UNIQUE) WHITE_UNIQUE="${VALUE:-0}" ;;
            DUPLICATE) WHITE_DUP="${VALUE:-0}" ;;
        esac
    done < "$WHITELIST_META"
fi

(( BLOCK_UNIQUE == 0 )) && BLOCK_UNIQUE="$BLOCK_FILE_COUNT"
(( WHITE_UNIQUE == 0 )) && WHITE_UNIQUE="$WHITE_FILE_COUNT"

BLOCK_DUP_PERCENT="$(percent "$BLOCK_DUP" "$BLOCK_RAW")"
WHITE_DUP_PERCENT="$(percent "$WHITE_DUP" "$WHITE_RAW")"

row "Blocklist Sources" "$(fmt "$BLOCKLIST_SOURCES") lists"
row "Blocklist Domains" "$(fmt "$BLOCK_FILE_COUNT") domains"
row "Blocklist Duplicates" "$(fmt "$BLOCK_DUP") entries"
row "Blocklist Duplicate Rate" "${BLOCK_DUP_PERCENT}%"
row "Blocklist Size" "$BLOCK_FILE_SIZE"
echo
row "Whitelist Sources" "$(fmt "$WHITELIST_SOURCES") lists"
row "Whitelist Domains" "$(fmt "$WHITE_FILE_COUNT") domains"
row "Whitelist Duplicates" "$(fmt "$WHITE_DUP") entries"
row "Whitelist Duplicate Rate" "${WHITE_DUP_PERCENT}%"
row "Whitelist Size" "$WHITE_FILE_SIZE"

# ============================================================
# INDONESIA IPSET MONITORING
# ============================================================

section "INDONESIA IPSET MONITORING"

if command -v ipset >/dev/null 2>&1; then
    # Cek IPv4
    if ipset list indo_v4 >/dev/null 2>&1; then
        SET4_ENTRIES="$(ipset list indo_v4 | grep "Number of entries" | awk '{print $NF}')"
        SET4_MEM="$(ipset list indo_v4 | grep "Size in memory" | awk '{print $4, $5}')"
        row "Ipset IPv4 (indo_v4)" "$(fmt "${SET4_ENTRIES:-0}") entries (${SET4_MEM:-N/A})"
    else
        warn "Ipset 'indo_v4' belum ada."
    fi

    # Cek IPv6
    if ipset list indo_v6 >/dev/null 2>&1; then
        SET6_ENTRIES="$(ipset list indo_v6 | grep "Number of entries" | awk '{print $NF}')"
        SET6_MEM="$(ipset list indo_v6 | grep "Size in memory" | awk '{print $4, $5}')"
        row "Ipset IPv6 (indo_v6)" "$(fmt "${SET6_ENTRIES:-0}") entries (${SET6_MEM:-N/A})"
    else
        warn "Ipset 'indo_v6' belum ada."
    fi
else
    warn "Modul ipset tidak tersedia."
fi

# ============================================================
# DATABASE INTEGRITY
# ============================================================

section "DATABASE INTEGRITY"

if [[ -f "$BLOCKLIST_FILE" ]]; then
    if [[ "$BLOCK_UNIQUE" -eq "$BLOCK_FILE_COUNT" ]]; then
        ok "Blocklist integrity: PASS"
        row "Blocklist Status" "UNIQUE / CLEAN"
    else
        warn "Blocklist metadata berbeda dengan file final."
        row "Blocklist Status" "CHECK REQUIRED"
    fi
else
    error "Blocklist file tidak ditemukan."
fi

if [[ -f "$WHITELIST_FILE" ]]; then
    if [[ "$WHITE_UNIQUE" -eq "$WHITE_FILE_COUNT" ]]; then
        ok "Whitelist integrity: PASS"
        row "Whitelist Status" "UNIQUE / CLEAN"
    else
        warn "Whitelist metadata berbeda dengan file final."
        row "Whitelist Status" "CHECK REQUIRED"
    fi
else
    error "Whitelist file tidak ditemukan."
fi

# ============================================================
# UPTIME & HEALTH SUMMARY
# ============================================================

section "UNBOUND UPTIME"

UPTIME_SEC="$(printf "%.0f" "${UPTIME:-0}")"
DAYS=$((UPTIME_SEC / 86400))
HOURS=$(((UPTIME_SEC % 86400) / 3600))
MINS=$(((UPTIME_SEC % 3600) / 60))
SECS=$((UPTIME_SEC % 60))

if (( DAYS > 0 )); then
    UPTIME_TEXT="${DAYS} hari ${HOURS} jam ${MINS} menit"
elif (( HOURS > 0 )); then
    UPTIME_TEXT="${HOURS} jam ${MINS} menit"
elif (( MINS > 0 )); then
    UPTIME_TEXT="${MINS} menit ${SECS} detik"
else
    UPTIME_TEXT="${SECS} detik"
fi

row "Unbound Uptime" "$UPTIME_TEXT"

section "HEALTH SUMMARY"

HEALTH=0
HEALTH_TOTAL=5

[[ "$UNBOUND_STATUS" == "active" ]] && HEALTH=$((HEALTH + 1))
[[ -f "$BLOCKLIST_FILE" ]] && HEALTH=$((HEALTH + 1))
[[ -f "$WHITELIST_FILE" ]] && HEALTH=$((HEALTH + 1))
[[ -f "$BLOCKLIST_FILE" ]] && [[ "$BLOCK_UNIQUE" -eq "$BLOCK_FILE_COUNT" ]] && HEALTH=$((HEALTH + 1))
[[ -f "$WHITELIST_FILE" ]] && [[ "$WHITE_UNIQUE" -eq "$WHITE_FILE_COUNT" ]] && HEALTH=$((HEALTH + 1))

if (( HEALTH == HEALTH_TOTAL )); then
    printf "\n%b\n" "${C_GREEN}${C_BOLD}        [✓] IDGUARD DNS HEALTHY${C_RESET}"
    printf "%b\n" "${C_GREEN}        All critical checks passed.${C_RESET}"
elif (( HEALTH >= 3 )); then
    printf "\n%b\n" "${C_YELLOW}${C_BOLD}        [!] IDGUARD DNS WARNING${C_RESET}"
    printf "%b\n" "${C_YELLOW}        Some checks require attention.${C_RESET}"
else
    printf "\n%b\n" "${C_RED}${C_BOLD}        [✗] IDGUARD DNS CRITICAL${C_RESET}"
    printf "%b\n" "${C_RED}        Critical checks failed.${C_RESET}"
fi

row "Health Score" "${HEALTH}/${HEALTH_TOTAL}"

# ============================================================
# TELEGRAM NOTIFICATION SENDER (Fully Aligned & Multi-Section)
# ============================================================
if [[ "${TELEGRAM_ENABLED:-false}" == "true" ]]; then
    TG_MSG="<b>🛡️ IDGUARD DNS ROOT SERVERS STATUS</b>"$'\n'
    TG_MSG+="<b>Host:</b> ${HOSTNAME_VAL:-$(hostname)} | <b>Time:</b> ${CURRENT_TIME:-$(date '+%Y-%m-%d %H:%M:%S %Z')}"$'\n\n'
    
    # --- BAGIAN 1: GLOBAL ROOT SERVERS LATENCY (A - M) ---
    TG_MSG+="<b>🌐 ROOT SERVERS LATENCY (A - M)</b>"$'\n'
    TG_MSG+="<pre>"
    TG_MSG+="$(printf "%-7s | %-10s | %-10s\n" "Root" "RTT (v4)" "RTT (v6)")"
    TG_MSG+="-----------------------------------"$'\n'
    
    table_lines=()
    for key in {A..M}; do
        if [[ -f "$TMP_DIR/$key" ]]; then
            rtt4=$(ping -c 1 -W 1 "${ROOT_V4[$key]}" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
            rtt6=$(ping -6 -c 1 -W 1 "${ROOT_V6[$key]}" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
            
            str4="${rtt4:+$(printf "%6.2f ms" "$rtt4")}"
            [[ -z "$str4" ]] && str4="TIMEOUT"
            
            str6="${rtt6:+$(printf "%6.2f ms" "$rtt6")}"
            [[ -z "$str6" ]] && str6="TIMEOUT"
            
            table_lines+=("$(printf "Root-%-2s  | %-10s | %-10s" "$key" "$str4" "$str6")")
        fi
    done
    TG_MSG+="$(printf '%s\n' "${table_lines[@]}")"
    TG_MSG+="</pre>"$'\n\n'

    # --- BAGIAN 2: ACTIVE STUB IPv4 ROOT SERVERS ---
    v4_lines=()
    for key in {A..M}; do
        if [[ -f "$TMP_DIR/$key" ]]; then
            rtt_val=$(ping -c 1 -W 1 "${ROOT_V4[$key]}" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
            if [[ -n "$rtt_val" ]]; then
                val_int="${rtt_val%.*}"
                if (( val_int < 35 )); then
                    tag=""
                    (( val_int < 15 )) && tag=" (Ultra-Fast)"
                    v4_lines+=("$(printf "%-15s (Root %s) : %6.2f ms%s" "${ROOT_V4[$key]}" "$key" "$rtt_val" "$tag")")
                fi
            fi
        fi
    done

    if (( ${#v4_lines[@]} > 0 )); then
        TG_MSG+="<b>[+] Active Stub IPv4 Root Servers:</b>"$'\n'
        TG_MSG+="<pre>"
        TG_MSG+="Target (Stub-Addr)  | RTT (Latency)"$'\n'
        TG_MSG+="---------------------------------------"$'\n'
        TG_MSG+="$(printf '%s\n' "${v4_lines[@]}")"
        TG_MSG+="</pre>"$'\n\n'
    fi

    # --- BAGIAN 3: ACTIVE STUB IPv6 ROOT SERVERS ---
    v6_lines=()
    for key in {A..M}; do
        if [[ -f "$TMP_DIR/$key" ]]; then
            rtt_val6=$(ping -6 -c 1 -W 1 "${ROOT_V6[$key]}" 2>/dev/null | awk -F'rtt min/avg/max/mdev = ' '/rtt/ {print $2}' | cut -d'/' -f2 || true)
            if [[ -n "$rtt_val6" ]]; then
                val6_int="${rtt_val6%.*}"
                if (( val6_int < 35 )); then
                    tag6=""
                    (( val6_int < 15 )) && tag6=" (Ultra-Fast)"
                    v6_lines+=("$(printf "%-15s (Root %s) : %6.2f ms%s" "${ROOT_V6[$key]}" "$key" "$rtt_val6" "$tag6")")
                fi
            fi
        fi
    done

    if (( ${#v6_lines[@]} > 0 )); then
        TG_MSG+="<b>[+] Active Stub IPv6 Root Servers:</b>"$'\n'
        TG_MSG+="<pre>"
        TG_MSG+="Target (Stub-Addr)  | RTT (Latency)"$'\n'
        TG_MSG+="---------------------------------------"$'\n'
        TG_MSG+="$(printf '%s\n' "${v6_lines[@]}")"
        TG_MSG+="</pre>"
    fi
    
    send_telegram "$TG_MSG"
fi

echo
line
printf "%b\n" "${C_BOLD}Status monitoring selesai.${C_RESET}"
line