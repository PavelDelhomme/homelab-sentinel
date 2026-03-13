# Homelab Sentinel — déploiement depuis le PC vers la Raspberry Pi
# Backend sur la Pi : Docker uniquement. make install (première fois), make update ou make push (mise à jour).

PI_IP    ?= 192.168.1.37
PI_USER  ?= pavel
PI_TARGET = $(PI_USER)@$(PI_IP)
PI_DIR   = homelab-sentinel

# Exclusions pour rsync (ne pas envoyer .git, caches, venv, etc.)
RSYNC_EXCLUDE = --exclude '.git' --exclude '__pycache__' --exclude '*.pyc' --exclude 'node_modules' --exclude '.env' --exclude 'venv' --exclude '.venv' --exclude 'pgdata'

.PHONY: install update push sync shell status remmina-profile bootstrap test-backend-local stop-backend-local openwrt-info help

help:
	@echo "Homelab Sentinel — déploiement PC → Raspberry Pi (Docker sur la Pi)"
	@echo ""
	@echo "  make bootstrap      Une seule fois : clé SSH + config Pi (mot de passe une fois)"
	@echo "  make install       Première fois : sync + Docker + backend sur la Pi (+ profil Remmina)"
	@echo "  make update        Met à jour le projet sur la Pi et redémarre le backend (Docker)"
	@echo "  make push          Identique à make update (sync + redémarrage backend)"
	@echo "  make sync          Synchronise les fichiers sans redémarrer le backend"
	@echo "  make shell         Session SSH sur la Pi (ou : ssh pi-homelab si config SSH)"
	@echo "  make status        État des conteneurs Docker sur la Pi"
	@echo "  make remmina-profile Profil Remmina sur ce PC"
	@echo "  make test-backend-local Backend en Docker sur cette machine (test)"
	@echo "  make openwrt-info  Infos OpenWrt (sans Pi ni dongle)"
	@echo ""
	@echo "Variables : PI_IP=$(PI_IP)  PI_USER=$(PI_USER)"
	@echo "Override  : make push PI_IP=192.168.1.50  |  make bootstrap PI_IP=raspberrypi.local"

# --- Bootstrap : une seule fois — clé SSH + config Pi (mot de passe demandé une fois) ---
bootstrap:
	@cd "$(CURDIR)" && PI_IP="$(PI_IP)" PI_USER="$(PI_USER)" STATIC_IP="192.168.1.37" ./scripts/bootstrap_pi.sh

# --- Sync : envoi des fichiers du dépôt vers la Pi ---
sync:
	rsync -avz --delete $(RSYNC_EXCLUDE) ./ $(PI_TARGET):$(PI_DIR)/

# --- Install : première fois — profil Remmina sur ce PC + sync + Docker sur la Pi + démarrage backend ---
install: remmina-profile sync
	ssh $(PI_TARGET) 'REPO_DIR=$(PI_DIR) bash -s' < scripts/pi_install_stack.sh

# --- Update : sync + redémarrage du backend sur la Pi (Docker) ---
# Nécessite d'avoir fait "make install" au moins une fois (Docker installé sur la Pi).
update: sync
	@ssh $(PI_TARGET) 'command -v docker >/dev/null 2>&1 || { echo ""; echo "*** Docker n'\''est pas installé sur la Pi. Lance d'\''abord : make install ***"; echo ""; exit 1; }'
	ssh $(PI_TARGET) 'cd ~/'"$(PI_DIR)"'/backend && sudo docker compose up -d --build'

# --- Push : identique à update (raccourci pour « pousser les mises à jour ») ---
push: update

# --- Session SSH sur la Pi ---
shell:
	ssh $(PI_TARGET)

# --- Statut : conteneurs Docker sur la Pi ---
status:
	@ssh $(PI_TARGET) 'cd ~/'"$(PI_DIR)"'/backend 2>/dev/null && sudo docker compose ps || echo "Backend pas encore déployé (make install)"'

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
