# Tout faire depuis ton PC fixe — déploiement Homelab Sentinel sur la Raspberry Pi

Tu codes sur ton PC, tu déploies et tu mets à jour la Pi **sans quitter ta machine**. Tout est prévu pour que **tu n’aies rien à faire à la main** après une seule étape optionnelle (bootstrap).

---

## Ce que tu es obligé de faire (une seule fois, si la Pi n’est pas encore configurée)

1. **Brancher la Pi** en Ethernet sur la box et l’allumer.
2. Depuis le PC, à la racine du dépôt : **`make bootstrap`**. Tu entres **une seule fois** le mot de passe de l’utilisateur **pavel** quand il est demandé. Le script configure la Pi (IP statique 192.168.1.37, SSH, xrdp, AZERTY, Docker sans mot de passe).
3. Redémarrer la Pi : **`ssh pavel@192.168.1.37 'sudo reboot'`** (ou via VNC). Attendre 1–2 min.
4. **`make install`** : envoie le projet, démarre le backend en **Docker** sur la Pi, et installe le profil Remmina sur ton PC. **Aucune interaction.**

Si la Pi n’est pas encore en 192.168.1.37 (première connexion en DHCP) : **`make bootstrap PI_IP=raspberrypi.local`**, puis après redémarrage **`make install`**. Ensuite **`make update`** ou **`make push`** à chaque déploiement — tout se fait sans que tu touches à rien.

---

## Prérequis

- **Sur le PC** : `rsync`, `ssh`, `make`, `ssh-copy-id`. Le dépôt **homelab-sentinel** est cloné sur ton PC.
- **Sur la Pi** : après **`make bootstrap`** (et redémarrage), IP 192.168.1.37, utilisateur pavel, SSH actif, clé SSH en place.

---

## Commandes depuis le PC (à la racine du dépôt)

| Commande | Rôle |
|----------|------|
| **`make bootstrap`** | **Une seule fois** : copie ta clé SSH sur la Pi (tu entres le mot de passe pavel une fois) et lance le script de config Pi (IP statique, SSH, xrdp, AZERTY, Docker sans mot de passe). Ensuite plus besoin de mot de passe pour `make install` / `make update`. |
| **`make install`** | Première fois après bootstrap : Docker sur la Pi + backend + profil Remmina sur le PC. |
| **`make update`** | Met à jour les fichiers sur la Pi et redémarre le backend (Docker). Aucune interaction. |
| **`make push`** | Identique à `make update` (sync + redémarrage backend) — raccourci pour déployer. |
| **`make sync`** | Synchronise uniquement les fichiers (sans redémarrer le backend). |
| **`make shell`** | Ouvre une session SSH sur la Pi (ou utilise **`ssh pi-homelab`** si tu as configuré `~/.ssh/config`). |
| **`make status`** | Affiche l’état des conteneurs Docker sur la Pi. |
| **`make remmina-profile`** | Installe le profil Remmina (connexion 192.168.1.37, 1920×1080) sur ce PC. |

Tu peux surcharger l’IP ou l’utilisateur :  
`make push PI_IP=192.168.1.50` ou `make install PI_USER=pi`.

---

## Ce qui est déployé

- **Racine du dépôt** → répertoire **`~/homelab-sentinel`** sur la Pi (scripts, docs, openwrt, firmware, backend).
- **Backend** : au premier `make install`, Docker et Docker Compose sont installés sur la Pi si besoin, puis `backend/docker-compose.yml` est lancé (API sur le port 5500, PostgreSQL, Mosquitto).
- **OpenWrt** : les configs dans `openwrt/` sont copiées sur la Pi ; tu les utilises plus tard quand tu passeras la Pi en routeur (avec dongle USB-Ethernet).
- **Firmware** : les dossiers `firmware/` (prises ESP32, gamelle RFID, etc.) sont synchronisés ; le flash des ESP32/Arduino se fait à part (PC → câble USB ou OTA depuis l’API plus tard).

---

## Ordre conseillé

1. **Une seule fois** (si la Pi n’est pas encore configurée) : **`make bootstrap`** (tu entres le mot de passe pavel quand demandé). Puis redémarrer la Pi et lancer **`make install`**. C’est tout.
2. **Au quotidien** : tu modifies le code sur ton PC, puis **`make push`** ou **`make update`** — aucun mot de passe, aucune action sur la Pi. Tu peux vérifier en VNC/Remmina ou avec **`make status`**. Alias possible : **`homelab-push`** (voir [docs/cursor_remote_ssh_pi.md](docs/cursor_remote_ssh_pi.md)).

---

## Remmina (RDP) : résolution et presse-papiers

- Le profil fourni est en **1920×1080** fixe (pas de scale) pour éviter les artefacts.
- Presse-papiers : le profil a le partage activé (`disableclipboard=0`). Si le copier-coller ne marche pas, voir [connexion_rdp_vnc_pi.md](connexion_rdp_vnc_pi.md) (section Presse-papiers).
- Installer le profil sur ton PC : **`make remmina-profile`**.

---

## Dépannage

- **`make install` ou `make update` : connexion refusée**  
  Vérifier que la Pi est allumée, sur le réseau (192.168.1.37), et que SSH est actif : `ssh pavel@192.168.1.37` ou `ssh pi-homelab` (si config SSH).

- **Backend ne démarre pas sur la Pi**  
  Se connecter en SSH (`make shell` ou `ssh pi-homelab`) puis : `cd ~/homelab-sentinel/backend && sudo docker compose logs -f`.

- **Changer l’IP de la Pi**  
  Utiliser `make push PI_IP=192.168.1.XX` (et adapter le profil Remmina si besoin).

- **Test GitHub en SSH sur le PC**  
  Utiliser **`ssh -T git@github.com`** (avec un **T majuscule**). Avec **`-t`** (minuscule) tu obtiens « PTY allocation request failed » : ce n’est pas une panne GitHub, juste la mauvaise option. Détail et config Git/GitHub sur la Pi : [docs/cursor_remote_ssh_pi.md](docs/cursor_remote_ssh_pi.md).

- **Cursor Remote SSH vers la Pi : « Architecture not supported: armv7l »**  
  Cursor ne supporte pas la Pi 2 (armv7l). **Ne pas utiliser** Remote SSH vers la Pi. À la place : coder sur le PC dans Cursor (dépôt local), puis **`make push`** pour déployer ; pour un terminal ou une édition rapide sur la Pi : **`ssh pi-homelab`** puis nano/vim. Voir [docs/cursor_remote_ssh_pi.md](docs/cursor_remote_ssh_pi.md).
