# STATUS — Homelab Sentinel

Suivi du matériel et de l’avancement des phases. À mettre à jour au fil des achats et des étapes.

---

## Ce qui a été fait (système de base)

- **Déploiement 100 % depuis le PC** : `make bootstrap`, `make install`, `make update` ou **`make push`**, `make sync`, `make status`, `make remmina-profile`. Backend sur la Pi en **Docker** uniquement.
- **Backend** : API FastAPI (port 5500), PostgreSQL, Mosquitto — le tout en **Docker** sur la Pi (`make install` puis `make update` ou `make push`).
- **Firmware** : dossiers `firmware/` (prises ESP32, gamelle RFID) synchronisés avec `make sync` ; flash ESP32/Arduino à part (PC → câble USB ou OTA plus tard).
- **OpenWrt** : configs dans `openwrt/` (network, nftables) pour la phase 2 (Pi en routeur avec dongle). Doc : [docs/openwrt_phase2.md](docs/openwrt_phase2.md).
- **Testé en local** : `make help`, `make remmina-profile`, **`make openwrt-info`**, `make test-backend-local` (backend Docker puis curl http://localhost:5500/ et /api/docs — OK). Conteneurs arrêtés après test.

---

## Management, monitoring, app mobile, tunnel sécurisé et DNS

Pour **gérer et monitorer** le homelab (dont le **DNS**) depuis **n’importe où** avec une **interface mobile** et un **tunnel ultra sécurisé** :

- **Tunnel** : accès distant sans ouvrir de ports sur la box — **Tailscale** (recommandé), ou WireGuard / Cloudflare Tunnel. Une fois Tailscale sur la Pi et sur le téléphone, accès à l’API (et au futur dashboard) via l’IP Tailscale depuis n’importe où.
- **Interface mobile** : PWA du dashboard (ajout à l’écran d’accueil) puis, si besoin, app dédiée ; accès uniquement via le tunnel.
- **DNS** : gestion des noms locaux (homelab.local, api.homelab, etc.) via dnsmasq/Unbound sur la Pi ou OpenWrt ; l’app mobile pourra piloter le DNS via une API dédiée (à venir).
- **Monitoring** : endpoint `/health` et métriques optionnelles ; affichage dans le dashboard et l’app.

Doc détaillée : **[docs/management_mobile_tunnel_dns.md](docs/management_mobile_tunnel_dns.md)**.

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

## Configuration de base : accéder à la Pi à distance

**Ce que tu as** : une Raspberry Pi déjà en place — hostname **raspberrypi**, utilisateur **pavel** (mot de passe à utiliser à la connexion). Câble Ethernet à brancher sur la box. Pas d’interface graphique sur la Pi : tout se fait en SSH + script.

**Objectif** : configurer en une fois (script automatique) l’**IP statique**, **SSH** et **RDP** au démarrage, pour te connecter à distance sans rien faire à la main. Le script détecte tout seul le réseau (passerelle, DNS, fin de plage DHCP) et applique la config.

**Connexion actuelle** : Pi branchée sur la **box en Ethernet**. **eth0** = 192.168.1.37 (connexion principale, VNC/SSH/RDP). **eth1** = 192.168.1.1 (deuxième interface, ex. dongle USB-Ethernet). Pas de WiFi pour l’instant.

**À faire** : envoyer le script depuis ton PC pour configurer l’**IP statique 192.168.1.37** (obligatoire), **SSH** et **xrdp** au démarrage. Ensuite connexion à distance en **VNC** (déjà en place), **SSH** ou **RDP**.

---

### Envoyer et lancer le script depuis ton PC (Pi sur la box, IP 192.168.1.37)

Connexion **VNC** déjà en place sur **192.168.1.37**. Depuis ton **ordinateur fixe** (dans le dossier du dépôt homelab-sentinel), en une seule commande : envoyer le script sur la Pi puis l’exécuter avec **IP statique 192.168.1.37** (obligatoire pour l’accès à distance).

```bash
cd /chemin/vers/homelab-sentinel
scp scripts/raspberry_setup_auto.sh pavel@192.168.1.37:~/ && ssh pavel@192.168.1.37 'chmod +x ~/raspberry_setup_auto.sh && sudo STATIC_IP=192.168.1.37 ~/raspberry_setup_auto.sh'
```

Tu entres le mot de passe **pavel** quand `scp` et `ssh` le demandent. Le script : répare dpkg si besoin, configure l’**IP statique 192.168.1.37** sur eth0, active **SSH** et **xrdp** au démarrage. Pas de wlan0 (réseau à vérifier si besoin après envoi).

**Connexion à distance** (après script + redémarrage si proposé) :
- **VNC** : directement à **192.168.1.37** (déjà en place).
- **SSH** : `ssh pavel@192.168.1.37`
- **RDP** : client RDP, adresse **192.168.1.37**, port 3389, utilisateur pavel.

Sur ton **PC fixe** (Arch), pour installer un client RDP graphique correct (Remmina, gratuit, open source) à la place de « Connexions bureau » GNOME : exécuter **`scripts/install_rdp_client.sh`** (installe Remmina + FreeRDP). Ensuite lancer Remmina, nouvelle connexion RDP vers 192.168.1.37:3389, utilisateur pavel.

**Profil Remmina prêt à l’emploi** : exécuter **`scripts/install_remmina_profile.sh`** ou **`make remmina-profile`** pour copier la connexion « Pi Homelab (192.168.1.37) » dans Remmina (mot de passe pavel à la demande). Le profil est réglé en **1920×1080** fixe (pas de scale) et presse-papiers activé ; si le copier-coller ne marche pas, voir [docs/connexion_rdp_vnc_pi.md](docs/connexion_rdp_vnc_pi.md).

**RDP = nouvelle session** (pas le même écran qu’en VNC/HDMI). Pour le **rendu direct** (écran en live), utiliser **VNC**. **Clavier AZERTY** : le script **raspberry_setup_auto.sh** configure maintenant le clavier français (AZERTY) sur la Pi et l’autostart `setxkbmap fr` pour les sessions graphiques. Si tu as déjà lancé le script avant cette mise à jour, relance-le une fois, ou en session (RDP/VNC) exécuter : `setxkbmap fr`. Détail : [docs/connexion_rdp_vnc_pi.md](docs/connexion_rdp_vnc_pi.md).

**Dépannage dpkg/apt** : si après un `apt upgrade` tu as des erreurs (adduser, systemd, dbus, udev, bluez, etc.), voir [docs/pi_repair_dpkg.md](docs/pi_repair_dpkg.md). Réparation rapide depuis le PC :  
`scp scripts/pi_repair_dpkg.sh pavel@192.168.1.37:~/ && ssh pavel@192.168.1.37 'chmod +x ~/pi_repair_dpkg.sh && sudo ~/pi_repair_dpkg.sh'`

**Tout depuis le PC (déploiement, mise à jour)** : **[docs/workflow_pc_vers_pi.md](docs/workflow_pc_vers_pi.md)**. Une fois la Pi configurée : **`make bootstrap`** (une fois), redémarrage Pi, puis **`make install`**. Ensuite **`make update`** ou **`make push`** à chaque déploiement.

**Pousser les mises à jour** : **`make push`** ou **`make update`** (sync + redémarrage du backend Docker sur la Pi). Alias pratique : `alias homelab-push='cd /home/pactivisme/Documents/Dev/Perso/homelab/homelab-sentinel && make push'` dans ton `~/.zshrc`. Détail : [docs/cursor_remote_ssh_pi.md](docs/cursor_remote_ssh_pi.md).

**Cursor Remote SSH ne fonctionne pas sur Raspberry Pi 2** : le Cursor Server ne supporte pas l’architecture **armv7l**. Tu obtiens « Architecture not supported: armv7l ». **Workflow à utiliser** : coder sur le PC dans Cursor (dossier homelab-sentinel local), puis **`make push`** pour déployer sur la Pi. Pour agir sur la Pi (terminal, logs, édition rapide) : **`ssh pi-homelab`** (config **`Host pi-homelab`** dans **`~/.ssh/config`**, voir **`scripts/ssh_config_example.txt`**). Ça ne modifie pas GitHub : **test avec `ssh -T git@github.com`** (T majuscule). Git/GitHub sur la Pi (optionnel, pour commit/push depuis la Pi en SSH) : [docs/cursor_remote_ssh_pi.md](docs/cursor_remote_ssh_pi.md).

**Backend sur la Pi (sans surcharger)** : backend en **Docker** sur la Pi : **`make install`** (première fois), puis **`make update`** ou **`make push`** pour déployer les mises à jour. Voir [docs/workflow_pc_vers_pi.md](docs/workflow_pc_vers_pi.md).

**OpenWrt (routage / box)** : phase 2, quand tu auras **une deuxième interface**. La **Pi 2 n’a pas de WiFi intégré** (un seul Ethernet eth0) : il faut un **dongle USB-Ethernet** (recommandé, second câble) ou un dongle USB-WiFi. Configs dans **`openwrt/`**, doc : **[docs/openwrt_phase2.md](docs/openwrt_phase2.md)**. **`make openwrt-info`** (sur le PC, sans Pi ni dongle) affiche les étapes et la liste des configs. Sync envoie `openwrt/` sur la Pi ; pour une Pi flashee en OpenWrt, tu copies les configs à la main.

**Commandes exécutables sur cette machine (sans Pi)** : **`make test-backend-local`** lance le backend en Docker en local (test) ; **`make stop-backend-local`** l’arrête. **`make openwrt-info`** affiche les infos OpenWrt.

---

### Méthode rapide : tout avec le script (recommandé)

1. **Brancher la Pi** : câble Ethernet Pi → port LAN de la Bbox, alimentation. Attendre 1–2 min.

2. **Trouver l’IP de la Pi** (depuis ton PC) :
   - `ping raspberrypi.local`  
   - ou aller sur la Bbox (http://192.168.1.254) → liste des appareils → repérer la Pi.

3. **Se connecter en SSH** (une seule fois) :
   ```bash
   ssh pavel@raspberrypi.local
   ```
   (ou `ssh pavel@<IP_PI>` si tu as l’IP). Mot de passe : celui de l’utilisateur pavel.

4. **Récupérer le script sur la Pi** (au choix) :
   - **Depuis le dépôt** (si tu as le repo sur ton PC) :
     ```bash
     scp scripts/raspberry_setup_auto.sh pavel@raspberrypi.local:~/
     ```
   - **Ou** copier le contenu du fichier `scripts/raspberry_setup_auto.sh` du projet et le coller dans un fichier sur la Pi :
     ```bash
     nano ~/raspberry_setup_auto.sh
     # coller le contenu, Ctrl+O, Entrée, Ctrl+X
     chmod +x ~/raspberry_setup_auto.sh
     ```

5. **Lancer le script sur la Pi** :
   ```bash
   sudo ~/raspberry_setup_auto.sh
   ```
   Le script :
   - **répare dpkg/apt** si une installation a été interrompue (partage USB débranché, etc.),
   - détecte la passerelle et les DNS (réseau Bbox),
   - choisit une IP statique hors plage DHCP typique (ex. 192.168.1.50),
   - configure l’interface **eth0** en statique dans `/etc/dhcpcd.conf`,
   - active **SSH** et **xrdp** au démarrage,
   - propose de redémarrer.

**Important** : ne pas débrancher le câble réseau ni le partage de connexion pendant l’exécution du script (surtout pendant apt/dpkg).

6. **Redémarrer** la Pi (si tu as répondu oui au script, c’est déjà fait). Sinon : `sudo reboot`. Attendre 1–2 min.

7. **Se connecter à distance** :
   - **VNC** : directement à **192.168.1.37** (déjà en place).
   - **SSH** : `ssh pavel@192.168.1.37` (ou l’IP fixe si tu as lancé le script avec STATIC_IP=192.168.1.37).
   - **RDP** : client RDP (Remmina, Bureau à distance Windows), adresse **192.168.1.37**, port **3389**, utilisateur **pavel**.

---

### Ce que fait le script (vérifications automatiques)

| Étape | Action |
|-------|--------|
| **dpkg/apt** | Si une installation a été interrompue : `dpkg --configure -a` puis `apt --fix-broken install`. Évite de lancer le script sans connexion stable (risque de re-interrompre). |
| **Connexion USB** | Si passerelle en **10.x.x.x** (partage USB) : **pas d’IP statique**, seulement SSH + xrdp. Connecte-toi à l’IP actuelle (ex. 10.117.216.143). Branche la Pi sur la box puis relance le script pour l’IP fixe. |
| Réseau | Détection de la passerelle par défaut et des DNS (Bbox ou USB). |
| Interface | Utilise **eth0** pour l’IP statique (quand pas en USB). Pas de wlan0 sur cette Pi. Si wlan0 existait, le script configurerait aussi le WiFi en .51. |
| IP statique | Par défaut .50 ; pour **192.168.1.37** (obligatoire ici) : `sudo STATIC_IP=192.168.1.37 ./raspberry_setup_auto.sh`. |
| dhcpcd | Sauvegarde de `/etc/dhcpcd.conf`, ajout du bloc eth0 statique (sans toucher au reste). |
| SSH | `systemctl enable --now ssh`. |
| xrdp | `apt install -y xrdp` si besoin, puis `systemctl enable --now xrdp`. |
| Redémarrage | Proposé à la fin pour appliquer l’IP statique. |

Aucune étape manuelle : une fois connecté en SSH et le script lancé, tout est configuré. Après reboot, accès direct en SSH et RDP à l’IP fixe.

---

### Résultat

- **IP statique** (ex. 192.168.1.50) : même adresse à chaque démarrage.
- **SSH** et **RDP (xrdp)** actifs au démarrage : connexion en ligne de commande ou bureau à distance depuis ton réseau.
- **Hostname** : reste **raspberrypi** (pas de changement).
- **Utilisateur** : **pavel** pour SSH et RDP.

---

### Fichier du script

Le script est dans le dépôt : **`scripts/raspberry_setup_auto.sh`**. Tu peux le consulter ou le modifier (variables en tête : `STATIC_IP`, `INTERFACE`, `FIX_DPKG`). Documentation détaillée pas à pas (sans script) : [docs/premiers_pas_complet.md](docs/premiers_pas_complet.md) et [docs/pi_client_box.md](docs/pi_client_box.md).

---

### Réparer dpkg si interrompu (avant ou sans le script)

Si un message du type **« dpkg a été interrompu »** ou **« Vous devez exécuter dpkg --configure -a »** s’affiche (souvent après un partage de connexion USB débranché pendant un `apt install`), fais ceci **sur la Pi en SSH**, avec une connexion **stable** (Ethernet ou partage USB bien branché, ne pas débrancher pendant les commandes) :

1. **Terminer les configurations dpkg en attente** :
   ```bash
   sudo dpkg --configure -a
   ```
   Répondre aux éventuelles questions (garder la config par défaut si tu ne sais pas). Attendre la fin.

2. **Réparer les dépendances manquantes / paquets cassés** :
   ```bash
   sudo apt --fix-broken install -y
   ```

3. **Mettre à jour les listes et le système** (optionnel) :
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

Ensuite tu peux lancer le script `raspberry_setup_auto.sh`. Le script fait lui‑même les étapes 1 et 2 au début (variable `FIX_DPKG=true` par défaut). Pour désactiver la réparation automatique : `sudo FIX_DPKG=false ./raspberry_setup_auto.sh`.

**Pour limiter les déconnexions** : privilégier l’**Ethernet** (câble vers la Bbox) plutôt que le partage USB pour lancer le script et les `apt install`. Si tu restes en partage USB, ne pas débrancher le câble ni éteindre le téléphone pendant les mises à jour ou l’installation de xrdp.

### Cas : Pi avec WiFi (pas encore de câble)

Si ta Pi a une interface WiFi (wlan0) et que tu n’es pas encore branché en Ethernet : voir [docs/pi_wifi_et_eth_static.md](docs/pi_wifi_et_eth_static.md) pour WiFi statique + eth0 en avance. Sinon, le script ci‑dessus suppose **eth0** branché sur la Bbox.

---

## PC fixe : Bluetooth au démarrage + Logitech (Craft, MX Master 3)

Sur ton **PC fixe** (Arch Linux) : le Bluetooth doit **démarrer au démarrage** et tu dois pouvoir **vérifier la connexion** et connecter les **Logitech Craft** et **MX Master 3** (deuxième appareil / canal 2).

- **Bluetooth au démarrage** : le service `bluetooth` est activé ; dans `/etc/bluetooth/main.conf` l’option **`AutoEnable=true`** est activée pour que le contrôleur soit allumé à chaque boot.
- **Vérifier** : `bluetoothctl show` (Powered: yes, Pairable: yes) ; si besoin `bluetoothctl power on`.
- **Connecter les Logitech** : mettre le clavier/souris en mode appairage (canal 2), puis `bluetoothctl` → `scan on` → `pair <MAC>` → `trust <MAC>` → `connect <MAC>`.

Guide détaillé : **[docs/pc_bluetooth_logitech.md](docs/pc_bluetooth_logitech.md)** — commandes pour vérifier le Bluetooth et appairer Craft + MX Master 3.

---

## Phases du guide

| Phase | Description | Statut |
|-------|-------------|--------|
| 0 / Premiers pas | Pi en **client** sur la box : Raspberry Pi OS, Ethernet, IP statique, SSH ([docs/pi_client_box.md](docs/pi_client_box.md)) | En place (script + bootstrap) |
| 1 | Optionnel plus tard : Pi en routeur (OpenWrt + dongle), firewall, WireGuard, relais box — [docs/openwrt_phase2.md](docs/openwrt_phase2.md) | Prévu (configs dans `openwrt/`) |
| 2 | Infra serveur : backend (API FastAPI), PostgreSQL, Mosquitto en **Docker** sur la Pi — **`make install`** / **`make update`** / **`make push`** | Prêt (scripts + Makefile, testé en local) |
| 3 | Premier device IoT (prise ESP32, MQTT, dashboard) | Non démarré |
| 4 | Caméras + NVR (Frigate) | Non démarré |
| 5 | Gamelle RFID chat | Non démarré |
| 6 | Baby-phone | Non démarré |
| 7 | Interface complète (Vue.js, PWA, automations) | Non démarré |

### Détail « Premiers pas » (tout dans l’ordre)

Voir **[docs/premiers_pas_complet.md](docs/premiers_pas_complet.md)** pour le détail étape par étape. En résumé : flash SD (SSH activé) → brancher Pi sur la box → trouver l’IP → première connexion SSH → IP statique → SSH + xrdp au démarrage → test accès à distance.

### Détail Phase 1 — OpenWrt (optionnel, quand dongle)

- **Pi 2** : **pas de WiFi intégré**, un seul port Ethernet (eth0). Pour faire WAN + LAN il faut **au moins une interface en plus** :
  - **Dongle USB-Ethernet** (recommandé) : eth0 = LAN, eth1 = WAN (ou l’inverse). Tu branches le dongle en second câble vers la box.
  - **Dongle USB-WiFi** : eth0 + wlan0 possible mais moins courant pour un routeur.
- **Sans dongle** : on peut préparer les configs et les tester sur le PC (**`make openwrt-info`**). Le flash OpenWrt sur la Pi se fera quand tu auras le dongle.
- [ ] Flasher OpenWrt sur Pi 2 (image arm 32-bit).
- [ ] Installer driver USB-Ethernet (RTL8152 ou AX88179 selon dongle), reboot.
- [ ] Copier `openwrt/network.example.conf` → `/etc/config/network`, puis `/etc/init.d/network restart`.
- [ ] Firewall nftables (voir `openwrt/nftables.example.conf`).
- [ ] WireGuard ou Tailscale (accès distant).
- [ ] Relais reboot box + script `scripts/watchdog_box.py`.

---

## Notes

- **Système de base** : tout est lancé **depuis le PC** et déployé sur la **Raspberry** (sync, backend en **Docker**). **`make push`** ou **`make update`** : sync + redémarrage du backend sur la Pi. **`make shell`** ou **`ssh pi-homelab`** (si config SSH) pour une session sur la Pi.
- **Config SSH** : le bloc **`Host pi-homelab`** dans `~/.ssh/config` permet **`ssh pi-homelab`** (terminal, nano, commandes). Cursor Remote SSH ne fonctionne pas sur la Pi 2 (armv7l). Il **n’affecte pas** la connexion **GitHub** (`git@github.com`) : tu peux vérifier avec `ssh -T git@github.com`.
- **Pi** : on garde **Raspberry Pi OS** (pas OpenWrt pour l’infra). La Pi est un **client** sur la box ; OpenWrt est pour plus tard (routeur avec dongle). Voir [docs/pi_client_box.md](docs/pi_client_box.md) et [docs/openwrt_phase2.md](docs/openwrt_phase2.md).
- **Arduino** : non connecté pour l’instant ; prévu pour gamelle / prises ou autre selon le guide quand le matériel sera là.
- **Dongle** : pour faire de la Pi un **routeur** (OpenWrt) il faut une **deuxième interface** : dongle USB-Ethernet (recommandé) ou USB-WiFi. Voir [docs/openwrt_phase2.md](docs/openwrt_phase2.md) et **`make openwrt-info`**.
