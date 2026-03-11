# PC fixe : Bluetooth au démarrage + Logitech (Craft, MX Master 3)

Ce que tu as fait pour que le **Bluetooth démarre au démarrage** et pour **vérifier / connecter** les appareils Logitech (Craft, MX Master 3) sur ton PC fixe (Arch Linux).

---

## 1. Bluetooth au démarrage

- **Service** : `bluetooth.service` est **activé** (`sudo systemctl enable bluetooth`). Il démarre à chaque boot.
- **Contrôleur allumé** : dans `/etc/bluetooth/main.conf`, l’option **`AutoEnable=true`** est activée. Au démarrage du service, le contrôleur Bluetooth est mis sous tension automatiquement ; tu n’as rien à lancer à la main.

Si après un reboot le Bluetooth ne semble pas actif :

```bash
sudo systemctl status bluetooth
bluetoothctl show
```

Si `Powered: no`, allume-le une fois : `bluetoothctl power on`. Avec `AutoEnable=true`, normalement c’est déjà allumé.

---

## 2. Vérifier que le Bluetooth fonctionne

```bash
# État du service
sudo systemctl status bluetooth

# Contrôleur : doit être Powered: yes, Pairable: yes
bluetoothctl show

# Allumer le contrôleur si besoin
bluetoothctl power on

# Rendre la machine visible/appairable
bluetoothctl pairable on
bluetoothctl discoverable on
```

---

## 3. Connecter les Logitech (Craft, MX Master 3)

Les deux appareils se connectent en **Bluetooth** comme deuxième appareil (multi-device). Même procédure pour chacun.

### 3.1 Mettre le clavier / la souris en mode appairage

- **Logitech Craft** : bascule sur le canal **2** (bouton 1/2/3) si tu utilises le canal 2 pour ce PC, puis maintenir la touche **Bluetooth** (ou le combi indiqué dans la notice) jusqu’à ce que le voyant clignote (mode appairage).
- **MX Master 3** : bouton **au-dessus de la molette** ou **sous la souris** pour basculer sur le canal 2, puis maintenir le bouton **Bluetooth** jusqu’au clignotement (mode appairage).

(Réfère-toi à la notice Logitech pour le détail selon le modèle.)

### 3.2 Sur le PC : scan, appairage, connexion

```bash
bluetoothctl
```

Dans `bluetoothctl` :

```text
power on
pairable on
scan on
```

Attends que **Craft** et **MX Master 3** apparaissent (adresse MAC du type `XX:XX:XX:XX:XX:XX`). Note les MAC si besoin.

Pour **chaque** appareil (remplace `XX:XX:XX:XX:XX:XX` par l’adresse affichée) :

```text
pair XX:XX:XX:XX:XX:XX
trust XX:XX:XX:XX:XX:XX
connect XX:XX:XX:XX:XX:XX
```

Puis arrête le scan :

```text
scan off
quit
```

### 3.3 Vérifier la connexion

```bash
bluetoothctl devices
bluetoothctl info XX:XX:XX:XX:XX:XX
```

Pour un appareil connecté, tu dois voir `Connected: yes`.

---

## 4. Résumé des commandes utiles

| Action | Commande |
|--------|----------|
| État du service | `sudo systemctl status bluetooth` |
| État du contrôleur | `bluetoothctl show` |
| Allumer le contrôleur | `bluetoothctl power on` |
| Lancer l’appairage (CLI) | `bluetoothctl` puis `scan on`, `pair <MAC>`, `trust <MAC>`, `connect <MAC>` |
| Liste des appareils | `bluetoothctl devices` |
| Infos d’un appareil | `bluetoothctl info <MAC>` |

Avec **AutoEnable=true** et le service **bluetooth** activé, au prochain démarrage du PC le Bluetooth sera déjà actif et tu pourras te connecter aux Logitech (Craft, MX Master 3) comme deuxième appareil sans rien reconfigurer.
