# OpenWrt (phase 2) — Pi en routeur

À faire **quand tu auras une deuxième interface** (dongle USB-Ethernet ou USB-WiFi). La **Raspberry Pi 2 n’a pas de WiFi intégré** : un seul port Ethernet (eth0). Pour faire WAN + LAN il faut donc **au moins une interface en plus**.

---

## Options pour avoir deux interfaces (Pi 2)

| Option | Rôle | Comment |
|--------|------|--------|
| **Dongle USB-Ethernet** (recommandé) | eth0 = LAN, eth1 = WAN (ou l’inverse) | Tu branches un **câble** du dongle vers la box (WAN) et le port natif (eth0) vers le switch (LAN). Très stable pour un routeur. |
| **Dongle USB-WiFi** | eth0 = LAN, wlan0 = WAN (client box) ou wlan0 = LAN (AP) | Moins courant en routeur qu’Ethernet ; possible si tu veux du WiFi en plus. |

**En résumé** : avec une Pi 2, sans dongle tu ne peux pas faire routeur (un seul lien). Dès que tu ajoutes **un adaptateur USB → Ethernet** (second câble) ou un **USB-WiFi**, tu peux installer OpenWrt et utiliser une interface pour WAN, l’autre pour LAN. On recommande le **dongle USB-Ethernet** (ex. TP-Link UE300) pour le rôle routeur.

*(Sur une Pi 3/4, le WiFi intégré peut servir de deuxième interface — WAN ou LAN — sans dongle.)*

---

## Rôle typique (avec dongle USB-Ethernet)

- **eth0** (natif) → LAN (192.168.10.1, switch / clients).
- **eth1** (dongle) → WAN (DHCP vers la box).

Les configs sont dans **`openwrt/`** à la racine du dépôt. Elles sont synchronisées sur la Pi avec **`make sync`** tant que la Pi tourne sous Raspberry Pi OS. Quand tu passeras la Pi sous OpenWrt, tu copieras ces fichiers **depuis ton PC** vers la Pi (OpenWrt) ou tu les utiliseras comme référence.

---

## Étapes (quand tu as le dongle)

1. **Flasher OpenWrt** sur la Pi (image arm (32-bit) pour Pi 2) : [openwrt.org](https://openwrt.org/toh/raspberry_pi_foundation/raspberry_pi_2).
2. **Installer le driver** du dongle (sur la Pi OpenWrt) :
   ```bash
   opkg update
   # RTL8153 (ex. TP-Link UE300) :
   opkg install kmod-usb-net-rtl8152
   # AX88179 :
   # opkg install kmod-usb-net-asix-ax88179
   reboot
   ```
3. **Réseau** : copier `openwrt/network.example.conf` vers `/etc/config/network` sur la Pi (adapter les IP si besoin). Puis `/etc/init.d/network restart`.
4. **Firewall** : utiliser `openwrt/nftables.example.conf` comme base (LuCI ou `/etc/nftables.conf`).

---

## Commandes depuis le PC (sans Pi OpenWrt)

- **`make openwrt-info`** : affiche un résumé des configs OpenWrt et les étapes à faire sur la Pi quand tu auras le dongle.
- **`make sync`** : envoie aussi le dossier `openwrt/` sur la Pi (Raspberry Pi OS) ; pour une Pi déjà flashee en OpenWrt, tu copies les fichiers à la main depuis le dépôt.

---

## Compatibilité avec le projet

- Le **backend** (API, MQTT) tourne aujourd’hui sur **Raspberry Pi OS** (client sur la box). Si tu passes la Pi en **routeur OpenWrt**, tu peux soit garder une seule Pi (OpenWrt = routeur uniquement, pas d’API sur cette machine), soit ajouter une **deuxième Pi** pour l’API, soit faire tourner l’API ailleurs (NAS, autre serveur).
- Les configs **openwrt/** du dépôt servent à avoir un routage/firewall cohérent avec le reste du projet ; le déploiement se fait à la main (copie des fichiers) depuis le PC vers la Pi OpenWrt.

Référence : [guide_domotique_complet.md](../guide_domotique_complet.md) section 1.
