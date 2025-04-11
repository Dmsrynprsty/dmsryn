#!/bin/bash

# Function: Retry apt install sampai berhasil
retry_install() {
    local package=$1
    local max_retries=5
    local count=1

    echo "[🔄] Menginstall paket: $package..."

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

# Banner
clear
echo -e "\e[96m╔═══════════════════════════════════════╗"
echo -e "║       🔥 AUTO SOCKS5 INSTALLER 🔥      ║"
echo -e "╠═══════════════════════════════════════╣"
echo -e "║          CREATED BY DMSRYN           ║"
echo -e "╚═══════════════════════════════════════╝\e[0m"

# Loading animation function
show_loading() {
    local pid=$1
    local delay=0.15
    local spinstr='|/-\'
    echo -n "[🛰️ ] Update repository... "
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    echo " [✅ Done]"
}

# Jalankan apt update dengan animasi loading
apt update -y >/dev/null 2>&1 &
show_loading $!

# Install dependencies
retry_install dante-server
retry_install curl
retry_install net-tools

# Prompt user
echo -e "\n\e[93m📲 Silakan masukkan detail akun SOCKS5 kamu:\e[0m"
read -p "👤 Username: " user
read -s -p "🔑 Password: " pass
echo -e "\n"

# Buat file konfigurasi danted (PORT = 8443)
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

# Restart service
systemctl restart danted

# Output info
IP=$(curl -s ifconfig.me)
echo -e "\n\e[92m🎉 SOCKS5 SERVER BERHASIL DIBUAT!\e[0m"
echo -e "\e[96m📦 Detail:\e[0m"
echo "$IP:8443:$user:$pass"
echo -e "\n\e[91m🚫 Gunakan dengan bijak! Jangan lakukan hal ilegal, spam, atau iseng berbahaya.\e[0m"
echo -e "\e[90m# CREATED BY DMSRYN - 2025\e[0m"
