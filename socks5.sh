#!/bin/bash

# Function: Retry apt install sampai berhasil
retry_install() {
    local package=$1
    local max_retries=5
    local count=1

    echo -e "\n[🔄] Menginstall paket: $package..."
    until apt install -y "$package" >/dev/null 2>&1; do
        echo "[❌] Gagal install $package (Percobaan $count/$max_retries). Coba lagi bentar..."
        sleep 5
        ((count++))
        if [ $count -gt $max_retries ]; then
            echo "[🚫] Gagal install $package setelah $max_retries percobaan. Exit deh..."
            exit 1
        fi
    done
    echo "[✅] $package berhasil diinstall!"
}

# Banner awal
clear
echo -e "\e[96m╔═══════════════════════════════════════╗"
echo -e "║       🔥 AUTO SOCKS5 INSTALLER 🔥       ║"
echo -e "╠═══════════════════════════════════════╣"
echo -e "║          CREATED BY DMSRYNPRSTY        ║"
echo -e "╚═══════════════════════════════════════╝\e[0m"
sleep 1

# Update repo (dengan animasi loading)
echo -n "[🛰️ ] Update repository..."
apt update -y >/dev/null 2>&1
echo -e "  [✅ Done]"

# Install dependencies
retry_install dante-server
retry_install curl
retry_install net-tools

# Input user/pass
echo -e "\n\e[93m📲 Silakan masukkan detail akun SOCKS5 kamu:\e[0m"
read -p "👤 Username: " user
read -s -p "🔑 Password: " pass
echo -e "\n"

# Buat file konfigurasi
cat > /etc/danted.conf <<EOF
logoutput: syslog
internal: ens3 port = 8443
external: ens3
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

# Tambah user
useradd -m "$user"
echo "$user:$pass" | chpasswd

# Restart danted
systemctl restart danted

# Output
IP=$(curl -s ifconfig.me)
echo -e "\n\e[92m🎉 SOCKS5 SERVER SIAP DIGUNAKAN!\e[0m"
echo "═════════════════════════════════════════"
echo "➡️  $IP:8443:$user:$pass"
echo "═════════════════════════════════════════"
echo -e "\e[96m🚀 Gunakan dengan bijak ya, jangan buat hal aneh-aneh...\e[0m"
