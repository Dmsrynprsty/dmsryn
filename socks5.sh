#!/bin/bash

clear
echo "Updating system..."
apt update -y >/dev/null 2>&1
apt install -y dante-server net-tools curl >/dev/null 2>&1

echo "========================================"
echo "   MASUKKAN USER DAN PASS NYA BRE!!!"
echo "========================================"

read -p "Enter username: " user
read -s -p "Enter password: " pass
echo ""
echo "========================================"

useradd -m $user >/dev/null 2>&1
echo "$user:$pass" | chpasswd

iface=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
vpsip=$(curl -s ifconfig.me)

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

systemctl restart danted

echo "   AUTO SOCKS BY DMSRYN 🔥"
echo "========================================"
echo "SOCKS : $vpsip:8443:$user:$pass"
echo "========================================"
echo "   GUNAKAN DENGAN BIJAK YA BREEE :)"
