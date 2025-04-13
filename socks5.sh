#!/bin/bash

clear

echo "[+] MULAI INSTALL ULANG SETIAP JALAN! 🔁"
echo "[+] Proses install dante-server, net-tools, curl, dll..."

apt update -y >/dev/null 2>&1
apt install -y dante-server net-tools curl dialog tzdata locales procps >/dev/null 2>&1

# === INPUT USER & PASS ===
echo "========================================"
echo "   MASUKKAN USER DAN PASS NYA BRE!!!"
echo "========================================"

exec < /dev/tty
read -p "Enter username: " user
read -s -p "Enter password: " pass
echo ""
echo "========================================"

# === USER SETUP ===
useradd -m "$user" >/dev/null 2>&1
echo "$user:$pass" | chpasswd

# === NETWORK SETUP ===
iface=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
vpsip=$(curl -s ifconfig.me)

# === CONFIG DANTED ===
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

# === BUAT SERVICE sockd JIKA BELUM ADA ===
if [ ! -f /etc/systemd/system/sockd.service ]; then
    echo "[+] Membuat service sockd secara manual..."
    cat > /etc/systemd/system/sockd.service <<EOF
[Unit]
Description=Dante SOCKS5 Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/sockd -f /etc/danted.conf
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable sockd
fi

# === JALANKAN SERVICE ===
systemctl restart sockd

# === OUTPUT ===
echo "   AUTO SOCKS5 BY DMSRYN 🔥"
echo "========================================"
echo "SOCKS : $vpsip:8443:$user:$pass"
echo "========================================"
echo "   GUNAKAN DENGAN BIJAK YA BREEE :)"
