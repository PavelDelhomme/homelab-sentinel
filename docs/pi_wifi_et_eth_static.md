# Raspberry Pi : WiFi statique + Ethernet (eth0) statique (pas encore branché en câble)

Tu n’es **pas encore connecté en Ethernet** : tu utilises le **WiFi** pour l’instant. Ce guide décrit comment configurer une **IP statique sur le WiFi (wlan0)** et préparer en avance l’**IP statique sur l’Ethernet (eth0)** pour quand tu brancheras le câble. Comme ça, une seule config à faire : WiFi statique maintenant, eth0 statique déjà prête pour plus tard.

**Contexte** : Pi avec une interface WiFi (wlan0) et une Ethernet (eth0). Pour l’instant seul le WiFi est utilisé ; eth0 sera branché plus tard.

---

## 1. Réseau à utiliser

À noter (depuis la Bbox ou en regardant une config DHCP actuelle) :

- **Réseau** : ex. `192.168.1.0/24`
- **Passerelle** : ex. `192.168.1.254`
- **DNS** : ex. `192.168.1.254` ou `8.8.8.8`
- **Plage DHCP** : ex. .10–.199 → tu choisis des IP **hors** de cette plage.

Exemple d’IP à utiliser (à adapter) :

- **WiFi (wlan0)** : `192.168.1.51` (pour la connexion actuelle).
- **Ethernet (eth0)** : `192.168.1.50` (pour quand tu brancheras le câble).

---

## 2. Méthode dhcpcd (Raspberry Pi OS classique)

Tu édites **un seul fichier** : `/etc/dhcpcd.conf`. Tu y mets la config statique pour **wlan0** et pour **eth0**. Même si eth0 n’est pas branché, dhcpcd appliquera la config dès que l’interface sera active.

En SSH sur la Pi :

```bash
sudo nano /etc/dhcpcd.conf
```

À la **fin du fichier**, ajoute (adapte les IP, passerelle et DNS si besoin) :

```
# --- WiFi : IP statique (connexion actuelle) ---
interface wlan0
static ip_address=192.168.1.51/24
static routers=192.168.1.254
static domain_name_servers=192.168.1.254 8.8.8.8

# --- Ethernet : IP statique (pour quand tu brancheras le câble) ---
interface eth0
static ip_address=192.168.1.50/24
static routers=192.168.1.254
static domain_name_servers=192.168.1.254 8.8.8.8
```

Sauvegarde : **Ctrl+O**, Entrée, **Ctrl+X**.

Redémarre la Pi :

```bash
sudo reboot
```

Après redémarrage :

- En **WiFi** : la Pi aura l’IP `192.168.1.51`. Tu te connectes en `ssh pi@192.168.1.51`.
- Quand tu **brancheras l’Ethernet** (sans couper le WiFi si tu veux) : eth0 aura l’IP `192.168.1.50`. Tu pourras aussi faire `ssh pi@192.168.1.50`.

---

## 3. Méthode NetworkManager (si la Pi utilise nmcli)

Si `nmcli con show` affiche des connexions (WiFi et filaire), configure les deux.

**WiFi (remplace le nom de la connexion si besoin)** :

```bash
nmcli con show
# Repère le nom de la connexion WiFi (ex. "Wi-Fi" ou "raspberrypi")

sudo nmcli con mod "Wi-Fi" ipv4.addresses 192.168.1.51/24
sudo nmcli con mod "Wi-Fi" ipv4.gateway 192.168.1.254
sudo nmcli con mod "Wi-Fi" ipv4.dns "192.168.1.254 8.8.8.8"
sudo nmcli con mod "Wi-Fi" ipv4.method manual
sudo nmcli con up "Wi-Fi"
```

**Ethernet (pour plus tard)** :

```bash
# Repère le nom de la connexion filaire (ex. "Wired connection 1" ou "eth0")
sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.1.50/24
sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.1.254
sudo nmcli con mod "Wired connection 1" ipv4.dns "192.168.1.254 8.8.8.8"
sudo nmcli con mod "Wired connection 1" ipv4.method manual
# Ne pas faire "up" si le câble n’est pas branché ; la config sera utilisée quand tu brancheras.
```

---

## 4. Vérifier

En WiFi (sans câble branché) :

```bash
ip addr show wlan0
# Tu dois voir 192.168.1.51/24
```

Quand le câble Ethernet est branché :

```bash
ip addr show eth0
# Tu dois voir 192.168.1.50/24
```

---

## 5. RDP et SSH

Une fois l’IP statique en place (WiFi et/ou Ethernet), tu actives SSH et RDP comme dans [raspberry_ssh_rdp_acces_distant.md](raspberry_ssh_rdp_acces_distant.md). Tu te connectes à l’IP correspondante :

- En WiFi seulement : `ssh pi@192.168.1.51` et RDP vers `192.168.1.51`.
- Une fois l’Ethernet branché : `ssh pi@192.168.1.50` et RDP vers `192.168.1.50` (ou garde le WiFi si tu préfères).
