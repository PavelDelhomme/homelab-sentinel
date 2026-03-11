# Connecter la Raspberry Pi 2 à la Bbox et maîtriser l’accès à distance

Ce guide décrit **tout ce qu’il faut faire** pour : brancher la Pi en **client** sur ta Bbox (Ethernet), lui donner une **IP statique** sur l’interface **eth0**, et la **récupérer / contrôler à distance** en SSH depuis ton réseau. **Pas d’OpenWrt** : on garde Raspberry Pi OS. Mode **test** : on ne modifie pas la config principale de la Bbox (pas de redirection de ports pour l’instant).

---

## Ordre de ce que tu fais (vue d’ensemble)

1. **Bbox** : noter la plage DHCP et (optionnel) réserver une IP pour la Pi — sans toucher au reste.
2. **Carte SD** : flasher Raspberry Pi OS, activer SSH, premier boot.
3. **Réseau** : câble Ethernet Pi → port LAN Bbox, trouver l’IP de la Pi (Bbox ou `ping homelab-sentinel.local`).
4. **SSH** : se connecter, changer le mot de passe, noter l’adresse MAC de **eth0** si tu veux réserver l’IP sur la Bbox.
5. **IP statique sur la Pi** : configurer **uniquement l’interface Ethernet (eth0)** (dhcpcd ou NetworkManager).
6. **Redémarrage** : vérifier que la Pi répond en IP fixe et que SSH fonctionne.
7. **Accès distant** : depuis n’importe quel appareil du même réseau, `ssh pi@<IP_FIXE>`.

**Redirection de ports** : on n’en configure **aucune** sur la Bbox pour l’instant. Tout reste en local (LAN). Quand tu voudras accéder à la Pi depuis l’extérieur, on pourra ajouter une redirection ou un VPN plus tard.

---

## 1. Côté Bbox (sans tout casser)

Objectif : savoir quelle plage d’IP la Bbox donne en DHCP, et éventuellement réserver une IP pour la Pi. **On ne change pas les redirections de ports.**

### 1.1 Accéder à l’interface

- Ouvre un navigateur et va sur : **http://192.168.1.254**
- Connecte-toi (identifiants de ta Bbox).

### 1.2 Noter la plage DHCP

- Va dans la partie **Bbox** (bleue), puis **Services de la Box** → **DHCP** (ou **Réseau local** / **Paramètres DHCP** selon le modèle).
- Note la **plage d’adresses** que la Bbox attribue automatiquement (ex. de `192.168.1.10` à `192.168.1.199`).

On va choisir une IP **en dehors** de cette plage pour la Pi (ex. `192.168.1.50` si la plage est .10–.199). Comme ça, pas de conflit même sans réserver l’IP sur la Bbox.

Exemples courants Bbox :

- Réseau : `192.168.1.0/24`
- Passerelle : `192.168.1.254`
- Plage DHCP souvent : `.2` à `.100` ou `.10` à `.199` — **à vérifier chez toi**.

### 1.3 (Optionnel) Réserver une IP pour la Pi dans la Bbox

Si tu préfères que la Bbox « réserve » la même IP pour la Pi (via son adresse MAC) :

- Dans **DHCP** / **Réservation d’adresse** (ou équivalent), ajoute une entrée :
  - **Adresse MAC** : tu la récupéreras sur la Pi après la première connexion SSH (voir §4.1).
  - **IP à réserver** : ex. `192.168.1.50` (hors plage dynamique).
  - **Nom** : ex. `homelab-sentinel`.

Tu peux aussi **ne pas** réserver et mettre quand même une IP statique **sur la Pi** : tant que cette IP est hors plage DHCP, ça marche. La réservation Bbox évite juste qu’un autre appareil reçoive la même IP en DHCP.

### 1.4 Ce qu’on ne fait pas pour l’instant

- **Aucune redirection de port** (pas de port 22 vers la Pi, pas d’ouverture vers l’extérieur). Accès uniquement depuis ton réseau local.
- Pas de changement de mot de passe Bbox ni de config WAN.

---

## 2. Côté matériel

- **Raspberry Pi 2**
- **Carte microSD** 16 Go+ (classe 10)
- **Alimentation** 5V micro-USB
- **Câble Ethernet**
- **PC** pour préparer la carte SD

Branchements (après avoir flashé la carte) :

- **Ethernet** : un câble entre le **port Ethernet de la Pi** et un **port LAN de la Bbox** (pas le WAN).
- **Carte SD** dans la Pi, puis **alimentation**.

```
                    Bbox (192.168.1.254)
                         │
    [LAN] ───────────────┼───────────────
         │               │
    Câble Ethernet   Raspberry Pi 2
         │               │
                    eth0 → IP statique (ex. 192.168.1.50)
```

---

## 3. Installer Raspberry Pi OS et activer SSH

### 3.1 Raspberry Pi Imager

- https://www.raspberrypi.com/software/
- Télécharge l’**Imager**, installe-le.
- Choisis **Raspberry Pi OS** (32-bit pour Pi 2), ta **carte microSD**.

### 3.2 Avant d’écrire : options (engrenage)

- **Nom d’hôte** : `homelab-sentinel` (pour te connecter en `ssh pi@homelab-sentinel.local`).
- **Activer SSH** : **Mot de passe** — coche « Activer » et choisis un mot de passe pour l’utilisateur `pi`.
- **Wi‑Fi** : optionnel (on utilise l’Ethernet).
- **Région** : clavier, fuseau, locale.

Puis **Écrire** sur la carte.

### 3.3 Si la carte est déjà flashée sans SSH

- Monte la carte sur le PC, ouvre la partition **boot** (FAT).
- Crée un fichier vide nommé **`ssh`** (sans extension).
- Éjecte la carte, mets-la dans la Pi.

---

## 4. Premier démarrage, trouver la Pi, première connexion SSH

1. Carte SD dans la Pi, **Ethernet** branché sur un **port LAN de la Bbox**, puis **alim**.
2. Attends 1 à 2 minutes.

### 4.1 Trouver l’IP de la Pi

**Option A — Nom d’hôte** (si tu as mis `homelab-sentinel` dans l’Imager)  
Depuis un PC du même réseau :

```bash
ping homelab-sentinel.local
# ou
ping raspberrypi.local
```

L’IP s’affiche dans la réponse (ex. `192.168.1.42`).

**Option B — Liste des appareils sur la Bbox**  
Va sur http://192.168.1.254 → liste des appareils connectés / DHCP. Repère la Pi (nom ou « Raspberry »).

**Option C — Scan** (Linux, avec `nmap`) :

```bash
nmap -sn 192.168.1.0/24
```

### 4.2 Connexion SSH

Remplace `<IP_DE_LA_PI>` par l’IP trouvée (ex. `192.168.1.42`) :

```bash
ssh pi@<IP_DE_LA_PI>
# ou
ssh pi@homelab-sentinel.local
```

À la première connexion, change le mot de passe :

```bash
passwd
```

### 4.3 Récupérer l’adresse MAC de eth0 (pour la Bbox)

Si tu veux réserver l’IP sur la Bbox (§1.3), récupère l’adresse MAC de l’interface **Ethernet** :

```bash
ip link show eth0
```

Tu vois une ligne du type `link/ether aa:bb:cc:dd:ee:ff`. Note cette adresse MAC pour la config DHCP de la Bbox.

---

## 5. IP statique sur l’interface Ethernet (eth0)

On configure **uniquement l’interface Ethernet (eth0)**. Il faut connaître : ton réseau (ex. 192.168.1.0/24), la passerelle (ex. 192.168.1.254), les DNS, et une IP fixe **hors plage DHCP** (ex. 192.168.1.50).

### 5.1 Récupérer passerelle et DNS (sur la Pi en SSH)

```bash
ip route | grep default
cat /etc/resolv.conf
```

Note :

- **Passerelle** : après `default via` (souvent `192.168.1.254`).
- **DNS** : les lignes `nameserver` (souvent `192.168.1.254` ou `8.8.8.8`).

### 5.2 Choisir l’IP fixe

Exemple : réseau `192.168.1.0/24`, passerelle `192.168.1.254`. Choisis une IP hors plage DHCP, par ex. **192.168.1.50**.  
Tu utiliseras : `192.168.1.50/24`, passerelle `192.168.1.254`, DNS `192.168.1.254 8.8.8.8`.

### 5.3 Savoir si la Pi utilise dhcpcd ou NetworkManager

En SSH :

```bash
# Si ce fichier existe et que tu as une section "interface eth0" ou rien qui désactive eth0, c'est souvent dhcpcd
ls -la /etc/dhcpcd.conf

# Si NetworkManager gère le réseau, tu auras une sortie avec des connexions
nmcli con show
```

- **Raspberry Pi OS « classique »** (sans bureau, ou Lite) : en général **dhcpcd**.
- **Raspberry Pi OS avec bureau** (nouvelle version) : parfois **NetworkManager**. Si `nmcli con show` affiche une connexion filaire, utilise la méthode NetworkManager.

### 5.4 Méthode A : dhcpcd (interface eth0 uniquement)

Édite la config :

```bash
sudo nano /etc/dhcpcd.conf
```

Va **à la fin du fichier**. Vérifie qu’il n’y a pas déjà un bloc `interface eth0` qui pourrait écraser le tien. Ajoute (en adaptant si ton réseau n’est pas 192.168.1.x) :

```
# --- Configuration statique pour l'interface Ethernet (eth0) ---
interface eth0
static ip_address=192.168.1.50/24
static routers=192.168.1.254
static domain_name_servers=192.168.1.254 8.8.8.8
```

Sauvegarde : **Ctrl+O**, Entrée, **Ctrl+X**.

Redémarre :

```bash
sudo reboot
```

Attends 1 minute, puis depuis ton PC :

```bash
ping 192.168.1.50
ssh pi@192.168.1.50
```

### 5.5 Méthode B : NetworkManager (interface Ethernet)

Liste les connexions :

```bash
nmcli con show
```

Repère le nom de la connexion **filaire** (ex. `Wired connection 1` ou `Connexion filaire 1`). Remplace `"Wired connection 1"` dans les commandes ci-dessous si besoin.  
Configure l’IP statique **uniquement pour cette connexion** (donc pour l’Ethernet) :

```bash
sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.1.50/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.1.254
sudo nmcli con mod "Wired connection 1" ipv4.dns "192.168.1.254 8.8.8.8"
sudo nmcli con mod "Wired connection 1" ipv4.method manual
sudo nmcli con up "Wired connection 1"
```

Vérifie :

```bash
ip addr show eth0
```

Tu dois voir `192.168.1.50/24`. Depuis ton PC :

```bash
ssh pi@192.168.1.50
```

---

## 6. Récupérer et maîtriser la Pi à distance (dans ton réseau)

Une fois l’IP statique en place :

- **Ping** : depuis n’importe quel appareil du même réseau, `ping 192.168.1.50` (ou `ping homelab-sentinel.local`).
- **SSH** : `ssh pi@192.168.1.50` (ou `ssh pi@homelab-sentinel.local`). C’est ton accès « à distance » dans le LAN.

### 6.1 (Recommandé) Clé SSH pour ne pas taper le mot de passe

Sur **ton PC** (pas sur la Pi) :

```bash
ssh-keygen -t ed25519 -f ~/.ssh/homelab_sentinel -N ""
```

Envoie la clé publique sur la Pi (remplace l’IP si différente) :

```bash
ssh-copy-id -i ~/.ssh/homelab_sentinel.pub pi@192.168.1.50
```

Ensuite tu pourras faire :

```bash
ssh -i ~/.ssh/homelab_sentinel pi@192.168.1.50
```

Ou ajoute dans `~/.ssh/config` sur ton PC :

```
Host homelab
    HostName 192.168.1.50
    User pi
    IdentityFile ~/.ssh/homelab_sentinel
```

Puis simplement : `ssh homelab`.

### 6.2 Checklist finale

- [ ] Bbox : plage DHCP notée ; (optionnel) réservation IP pour la Pi.
- [ ] Pi : Raspberry Pi OS flashé, SSH activé, Ethernet branché sur un port LAN de la Bbox.
- [ ] Première connexion : IP trouvée (Bbox ou `ping homelab-sentinel.local`), `ssh pi@<IP>`, `passwd` fait.
- [ ] IP statique sur **eth0** (dhcpcd ou NetworkManager), redémarrage fait.
- [ ] Après reboot : `ping 192.168.1.50` répond, `ssh pi@192.168.1.50` fonctionne.
- [ ] (Optionnel) Clé SSH et `ssh homelab` depuis ton PC.

---

## 7. Redirection de ports (on ne fait pas pour l’instant)

Pour rester en **mode test** et ne rien casser :

- **Aucune redirection de port** n’est configurée sur la Bbox. La Pi n’est pas exposée sur Internet.
- L’accès « à distance » dont on parle ici = **depuis ton réseau local** (SSH sur l’IP fixe).

Quand tu voudras accéder à la Pi depuis l’extérieur (hors de chez toi), on pourra envisager soit une redirection de port (ex. 22 → Pi), soit un VPN (WireGuard, etc.). Pour l’instant, la base est : Pi en client, IP statique sur eth0, maîtrise en SSH dans le LAN.

---

## 8. Suite possible (plus tard)

- `sudo apt update && sudo apt upgrade -y`
- Installer Docker sur la Pi pour le backend du projet
- Désactiver le Wi‑Fi de la Pi si tu n’utilises que l’Ethernet

Le dossier **openwrt/** du dépôt reste pour plus tard si tu veux un jour faire de la Pi un routeur (avec un dongle USB-Ethernet). Pour l’instant, on ne l’utilise pas.
