#!/bin/bash
#
# Installation native (sans Docker) sur la Raspberry Pi — beaucoup plus léger.
# À lancer via : make install-native (depuis le PC, après sync).
# Installe : PostgreSQL, Mosquitto, Python venv, dépendances backend, service systemd.
# Utilise ~/homelab-sentinel sur la Pi.

set -e
REPO_ROOT="$HOME/${REPO_DIR:-homelab-sentinel}"
BACKEND_DIR="$REPO_ROOT/backend"

cd "$REPO_ROOT" || { echo "[ERR] $REPO_ROOT introuvable. Lancer make sync depuis le PC."; exit 1; }
[[ -f "$BACKEND_DIR/requirements.txt" ]] || { echo "[ERR] $BACKEND_DIR/requirements.txt introuvable."; exit 1; }

echo "[INFO] Installation native (sans Docker) — léger pour la Pi..."

# --- PostgreSQL ---
if ! command -v psql &>/dev/null; then
  echo "[INFO] Installation de PostgreSQL..."
  sudo apt-get update -qq
  sudo apt-get install -y postgresql postgresql-contrib
fi
sudo systemctl enable postgresql --now 2>/dev/null || true

# --- Créer l'utilisateur et la base si besoin ---
if ! sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='homelab'" | grep -q 1; then
  echo "[INFO] Création de l'utilisateur et de la base homelab..."
  sudo -u postgres psql -c "CREATE USER homelab WITH PASSWORD 'secret';" 2>/dev/null || true
  sudo -u postgres psql -c "CREATE DATABASE homelab OWNER homelab;" 2>/dev/null || true
fi

# --- Mosquitto ---
if ! command -v mosquitto &>/dev/null; then
  echo "[INFO] Installation de Mosquitto..."
  sudo apt-get install -y mosquitto mosquitto-clients
fi
# Config minimale si pas déjà présente
if [[ -f "$BACKEND_DIR/mosquitto/config/mosquitto.conf" ]]; then
  sudo cp "$BACKEND_DIR/mosquitto/config/mosquitto.conf" /etc/mosquitto/conf.d/homelab.conf 2>/dev/null || true
fi
sudo systemctl enable mosquitto --now 2>/dev/null || true

# --- Python venv et dépendances ---
if [[ ! -f "$BACKEND_DIR/.venv/bin/uvicorn" ]]; then
  echo "[INFO] Création du venv et installation des dépendances Python..."
  python3 -m venv "$BACKEND_DIR/.venv"
  "$BACKEND_DIR/.venv/bin/pip" install --upgrade pip -q
  "$BACKEND_DIR/.venv/bin/pip" install -r "$BACKEND_DIR/requirements.txt" -q
fi

# --- Service systemd ---
SVC_NAME="homelab-api.service"
SVC_SRC="$BACKEND_DIR/homelab-api.service"
if [[ -f "$SVC_SRC" ]]; then
  # Adapter le chemin si REPO_ROOT n'est pas /home/pavel/homelab-sentinel
  sed "s|/home/pavel/homelab-sentinel|$REPO_ROOT|g" "$SVC_SRC" | sudo tee /etc/systemd/system/$SVC_NAME >/dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable $SVC_NAME --now
  echo "[INFO] Service $SVC_NAME activé et démarré."
else
  echo "[WARN] $SVC_SRC introuvable. Démarrage manuel : cd $BACKEND_DIR && .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 5500"
fi

echo "[OK] Installation native terminée. API : http://$(hostname -I | awk '{print $1}'):5500"
