#!/bin/bash

# Function: Tampilkan animasi loading saat proses berjalan
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

# Function: Tunggu jika apt sedang dikunci proses lain
wait_for_apt() {
    while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || \
          fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || \
          fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        echo "[⏳] Menunggu proses apt yang lain selesai..."
        sleep 5
    done
}

# Function: Install ulang jika gagal
retry_install() {
    local package=$1
    local max_retries=5
    local count=1

    echo "[🔄] Menginstall paket: $package..."

    until apt install -y "$package" >/dev/null 2>&1; do
        echo "[❌] Gagal install $package (Percobaan $count/$max_retries). Coba lagi bentar..."
        wait_for_apt
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
echo -e "\e[96m╔══════════════════════════════════════════╗"
echo -e "║       🔥 AUTO SOCKS5 INSTALLER 🔥           ║"
echo -e "╠══════════════════════════════════════════╣"
echo -e "║            CREATED BY DMSRYN                ║"
echo -e "╚══════════════════════════════════════════╝\e[0m"

# Step: Update repo + animasi
wait_for_apt
apt update -y >/dev/null 2>&1 &
show_loading $!

# Step: Install dependencies
retry_install dante-server
retry_install curl
retry_install net-tools

# Prompt input
echo -e "\n\e[93m📲 Silakan masukkan detail akun SOCKS5 kamu:\e[0m"
read -p "👤 Username: " user
read -s -p "🔑 Password: " pass
echo -e "\n"

# Buat config danted (port 8443)
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

# Tambahkan user SOCKS
useradd -m "$user"
echo "$user:$pass" | chpasswd

# Restart danted
systemctl restart danted

# Ambil IP VPS
IP=$(curl -s ifconfig.me)

# Output info
echo -e "\n\e[92m🎉 SOCKS5 SERVER BERHASIL DIBUAT!\e[0m"
echo "$IP:8443:$user:$pass"
echo -e "\n\e[91m🚫 Gunakan dengan bijak! Jangan untuk spam, ilegal, atau hal aneh-aneh ya bre...\e[0m"
echo -e "\e[90m# Created by DMSRYN - 2025\e[0m"
