# Connexion RDP et VNC à la Raspberry Pi

## RDP (Remmina) : nouvelle session

Avec **xrdp** sur la Pi, une connexion **RDP** ouvre toujours une **nouvelle session** (nouveau bureau). Ce n’est pas un bug : c’est le fonctionnement normal. Tu ne vois pas le même écran qu’en direct sur le HDMI ou qu’en VNC.

- **Pour voir le même écran qu’en direct** (ce qui s’affiche sur la Pi / en VNC) : utilise **VNC** (connexion à 192.168.1.37, port 5900 en général). VNC affiche la session « live ».
- **RDP** : pratique pour avoir une session dédiée (bureau séparé), sans toucher à ce qui tourne sur l’écran physique / VNC.

Résumé : **VNC = rendu direct** ; **RDP = nouvelle session**.

---

## Clavier AZERTY dans la session RDP

La session RDP utilise le clavier configuré **sur la Pi** pour cette session. Pour avoir **AZERTY** :

### Sur la Raspberry Pi (en SSH ou en VNC)

1. **Une fois dans une session** (RDP ou bureau local) :
   ```bash
   setxkbmap fr
   ```
   Le clavier passe en AZERTY pour cette session.

2. **Pour que ce soit permanent** (toutes les sessions, dont RDP) :
   - **Raspberry Pi OS avec bureau** : Menu **Préférences** → **Clavier** → **Disposition** → **French** (ou **France - AZERTY**).
   - Ou ajouter dans le fichier de démarrage de session (ex. `~/.config/autostart/setxkbmap.desktop` ou dans `~/.profile`) :
     ```bash
     setxkbmap fr
     ```

Après ça, en te reconnectant en RDP, la session devrait être en AZERTY (si la disposition par défaut du système est French, ou après avoir lancé `setxkbmap fr` une fois dans la session RDP).

---

## Profil Remmina sur ton PC

Le dépôt contient un profil prêt à l’emploi :

- **Fichier** : `scripts/remmina/Pi-Homelab-192.168.1.37.remmina`
- **Installation** : exécuter `scripts/install_remmina_profile.sh` depuis la racine du dépôt. Le profil est copié dans `~/.local/share/remmina/`. Ouvre Remmina : la connexion **« Pi Homelab (192.168.1.37) »** apparaît. Mot de passe **pavel** à la demande. Résolution du profil : **1920×1080** fixe (pas de scale) pour éviter les artefacts.

---

## Presse-papiers (copier-coller) PC ↔ session RDP

Le profil a le presse-papiers partagé (`disableclipboard=0`). Si le copier-coller ne marche pas : (1) Dans Remmina, paramètres de la connexion → cocher « Partager le presse-papiers ». (2) Fermer la session et se reconnecter. (3) Le texte fonctionne en général ; pour les fichiers utiliser `scp`. (4) Sur la Pi : `sudo apt install -y xrdp && sudo systemctl restart xrdp`.

---

## Remmina ne se reconnecte pas après un reboot de la Pi

Après un **reboot** (par ex. `ssh pavel@192.168.1.37 'sudo reboot'`), Remmina peut refuser de se connecter pendant un moment.

1. **Attendre 1 à 2 minutes** que la Pi ait fini de démarrer (réseau + xrdp).
2. Vérifier que la Pi répond : `ping 192.168.1.37` puis `ssh pavel@192.168.1.37`.
3. Si le **RDP** ne répond toujours pas : en SSH sur la Pi, vérifier xrdp :  
   `sudo systemctl status xrdp`  
   Si le service est inactif ou en erreur :  
   `sudo systemctl restart xrdp`  
   Puis réessayer la connexion Remmina.
