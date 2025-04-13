#!/bin/bash

# Warna
CYAN='\e[96m'
YELLOW='\e[93m'
GREEN='\e[92m'
RED='\e[91m'
RESET='\e[0m'

# Loading animasi
loading() {
  local msg=$1
  local i=0
  local sp='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  echo -ne "${CYAN}${msg}...${RESET} "
  while sleep 0.1; do
    i=$(( (i+1) %10 ))
    printf "\b${sp:$i:1}"
  done
}

# Stop loading
stop_loading() {
  kill "$1" >/dev/null 2>&1
  wait "$1" 2>/dev/null
  echo -ne "\b${GREEN}[✅ Done]${RESET}\n"
}

clear

# Banner
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════╗"
echo "║       🔥 AUTO SOCKS5 INSTALLER        ║"
echo "╠═══════════════════════════════════════╣"
echo "║       BY DMSRYN - STAY COOL 😎        ║"
echo "╚═══════════════════════════════════════╝"
echo -e "${RESET}"

# Update system
loading "[🛰️ ] Updating system"
apt update -y >/dev/null 2>&1 &
pid=$!
wait $pid; stop_loading $!

# Install packages
for pkg in dante-server net-tools curl; do
  loading "[🔧] Installing $pkg"
  apt install -y $pkg >/dev/null 2>&1 &
  pid=$!
  wait $pid; stop_loading $!
done

# Input user & pass
echo -e "\n${YELLOW}📲 Silakan masukkan detail akun SOCKS5 kamu:${RESET}"
read -p "👤 Username: " user
read -s -p "🔑 Password: " pass
echo -e "\n"

# Tambah user
useradd -m "$user" >/dev/null 2>&1
echo "$user:$pass" | chpasswd

# Deteksi IP & Interface
iface=$(ip route get 1.1.1.1 | awk '{print $5; exit}')
vpsip=$(curl -s ifconfig.me)

# Konfigurasi Dante
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

# Restart dante
systemctl restart danted

# Output hasil
echo -e "${GREEN}\n🎉 SOCKS5 Server kamu sudah aktif!${RESET}"
echo -e "${CYAN}═════════════════════════════════════════"
echo "🌐 SOCKS5: $vpsip:8443:$user:$pass"
echo -e "═════════════════════════════════════════${RESET}"
echo -e "${YELLOW}🚀 Gunakan dengan bijak, jangan buat hal aneh-aneh!${RESET}"
echo -e "${RED}❗ Awas! Dilarang untuk aktivitas ilegal!${RESET}"
