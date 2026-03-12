#!/bin/bash
# Affiche les infos OpenWrt et vérifie la présence des configs.
# Usage : make openwrt-info  ou  ./scripts/openwrt_info.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OPENWRT_DIR="$REPO_ROOT/openwrt"

echo "=== OpenWrt (phase 2) — Pi en routeur ==="
echo ""
echo "Raspberry Pi 2 : pas de WiFi intégré, un seul Ethernet (eth0)."
echo "Pour faire WAN + LAN il faut un dongle : USB-Ethernet (recommandé) ou USB-WiFi."
echo ""

if [[ -d "$OPENWRT_DIR" ]]; then
  echo "Configs dans le dépôt :"
  for f in "$OPENWRT_DIR"/*.example.conf "$OPENWRT_DIR"/*.conf; do
    [[ -f "$f" ]] || continue
    echo "  - $(basename "$f")"
  done
  [[ -f "$OPENWRT_DIR/network.example.conf" ]] && echo "  -> network.example.conf : eth0=LAN (192.168.10.1), eth1=WAN (DHCP)"
  [[ -f "$OPENWRT_DIR/nftables.example.conf" ]] && echo "  -> nftables.example.conf : base firewall"
  echo ""
  echo "Quand tu auras le dongle USB-Ethernet :"
  echo "  1. Flasher OpenWrt sur la Pi (arm 32-bit pour Pi 2)"
  echo "  2. opkg install kmod-usb-net-rtl8152  (ou asix pour AX88179), reboot"
  echo "  3. Copier openwrt/network.example.conf -> /etc/config/network sur la Pi"
  echo "  4. /etc/init.d/network restart"
  echo ""
  echo "Doc complète : docs/openwrt_phase2.md"
else
  echo "Dossier openwrt/ introuvable."
  exit 1
fi
