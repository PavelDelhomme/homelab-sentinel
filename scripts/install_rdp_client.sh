#!/bin/bash
#
# Installe un client RDP graphique (Remmina + FreeRDP) sur ton PC Arch Linux
# pour te connecter à la Raspberry Pi (ou toute machine RDP).
#
# Usage : ./install_rdp_client.sh
# Ou : sudo ./install_rdp_client.sh (pour pacman)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

# Détecter si on est sur Arch (pacman)
if ! command -v pacman &>/dev/null; then
  err "Ce script est prévu pour Arch Linux (pacman). Pour une autre distro, installe Remmina + plugin RDP manuellement."
fi

info "Installation de Remmina (client bureau à distance) + FreeRDP (support RDP)..."
sudo pacman -S --noconfirm remmina freerdp

info "Installation terminée."
echo ""
echo "  Pour te connecter à la Pi en RDP :"
echo "    1. Lance Remmina (menu applications ou : remmina)"
echo "    2. Nouvelle connexion : protocole **RDP**, serveur **192.168.1.37**, port **3389**"
echo "    3. Utilisateur : **pavel**, mot de passe : celui de la Pi"
echo "    4. Enregistrer la connexion pour la retrouver en un clic."
echo ""
echo "  Si le protocole RDP n’apparaît pas, ferme complètement Remmina (killall remmina) puis relance-le."
echo ""
