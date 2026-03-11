# Premiers pas complets : Raspberry Pi de base → accès à distance (SSH + RDP, IP statique)

Tu as : **une Raspberry Pi de base**, **l’OS** (Raspberry Pi OS), un **câble Ethernet**. Tu es sur **ton ordinateur fixe**. Ce guide détaille **tout ce que tu dois faire** pour arriver à : Pi connectée à la box, **IP statique**, **SSH** et **RDP** actifs **à chaque démarrage**, pour y accéder de loin depuis ton réseau.

---

## Ce que tu obtiens à la fin

- Pi branchée en Ethernet sur la box (Bbox).
- **IP statique** (ex. 192.168.1.50) : même adresse après chaque redémarrage.
- **SSH** activé au démarrage : tu peux te connecter en ligne de commande depuis ton PC.
- **RDP** (xrdp) activé au démarrage : tu peux ouvrir le bureau de la Pi à distance depuis ton PC.
- Aucune manipulation à refaire après un reboot de la Pi.

---

## Étape 1 — Sur ton PC : préparer la carte SD

1. Insère la **carte microSD** dans ton PC (lecteur ou adaptateur).
2. Ouvre **Raspberry Pi Imager** : https://www.raspberrypi.com/software/
3. Choisis :
   - **Système d’exploitation** : **Raspberry Pi OS** (32-bit pour Pi 2).
   - **Stockage** : ta carte microSD.
4. Clique sur **Paramètres** (engrenage) et configure :
   - **Nom d’hôte** : `homelab-sentinel` (pour te connecter plus tard en `homelab-sentinel.local`).
   - **Activer SSH** : coche « Activer », utilise **Authentification par mot de passe** et choisis un **mot de passe pour l’utilisateur `pi`** (note-le).
   - **Région** : clavier, fuseau horaire, locale si tu veux.
5. Clique sur **Enregistrer** puis **Écrire**. Attends la fin, éjecte la carte.

---

## Étape 2 — Brancher la Pi et la démarrer

1. Insère la **carte SD** dans la Raspberry Pi.
2. Branche le **câble Ethernet** : un côté dans le **port Ethernet de la Pi**, l’autre dans un **port LAN de la box** (pas le port WAN / Internet).
3. Branche l’**alimentation** 5V micro-USB sur la Pi.
4. Attends **1 à 2 minutes** que la Pi démarre et reçoive une IP de la box.

---

## Étape 3 — Depuis ton PC : trouver l’IP de la Pi

Ouvre un terminal sur ton PC.

**Option A — Nom d’hôte** (si tu as mis `homelab-sentinel` à l’étape 1) :

```bash
ping homelab-sentinel.local
```

L’IP s’affiche (ex. `192.168.1.42`). Note-la.

**Option B — Interface de la box**  
Va sur **http://192.168.1.254**, connecte-toi, ouvre la liste des appareils connectés / DHCP et repère la Pi (nom ou « Raspberry »). Note son IP.

**Option C — Scan réseau** (Linux, avec `nmap`) :

```bash
nmap -sn 192.168.1.0/24
```

Repère l’IP de la Pi dans la liste.

---

## Étape 4 — Depuis ton PC : première connexion SSH

Dans le terminal (remplace `<IP_PI>` par l’IP notée à l’étape 3) :

```bash
ssh pi@<IP_PI>
```

Exemple : `ssh pi@192.168.1.42`. À la première connexion, accepte l’empreinte (tape `yes`). Entre le mot de passe de l’utilisateur `pi` (celui choisi dans l’Imager).

Une fois connecté, change le mot de passe si tu veux :

```bash
passwd
```

Tu es maintenant **sur la Pi en SSH**.

---

## Étape 5 — Sur la Pi (en SSH) : IP statique

Tu dois configurer une **IP fixe** pour l’interface **Ethernet (eth0)**. D’abord récupère la passerelle et les DNS :

```bash
ip route | grep default
cat /etc/resolv.conf
```

Note la **passerelle** (souvent `192.168.1.254`) et les **DNS** (souvent `192.168.1.254` ou `8.8.8.8`).  
Choisis une **IP hors plage DHCP** de la box (ex. `192.168.1.50` si ta box donne du .10 au .199). Tu utiliseras : `192.168.1.50/24`, passerelle `192.168.1.254`, DNS `192.168.1.254 8.8.8.8`.

**Méthode dhcpcd** (Raspberry Pi OS classique) :

```bash
sudo nano /etc/dhcpcd.conf
```

Va à la **fin du fichier** et ajoute (adapte si ton réseau n’est pas 192.168.1.x) :

```
interface eth0
static ip_address=192.168.1.50/24
static routers=192.168.1.254
static domain_name_servers=192.168.1.254 8.8.8.8
```

Sauvegarde : **Ctrl+O**, Entrée, **Ctrl+X**.

**Redémarre la Pi** :

```bash
sudo reboot
```

Attends 1 minute. Ta Pi a maintenant l’IP fixe (ex. 192.168.1.50). Reconnecte-toi depuis ton PC :

```bash
ssh pi@192.168.1.50
```

(Remplace par ton IP si différente.)

---

## Étape 6 — Sur la Pi (en SSH) : SSH et RDP au démarrage

Tu es reconnecté en SSH avec l’IP statique. Active **SSH** et **RDP** pour qu’ils démarrent à chaque boot.

### 6.1 SSH à chaque démarrage

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

### 6.2 RDP (xrdp) à chaque démarrage

```bash
sudo apt update
sudo apt install -y xrdp
sudo systemctl enable xrdp
sudo systemctl start xrdp
```

Vérifie :

```bash
sudo systemctl status ssh
sudo systemctl status xrdp
```

Les deux doivent afficher `enabled` et `active (running)`.

---

## Étape 7 — Depuis ton PC : tester l’accès à distance

- **SSH** : `ssh pi@192.168.1.50` (remplace par ton IP). Ça doit marcher à chaque démarrage de la Pi.
- **RDP** : ouvre un client RDP sur ton PC :
  - **Windows** : `Win + R` → `mstsc` → adresse `192.168.1.50`.
  - **Linux** : Remmina, protocole RDP, serveur `192.168.1.50`, utilisateur `pi`, mot de passe.
  Connexion : port **3389**, utilisateur **pi**, mot de passe de la Pi. Si l’écran est gris, choisis la session **Xorg** sur l’écran de login xrdp.

Après un **redémarrage de la Pi** : attends 1–2 minutes, puis reconnecte-toi en SSH ou en RDP à la même IP. Rien à reconfigurer.

---

## Récap : ordre des étapes

| # | Où | Action |
|---|-----|--------|
| 1 | PC | Imager : flash Raspberry Pi OS sur SD, activer SSH, mot de passe `pi`, nom d’hôte `homelab-sentinel`. |
| 2 | Physique | Carte SD dans la Pi, Ethernet Pi → LAN box, alim. |
| 3 | PC | Trouver l’IP de la Pi (ping, Bbox, ou scan). |
| 4 | PC | `ssh pi@<IP>`, premier login, optionnel `passwd`. |
| 5 | Pi (SSH) | IP statique dans `/etc/dhcpcd.conf` (eth0), `sudo reboot`. |
| 6 | Pi (SSH) | Reconnect avec IP fixe ; `systemctl enable --now ssh` et `apt install xrdp` + `systemctl enable --now xrdp`. |
| 7 | PC | Tester `ssh pi@192.168.1.50` et client RDP vers 192.168.1.50. |

---

## Docs détaillées

- **Câblage, Bbox, détail IP statique** : [pi_client_box.md](pi_client_box.md).
- **SSH + RDP (xrdp), clients RDP, dépannage** : [raspberry_ssh_rdp_acces_distant.md](raspberry_ssh_rdp_acces_distant.md).
