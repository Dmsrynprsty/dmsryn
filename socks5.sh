#!/bin/bash

clear

# === [AUTO RERUN HANDLER] ===
if [ ! -f /tmp/socks_installed.flag ]; then
    echo "[+] Instalasi awal dependensi... sabar bre 🛠️"
    apt update -y >/dev/null 2>&1
    apt install -y dante-server net-tools curl dialog tzdata locales procps >/dev/null 2>&1

    # Tandai instalasi sudah dilakukan
    touch /tmp/socks_installed.flag

    echo "[+] Instalasi selesai. Script akan dijalankan ulang untuk melanjutkan 🔁"
    sleep 1
    exec bash "$0" # Re-run script
    exit
fi

# === [INPUT USER & PASS] ===
echo "========================================"
echo "   MASUKKAN USER DAN PASS NYA BRE!!!"
echo "========================================"

exec < /dev/tty
read -p "Enter username: " user
read -s -p "Enter password: " pass
echo ""
echo "========================================"

# === [USER SETUP] ===
useradd -m "$user" >/dev/null 2>&1
echo "$user:$pass" | chpasswd

# === [NETWORK SETUP] ===
iface=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
vpsip=$(curl -s ifconfig.me)

# === [DANTED CONFIG] ===
cat > /etc/danted.conf <<EOF
logoutput: syslog
internal: $iface port = 8443
external: $iface
method: username
user.privileged: root
user.unprivileged: nobody
user.libwrap: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}
EOF

# === [START DANTED] ===
systemctl restart danted

# === [OUTPUT INFO] ===
echo "   AUTO SOCKS5 BY DMSRYN 🔥"
echo "========================================"
echo "SOCKS : $vpsip:8443:$user:$pass"
echo "========================================"
echo "   GUNAKAN DENGAN BIJAK YA BREEE :)"
