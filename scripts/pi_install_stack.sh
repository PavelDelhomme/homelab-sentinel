#!/bin/bash
#
# À lancer sur la Raspberry Pi (via make install depuis le PC).
# Installe Docker + Docker Compose si besoin, puis démarre le backend (API + DB + MQTT).
# Usage : depuis le PC, dans le dépôt : make install (sync + ssh 'bash -s' < ce script)

set -e
REPO_ROOT="$HOME/${REPO_DIR:-homelab-sentinel}"
cd "$REPO_ROOT" || { echo "[ERR] Répertoire $REPO_ROOT introuvable. Lancer make install depuis le PC."; exit 1; }

# --- Docker ---
if ! command -v docker &>/dev/null; then
  echo "[INFO] Installation de Docker..."
  curl -fsSL https://get.docker.com | sh
  sudo usermod -aG docker "$USER" 2>/dev/null || true
  echo "[INFO] Docker installé. Une déconnexion/reconnexion SSH peut être nécessaire pour le groupe docker."
fi

# --- Docker Compose (plugin) ---
if ! docker compose version &>/dev/null; then
  echo "[INFO] Installation du plugin Docker Compose..."
  sudo apt-get update -qq
  sudo apt-get install -y docker-compose-plugin 2>/dev/null || {
    # Fallback : standalone compose v2
    sudo mkdir -p /usr/local/lib/docker/cli-plugins
    sudo curl -sSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
    sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
  }
fi

# --- Démarrer le backend (depuis le répertoire du dépôt sur la Pi) ---
BACKEND_DIR="$REPO_ROOT/backend"
if [[ ! -f "$BACKEND_DIR/docker-compose.yml" ]]; then
  echo "[ERR] $BACKEND_DIR/docker-compose.yml introuvable. Lance make install depuis le PC (dans le dépôt homelab-sentinel)."
  exit 1
fi

echo "[INFO] Démarrage du backend (API, PostgreSQL, Mosquitto)..."
cd "$BACKEND_DIR"
sudo docker compose up -d --build

echo "[INFO] Backend démarré. API : http://$(hostname -I | awk '{print $1}'):5500"
