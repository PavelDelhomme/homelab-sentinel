# Raspberry Pi : config complète accès à distance (SSH + RDP)

Guide pour tout configurer sur la **Raspberry Pi** : IP statique, SSH et **RDP** (bureau à distance), avec démarrage automatique du serveur RDP à chaque boot. Après un redémarrage de la Pi, tu peux te reconnecter en SSH ou en RDP sans rien refaire.

---

## Vue d’ensemble

| Élément | Rôle |
|--------|------|
| **IP statique** | La Pi garde toujours la même adresse (ex. 192.168.1.50) pour SSH et RDP. |
| **SSH** | Accès en ligne de commande à chaque démarrage. |
| **RDP (xrdp)** | Bureau graphique à distance ; le service démarre à chaque boot. |
| **Client RDP** | Logiciel sur ton PC pour te connecter (Remmina, Bureau à distance Windows, etc.). |

Référence câblage + première connexion : [pi_client_box.md](pi_client_box.md).

---

## 1. Prérequis

- Raspberry Pi branchée sur la Bbox en Ethernet.
- Tu as déjà fait au moins une connexion SSH (sinon suis [pi_client_box.md](pi_client_box.md) pour le premier boot et l’IP statique).

On suppose dans la suite que la Pi a une **IP statique** (ex. `192.168.1.50`) et que tu peux faire `ssh pi@192.168.1.50`. Si ce n’est pas encore fait, configure l’IP statique comme dans [pi_client_box.md](pi_client_box.md) §5.

---

## 2. SSH : activé à chaque démarrage

Sur Raspberry Pi OS, SSH est géré par `systemd`. Pour qu’il soit actif à chaque démarrage :

```bash
sudo systemctl enable ssh
sudo systemctl start ssh
sudo systemctl status ssh
```

Vérifie que `Enabled` et `active (running)`. Ensuite, à chaque boot de la Pi, tu pourras faire :

```bash
ssh pi@192.168.1.50
```

(Remplace l’IP par la tienne.)

---

## 3. RDP : installer et activer à chaque démarrage

On utilise **xrdp** : serveur RDP sur la Pi. Après installation et activation du service, il démarre à chaque boot — tu pourras te connecter en bureau graphique dès que la Pi a redémarré.

### 3.1 Installer xrdp (sur la Pi, en SSH)

```bash
sudo apt update
sudo apt install -y xrdp
```

### 3.2 Activer le service xrdp au démarrage

```bash
sudo systemctl enable xrdp
sudo systemctl start xrdp
sudo systemctl status xrdp
```

Vérifie : `Loaded: ... enabled` et `Active: active (running)`.

### 3.3 (Optionnel) xrdp sur Raspberry Pi OS avec Wayland

Si tu utilises Raspberry Pi OS avec bureau (Bullseye/Bookworm) et session **Wayland**, xrdp peut ne pas afficher le bureau correctement. Dans ce cas, deux options :

**Option A — Passer la session en X11** (recommandé pour RDP)  
À la connexion (écran de login sur la Pi), clique sur l’icône engrenage ou « Session » et choisis **X11** (ou **Xorg**) au lieu de Wayland. Puis connecte-toi. Ensuite les connexions RDP utiliseront ce bureau X11.

**Option B — Utiliser une session X11 uniquement pour xrdp**  
Tu peux configurer xrdp pour lancer une session X11 dédiée. Si besoin, on peut détailler dans une prochaine version du guide.

### 3.4 Vérifier le port RDP

xrdp écoute par défaut sur le port **3389**. Pour vérifier :

```bash
ss -tlnp | grep 3389
# ou
sudo systemctl status xrdp
```

---

## 4. Se connecter en RDP depuis ton PC

Une fois xrdp installé et le service actif, depuis **n’importe quel appareil** sur ton réseau (Windows, Linux, Mac) tu ouvres un **client RDP** et tu te connectes à l’IP de la Pi.

### 4.1 Logiciels client RDP

| OS | Logiciel | Remarque |
|----|----------|----------|
| **Windows** | Bureau à distance (mstsc) | Intégré : `Win + R` → `mstsc` → entrer l’IP de la Pi. |
| **Linux** | **Remmina** | `sudo apt install remmina remmina-plugin-rdp` (Debian/Ubuntu) ou équivalent. |
| **Linux** | **FreeRDP** (ligne de commande) | `xfreerdp /v:192.168.1.50 /u:pi` |
| **macOS** | Microsoft Remote Desktop (App Store) | Ou « Bureau à distance » depuis le Mac. |

### 4.2 Paramètres de connexion

- **Adresse** : IP statique de la Pi (ex. `192.168.1.50`).
- **Port** : `3389` (par défaut, souvent pré-rempli).
- **Utilisateur** : `pi` (ou l’utilisateur que tu as créé sur la Pi).
- **Mot de passe** : le mot de passe de l’utilisateur `pi` sur la Pi.

Exemple sous Windows : Ouvre « Connexion Bureau à distance », saisis `192.168.1.50`, valide. Quand la fenêtre xrdp s’affiche, choisis **Xorg** si proposé, puis login `pi` + mot de passe.

Exemple sous Linux (Remmina) : Nouvelle connexion, protocole **RDP**, serveur `192.168.1.50`, utilisateur `pi`, mot de passe. Enregistre la session pour la reprendre en un clic.

---

## 5. Récapitulatif : ce qui est actif à chaque démarrage

Après avoir tout configuré :

| Service | Commande pour vérifier | Au démarrage |
|---------|------------------------|--------------|
| **SSH** | `sudo systemctl status ssh` | Activé (enable + start) |
| **xrdp** | `sudo systemctl status xrdp` | Activé (enable + start) |
| **IP statique** | `ip addr show eth0` | Configurée dans `/etc/dhcpcd.conf` ou NetworkManager |

Si la Pi redémarre, tu n’as rien à refaire : attendre 1–2 minutes puis te connecter en SSH ou en RDP à la même IP.

---

## 6. Commandes utiles (sur la Pi)

```bash
# Voir l’IP de la Pi (eth0)
ip addr show eth0

# Vérifier SSH
sudo systemctl status ssh

# Vérifier xrdp
sudo systemctl status xrdp

# Redémarrer xrdp si besoin
sudo systemctl restart xrdp
```

---

## 7. Checklist complète

- [ ] Pi connectée à la Bbox en Ethernet, IP statique configurée (voir [pi_client_box.md](pi_client_box.md)).
- [ ] SSH activé et démarré : `sudo systemctl enable --now ssh`.
- [ ] xrdp installé : `sudo apt install -y xrdp`.
- [ ] xrdp activé au démarrage : `sudo systemctl enable --now xrdp`.
- [ ] Sur la Pi (session locale) : session en X11 si besoin pour que RDP affiche le bureau.
- [ ] Sur ton PC : client RDP installé (Remmina, mstsc, etc.), connexion testée à `192.168.1.50` (ou ton IP) avec l’utilisateur `pi`.
- [ ] Après un reboot de la Pi : reconnexion SSH et RDP possibles sans reconfig.

---

## 8. Dépannage rapide

| Problème | Piste |
|----------|--------|
| RDP « connexion refusée » | Vérifier `sudo systemctl status xrdp` et `ss -tlnp | grep 3389`. |
| Écran gris ou vide en RDP | Utiliser la session **X11** sur la Pi (pas Wayland) pour la connexion graphique. |
| SSH ne démarre pas | `sudo systemctl enable ssh` puis `sudo systemctl start ssh`. Vérifier le pare-feu si tu en as un. |
| Pi injoignable après reboot | Vérifier le câble Ethernet, la Bbox, et que l’IP statique est bien celle attendue (`ip addr show eth0`). |
