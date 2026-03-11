# Homelab Sentinel

Projet domotique maison sécurisé : routeur/firewall sur Raspberry Pi 2, bus MQTT, API backend, prises connectées, gamelle RFID chat, caméras NVR, baby-phone, VPN WireGuard. Ce dépôt contient la documentation, les configs et le code de la stack.

**Référence complète** : tout le détail (architecture, schémas, commandes, code) est dans **[guide_domotique_complet.md](guide_domotique_complet.md)**.

---

## Matériel

- **Actuel** : Raspberry Pi 2, Arduino. Rien n’est encore connecté (Pi à brancher et à rendre accessible à distance).
- **À prévoir** : voir la [liste d’achats complète](guide_domotique_complet.md#12-liste-dachats-complète) dans le guide (dongle USB-Ethernet, switch, AP Wi‑Fi, relais, ESP32, capteurs, caméras, etc.).

---

## Premiers pas

1. **Connecter la Pi 2** au réseau (Ethernet ou Wi‑Fi selon ta box).
2. **Accès à distance** : configurer SSH (ou autre) selon ton besoin (accès ponctuel ou permanent). Détails dans le guide (section 1 pour OpenWrt, ou Raspberry Pi OS + SSH).

---

## Ordre de réalisation

Les 7 phases du guide :

1. **Réseau sécurisé** — OpenWrt sur Pi 2, WAN/LAN (nécessite dongle USB-Ethernet), firewall, WireGuard, relais reboot box.
2. **Infra serveur** — Docker, Mosquitto (MQTT + TLS), PostgreSQL, API FastAPI.
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
| `guide_domotique_complet.md` | Guide technique de référence (architecture, configs, code). |
| `STATUS.md` | État du matériel, des achats et des phases. |
| `openwrt/` | Configs exemple pour Pi 2 en routeur (réseau, firewall) — à utiliser quand tu auras un dongle USB-Ethernet. |
| `scripts/` | Scripts à déployer sur la Pi (ex. watchdog reboot box, une fois le relais en place). |
| `backend/` | API FastAPI (devices, énergie, caméras, gamelle, auth, automations) ; lancement local possible sans matos IoT. |
| `firmware/` | Emplacements pour les sketches Arduino/ESP32 (prises, gamelle RFID) ; voir le guide pour le code. |

---

## Démarrage rapide (plus tard)

- **Pi en routeur** : flasher OpenWrt (voir guide §1), configurer `openwrt/network.example.conf` et le firewall après achat du dongle.
- **Backend** : depuis la racine du repo, `cd backend && docker compose up -d` (ou `docker-compose` selon ta version) pour lancer l’API + PostgreSQL + Mosquitto en local.

Le détail des commandes et de la config est toujours dans **guide_domotique_complet.md**.
