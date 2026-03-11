# Backend HomeLab API

API FastAPI : devices, énergie, caméras, gamelle, auth, automations. Voir le [guide à la racine](../guide_domotique_complet.md) section 9.

## Lancer en local

```bash
python -m venv .venv
source .venv/bin/activate   # ou .venv\Scripts\activate sur Windows
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 5500
```

Docs : http://localhost:5500/api/docs (si `DEBUG=true`).

## Lancer avec Docker

```bash
docker compose up -d
```

L’API est sur le port 5500, PostgreSQL et Mosquitto sont démarrés. Créer les dossiers `mosquitto/config` et `mosquitto/data` si besoin (un `mosquitto/config/mosquitto.conf` minimal est fourni).

## Variables d’environnement

- `DATABASE_URL` — Connexion PostgreSQL (optionnel pour les squelettes actuels).
- `SECRET_KEY` — Clé JWT (à changer en production).
- `MQTT_HOST` — Broker MQTT (optionnel ; si absent, le client MQTT ne se connecte pas).
