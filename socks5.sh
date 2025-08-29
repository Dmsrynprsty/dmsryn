#!/bin/bash

clear
echo "Updating system..."
apt update -y >/dev/null 2>&1
apt install -y dante-server net-tools curl >/dev/null 2>&1

echo "========================================"
echo "   MASUKKAN USER DAN PASS NYA BRE!!!"
echo "========================================"

exec < /dev/tty
read -p "Enter username: " user
read -s -p "Enter password: " pass
echo ""
echo "========================================"

useradd -M -s /usr/sbin/nologin $user >/dev/null 2>&1
echo "$user:$pass" | chpasswd

# Tambahkan user ke DenyUsers jika belum ada
if ! grep -q "^DenyUsers" /etc/ssh/sshd_config; then
    echo "DenyUsers $user" >> /etc/ssh/sshd_config
else
    sed -i "/^DenyUsers/ s/$/ $user/" /etc/ssh/sshd_config
fi
systemctl restart ssh

iface=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
vpsip=$(curl -s ifconfig.me)

cat > /etc/danted.conf <<EOF
logoutput: syslog
internal: 0.0.0.0 port = 44445
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
echo "SOCKS : $vpsip:44445:$user:$pass"
echo "========================================"
echo "   GUNAKAN DENGAN BIJAK YA BREEE :)"
