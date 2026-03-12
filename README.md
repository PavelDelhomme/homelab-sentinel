# Homelab Sentinel

Projet domotique maison sécurisé : Raspberry Pi (client sur la box), bus MQTT, API backend, prises connectées, gamelle RFID chat, caméras NVR, baby-phone. Plus tard, option routeur/VPN si tu ajoutes le matériel. Ce dépôt contient la documentation, les configs et le code de la stack.

**Référence complète** : tout le détail (architecture, schémas, commandes, code) est dans **[guide_domotique_complet.md](guide_domotique_complet.md)**.

---

## Matériel

- **Actuel** : Raspberry Pi 2, Arduino. Rien n’est encore connecté (Pi à brancher et à rendre accessible à distance).
- **À prévoir** : voir la [liste d’achats complète](guide_domotique_complet.md#12-liste-dachats-complète) dans le guide (dongle USB-Ethernet, switch, relais, ESP32, capteurs, caméras, etc.). La Pi reste en **client** sur la box tant que tu n’as pas de dongle ; pas besoin d’OpenWrt pour commencer.

---

## Premiers pas : connecter la Pi et accès distant

**On ne flashe pas OpenWrt** : on garde Raspberry Pi OS. La Pi se connecte à la box en Ethernet comme un PC (client), avec IP statique et SSH.

Guide détaillé : **[docs/pi_client_box.md](docs/pi_client_box.md)** — câblage, flash Raspberry Pi OS, activation SSH, IP statique, accès depuis ton réseau. **Tout-en-un (depuis ton PC, Raspberry de base)** : **[docs/premiers_pas_complet.md](docs/premiers_pas_complet.md)** — ordre complet pour arriver à SSH + RDP au démarrage avec IP statique. Pour SSH + RDP seuls : [docs/raspberry_ssh_rdp_acces_distant.md](docs/raspberry_ssh_rdp_acces_distant.md).

---

## Ordre de réalisation

Les 7 phases du guide (à adapter selon ton matos) :

1. **Réseau** — Pour l’instant : Pi en **client** sur la box (voir [docs/pi_client_box.md](docs/pi_client_box.md)). Plus tard, si tu achètes un dongle USB-Ethernet : option OpenWrt routeur/firewall (guide §1).
2. **Infra serveur** — Docker sur la Pi, Mosquitto (MQTT), PostgreSQL, API FastAPI.
3. **Premier device IoT** — Prise connectée ESP32, MQTT, dashboard.
4. **Caméras** — Caméras IP, Frigate NVR, détection, MQTT.
5. **Gamelle chat** — RFID + servo, MQTT + API.
6. **Baby-phone** — Pi Zero + caméra NoIR, streaming, alerte bruit.
7. **Interface complète** — Dashboard Vue.js, PWA, automatisations.

Suivi détaillé : **[STATUS.md](STATUS.md)**.

---

## Structure du dépôt

| Dossier / Fichier | Description |
|-------------------|-------------|
| **Makefile** | Déploiement depuis le PC : **`make install`** (init sur la Pi), **`make update`** (mise à jour + redémarrage backend). Voir [docs/workflow_pc_vers_pi.md](docs/workflow_pc_vers_pi.md). |
| `guide_domotique_complet.md` | Guide technique de référence (architecture, configs, code). |
| `STATUS.md` | État du matériel, des achats et des phases. |
| `docs/pi_client_box.md` | **Premiers pas** : connecter la Pi à la box (Raspberry Pi OS), IP statique, SSH. |
| `docs/premiers_pas_complet.md` | **Configuration de base** : tout depuis ton PC (Rasp de base, OS, Ethernet) → SSH + RDP au démarrage, IP statique. |
| `docs/raspberry_ssh_rdp_acces_distant.md` | **Accès à distance** : config SSH + RDP (xrdp) sur la Pi, activation au démarrage, clients RDP (Remmina, etc.). |
| `docs/workflow_pc_vers_pi.md` | **Tout depuis le PC** : make install / make update, sync, Remmina (1920×1080, presse-papiers). |
| `docs/management_mobile_tunnel_dns.md` | **Management / monitoring** : app mobile, tunnel sécurisé (Tailscale/WireGuard), DNS, accès de n’importe où. |
| `docs/openwrt_phase2.md` | **OpenWrt** : Pi en routeur avec dongle USB-Ethernet (Pi 2 = pas de WiFi intégré). |
| `docs/pi_wifi_et_eth_static.md` | **Pas encore en Ethernet** : WiFi statique (wlan0) + Ethernet statique (eth0) préparée pour plus tard. |
| `docs/pc_bluetooth_logitech.md` | **PC fixe** : Bluetooth au démarrage, vérifier la connexion, connecter Logitech Craft et MX Master 3. |
| `openwrt/` | Configs exemple pour Pi en **routeur** (optionnel, quand tu auras un dongle USB-Ethernet). |
| `scripts/` | Scripts à déployer sur la Pi (ex. watchdog reboot box, une fois le relais en place). |
| `backend/` | API FastAPI (devices, énergie, caméras, gamelle, auth, automations) ; lancement local possible sans matos IoT. |
| `firmware/` | Emplacements pour les sketches Arduino/ESP32 (prises, gamelle RFID) ; voir le guide pour le code. |

---

## Démarrage rapide (plus tard)

- **Tout depuis ton PC** : à la racine du dépôt, **`make bootstrap`** une fois (mot de passe pavel à la demande), redémarre la Pi, puis **`make install`**. Ensuite **`make update`** pour mettre à jour la Pi et redémarrer le backend sans interaction. Détail : [docs/workflow_pc_vers_pi.md](docs/workflow_pc_vers_pi.md).
- **Pi sur la box** : suivi pas à pas dans [docs/pi_client_box.md](docs/pi_client_box.md) (Raspberry Pi OS, Ethernet, IP statique, SSH). Pas d’OpenWrt.
- **Pi en routeur** (optionnel, avec dongle) : voir guide §1 et `openwrt/`.
- **Backend** : depuis la racine du repo, `make update` (déploie sur la Pi) ou en local `cd backend && docker compose up -d`.

Le détail des commandes et de la config est toujours dans **guide_domotique_complet.md**.
