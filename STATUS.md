# STATUS — Homelab Sentinel

Suivi du matériel et de l’avancement des phases. À mettre à jour au fil des achats et des étapes.

---

## Matériel

### Possédé

- **Raspberry Pi 2**
- **Arduino**

Rien d’autre pour l’instant. Rien n’est encore connecté (Pi à brancher, accès à distance à configurer ; Arduino pas câblé).

### À acheter

Référence : [liste d’achats complète](guide_domotique_complet.md#12-liste-dachats-complète) dans le guide.

| Composant | Usage | Statut |
|-----------|--------|--------|
| Dongle USB-Ethernet (ex. TP-Link UE300) | WAN pour Pi routeur | Non acheté |
| Carte microSD 16 Go+ (classe 10) | OS Pi | Non acheté |
| Switch Ethernet 5/8 ports | LAN derrière la Pi | Non acheté |
| Point d’accès Wi‑Fi (ex. TP-Link EAP225) | Wi‑Fi maison | Non acheté |
| Module relais 5V 1 canal + câbles Dupont | Reboot box | Non acheté |
| ESP32, ACS712, ZMPT101B, HI-Link, relais, prises 230V | Prises connectées | Non acheté |
| Module RFID (FDX-B ou RDM6300) + servo | Gamelle chat | Non acheté |
| Caméras IP / ESP32-CAM, switch PoE | NVR | Non acheté |
| Pi Zero 2 W, caméra NoIR, micro USB | Baby-phone | Non acheté |
| Disque externe (stockage NVR) | Vidéo | Non acheté |

*(Cocher / mettre à jour : commandé, reçu.)*

---

## Premiers pas (avant Phase 1)

- [ ] **Connecter la Pi au réseau** (box en Ethernet ou Wi‑Fi).
- [ ] **Accès à distance** à la Pi (SSH ou autre) — à configurer selon besoin (ponctuel ou permanent).

---

## Phases du guide

| Phase | Description | Statut |
|-------|-------------|--------|
| 1 | Réseau sécurisé (OpenWrt, WAN/LAN, firewall, WireGuard, relais box) | Non démarré |
| 2 | Infra serveur (Docker, MQTT, PostgreSQL, FastAPI) | Non démarré |
| 3 | Premier device IoT (prise ESP32, MQTT, dashboard) | Non démarré |
| 4 | Caméras + NVR (Frigate) | Non démarré |
| 5 | Gamelle RFID chat | Non démarré |
| 6 | Baby-phone | Non démarré |
| 7 | Interface complète (Vue.js, PWA, automations) | Non démarré |

### Détail Phase 1 (quand matériel disponible)

- [ ] Flasher OpenWrt sur Pi 2
- [ ] Configurer WAN (eth1 = dongle) / LAN (eth0)
- [ ] Installer driver USB-Ethernet (selon chipset : RTL8152, AX88179, etc.)
- [ ] Firewall nftables (voir `openwrt/nftables.example.conf`)
- [ ] WireGuard (PiVPN)
- [ ] Relais reboot box + script `scripts/watchdog_box.py`

---

## Notes

- **Arduino** : non connecté pour l’instant ; prévu pour gamelle / prises ou autre selon le guide quand le matériel sera là.
- **Dongle** : quand tu en achèteras un, vérifier le chipset pour le bon driver OpenWrt (RTL8152, AX88179, etc. — voir guide §1).
