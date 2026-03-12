#!/bin/bash
# Copie le profil Remmina « Pi Homelab » vers ton dossier utilisateur.
# Après exécution, ouvre Remmina : la connexion apparaît (double-clic pour se connecter).
# Tu entres le mot de passe pavel à la première connexion.

set -e
REMMINA_DIR="${HOME}/.local/share/remmina"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE="Pi-Homelab-192.168.1.37.remmina"
SOURCE_PROFILE="$SCRIPT_DIR/remmina/$PROFILE"
mkdir -p "$REMMINA_DIR"
cp "$SOURCE_PROFILE" "$REMMINA_DIR/"
echo "Profil copié : $REMMINA_DIR/$PROFILE"
echo "Ouvre Remmina : la connexion « Pi Homelab (192.168.1.37) » est prête (mot de passe pavel à la demande)."
