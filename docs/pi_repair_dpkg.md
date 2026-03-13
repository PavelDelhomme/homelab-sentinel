# Réparer dpkg/apt après un upgrade cassé sur la Raspberry Pi

Si après un `sudo apt upgrade` (ou une mise à jour interrompue) tu as des erreurs avec des paquets comme **adduser, systemd, dbus, udev, bluez, xserver-xorg-core**, etc., suis ces étapes **sur la Pi** (en SSH ou en direct).

## 0. Erreur « dpkg frontend lock was locked by another process »

Si **make bootstrap** ou un script échoue avec un message du type *« dpkg frontend lock was locked by another process with pid XXXX »* :

- **Ne pas supprimer** les fichiers de verrou (`/var/lib/dpkg/lock`, `lock-frontend`) : ça peut casser le système.
- Un autre processus (souvent **apt**, **unattended-upgrades** ou un **make install** en cours) utilise dpkg. **Attendez 2 à 5 minutes** que ce processus se termine.
- Pour voir quel processus tient le verrou (sur la Pi en SSH) :
  ```bash
  sudo fuser -v /var/lib/dpkg/lock-frontend
  ```
- Ensuite **relancez make bootstrap** (ou le script) quand plus aucun apt/dpkg ne tourne. Si un processus reste bloqué, redémarrez la Pi puis relancez.

## 1. Connexion à la Pi

En général SSH fonctionne même si l’upgrade a planté. Depuis ton PC :

```bash
ssh pavel@192.168.1.37
```

## 2. Réparation de base (à faire en premier)

```bash
export DEBIAN_FRONTEND=noninteractive
sudo dpkg --configure -a
sudo apt-get -f install -y
sudo apt-get update
```

Si **tout passe**, tu as fini. Sinon, continue.

## 2b. adduser : « post-installation script subprocess was killed by signal (Segmentation fault) »

Sur **Raspberry Pi 2** (1 Go de RAM), le script post-installation du paquet **adduser** peut planter en segfault pendant `dpkg --configure -a`. Toute la chaîne (adduser → systemd → dbus → udev → …) reste alors bloquée. Souvent c’est un **manque de mémoire** pendant la configuration.

**À faire :**

1. **Ajouter un fichier swap** sur la Pi (1 Go) pour donner plus de mémoire virtuelle pendant dpkg. Depuis ton **PC** (à la racine du dépôt homelab-sentinel) :
   ```bash
   ssh pavel@192.168.1.37 'sudo bash -s' < scripts/pi_add_swap.sh
   ```
   Ou envoyer le script puis l’exécuter sur la Pi :
   ```bash
   scp scripts/pi_add_swap.sh pavel@192.168.1.37:~/
   ssh pavel@192.168.1.37 'chmod +x ~/pi_add_swap.sh && sudo ~/pi_add_swap.sh'
   ```
   Ou sur la Pi en SSH (si le dépôt est déjà syncé dans ~/homelab-sentinel) :
   ```bash
   sudo ~/homelab-sentinel/scripts/pi_add_swap.sh
   ```

2. **Redémarrer la Pi** pour repartir à froid : `ssh pavel@192.168.1.37 'sudo reboot'`. Attendre 2 min.

3. **Relancer la réparation** (sur la Pi en SSH) :
   ```bash
   export DEBIAN_FRONTEND=noninteractive
   sudo dpkg --configure -a
   sudo apt-get -f install -y
   sudo apt-get update
   ```
   Avec le swap, le postinst d’adduser a plus de chances de passer sans segfault.

4. Si **ça segfault encore** : une fois le swap actif, réessayer après un reboot. En dernier recours : réinstallation propre de Raspberry Pi OS (sauvegarder les données avant).

## 3. Si des paquets restent en erreur

Certains paquets (surtout **systemd**, **dbus**, **udev**) doivent être configurés dans un ordre précis. Essaie dans cet ordre :

```bash
export DEBIAN_FRONTEND=noninteractive
sudo dpkg --configure udev
sudo dpkg --configure dbus
sudo dpkg --configure dbus-x11
sudo dpkg --configure dbus-user-session
sudo dpkg --configure libpam-systemd:armhf
sudo dpkg --configure systemd
sudo dpkg --configure systemd-timesyncd
sudo dpkg --configure adduser
sudo dpkg --configure ifupdown
sudo dpkg --configure xserver-xorg-core
sudo dpkg --configure bluez
```

Puis :

```bash
sudo dpkg --configure -a
sudo apt-get -f install -y
```

## 4. Si une config demande une question (prompt)

Pour forcer la réponse par défaut et éviter que le script bloque :

```bash
export DEBIAN_FRONTEND=noninteractive
sudo -E dpkg --configure -a
```

Pour un paquet précis (ex. bluez) avec choix par défaut :

```bash
sudo DEBIAN_FRONTEND=noninteractive dpkg --configure bluez
```

## 5. Vérifier l’état

```bash
sudo dpkg --audit
apt list --broken 2>/dev/null
```

S’il n’y a plus de paquets « broken » ou « half-configured », tu peux refaire :

```bash
sudo apt update && sudo apt upgrade -y
```

## 6. Script automatique (dépôt)

Le script **`scripts/pi_repair_dpkg.sh`** enchaîne les étapes 2 et 3. À lancer **sur la Pi** avec :

```bash
sudo ./pi_repair_dpkg.sh
```

Depuis ton PC (envoi + exécution sur la Pi) :

```bash
scp scripts/pi_repair_dpkg.sh pavel@192.168.1.37:~/
ssh pavel@192.168.1.37 'chmod +x ~/pi_repair_dpkg.sh && sudo ~/pi_repair_dpkg.sh'
```

## En cas d’échec persistant

- **Redémarrer la Pi** après les étapes 2–3, puis relancer `sudo dpkg --configure -a` et `sudo apt -f install`.
- Si un **seul** paquet pose problème : noter le message d’erreur (souvent un `postinst` ou `trigger` qui échoue), chercher ce message sur le web (ex. « dpkg bluez postinst failed ») pour une solution ciblée.
- En dernier recours : sauvegarder tes données puis réinstaller Raspberry Pi OS (ou restaurer une image SD de backup).
