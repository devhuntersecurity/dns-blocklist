<<<<<<< HEAD
#!/bin/bash
set -euo pipefail

BASE_DIR="/etc/unbound/unbound.conf.d"
CACHE_FILE="/var/lib/unbound/cache.dump"

ERROR=0
CHANGED=1  # selalu dianggap berubah (always fresh)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ===============================
# PREREQUISITE CHECK
# ===============================
for cmd in wget curl unbound-control unbound-checkconf systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || {
        log "[!] Command tidak ditemukan: $cmd"
        exit 1
    }
done

# ===============================
# BACKUP CACHE
# ===============================
log "[?] Backup DNS cache..."
unbound-control dump_cache > "$CACHE_FILE" 2>/dev/null || true

# ===============================
# RESET FOLDER
# ===============================
log "[?] Reset folder blocklist..."
rm -rf "$BASE_DIR/malware" \
       "$BASE_DIR/00-safesearch" \
       "$BASE_DIR/zzz-whitelist" \

mkdir -p "$BASE_DIR/malware" \
         "$BASE_DIR/00-safesearch" \
         "$BASE_DIR/zzz-whitelist" \

# ===============================
# LIST
# ===============================
declare -A LISTS

# SAFESEARCH
LISTS["00-safesearch/00-DevHunter-Safesearch.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/safesearch.conf"

# Lokal / DevHunter
LISTS["malware/01-DevHunter-BlockListDev-Lokal.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/devhunter-BlockListDev.conf"

# OISD
LISTS["malware/01-DevHunter-OISD-Big.conf"]="https://big.oisd.nl/unbound"

# 1Hosts
LISTS["malware/01-DevHunter-1Hosts-Lite.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/1hosts-lite.conf"

# CertPL
LISTS["malware/01-DevHunter-CertPL.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/certpl.conf"

# Cyberhost
LISTS["malware/01-DevHunter-Cyberhost.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/cyberhost.conf"

# ThreatFox
LISTS["malware/01-DevHunter-ThreatFox.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/threatfox.conf"

# Hagezi
LISTS["malware/01-DevHunter-hagezi-dga7.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-dga7.conf"
LISTS["malware/01-DevHunter-hagezi-pro.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-pro.conf"
LISTS["malware/01-DevHunter-hagezi-tif.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-tif.conf"
LISTS["malware/01-DevHunter-hagezi-spam-tlds.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-spam-tlds.conf"
LISTS["malware/01-DevHunter-hagezi-nosafesearch.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-nosafesearch.conf"
LISTS["malware/01-DevHunter-hagezi-hoster.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-hoster.conf"
LISTS["malware/01-DevHunter-hagezi-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-gambling.conf"
LISTS["malware/01-DevHunter-hagezi-nsfw.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/BlockList_DB/hagezi-nsfw.conf"

# shadowwhisperer
LISTS["malware/01-DevHunter-shadowwhisperer-malware.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-malware.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-scam.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-scam.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-typo.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-typo.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-malware-hosting.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-malware-hosting-ips.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-gambling.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-tracking.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/BlockList_DB/shadowwhisperer-tracking.conf"

# romainmarcoux
LISTS["malware/01-DevHunter-romainmarcoux.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/romainmarcoux-full-aa-ab-ac.conf"

# anti-ad
LISTS["malware/01-DevHunter-anti-ad.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/anti-ad.conf"

# Tempest-Solutions-Company
LISTS["malware/01-DevHunter-pi-hole-all-malicious.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/pi-hole-all-malicious.conf"

# phishdestroy
LISTS["malware/01-DevHunter-phishdestroy.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/phishdestroy.conf"

# MalwareWorld
LISTS["malware/01-DevHunter-malwareworld-phishing.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-phishing.conf"
LISTS["malware/01-DevHunter-malwareworld-malware.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-malware.conf"
LISTS["malware/01-DevHunter-malwareworld-DGA.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-dga.conf"
LISTS["malware/01-DevHunter-malwareworld-knownattacker.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-knownattacker.conf"
LISTS["malware/01-DevHunter-malwareworld-spammer.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-spammer.conf"

# spydisec
LISTS["malware/01-DevHunter-spydisec-malicious-part1.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part1.conf"
LISTS["malware/01-DevHunter-spydisec-malicious-part2.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part2.conf"
LISTS["malware/01-DevHunter-spydisec-malicious-part3.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part3.conf"
LISTS["malware/01-DevHunter-spydisec-ads.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/BlockList_DB/spydisec-ads.conf"

# stalkerware
LISTS["malware/01-DevHunter-stalkerware.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/stalkerware.conf"
LISTS["malware/01-DevHunter-stalkerware-quad9.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/stalkerware-quad9.conf"

# NRD
LISTS["malware/01-DevHunter-nrd-1d.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/nrd-1d.conf"
LISTS["malware/01-DevHunter-nrd-3d.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/nrd-3d.conf"

# RPiList
LISTS["malware/01-DevHunter-RPiList-Malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/RPiList/Malware.fork.conf"
LISTS["malware/01-DevHunter-RPiList-Phishing.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/phishing/RPiList/Phishing-Angriffe.fork.conf"
LISTS["malware/01-DevHunter-RPiList-Spamm.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/spam/RPiList/spam-mails.fork.conf"

# useless-websites
LISTS["malware/01-DevHunter-useless-websites-parked-domains.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/useless-websites/jarelllama/parked-domains.fork.conf"
LISTS["malware/01-DevHunter-useless-websites-sefinek.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/useless-websites/sefinek.hosts.conf"

# Big Dragon
LISTS["malware/01-DevHunter-bigdargon-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/bigdargon/hostsVN.fork.conf"

# DandelionSprout
LISTS["malware/01-DevHunter-DandelionSprout-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/DandelionSprout-AntiMalwareHosts.fork.conf"

# disconnectme
LISTS["malware/01-DevHunter-disconnectme-simple-malvertising.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/disconnectme/simple-malvertising.fork.conf"

# URLhaus
LISTS["malware/01-DevHunter-URLhaus-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/malware-filter/urlhaus-filter-hosts-online.fork.conf"
LISTS["malware/01-DevHunter-URLhaus-abuse.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/abuse/urlhaus.abuse.ch/hostfile.fork.conf"

# Accomplist
LISTS["malware/01-DevHunter-Accomplist-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/Accomplist%20Gambling%20Unbound.conf"
LISTS["malware/01-DevHunter-Accomplist-Malicious-Dom.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/Accomplist%20Malicious-Dom%20Top-N%20Unbound.conf"
LISTS["malware/01-DevHunter-Accomplist-Anti-Track.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/BlockList_DB/Accomplist%20Anti-Track%20Top-N%20Unbound.conf"
LISTS["malware/01-DevHunter-Accomplist-Typosquat.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/BlockList_DB/Accomplist%20Typosquat%20Top-N%20Unbound.conf"

# Army Phishing
LISTS["malware/01-DevHunter-phishing-army.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/phishing/phishing.army/blocklist-extended.fork.conf"

# quidsup
LISTS["malware/01-DevHunter-notrack-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/quidsup/notrack-malware.fork.conf"

# stopforumspam
LISTS["malware/01-DevHunter-toxic-domains-whole.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/spam/stopforumspam/toxic-domains-whole.fork.conf"

# NeoDevHost
LISTS["malware/01-DevHunter-neodevhost.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/neodevhost.conf"

# Trustpositif Alsyundawy
LISTS["malware/01-DevHunter-Alsyundawy-TrustPositif-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/Alsyundawy%20TrustPositif%20Gambling%20Indonesia.conf"

# Trustpositif AU
LISTS["malware/01-DevHunter-trustpositif-gambling-au.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/trustpositif-gambling-au.conf"

# Trustpositif ID
LISTS["malware/01-DevHunter-trustpositif-gambling-id.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/trustpositif-gambling-id.conf"

# StevenBlack
LISTS["malware/01-DevHunter-StevenBlack.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/stevenblack-unbound.conf"

# ACMA Gambling
LISTS["malware/01-DevHunter-ACMA-Gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/acma-gambling.conf"
LISTS["malware/01-DevHunter-Estonia-Gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/estonia-gambling.conf"

# JUDOL
LISTS["malware/01-DevHunter-JUDOL.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/judol-gambling.conf"

# Gambling NL
LISTS["malware/01-DevHunter-Gambling-NL.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/gambling-nl.conf"

# FireBOG
LISTS["malware/01-DevHunter-firebog-aio.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/BlockList_DB/firebog-aio.conf"

# ===============================
# WHITELIST
# ===============================
LISTS["zzz-whitelist/zzzz-devhunter-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/devhunter-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-shadowwhisperer-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/shadowwhisperer-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-referral-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-apple-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-apple-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-huawei-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-huawei-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-lg-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-lgwebos-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-oppo-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-oppo-realme-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-samsung-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-samsung-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-vivo-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-vivo-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-win-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-winoffice-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-xiaomi-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-xiaomi-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-amazon-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-amazon-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-roku-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-roku-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-tiktok-ext-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-tiktok-extended-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-tiktok-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-tiktok-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-smart-tv-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/WhiteList%20DB/hagezi-smart-tv-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-blocklistproject-smart-tv-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/WhiteList%20DB/blocklistproject-smart-tv-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-LG-smart-tv-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/dns-blocklist/refs/heads/main/WhiteList%20DB/lg-smart-tv-whitelist.conf"

# ===============================
# DOWNLOAD
# ===============================
for path in "${!LISTS[@]}"; do

    url="${LISTS[$path]}"
    tmp="/tmp/unbound-$$-$(basename "$path")"
    dest="$BASE_DIR/$path"

    log "[+] Download $path"

    wget -T 30 -t 2 -qO "$tmp" "$url" || curl -fsSL "$url" -o "$tmp" || {
        log "[!] Gagal download: $path"
        ERROR=1
        continue
    }

    [ -s "$tmp" ] || {
        log "[!] File kosong: $path"
        ERROR=1
        continue
    }

    mv "$tmp" "$dest"
    log "[✓] Update: $path"

    if ! unbound-checkconf "$dest" >/dev/null 2>&1; then
        log "[!] Syntax error: $dest"
        ERROR=1
    fi

done

# ===============================
# RELOAD
# ===============================
if [ "$ERROR" -eq 0 ]; then

    log "[?] Reload Unbound (always fresh)..."

    if unbound-control reload_keep_cache 2>/dev/null; then
        log "[✓] Reload berhasil (cache dipertahankan)"

    else
        log "[!] reload_keep_cache gagal, fallback..."

        if systemctl reload unbound; then
            log "[✓] Reload berhasil"
        else
            log "[!] Restart Unbound"
            systemctl restart unbound
        fi

        log "[?] Restore cache..."
        unbound-control load_cache < "$CACHE_FILE" 2>/dev/null || true
    fi

else
    log "[!] Error ditemukan, Unbound tidak direload"
fi
=======
#!/bin/bash
set -euo pipefail

BASE_DIR="/etc/unbound/unbound.conf.d"
CACHE_FILE="/var/lib/unbound/cache.dump"

ERROR=0
CHANGED=1  # selalu dianggap berubah (always fresh)

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# ===============================
# PREREQUISITE CHECK
# ===============================
for cmd in wget curl unbound-control unbound-checkconf systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || {
        log "[!] Command tidak ditemukan: $cmd"
        exit 1
    }
done

# ===============================
# BACKUP CACHE
# ===============================
log "[?] Backup DNS cache..."
unbound-control dump_cache > "$CACHE_FILE" 2>/dev/null || true

# ===============================
# RESET FOLDER
# ===============================
log "[?] Reset folder blocklist..."
rm -rf "$BASE_DIR/malware" \
       "$BASE_DIR/00-safesearch" \
       "$BASE_DIR/zzz-whitelist" \
       "$BASE_DIR/zzz-block-lokal"

mkdir -p "$BASE_DIR/malware" \
         "$BASE_DIR/00-safesearch" \
         "$BASE_DIR/zzz-whitelist" \
         "$BASE_DIR/zzz-block-lokal"

# ===============================
# LIST
# ===============================
declare -A LISTS

# Lokal / DevHunter
LISTS["zzz-block-lokal/zzzz-DevHunter-BlockListDev-Lokal.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/devhunter-BlockListDev.conf"

# SAFESEARCH
LISTS["00-safesearch/00-DevHunter-SAFESEARCH.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/safesearch.conf"

# OISD
LISTS["malware/01-DevHunter-OISD-Big.conf"]="https://big.oisd.nl/unbound"
LISTS["malware/01-DevHunter-OISD-nsfw-small.conf"]="https://nsfw-small.oisd.nl/unbound"

# 1Hosts
LISTS["malware/01-DevHunter-1Hosts-Lite.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/1hosts-lite.conf"

# CertPL
LISTS["malware/01-DevHunter-CertPL.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/certpl.conf"

# Cyberhost
LISTS["malware/01-DevHunter-Cyberhost.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/cyberhost.conf"

# ThreatFox
LISTS["malware/01-DevHunter-ThreatFox.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/threatfox.conf"

# Hagezi
LISTS["malware/01-DevHunter-hagezi-dga7.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-dga7.conf"
LISTS["malware/01-DevHunter-hagezi-pro.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-pro.conf"
LISTS["malware/01-DevHunter-hagezi-tif.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-tif.conf"
LISTS["malware/01-DevHunter-hagezi-spam-tlds.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-spam-tlds.conf"
LISTS["malware/01-DevHunter-hagezi-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-gambling.conf"
LISTS["malware/01-DevHunter-hagezi-nosafesearch.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/hagezi-nosafesearch.conf"

# shadowwhisperer
LISTS["malware/01-DevHunter-shadowwhisperer-malware.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-malware.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-scam.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-scam.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-typo.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-typo.conf"
LISTS["malware/01-DevHunter-shadowwhisperer-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/shadowwhisperer-gambling.conf"

# romainmarcoux
LISTS["malware/01-DevHunter-romainmarcoux.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/romainmarcoux-full-aa-ab-ac.conf"

# anti-ad
LISTS["malware/01-DevHunter-anti-ad.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/anti-ad.conf"

# Tempest-Solutions-Company
LISTS["malware/01-DevHunter-pi-hole-all-malicious.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/pi-hole-all-malicious.conf"

# phishdestroy
LISTS["malware/01-DevHunter-phishdestroy.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/phishdestroy.conf"

# MalwareWorld
LISTS["malware/01-DevHunter-malwareworld-phishing.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-phishing.conf"
LISTS["malware/01-DevHunter-malwareworld-malware.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-malware.conf"
LISTS["malware/01-DevHunter-malwareworld-DGA.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/malwareworld-dga.conf"

# spydisec
LISTS["malware/01-DevHunter-spydisec-malicious-part1.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part1.conf"
LISTS["malware/01-DevHunter-spydisec-malicious-part2.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part2.conf"
LISTS["malware/01-DevHunter-spydisec-malicious-part3.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part3.conf"
#LISTS["malware/01-DevHunter-spydisec-malicious-part4.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part4.conf"
#LISTS["malware/01-DevHunter-spydisec-malicious-part5.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part5.conf"
#LISTS["malware/01-DevHunter-spydisec-malicious-part6.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part6.conf"
#LISTS["malware/01-DevHunter-spydisec-malicious-part7.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part7.conf"
#LISTS["malware/01-DevHunter-spydisec-malicious-part8.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part8.conf"
#LISTS["malware/01-DevHunter-spydisec-malicious-part9.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part9.conf"
#LISTS["malware/01-DevHunter-spydisec-malicious-part10.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part10.conf"
LISTS["malware/01-DevHunter-spydisec-malicious-part11.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/spydisec-malicious-part11.conf"

# stalkerware
LISTS["malware/01-DevHunter-stalkerware.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/stalkerware.conf"
LISTS["malware/01-DevHunter-stalkerware-quad9.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/stalkerware-quad9.conf"

# NRD
LISTS["malware/01-DevHunter-nrd-1d.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/nrd-1d.conf"
LISTS["malware/01-DevHunter-nrd-3d.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/nrd-3d.conf"

# RPiList
LISTS["malware/01-DevHunter-RPiList-Malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/RPiList/Malware.fork.conf"
LISTS["malware/01-DevHunter-RPiList-Phishing.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/phishing/RPiList/Phishing-Angriffe.fork.conf"

# useless-websites
LISTS["malware/01-DevHunter-useless-websites-parked-domains.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/useless-websites/jarelllama/parked-domains.fork.conf"
LISTS["malware/01-DevHunter-useless-websites-sefinek.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/useless-websites/sefinek.hosts.conf"

# blocklistproject
LISTS["malware/01-DevHunter-blocklistproject-redirect.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/redirect/blocklistproject/redirect.fork.conf"
LISTS["malware/01-DevHunter-blocklistproject-ransomware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/ransomware/blocklistproject/ransomware.fork.conf"
LISTS["malware/01-DevHunter-blocklistproject-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/blocklistproject/malware.fork.conf"
LISTS["malware/01-DevHunter-blocklistproject-abuse.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/abuse/blocklistproject/hosts.fork.conf"

# Big Dragon
LISTS["malware/01-DevHunter-bigdargon-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/bigdargon/hostsVN.fork.conf"

# DandelionSprout
LISTS["malware/01-DevHunter-DandelionSprout-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/DandelionSprout-AntiMalwareHosts.fork.conf"

# URLhaus
LISTS["malware/01-DevHunter-URLhaus-malware.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/malicious/malware-filter/urlhaus-filter-hosts-online.fork.conf"
LISTS["malware/01-DevHunter-URLhaus-abuse.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/abuse/urlhaus.abuse.ch/hostfile.fork.conf"

# Accomplist
LISTS["malware/01-DevHunter-Accomplist-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/Accomplist%20Gambling%20Unbound.conf"
LISTS["malware/01-DevHunter-Accomplist-Malicious-Dom.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/Accomplist%20Malicious-Dom%20Top-N%20Unbound.conf"
LISTS["malware/01-DevHunter-Accomplist-Family-Safe.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/Accomplist%20Family-Safe%20Top-N%20Unbound.conf"

# Trustpositif Alsyundawy
LISTS["malware/01-DevHunter-Alsyundawy-TrustPositif-gambling.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/Alsyundawy%20TrustPositif%20Gambling%20Indonesia.conf"

# Trustpositif AU
LISTS["malware/01-DevHunter-trustpositif-gambling-au.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/BlockList_DB/trustpositif-gambling-au.conf"

# StevenBlack
LISTS["malware/01-DevHunter-StevenBlack.conf"]="https://blocklist.sefinek.net/generated/v1/unbound/other/StevenBlack/fakenews-gambling-porn.fork.conf"

# ===============================
# WHITELIST
# ===============================
LISTS["zzz-whitelist/zzzz-devhunter-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/devhunter-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-shadowwhisperer-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/shadowwhisperer-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-referral-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-amazon-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-amazon-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-apple-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-apple-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-huawei-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-huawei-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-lg-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-lgwebos-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-oppo-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-oppo-realme-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-roku-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-roku-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-samsung-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-samsung-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-smart-tv-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-smart-tv-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-tiktok-ext-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-tiktok-extended-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-tiktok-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-tiktok-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-vivo-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-vivo-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-win-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-winoffice-whitelist.conf"
LISTS["zzz-whitelist/zzzz-devhunter-hagezi-xiaomi-whitelist.conf"]="https://raw.githubusercontent.com/devhunter-git/Unbound/refs/heads/main/WhiteList%20DB/hagezi-xiaomi-whitelist.conf"

# ===============================
# DOWNLOAD
# ===============================
for path in "${!LISTS[@]}"; do

    url="${LISTS[$path]}"
    tmp="/tmp/unbound-$$-$(basename "$path")"
    dest="$BASE_DIR/$path"

    log "[+] Download $path"

    wget -T 30 -t 2 -qO "$tmp" "$url" || curl -fsSL "$url" -o "$tmp" || {
        log "[!] Gagal download: $path"
        ERROR=1
        continue
    }

    [ -s "$tmp" ] || {
        log "[!] File kosong: $path"
        ERROR=1
        continue
    }

    mv "$tmp" "$dest"
    log "[✓] Update: $path"

    if ! unbound-checkconf "$dest" >/dev/null 2>&1; then
        log "[!] Syntax error: $dest"
        ERROR=1
    fi

done

# ===============================
# RELOAD
# ===============================
if [ "$ERROR" -eq 0 ]; then

    log "[?] Reload Unbound (always fresh)..."

    if unbound-control reload_keep_cache 2>/dev/null; then
        log "[✓] Reload berhasil (cache dipertahankan)"

    else
        log "[!] reload_keep_cache gagal, fallback..."

        if systemctl reload unbound; then
            log "[✓] Reload berhasil"
        else
            log "[!] Restart Unbound"
            systemctl restart unbound
        fi

        log "[?] Restore cache..."
        unbound-control load_cache < "$CACHE_FILE" 2>/dev/null || true
    fi

else
    log "[!] Error ditemukan, Unbound tidak direload"
fi
>>>>>>> f47e8251 (Update HaGeZi Native Roku Unbound blocklist)
