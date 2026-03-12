# Réparer dpkg/apt après un upgrade cassé sur la Raspberry Pi

Si après un `sudo apt upgrade` (ou une mise à jour interrompue) tu as des erreurs avec des paquets comme **adduser, systemd, dbus, udev, bluez, xserver-xorg-core**, etc., suis ces étapes **sur la Pi** (en SSH ou en direct).

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
