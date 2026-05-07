<<<<<<< HEAD
#!/bin/bash
set -euo pipefail

CONF_FILE="/etc/sysctl.d/99-unbound-highqps.conf"

echo "Membuat kernel tuning untuk Unbound resolver..."

cat <<'EOF' | sudo tee "$CONF_FILE" > /dev/null
# ==========================================
# High Performance DNS Resolver Kernel Tuning
# Optimized for Unbound
# ==========================================

# ---- File descriptors ----
fs.file-max = 4194304

# ---- Network core tuning ----
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 50000
net.core.netdev_budget = 600

# Socket buffers
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576

# ---- UDP tuning (DNS heavy workload) ----
net.ipv4.udp_mem = 262144 524288 1048576
net.ipv4.udp_rmem_min = 65536
net.ipv4.udp_wmem_min = 65536

net.ipv6.udp_mem = 262144 524288 1048576
net.ipv6.udp_rmem_min = 65536
net.ipv6.udp_wmem_min = 65536

# ---- TCP fallback tuning ----
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_synack_retries = 2

net.ipv4.tcp_rmem = 65536 262144 33554432
net.ipv4.tcp_wmem = 65536 262144 33554432

net.ipv6.tcp_rmem = 65536 262144 33554432
net.ipv6.tcp_wmem = 65536 262144 33554432

# ---- Port range for high outgoing queries ----
net.ipv4.ip_local_port_range = 10240 65535

# ---- Faster socket reuse ----
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fastopen = 3

# ---- SYN flood protection ----
net.ipv4.tcp_max_syn_backlog = 8192

# ---- ICMP rate limit disabled ----
net.ipv4.icmp_ratelimit = 0
net.ipv6.icmp.ratelimit = 0
EOF

echo "Reload sysctl parameters..."
sudo sysctl --system

=======
#!/bin/bash
set -euo pipefail

CONF_FILE="/etc/sysctl.d/99-unbound-highqps.conf"

echo "Membuat kernel tuning untuk Unbound resolver..."

cat <<'EOF' | sudo tee "$CONF_FILE" > /dev/null
# ==========================================
# High Performance DNS Resolver Kernel Tuning
# Optimized for Unbound
# ==========================================

# ---- File descriptors ----
fs.file-max = 4194304

# ---- Network core tuning ----
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 50000
net.core.netdev_budget = 600

# Socket buffers
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 1048576
net.core.wmem_default = 1048576

# ---- UDP tuning (DNS heavy workload) ----
net.ipv4.udp_mem = 262144 524288 1048576
net.ipv4.udp_rmem_min = 65536
net.ipv4.udp_wmem_min = 65536

net.ipv6.udp_mem = 262144 524288 1048576
net.ipv6.udp_rmem_min = 65536
net.ipv6.udp_wmem_min = 65536

# ---- TCP fallback tuning ----
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_synack_retries = 2

net.ipv4.tcp_rmem = 65536 262144 33554432
net.ipv4.tcp_wmem = 65536 262144 33554432

net.ipv6.tcp_rmem = 65536 262144 33554432
net.ipv6.tcp_wmem = 65536 262144 33554432

# ---- Port range for high outgoing queries ----
net.ipv4.ip_local_port_range = 10240 65535

# ---- Faster socket reuse ----
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fastopen = 3

# ---- SYN flood protection ----
net.ipv4.tcp_max_syn_backlog = 8192

# ---- ICMP rate limit disabled ----
net.ipv4.icmp_ratelimit = 0
net.ipv6.icmp.ratelimit = 0
EOF

echo "Reload sysctl parameters..."
sudo sysctl --system

>>>>>>> e336524c (Add files via upload)
echo "Kernel tuning selesai untuk Unbound resolver ✅"