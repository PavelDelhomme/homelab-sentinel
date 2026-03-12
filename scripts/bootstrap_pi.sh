#!/bin/bash
#
# À lancer sur ton PC, à la racine du dépôt homelab-sentinel.
# Fait tout en une fois : clé SSH vers la Pi (plus de mot de passe ensuite),
# envoi et exécution du script de config Pi (IP statique, SSH, xrdp, AZERTY, sudo Docker).
# Tu n'as à intervenir qu'une seule fois : entrer le mot de passe de la Pi quand demandé.
#
# Usage : make bootstrap   ou   ./scripts/bootstrap_pi.sh [IP_PI]
# Si la Pi n'est pas encore en 192.168.1.37 : make bootstrap PI_IP=raspberrypi.local

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PI_IP="${PI_IP:-${1:-192.168.1.37}}"
PI_USER="${PI_USER:-pavel}"
PI_TARGET="$PI_USER@$PI_IP"
STATIC_IP="${STATIC_IP:-192.168.1.37}"

echo "[Bootstrap] PC → Raspberry Pi ($PI_TARGET)"
echo ""

# --- Clé SSH (pour ne plus taper le mot de passe après) ---
if [[ ! -f "$HOME/.ssh/id_ed25519" ]] && [[ ! -f "$HOME/.ssh/id_rsa" ]]; then
  echo "[INFO] Création d'une clé SSH (aucune trouvée)..."
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -q
  echo "[INFO] Clé créée : ~/.ssh/id_ed25519.pub"
fi

echo "[INFO] Copie de la clé SSH vers la Pi (tu entres le mot de passe pavel une dernière fois)..."
if ! ssh-copy-id -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "$PI_TARGET" 2>/dev/null; then
  echo "[ERR] Impossible de se connecter à $PI_TARGET. Vérifie que la Pi est allumée, sur le réseau (IP $PI_IP ou raspberrypi.local), et que SSH est activé."
  exit 1
fi
echo "[INFO] Clé SSH installée. Les prochaines commandes (make install, make update) ne demanderont plus de mot de passe."
echo ""

# --- Envoi et exécution du script de config sur la Pi ---
echo "[INFO] Envoi du script de configuration sur la Pi..."
scp -q "$SCRIPT_DIR/raspberry_setup_auto.sh" "$PI_TARGET:~/"
echo "[INFO] Exécution du script sur la Pi (IP statique $STATIC_IP, SSH, xrdp, AZERTY, Docker sans mot de passe)..."
ssh "$PI_TARGET" "chmod +x ~/raspberry_setup_auto.sh && sudo STATIC_IP=$STATIC_IP DEBIAN_FRONTEND=noninteractive NONINTERACTIVE=1 SKIP_REBOOT_PROMPT=1 ~/raspberry_setup_auto.sh"

echo ""
echo "[OK] Bootstrap terminé."
echo "     Redémarre la Pi pour appliquer l'IP statique : ssh $PI_TARGET 'sudo reboot'"
echo "     Attends 2 min puis lance : make install"
echo "     Ensuite : make update à chaque modification de code."
