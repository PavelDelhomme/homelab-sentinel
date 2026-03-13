#!/bin/bash
#
# Crée un fichier swap de 1 Go sur la Raspberry Pi pour éviter les segfaults
# pendant dpkg/apt (surtout adduser sur Pi 2 avec 1 Go RAM).
# À lancer sur la Pi en root : sudo bash pi_add_swap.sh
# Ou depuis le PC : ssh pavel@192.168.1.37 'sudo bash -s' < scripts/pi_add_swap.sh
#
set -e
SWAPFILE="${SWAPFILE:-/var/swapfile}"
SWAP_MB="${SWAP_MB:-1024}"

if [[ $(id -u) -ne 0 ]]; then
  echo "Lancer avec sudo."
  exit 1
fi

if [[ -f /proc/swaps ]] && grep -q "$SWAPFILE" /proc/swaps 2>/dev/null; then
  echo "Swap déjà actif sur $SWAPFILE. Rien à faire."
  swapon --show
  exit 0
fi

if [[ -f "$SWAPFILE" ]]; then
  echo "Fichier $SWAPFILE existant. Activation..."
  chmod 600 "$SWAPFILE"
  swapon "$SWAPFILE" 2>/dev/null || true
  if grep -q "$SWAPFILE" /proc/swaps 2>/dev/null; then
    echo "Swap activé."
    if ! grep -q "$SWAPFILE" /etc/fstab 2>/dev/null; then
      echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
      echo "Ajouté à /etc/fstab."
    fi
    swapon --show
    exit 0
  fi
fi

echo "Création du fichier swap $SWAPFILE (${SWAP_MB} Mo)..."
dd if=/dev/zero of="$SWAPFILE" bs=1M count="$SWAP_MB" status=progress
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
swapon "$SWAPFILE"
if ! grep -q "$SWAPFILE" /etc/fstab 2>/dev/null; then
  echo "$SWAPFILE none swap sw 0 0" >> /etc/fstab
  echo "Ajouté à /etc/fstab (persistant après reboot)."
fi
echo "Swap activé. Redémarrez la Pi puis relancez : sudo dpkg --configure -a"
swapon --show
