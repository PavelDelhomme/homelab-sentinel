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

## Configuration de base : accéder à la Pi à distance

**Ce que tu as** : une Raspberry Pi déjà en place — hostname **raspberrypi**, utilisateur **pavel** (mot de passe à utiliser à la connexion). Câble Ethernet à brancher sur la box. Pas d’interface graphique sur la Pi : tout se fait en SSH + script.

**Objectif** : configurer en une fois (script automatique) l’**IP statique**, **SSH** et **RDP** au démarrage, pour te connecter à distance sans rien faire à la main. Le script détecte tout seul le réseau (passerelle, DNS, fin de plage DHCP) et applique la config.

**Connexion actuelle** : si tu es en **partage de connexion USB** (téléphone → Pi), évite de débrancher pendant les opérations **apt** ou **dpkg** (mise à jour, installation). Une déconnexion peut laisser **dpkg interrompu** et bloquer apt. Le script tente de réparer dpkg au démarrage ; si le problème persiste, utilise la procédure manuelle ci‑dessous.

En **USB**, le script **ne configure pas l’IP statique** (passerelle 10.x.x.x détectée) : il active seulement **SSH** et **xrdp** au démarrage. Tu peux te connecter tout de suite en SSH/RDP/VNC à l’IP actuelle (ex. 10.117.216.143). Une fois la Pi branchée sur la box en Ethernet, relancer le script pour configurer l’IP fixe.

---

### Envoyer et lancer le script depuis ton PC (Pi en USB, ex. 10.117.216.143)

Depuis ton **ordinateur fixe** (dans le dossier du dépôt homelab-sentinel), en une seule commande : envoyer le script sur la Pi puis l’exécuter. Remplace `<IP_PI>` par l’IP actuelle de la Pi (ex. **10.117.216.143** si tu es en partage USB).

```bash
cd /chemin/vers/homelab-sentinel
scp scripts/raspberry_setup_auto.sh pavel@<IP_PI>:~/ && ssh pavel@<IP_PI> 'chmod +x ~/raspberry_setup_auto.sh && sudo ~/raspberry_setup_auto.sh'
```

Exemple avec l’IP en USB :

```bash
scp scripts/raspberry_setup_auto.sh pavel@10.117.216.143:~/ && ssh pavel@10.117.216.143 'chmod +x ~/raspberry_setup_auto.sh && sudo ~/raspberry_setup_auto.sh'
```

Tu entres le mot de passe **pavel** quand `scp` et `ssh` le demandent. Le script tourne sur la Pi : il répare dpkg si besoin, n’applique **pas** d’IP statique (connexion USB), active SSH et xrdp, et affiche l’IP actuelle pour te connecter en SSH/RDP/VNC. Ensuite tu peux brancher la Pi sur la box (Ethernet) et relancer la même commande (avec la nouvelle IP en 192.168.x.x) pour configurer l’IP fixe.

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
   - **SSH** : `ssh pavel@192.168.1.50` (remplacer par l’IP affichée par le script si différente).
   - **RDP** : sur ton PC, ouvrir un client RDP (Remmina, Bureau à distance Windows), adresse **192.168.1.50**, port **3389**, utilisateur **pavel**, mot de passe. Après chaque reboot de la Pi, même chose : rien à reconfigurer.

---

### Ce que fait le script (vérifications automatiques)

| Étape | Action |
|-------|--------|
| **dpkg/apt** | Si une installation a été interrompue : `dpkg --configure -a` puis `apt --fix-broken install`. Évite de lancer le script sans connexion stable (risque de re-interrompre). |
| **Connexion USB** | Si passerelle en **10.x.x.x** (partage USB) : **pas d’IP statique**, seulement SSH + xrdp. Connecte-toi à l’IP actuelle (ex. 10.117.216.143). Branche la Pi sur la box puis relance le script pour l’IP fixe. |
| Réseau | Détection de la passerelle par défaut et des DNS (Bbox ou USB). |
| Interface | Utilise **eth0** pour l’IP statique (quand pas en USB). Si **wlan0** existe, configure aussi le WiFi en statique (.51) sur le réseau de la box. |
| IP statique | Choisit une IP en .50 (ex. 192.168.1.50) pour rester hors plage DHCP courante. Tu peux forcer une IP : `sudo STATIC_IP=192.168.1.51 ./raspberry_setup_auto.sh`. |
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
| 0 / Premiers pas | Pi en **client** sur la box : Raspberry Pi OS, Ethernet, IP statique, SSH ([docs/pi_client_box.md](docs/pi_client_box.md)) | Non démarré |
| 1 | Optionnel plus tard : Pi en routeur (OpenWrt + dongle), firewall, WireGuard, relais box | Non démarré |
| 2 | Infra serveur (Docker, MQTT, PostgreSQL, FastAPI) | Non démarré |
| 3 | Premier device IoT (prise ESP32, MQTT, dashboard) | Non démarré |
| 4 | Caméras + NVR (Frigate) | Non démarré |
| 5 | Gamelle RFID chat | Non démarré |
| 6 | Baby-phone | Non démarré |
| 7 | Interface complète (Vue.js, PWA, automations) | Non démarré |

### Détail « Premiers pas » (tout dans l’ordre)

Voir **[docs/premiers_pas_complet.md](docs/premiers_pas_complet.md)** pour le détail étape par étape. En résumé : flash SD (SSH activé) → brancher Pi sur la box → trouver l’IP → première connexion SSH → IP statique → SSH + xrdp au démarrage → test accès à distance.

### Détail Phase 1 (optionnel, quand dongle + matos)

- [ ] Flasher OpenWrt sur Pi 2 (si tu veux la Pi en routeur).
- [ ] Configurer WAN (eth1 = dongle) / LAN (eth0).
- [ ] Installer driver USB-Ethernet (selon chipset : RTL8152, AX88179, etc.).
- [ ] Firewall nftables (voir `openwrt/nftables.example.conf`).
- [ ] WireGuard (PiVPN).
- [ ] Relais reboot box + script `scripts/watchdog_box.py`.

---

## Notes

- **Pi** : on garde **Raspberry Pi OS** (pas OpenWrt). La Pi est un **client** sur la box ; pas de routage pour l’instant. Voir [docs/pi_client_box.md](docs/pi_client_box.md).
- **Arduino** : non connecté pour l’instant ; prévu pour gamelle / prises ou autre selon le guide quand le matériel sera là.
- **Dongle** : seulement si tu veux plus tard faire de la Pi un routeur ; voir `openwrt/` et guide §1.
