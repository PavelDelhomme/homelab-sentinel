# Management, monitoring, app mobile et accès à distance (tunnel sécurisé + DNS)

Ce document décrit ce qui est prévu pour **gérer et monitorer** le homelab (dont le **DNS**) depuis **n’importe où**, via une **interface mobile** et un **tunnel ultra sécurisé**.

---

## Objectif

- **Interface mobile** : une app (ou PWA) sur ton téléphone pour consulter le dashboard, lancer des actions, gérer le DNS, voir l’état des devices (prises, gamelle, caméras, etc.).
- **Accès de n’importe où** : sans ouvrir de ports sur la box ni exposer l’API directement sur Internet — tout passe par un **tunnel sécurisé** (VPN).
- **DNS** : pouvoir gérer les noms locaux (ex. `homelab.local`, `api.homelab`) et, si besoin, un DNS interne pour les devices IoT, le tout pilotable depuis l’app mobile.

---

## Tunnel sécurisé (accès distant)

Plusieurs options, à choisir selon ton niveau de maîtrise et ton hébergeur :

| Solution | Principe | Avantages | Inconvénients |
|----------|----------|-----------|----------------|
| **Tailscale** | VPN mesh, pas de port à ouvrir, client sur le téléphone et sur la Pi | Très simple, chiffré, accès direct à 100.x (IP Tailscale) | Dépendance à un tiers (Tailscale Inc.) |
| **WireGuard** | VPN classique, serveur sur la Pi ou la box, client sur le téléphone | Contrôle total, léger, rapide | Il faut une IP publique ou un relay (ex. VPS) si la box n’a pas d’IP fixe |
| **Cloudflare Tunnel** | Tunnel sortant Pi → Cloudflare, pas de port ouvert | Pas d’IP publique nécessaire, DDoS protection | Trafic passe par Cloudflare, config un peu plus lourde |

**Recommandation pour un usage « ultra sécurisé » et simple** : **Tailscale** sur la Pi et sur le téléphone. Une fois les deux sur le même réseau Tailscale, tu accèdes à l’API (et au futur dashboard) via l’IP Tailscale de la Pi (ex. `http://100.x.x.x:5500`) depuis n’importe où. Aucun port à ouvrir sur la box.

**Alternative** : **WireGuard** si tu veux tout auto-héberger (serveur WG sur la Pi ou sur un VPS qui relaie vers la Pi).

---

## Interface mobile (management)

- **Court terme** : **PWA** (Progressive Web App) du dashboard web — tu l’ajoutes à l’écran d’accueil du téléphone, tu te connectes au homelab via le tunnel (Tailscale/WireGuard). Pas d’app native à publier.
- **Moyen terme** : app mobile dédiée (React Native, Flutter, ou PWA améliorée) avec écrans : dashboard, devices, DNS, monitoring, alertes. L’app ne parle qu’à l’API du homelab (elle-même atteignable uniquement via le tunnel).

L’**API** (FastAPI) est déjà prévue pour devices, énergie, caméras, gamelle, auth, automations. Il restera à ajouter des endpoints **management** (santé des services, logs, métriques) et **DNS** (liste des zones / enregistrements, CRUD) si tu fais un DNS maison, ou à intégrer l’API du routeur (OpenWrt / dnsmasq) si le DNS est géré par le routeur.

---

## DNS (management depuis l’app)

- **Côté réseau** : sur la Pi (Raspberry Pi OS) ou sur OpenWrt (phase 2), un serveur DNS local (ex. **dnsmasq** ou **Unbound**) peut servir les noms locaux (ex. `homelab.local`, `api.homelab`) et éventuellement des sous-domaines pour les devices.
- **Côté management** : l’app mobile (ou le dashboard web) pourra lister / modifier les entrées DNS soit en appelant une **API dédiée** sur la Pi (petit service qui édite la config dnsmasq/Unbound et recharge), soit en parlant à l’API **LuCI / UCI** d’OpenWrt si le DNS tourne sur la Pi en OpenWrt. À documenter dans une phase ultérieure quand le routeur/DNS sera en place.

---

## Monitoring

- **Santé des services** : l’API peut exposer un endpoint `/health` (déjà prévu ou à ajouter) : état de la BDD, du broker MQTT, des principaux services. L’app mobile affiche un indicateur « tout vert » ou des alertes.
- **Métriques** : optionnel — Prometheus + Grafana sur la Pi, ou métriques simples exposées par l’API (compteurs MQTT, état des prises, etc.) pour les afficher dans le dashboard / l’app.

Tout cela sera détaillé dans le guide et dans STATUS.md au fur et à mesure (phase « Interface complète » et « Management »).

---

## Résumé

| Besoin | Solution prévue |
|--------|------------------|
| Accès distant sécurisé | Tunnel (Tailscale recommandé, ou WireGuard / Cloudflare Tunnel) |
| Interface mobile | PWA du dashboard puis, si besoin, app dédiée ; accès uniquement via le tunnel |
| Management DNS | API ou intégration LuCI/dnsmasq ; pilotable depuis l’app une fois le DNS local en place |
| Monitoring | Endpoint /health + métriques optionnelles ; affichage dans le dashboard et l’app |

Aucun port ouvert sur la box : tout passe par le tunnel. Les commandes d’installation de Tailscale (ou WireGuard) sur la Pi seront ajoutées dans les scripts ou dans la doc au moment de la phase « Accès distant ».
