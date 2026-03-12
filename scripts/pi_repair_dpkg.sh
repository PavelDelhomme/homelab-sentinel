#!/bin/bash
#
# Réparation dpkg/apt après upgrade cassé sur la Raspberry Pi.
# À lancer sur la Pi : sudo ./pi_repair_dpkg.sh
# Ou depuis le PC : ssh pavel@192.168.1.37 'sudo bash -s' < scripts/pi_repair_dpkg.sh
#
# Ne pas couper le réseau pendant l’exécution.

set -e
export DEBIAN_FRONTEND=noninteractive

echo "[1/3] dpkg --configure -a..."
if ! dpkg --configure -a; then
  echo "[2/3] Réparation par paquet (udev, dbus, systemd, ...)..."
  for pkg in udev dbus dbus-x11 dbus-user-session libpam-systemd:armhf systemd systemd-timesyncd adduser ifupdown xserver-xorg-core bluez; do
    if dpkg -s "$pkg" &>/dev/null; then
      dpkg --configure "$pkg" 2>/dev/null || true
    fi
  done
  echo "Relance dpkg --configure -a..."
  dpkg --configure -a || true
fi

echo "[3/3] apt -f install..."
apt-get -f install -y

echo "Vérification..."
dpkg --audit 2>/dev/null || true
echo "Terminé. Si des erreurs restent, voir docs/pi_repair_dpkg.md"
echo "Tu peux relancer : sudo apt update && sudo apt upgrade -y"
