# Homelab Sentinel — déploiement depuis le PC vers la Raspberry Pi
# Tout se lance depuis ta machine : make install (première fois), make update (mise à jour + redémarrage).

PI_IP    ?= 192.168.1.37
PI_USER  ?= pavel
PI_TARGET = $(PI_USER)@$(PI_IP)
PI_DIR   = homelab-sentinel

# Exclusions pour rsync (ne pas envoyer .git, caches, venv, etc.)
RSYNC_EXCLUDE = --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' --exclude 'node_modules' --exclude '.env' --exclude 'venv' --exclude '.venv' --exclude 'pgdata'

.PHONY: install install-native update update-native sync shell status remmina-profile bootstrap test-backend-local stop-backend-local openwrt-info help

help:
	@echo "Homelab Sentinel — déploiement PC → Raspberry Pi"
	@echo ""
	@echo "  make bootstrap      Une seule fois : clé SSH + config Pi (tu entres le mot de passe une fois)"
	@echo "  make install        Initialise le projet sur la Pi : sync + Docker + backend (+ profil Remmina sur ce PC)"
	@echo "  make update         Met à jour le projet sur la Pi et redémarre le backend (sans interaction)"
	@echo "  make sync           Synchronise uniquement les fichiers (sans redémarrer les services)"
	@echo "  make shell          Ouvre une session SSH sur la Pi"
	@echo "  make status         Affiche le statut des conteneurs sur la Pi"
	@echo "  make remmina-profile Installe le profil Remmina (192.168.1.37, 1920x1080) sur ce PC"
	@echo "  make test-backend-local Lance le backend en Docker sur cette machine (test)"
	@echo "  make openwrt-info   Affiche les infos OpenWrt et les étapes (sans Pi ni dongle)"
	@echo ""
	@echo "Variables : PI_IP=$(PI_IP)  PI_USER=$(PI_USER)"
	@echo "Override  : make update PI_IP=192.168.1.50  |  make bootstrap PI_IP=raspberrypi.local"

# --- Bootstrap : une seule fois — clé SSH + config Pi (mot de passe demandé une fois) ---
bootstrap:
	@cd "$(CURDIR)" && PI_IP="$(PI_IP)" PI_USER="$(PI_USER)" STATIC_IP="192.168.1.37" ./scripts/bootstrap_pi.sh

# --- Sync : envoi des fichiers du dépôt vers la Pi ---
sync:
	rsync -avz --delete $(RSYNC_EXCLUDE) ./ $(PI_TARGET):$(PI_DIR)/

# --- Install : première fois — profil Remmina sur ce PC + sync + Docker sur la Pi + démarrage backend ---
install: remmina-profile sync
	ssh $(PI_TARGET) 'REPO_DIR=$(PI_DIR) bash -s' < scripts/pi_install_stack.sh

# --- Install native (sans Docker) : plus léger pour la Pi 2 ---
install-native: remmina-profile sync
	ssh $(PI_TARGET) 'REPO_DIR=$(PI_DIR) bash -s' < scripts/pi_install_native.sh

# --- Update : sync + redémarrage du backend sur la Pi (Docker) ---
update: sync
	ssh $(PI_TARGET) 'cd ~/'"$(PI_DIR)"'/backend && sudo docker compose up -d --build'

# --- Update native : sync + redémarrage du service systemd ---
update-native: sync
	ssh $(PI_TARGET) 'sudo systemctl restart homelab-api.service'

# --- Session SSH sur la Pi ---
shell:
	ssh $(PI_TARGET)

# --- Statut : Docker ou service systemd ---
status:
	@ssh $(PI_TARGET) 'cd ~/'"$(PI_DIR)"'/backend 2>/dev/null && (sudo docker compose ps 2>/dev/null || sudo systemctl status homelab-api.service --no-pager 2>/dev/null) || echo "Backend pas encore déployé (make install ou make install-native)"'

# --- Profil Remmina sur ce PC (résolution 1920x1080, presse-papiers activé) ---
remmina-profile:
	./scripts/install_remmina_profile.sh

# --- Test backend en local (cette machine, Docker) ---
test-backend-local:
	cd backend && docker compose up -d --build
	@echo "API : http://localhost:5500  —  make stop-backend-local pour arrêter"

# --- Arrêter le backend local ---
stop-backend-local:
	cd backend && docker compose down

# --- Infos OpenWrt (configs, étapes ; exécutable sans Pi ni dongle) ---
openwrt-info:
	bash ./scripts/openwrt_info.sh
