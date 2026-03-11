#!/bin/bash
#
# Script de configuration automatique de la Raspberry Pi pour Homelab Sentinel.
# À lancer sur la Pi (en SSH) : sudo ./raspberry_setup_auto.sh
#
# Fait : réparation dpkg si interrompu, détection réseau, IP statique eth0,
#        SSH et xrdp au démarrage.
#
# Important : ne pas débrancher le câble réseau / partage de connexion pendant
#             l’exécution du script (surtout pendant les opérations apt/dpkg).
#
# Utilisateur existant : pavel (ou pi). Hostname actuel conservé (ex. raspberrypi).

set -e

# --- Variables modifiables (optionnel) ---
STATIC_IP="${STATIC_IP:-}"
INTERFACE="${INTERFACE:-eth0}"
INTERFACE_WLAN="${INTERFACE_WLAN:-wlan0}"
FIX_DPKG="${FIX_DPKG:-true}"
# Connexion USB : ne pas configurer l’IP statique (détecté auto si passerelle 10.x)
SKIP_STATIC_IP="${SKIP_STATIC_IP:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()   { echo -e "${RED}[ERR]${NC} $*"; exit 1; }

# --- Vérifications ---
[[ $(id -u) -eq 0 ]] || err "Lancer le script avec sudo : sudo $0"

warn "Ne débranchez pas le câble réseau / partage de connexion pendant ce script (surtout pendant apt/dpkg)."

# --- Réparation dpkg/apt si interrompu ---
if [[ "$FIX_DPKG" == "true" ]]; then
  info "Vérification de l’état dpkg/apt..."
  export DEBIAN_FRONTEND=noninteractive
  if ! dpkg --configure -a; then
    err "dpkg --configure -a a échoué. Corrigez manuellement (voir STATUS.md), puis relancez le script."
  fi
  if ! apt-get -f install -y; then
    err "apt --fix-broken install a échoué. Vérifiez la connexion réseau, corrigez puis relancez."
  fi
  info "dpkg/apt OK."
fi

# --- Mise à jour des listes (optionnel, peut être long) ---
info "Mise à jour des listes de paquets (apt update)..."
apt-get update -qq || warn "apt update a échoué (réseau ?). On continue."

# --- Vérifier qu'on est bien sur une Pi (optionnel) ---
if [[ -f /etc/os-release ]]; then
  if ! grep -qi raspbian /etc/os-release 2>/dev/null && ! grep -qi "raspberry pi os" /etc/os-release 2>/dev/null; then
    warn "Ce système ne semble pas être Raspberry Pi OS. Continuer quand même ? (o/N)"
    read -r r; [[ "${r,,}" != "o" ]] && exit 1
  fi
fi

# Vérifier que l'interface existe (sauf si on saute la config IP)
ip link show "$INTERFACE" &>/dev/null || true
INTERFACE_EXISTS=$?

# --- Détection du réseau ---
info "Détection du réseau..."

GATEWAY=$(ip route show default 2>/dev/null | awk '/default/ { print $3 }')
[[ -z "$GATEWAY" ]] && err "Aucune passerelle par défaut. Branchez le câble Ethernet (ou partage USB) et réessayez."

# Connexion USB (partage de connexion) : passerelle 10.x.x.x → ne pas configurer d’IP statique
if [[ -z "$SKIP_STATIC_IP" ]]; then
  if [[ "$GATEWAY" == 10.* ]]; then
    SKIP_STATIC_IP=1
    info "Connexion USB détectée (passerelle $GATEWAY) : pas d’IP statique, seulement SSH + xrdp."
  fi
fi

CURRENT_IP=$(ip -4 addr show scope global 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -1)

if [[ "$SKIP_STATIC_IP" == "1" ]]; then
  warn "IP statique non configurée. Branchez la Pi sur la box en Ethernet puis relancez le script pour l’IP fixe."
  STATIC_IP="$CURRENT_IP"
else
  [[ $INTERFACE_EXISTS -ne 0 ]] && err "Interface $INTERFACE introuvable. Vérifiez avec : ip link"

  # Premier nameserver ou passerelle
  DNS1=$(grep -m1 "nameserver" /etc/resolv.conf 2>/dev/null | awk '{ print $2 }')
  DNS1="${DNS1:-$GATEWAY}"
  DNS2="8.8.8.8"

  if [[ -z "$STATIC_IP" ]]; then
    PREFIX=$(echo "$GATEWAY" | cut -d. -f1-3)
    STATIC_IP="${PREFIX}.50"
    info "IP statique auto : $STATIC_IP (passerelle $GATEWAY)"
  else
    info "IP statique demandée : $STATIC_IP"
  fi

  if ! [[ "$STATIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    err "Format d'IP invalide : $STATIC_IP"
  fi

  DHCPCD_CONF="/etc/dhcpcd.conf"
  [[ ! -f "$DHCPCD_CONF" ]] && err "Fichier $DHCPCD_CONF introuvable."

  cp -a "$DHCPCD_CONF" "${DHCPCD_CONF}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
  if grep -q "interface $INTERFACE" "$DHCPCD_CONF" 2>/dev/null; then
    info "Ancienne config statique pour $INTERFACE trouvée, remplacement..."
    sed -i "/^interface $INTERFACE$/,/^$/d" "$DHCPCD_CONF"
  fi
  cat >> "$DHCPCD_CONF" << EOF

# --- Homelab Sentinel : IP statique $INTERFACE (raspberry_setup_auto.sh) ---
interface $INTERFACE
static ip_address=${STATIC_IP}/24
static routers=$GATEWAY
static domain_name_servers=$DNS1 $DNS2
EOF
  info "Config dhcpcd écrite pour $INTERFACE -> $STATIC_IP"

  # WiFi (wlan0) : même réseau box, IP .51
  if ip link show "$INTERFACE_WLAN" &>/dev/null; then
    PREFIX=$(echo "$GATEWAY" | cut -d. -f1-3)
    STATIC_IP_WLAN="${PREFIX}.51"
    if grep -q "interface $INTERFACE_WLAN" "$DHCPCD_CONF" 2>/dev/null; then
      sed -i "/^interface $INTERFACE_WLAN$/,/^$/d" "$DHCPCD_CONF"
    fi
    cat >> "$DHCPCD_CONF" << EOF

# --- Homelab Sentinel : IP statique $INTERFACE_WLAN (raspberry_setup_auto.sh) ---
interface $INTERFACE_WLAN
static ip_address=${STATIC_IP_WLAN}/24
static routers=$GATEWAY
static domain_name_servers=$DNS1 $DNS2
EOF
    info "Config dhcpcd écrite pour $INTERFACE_WLAN -> $STATIC_IP_WLAN"
  fi
fi

# Premier nameserver (pour résumé si mode USB)
DNS1=$(grep -m1 "nameserver" /etc/resolv.conf 2>/dev/null | awk '{ print $2 }')
DNS1="${DNS1:-$GATEWAY}"
DNS2="8.8.8.8"

# --- SSH : activer au démarrage ---
if systemctl is-enabled ssh &>/dev/null; then
  info "SSH déjà activé au démarrage."
else
  systemctl enable ssh && info "SSH activé au démarrage."
fi
systemctl start ssh 2>/dev/null || true
info "SSH : actif."

# --- xrdp : installation et activation au démarrage ---
if ! command -v xrdp &>/dev/null; then
  info "Installation de xrdp..."
  apt-get update -qq && apt-get install -y xrdp
fi
if systemctl is-enabled xrdp &>/dev/null; then
  info "xrdp déjà activé au démarrage."
else
  systemctl enable xrdp && info "xrdp activé au démarrage."
fi
systemctl start xrdp 2>/dev/null || true
info "xrdp : actif (port 3389)."

# --- Résumé ---
echo ""
echo -e "${GREEN}=== Configuration terminée ===${NC}"
echo ""
if [[ "$SKIP_STATIC_IP" == "1" ]]; then
  echo "  Connexion USB : IP statique non configurée."
  echo "  IP actuelle   : ${CURRENT_IP:-?}"
  echo ""
  echo "  Connectez-vous depuis votre PC :"
  echo "    SSH : ssh pavel@${CURRENT_IP:-<IP_PI>}"
  echo "    RDP : adresse ${CURRENT_IP:-<IP_PI>}, port 3389, utilisateur pavel"
  echo "    VNC : adresse ${CURRENT_IP:-<IP_PI>}, port 5900 (si VNC actif)"
  echo ""
  echo "  Ensuite : branchez la Pi sur la box en Ethernet, relancez ce script pour configurer l’IP fixe."
  echo ""
  read -p "Redémarrer maintenant (recommandé pour SSH/xrdp) ? (o/N) " r
else
  echo "  Interface   : $INTERFACE"
  echo "  IP statique : $STATIC_IP"
  echo "  Passerelle  : $GATEWAY"
  echo ""
  echo "  SSH et xrdp sont activés au démarrage."
  echo ""
  echo -e "${YELLOW}Redémarrage nécessaire pour appliquer l'IP statique.${NC}"
  echo ""
  echo "  Après redémarrage (attendre 1–2 min), connectez-vous :"
  echo "    SSH : ssh pavel@$STATIC_IP"
  echo "    RDP : adresse $STATIC_IP, port 3389, utilisateur pavel"
  echo ""
  read -p "Redémarrer maintenant ? (o/N) " r
fi
if [[ "${r,,}" == "o" ]]; then
  reboot
else
  echo "Pensez à redémarrer : sudo reboot"
fi
