# Travailler sur le projet depuis le PC (Cursor, SSH, Git, make push)

Tu veux **coder le projet** sur ton PC, **déployer sur la Raspberry Pi** avec **`make push`**, et éventuellement **éditer ou lancer des commandes sur la Pi** en SSH. Le backend sur la Pi tourne en **Docker**.

---

## Limitation : Cursor Remote SSH ne marche pas sur Raspberry Pi 2

**Cursor Remote SSH** installe un « Cursor Server » sur la machine distante. Ce serveur **ne supporte pas l’architecture armv7l** (Raspberry Pi 2). En te connectant à la Pi avec Remote SSH, tu obtiens :

```text
Architecture not supported: armv7l
Couldn't install Cursor Server, install script returned non-zero exit status
```

Donc : **ne pas utiliser Cursor Remote SSH vers la Pi 2**. À la place, tu travailles **sur le PC** (Cursor ouvre le dépôt local) et tu déploies avec **`make push`**.

---

## Workflow recommandé : coder sur le PC, déployer sur la Pi

1. **Sur ton PC** : ouvre **Cursor** et le dossier **`homelab-sentinel`** (le dépôt cloné sur ton PC).
2. Tu codes, tu fais **git commit / git push** comme d’habitude (Git et GitHub restent sur le PC).
3. Pour envoyer le code **vers la Pi** et redémarrer le backend : à la racine du dépôt sur le PC :
   ```bash
   make push
   ```
   (ou **`make update`**, ou l’alias **`homelab-push`** si tu l’as configuré.)

La Pi reçoit tout le projet (rsync) et le backend Docker redémarre. Pas besoin d’ouvrir la Pi dans Cursor.

---

## 1. Config SSH sur le PC (pour `ssh pi-homelab`)

Même sans Cursor Remote SSH, la config **`pi-homelab`** dans **`~/.ssh/config`** est utile : terminal, commandes à distance, et édition en SSH (nano/vim). Elle **ne modifie pas** GitHub.

### Éditer `~/.ssh/config` sur le PC

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
nano ~/.ssh/config
```

Ajoute **à la fin** du fichier :

```sshconfig
Host pi-homelab
    HostName 192.168.1.37
    User pavel
    Port 22
    IdentityFile ~/.ssh/id_ed25519
```

- Clé **id_rsa** → `IdentityFile ~/.ssh/id_rsa`.
- Pas de clé pour la Pi → enlève la ligne `IdentityFile`.

Puis : `chmod 600 ~/.ssh/config`.

### Tester GitHub sur le PC

Utilise **`-T`** (majuscule), **pas** `-t` (minuscule) :

```bash
ssh -T git@github.com
```

Avec **`-t`** tu as « PTY allocation request failed » ; avec **`-T`** tu vois le message GitHub d’authentification.

### Tester la connexion à la Pi

```bash
ssh pi-homelab
```

Tu dois être connecté à la Pi.

---

## 2. Éditer des fichiers ou lancer des commandes sur la Pi

Comme **Cursor Remote SSH ne fonctionne pas** sur la Pi 2, tu peux :

- **En SSH** : `ssh pi-homelab`, puis éditer avec **nano** ou **vim** (`nano ~/homelab-sentinel/backend/app/main.py` par ex.), ou lancer des commandes (logs Docker, restart, etc.).
- **En bureau à distance** : **VNC** ou **Remmina (RDP)** vers 192.168.1.37, puis ouvrir un éditeur graphique sur la Pi (Geany, etc.) si tu en installes un.

Pour le projet homelab-sentinel, le flux normal reste : **éditer sur le PC dans Cursor** → **`make push`** pour déployer sur la Pi.

---

## 3. Git et GitHub sur la Raspberry Pi (optionnel)

Utile si tu veux faire un **git pull** ou **git push** **depuis la Pi** (en SSH, en ligne de commande), par exemple après avoir modifié un fichier en nano sur la Pi.

### 3.1 Clé SSH sur la Pi

Sur la Pi (`ssh pi-homelab` puis) :

```bash
ssh-keygen -t ed25519 -C "pavel@raspberry-homelab" -f ~/.ssh/id_ed25519 -N ""
cat ~/.ssh/id_ed25519.pub
```

Colle la clé publique dans **GitHub → Settings → SSH and GPG keys → New SSH key**.

### 3.2 Tester GitHub depuis la Pi

Sur la Pi :

```bash
ssh -T git@github.com
```

(**T** majuscule.)

### 3.3 Config Git sur la Pi

```bash
git config --global user.name "Ton nom ou pseudo"
git config --global user.email "ton-email@example.com"
```

### 3.4 Remote Git sur la Pi (si besoin)

Si `~/homelab-sentinel` sur la Pi vient de **make sync** / **make install**, il n’a souvent pas de remote. Pour push depuis la Pi :

```bash
cd ~/homelab-sentinel
git remote -v
# Si pas d'origin :
git remote add origin git@github.com:PavelDelhomme/homelab-sentinel.git
```

Ensuite tu peux faire **git push** depuis la Pi (en SSH, en ligne de commande). La source de vérité reste en général le dépôt sur ton PC ; **make push** envoie le code du PC vers la Pi.

---

## 4. Pousser les mises à jour du projet (PC → Pi)

À la racine du dépôt **sur ton PC** :

```bash
make push
```
ou
```bash
make update
```

### Alias (sur le PC)

Dans `~/.zshrc` ou `~/.bashrc` :

```bash
alias homelab-push='cd /home/pactivisme/Documents/Dev/Perso/homelab/homelab-sentinel && make push'
```

Puis : **`homelab-push`** pour déployer sur la Pi.

### Cron (optionnel)

```bash
crontab -e
```

Exemple (tous les jours à 8h) :

```cron
0 8 * * * cd /home/pactivisme/Documents/Dev/Perso/homelab/homelab-sentinel && make push
```

---

## 5. Récap

| Élément | Détail |
|--------|--------|
| **Cursor Remote SSH** | **Ne fonctionne pas sur Raspberry Pi 2** (armv7l non supporté). Ne pas l’utiliser vers la Pi. |
| **Où coder** | **Sur le PC** : Cursor ouvre le dossier **homelab-sentinel** (dépôt local). Git commit / push sur le PC. |
| **Déployer sur la Pi** | **`make push`** ou **`make update`** (ou alias **homelab-push**) depuis le PC. |
| **SSH vers la Pi** | Config **Host pi-homelab** dans **`~/.ssh/config`** → **`ssh pi-homelab`** pour terminal, nano/vim, commandes. N’affecte pas GitHub. |
| **GitHub sur le PC** | Test : **`ssh -T git@github.com`** (T majuscule). |
| **Git sur la Pi** | Optionnel : clé SSH sur la Pi, ajoutée à GitHub, `git config`, `git remote add origin` si tu veux push depuis la Pi en ligne de commande. |

En résumé : **tu codes dans Cursor sur le PC**, tu déploies avec **`make push`**. Pour agir sur la Pi, utilise **`ssh pi-homelab`** (et éventuellement VNC/Remmina), pas Cursor Remote SSH.
