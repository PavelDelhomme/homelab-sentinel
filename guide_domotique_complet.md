# 🏠 Projet Domotique Maison Ultra-Sécurisé — Guide Complet

## Sommaire
1. Architecture réseau (Pi 2 routeur/firewall)
2. Reboot électrique de la box via relais
3. Prises connectées avec mesure de consommation
4. Gamelle RFID pour chat
5. Système caméras + NVR maison
6. Baby-phone maison
7. Tunnel VPN sécurisé (WireGuard)
8. Bus MQTT sécurisé (Mosquitto + TLS)
9. Backend API maison (FastAPI)
10. Interface Web & Mobile
11. Sécurité globale & DMZ
12. Liste d'achats complète

---

## 1. Architecture Réseau — Raspberry Pi 2 comme Routeur/Firewall

### Objectif
Placer la Pi 2 entre ta box Bouygues et tout ton réseau local pour filtrer, segmenter et sécuriser.

### Matériel nécessaire
| Composant | Rôle | Prix estimé |
|-----------|------|-------------|
| Raspberry Pi 2 (déjà possédé) | Routeur / Firewall / VPN | 0 € |
| Dongle USB-Ethernet (ex: TP-Link UE300) | 2ème interface réseau (WAN) | ~15 € |
| Carte microSD 16 Go+ (classe 10) | Stockage OS | ~8 € |
| Switch Ethernet 5/8 ports (ex: Netgear GS305) | Distribution LAN derrière la Pi | ~15-20 € |
| Point d'accès Wi-Fi (ex: TP-Link EAP225) | Wi-Fi derrière la Pi (remplace Wi-Fi box) | ~50-70 € |

### Schéma réseau

```
Internet
    │
┌───┴───┐
│  Box   │  (mode bridge si possible, sinon NAT classique)
│Bouygues│  Wi-Fi désactivé
└───┬───┘
    │ Câble Ethernet
    │
┌───┴───────────┐
│ Raspberry Pi 2 │
│   (OpenWrt)    │
│                │
│ eth0 (natif)   │ ← LAN (vers switch)
│ usb-eth (dongle)│ ← WAN (vers box)
└──┬────────────┘
   │
┌──┴──────────┐
│  Switch ETH  │
├──────────────┤
│              │
├── AP Wi-Fi ──┤  → Réseau "Maison" (VLAN 10)
│              │
├── RPi Serveur │  → Réseau "Serveurs" (VLAN 20)
│  (domotique)  │
│              │
├── Caméras ───┤  → Réseau "IoT" (VLAN 30)
│  ESP32, etc.  │
│              │
└──────────────┘
```

### Installation OpenWrt sur Pi 2

**Étape 1 — Flasher OpenWrt**
1. Télécharger l'image Pi 2 depuis https://openwrt.org/toh/raspberry_pi_foundation/raspberry_pi
2. Flasher avec Balena Etcher sur la carte microSD
3. Insérer la SD dans la Pi 2 et démarrer

**Étape 2 — Configuration réseau initiale**
```bash
# Se connecter via Ethernet (eth0 par défaut sur 192.168.1.1)
# Changer le mot de passe root
passwd

# Éditer la config réseau
vi /etc/config/network

# Exemple de configuration :
config interface 'loopback'
    option device 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config interface 'wan'
    option device 'eth1'          # dongle USB-Ethernet
    option proto 'dhcp'

config interface 'wan6'
    option device 'eth1'
    option proto 'dhcpv6'

config interface 'lan'
    option device 'eth0'          # port Ethernet natif
    option proto 'static'
    option ipaddr '192.168.10.1'
    option netmask '255.255.255.0'
```

**Étape 3 — Installer le driver USB-Ethernet**
```bash
opkg update
# Pour TP-Link UE300 (chipset RTL8153) :
opkg install kmod-usb-net-rtl8152
# Pour d'autres adaptateurs (AX88179) :
# opkg install kmod-usb-net-asix-ax88179
reboot
```

**Étape 4 — Installer LuCI (interface web)**
```bash
opkg install luci luci-ssl
```

### Firewall et segmentation (nftables)

**Fichier /etc/nftables.conf (ou via LuCI > Firewall)**

```
#!/usr/sbin/nft -f
flush ruleset

define LAN_NET = 192.168.10.0/24
define IOT_NET = 192.168.30.0/24

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;
        ct state established,related accept
        iif "lo" accept
        iifname "eth0" tcp dport { 22, 80, 443 } accept   # admin depuis LAN
        iifname "eth0" udp dport 51820 accept              # WireGuard
        iifname "eth0" icmp type echo-request accept
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
        ct state established,related accept

        # LAN → Internet : OK
        iifname "eth0" oifname "eth1" accept

        # IoT → Internet : OK mais PAS vers LAN
        iifname "br-iot" oifname "eth1" accept
        iifname "br-iot" oifname "eth0" drop

        # LAN → IoT : autorisé (pour administrer)
        iifname "eth0" oifname "br-iot" accept
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}

table inet nat {
    chain postrouting {
        type nat hook postrouting priority srcnat;
        oifname "eth1" masquerade
    }
}
```

### Performances Pi 2 — Limites
- ~35-70 Mbps en NAT pur (suffisant pour la plupart des connexions fibre grand public)
- VPN WireGuard: ~20-30 Mbps (WireGuard est léger, bien adapté aux CPU ARM)
- Si tu as besoin de plus, un Pi 4 ou mini-PC sera le prochain upgrade

---

## 2. Reboot Électrique de la Box via Relais

### Objectif
La Pi surveille Internet et reboot la box automatiquement si plus de connexion.

### Matériel
| Composant | Rôle | Prix estimé |
|-----------|------|-------------|
| Module relais 5V 1 canal (ex: SRD-05VDC-SL-C) | Couper/remettre le 230V de la box | ~3-5 € |
| Câbles Dupont femelle-femelle | Connexion Pi ↔ relais | ~2 € |
| Rallonge électrique (à couper) | Intégrer le relais sur la ligne 230V | ~5 € |

### Schéma de câblage

```
Raspberry Pi 2              Module Relais 5V
┌──────────┐               ┌─────────────────┐
│          │               │                 │
│ GPIO 17 ─┼──── IN ───── │ IN              │
│          │               │                 │
│ 5V (pin 2)┼──── VCC ──── │ VCC             │
│          │               │                 │
│ GND (pin 6)┼── GND ───── │ GND             │
│          │               │                 │
└──────────┘               │    COM ──┐      │
                           │    NO ───┼──┐   │
                           │    NC    │  │   │
                           └──────────┘  │   │
                                         │   │
                              Phase 230V ─┘   │
                              (vers box) ─────┘
                              Neutre : direct (pas coupé)
```

**⚠️ SÉCURITÉ 230V** : ne JAMAIS travailler sous tension. Utiliser un boîtier isolé. Le relais coupe uniquement la PHASE (fil marron).

### Câblage détaillé du 230V

```
Prise murale ──► Rallonge coupée
                  │
                  ├── Neutre (bleu) ──────────► directement vers prise box
                  │
                  ├── Phase (marron) ──► COM du relais
                  │                       NO du relais ──► Phase vers prise box
                  │
                  └── Terre (vert/jaune) ──► directement vers prise box
```

**NO (Normally Open)** = circuit ouvert au repos → quand GPIO HIGH, le relais ferme → la box a du courant.

### Script de surveillance (Python)

```python
#!/usr/bin/env python3
# /usr/local/bin/watchdog_box.py

import RPi.GPIO as GPIO
import subprocess
import time
import logging

RELAY_PIN = 17
PING_TARGET = "8.8.8.8"
PING_COUNT = 3
CHECK_INTERVAL = 60       # secondes entre chaque vérification
FAIL_THRESHOLD = 3        # nb d'échecs consécutifs avant reboot
POWER_OFF_DURATION = 10   # secondes coupure
BOOT_WAIT = 120           # attendre que la box redémarre

logging.basicConfig(
    filename="/var/log/watchdog_box.log",
    level=logging.INFO,
    format="%(asctime)s %(message)s"
)

GPIO.setmode(GPIO.BCM)
GPIO.setup(RELAY_PIN, GPIO.OUT)
GPIO.output(RELAY_PIN, GPIO.HIGH)  # relais fermé = box alimentée

fail_count = 0

def ping_ok():
    result = subprocess.run(
        ["ping", "-c", str(PING_COUNT), "-W", "3", PING_TARGET],
        capture_output=True
    )
    return result.returncode == 0

def reboot_box():
    logging.info("REBOOT BOX — coupure alimentation")
    GPIO.output(RELAY_PIN, GPIO.LOW)   # ouvre le relais = coupe la box
    time.sleep(POWER_OFF_DURATION)
    GPIO.output(RELAY_PIN, GPIO.HIGH)  # ferme le relais = rallume
    logging.info("REBOOT BOX — alimentation rétablie, attente boot...")
    time.sleep(BOOT_WAIT)

try:
    while True:
        if ping_ok():
            fail_count = 0
        else:
            fail_count += 1
            logging.warning(f"Ping échoué ({fail_count}/{FAIL_THRESHOLD})")
            if fail_count >= FAIL_THRESHOLD:
                reboot_box()
                fail_count = 0
        time.sleep(CHECK_INTERVAL)
except KeyboardInterrupt:
    GPIO.cleanup()
```

### Lancer au démarrage
```bash
# Créer un service systemd
sudo nano /etc/systemd/system/watchdog-box.service

[Unit]
Description=Box Watchdog Reboot Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 /usr/local/bin/watchdog_box.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target

# Activer
sudo systemctl enable watchdog-box
sudo systemctl start watchdog-box
```

---

## 3. Prises Connectées avec Mesure de Consommation

### Objectif
Prise DIY : on/off commandable + mesure tension/courant/puissance → MQTT → backend.

### Matériel (par prise)
| Composant | Rôle | Prix estimé |
|-----------|------|-------------|
| ESP32 WROOM-32D | MCU + Wi-Fi | ~5-8 € |
| Module relais 5V (SRD-05VDC) | Commuter le 230V | ~2-3 € |
| ACS712 20A (capteur courant) | Mesurer le courant | ~2 € |
| ZMPT101B (capteur tension) | Mesurer la tension | ~3 € |
| HI-Link HLK-PM01 (5V 3W SMPS) | Alimentation 5V depuis 230V | ~3-4 € |
| Prise mâle 230V + prise femelle 230V | Entrée/sortie | ~3 € |
| Boîtier (imprimé 3D ou acheté) | Sécurité isolation | ~2-5 € |
| **TOTAL par prise** | | **~20-30 €** |

### Schéma électrique

```
230V Entrée (prise mâle)
    │
    ├── Phase ──┬── ZMPT101B (entrée) ──► mesure tension
    │           │
    │           └── ACS712 (en série) ──► mesure courant
    │                    │
    │                    └──► COM du Relais
    │                            NO ──► Phase sortie (prise femelle)
    │
    ├── Neutre ──┬── ZMPT101B (entrée) ──► mesure tension
    │            │
    │            └──────────────────────► Neutre sortie (prise femelle)
    │
    └── HI-Link HLK-PM01 (L, N) ──► 5V DC
                                       │
                                       ├── ESP32 (VIN)
                                       ├── Relais (VCC)
                                       └── Capteurs (VCC)


ESP32 Câblage capteurs :
┌──────────────┐
│ ESP32         │
│               │
│ GPIO 34 ◄──── ACS712 OUT (courant)
│ GPIO 35 ◄──── ZMPT101B OUT (tension)
│ GPIO 26 ────► IN du relais (commande)
│               │
│ VIN ◄──────── 5V (HI-Link)
│ GND ◄──────── GND commun
└──────────────┘
```

### Code ESP32 (Arduino IDE)

```cpp
#include <WiFi.h>
#include <PubSubClient.h>

// --- Config ---
const char* ssid = "MonReseau_IoT";
const char* password = "MotDePasseWiFi";
const char* mqtt_server = "192.168.10.50";  // IP du broker MQTT
const int mqtt_port = 8883;
const char* device_id = "prise_salon";

// --- Pins ---
#define CURRENT_PIN 34
#define VOLTAGE_PIN 35
#define RELAY_PIN   26

// --- Calibration ---
const float V_REF = 3.3;
const int ADC_MAX = 4095;
const float ACS_SENSITIVITY = 0.100; // 100mV/A pour ACS712-20A
const float ACS_OFFSET = 1.65;      // offset à 0A
const float MAINS_VOLTAGE = 230.0;

WiFiClient espClient;
PubSubClient client(espClient);

float readCurrent() {
    long sum = 0;
    for (int i = 0; i < 1000; i++) {
        int raw = analogRead(CURRENT_PIN);
        sum += raw;
        delayMicroseconds(100);
    }
    float avg = (float)sum / 1000.0;
    float voltage = (avg / ADC_MAX) * V_REF;
    float current = (voltage - ACS_OFFSET) / ACS_SENSITIVITY;
    return abs(current);
}

float readVoltage() {
    long sum = 0;
    for (int i = 0; i < 1000; i++) {
        int raw = analogRead(VOLTAGE_PIN);
        sum += raw;
        delayMicroseconds(100);
    }
    float avg = (float)sum / 1000.0;
    // Calibration nécessaire selon ton module ZMPT101B
    float voltage = (avg / ADC_MAX) * V_REF * 110.0; // facteur à ajuster
    return voltage;
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
    String msg = "";
    for (int i = 0; i < length; i++) msg += (char)payload[i];

    if (String(topic) == String("home/") + device_id + "/set") {
        if (msg == "ON")  digitalWrite(RELAY_PIN, HIGH);
        if (msg == "OFF") digitalWrite(RELAY_PIN, LOW);

        client.publish((String("home/") + device_id + "/state").c_str(),
                       digitalRead(RELAY_PIN) ? "ON" : "OFF");
    }
}

void reconnect() {
    while (!client.connected()) {
        if (client.connect(device_id, "mqtt_user", "mqtt_password")) {
            client.subscribe((String("home/") + device_id + "/set").c_str());
        } else {
            delay(5000);
        }
    }
}

void setup() {
    Serial.begin(115200);
    pinMode(RELAY_PIN, OUTPUT);
    digitalWrite(RELAY_PIN, LOW);

    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) delay(500);

    client.setServer(mqtt_server, mqtt_port);
    client.setCallback(mqttCallback);
}

void loop() {
    if (!client.connected()) reconnect();
    client.loop();

    static unsigned long lastPublish = 0;
    if (millis() - lastPublish > 5000) {  // toutes les 5 sec
        float current = readCurrent();
        float voltage = readVoltage();
        float power = current * voltage;

        char payload[128];
        snprintf(payload, sizeof(payload),
            "{\"current\":%.2f,\"voltage\":%.1f,\"power\":%.1f,\"state\":\"%s\"}",
            current, voltage, power,
            digitalRead(RELAY_PIN) ? "ON" : "OFF");

        client.publish((String("home/") + device_id + "/telemetry").c_str(), payload);
        lastPublish = millis();
    }
}
```

---

## 4. Gamelle RFID pour Chat (vérification puce)

### Objectif
Seul ton chat (identifié par puce RFID sur collier) peut ouvrir la gamelle.

### Important : type de puce
- Les **puces animales implantées** utilisent **134.2 kHz FDX-B** (ISO 11784/85)
- Les modules classiques RC522/MFRC522 fonctionnent à **13.56 MHz** → ne lisent PAS les puces animales
- Il faut un module **FDX-B 134.2 kHz** dédié, ou bien mettre un **tag RFID 125 kHz** sur le collier

### Option A : Lire la puce implantée (134.2 kHz FDX-B)
| Composant | Rôle | Prix estimé |
|-----------|------|-------------|
| Module RFID FDX-B 134.2 kHz + antenne | Lire la puce implantée | ~15-25 € (AliExpress) |
| ESP32 ou Arduino Nano | MCU | ~5-8 € |
| Servo moteur MG90S (métal) | Ouvrir/fermer trappe gamelle | ~5 € |
| Alimentation 5V | Alimenter le tout | ~5 € |
| Boîtier/gamelle (impression 3D) | Structure physique | ~5-10 € |
| **TOTAL** | | **~35-55 €** |

### Option B : Tag RFID 125 kHz sur collier (plus simple, plus fiable)
| Composant | Rôle | Prix estimé |
|-----------|------|-------------|
| Module RDM6300 (125 kHz) | Lecteur RFID | ~3-5 € |
| Tags RFID 125 kHz (lot) | À mettre sur le collier | ~3 € le lot |
| ESP32 ou Arduino Nano | MCU | ~5-8 € |
| Servo moteur MG90S | Trappe | ~5 € |

### Schéma de câblage (Option B — RDM6300 + ESP32)

```
┌──────────────┐       ┌────────────┐
│   RDM6300    │       │   ESP32    │
│              │       │            │
│  TX ─────────┼──►──── GPIO 16 (RX2)
│  VCC ────────┼──►──── 5V
│  GND ────────┼──►──── GND
│              │       │            │
│  [Antenne]   │       │ GPIO 18 ──────► Signal Servo
│              │       │ GPIO 19 ──────► LED verte (OK)
│              │       │ GPIO 21 ──────► LED rouge (refusé)
│              │       │ GPIO 22 ──────► Buzzer
└──────────────┘       └────────────┘

Servo MG90S :
  Signal (orange) ← GPIO 18
  VCC (rouge) ← 5V
  GND (marron) ← GND
```

### Logique
```
1. L'antenne scanne en continu
2. Si tag détecté → vérifier ID dans liste autorisée
3. Si OK → servo ouvre la trappe + LED verte + bip court
4. Attendre 30 sec (temps de manger)
5. Fermer la trappe
6. Si tag inconnu → LED rouge + double bip
7. Envoyer événement via MQTT :
   - home/feeder/event → {"cat":"Minou","action":"feed","timestamp":"..."}
```

### Code Arduino (simplifié)

```cpp
#include <SoftwareSerial.h>
#include <Servo.h>

SoftwareSerial rfidSerial(16, 17); // RX, TX
Servo trappeServo;

// IDs autorisés (ton chat)
const String ALLOWED_TAGS[] = {"0A0B0C0D0E", "1234567890"};
const int NUM_ALLOWED = 2;

void setup() {
    Serial.begin(115200);
    rfidSerial.begin(9600);
    trappeServo.attach(18);
    trappeServo.write(0); // fermé
    pinMode(19, OUTPUT); // LED verte
    pinMode(21, OUTPUT); // LED rouge
    pinMode(22, OUTPUT); // Buzzer
}

String readRFID() {
    String tag = "";
    if (rfidSerial.available()) {
        delay(100);
        while (rfidSerial.available()) {
            char c = rfidSerial.read();
            if (c != '\n' && c != '\r') tag += c;
        }
    }
    return tag;
}

bool isAllowed(String tag) {
    for (int i = 0; i < NUM_ALLOWED; i++) {
        if (tag.indexOf(ALLOWED_TAGS[i]) >= 0) return true;
    }
    return false;
}

void openFeeder() {
    digitalWrite(19, HIGH);     // LED verte
    trappeServo.write(90);      // ouvrir
    delay(30000);               // 30 sec pour manger
    trappeServo.write(0);       // fermer
    digitalWrite(19, LOW);
}

void rejectAccess() {
    for (int i = 0; i < 3; i++) {
        digitalWrite(21, HIGH); // LED rouge
        digitalWrite(22, HIGH); // Buzzer
        delay(200);
        digitalWrite(21, LOW);
        digitalWrite(22, LOW);
        delay(200);
    }
}

void loop() {
    String tag = readRFID();
    if (tag.length() > 5) {
        Serial.println("Tag: " + tag);
        if (isAllowed(tag)) {
            openFeeder();
            // TODO: envoyer via MQTT
        } else {
            rejectAccess();
        }
    }
    delay(100);
}
```

---

## 5. Système Caméras + NVR Maison (Frigate)

### Architecture

```
Caméras IP (RTSP)          Serveur (RPi 4 / mini-PC / ton serveur)
┌──────────┐               ┌─────────────────────┐
│ Cam 1    │──RTSP──►      │  Docker             │
│ Cam 2    │──RTSP──►      │  ┌─────────────┐    │
│ (ESP32-  │               │  │   Frigate    │    │
│  CAM opt)│               │  │   NVR        │    │
└──────────┘               │  │   ─ détection│    │
                           │  │   ─ recording│    │
                           │  │   ─ MQTT     │    │
                           │  └──────┬──────┘    │
                           │         │ events    │
                           │  ┌──────┴──────┐    │
                           │  │  Mosquitto   │    │
                           │  │  (MQTT)      │    │
                           │  └─────────────┘    │
                           │                     │
                           │  Stockage vidéo :   │
                           │  /media/frigate/    │
                           └─────────────────────┘
```

### Matériel caméras
| Option | Description | Prix estimé |
|--------|-------------|-------------|
| Caméras IP PoE (ex: Reolink RLC-510A) | 5MP, RTSP natif, IR nuit | ~40-60 € /unité |
| ESP32-CAM (budget) | 2MP, MJPEG, qualité limitée | ~5-10 € /unité |
| Switch PoE (si cams PoE) | Alimenter les cams via Ethernet | ~30-50 € |

### Installation Frigate (Docker)

**docker-compose.yml**
```yaml
version: "3.9"
services:
  frigate:
    container_name: frigate
    privileged: true
    restart: unless-stopped
    image: ghcr.io/blakeblackshear/frigate:stable
    shm_size: "256mb"
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - ./frigate/config.yml:/config/config.yml:ro
      - ./frigate/storage:/media/frigate
      - type: tmpfs
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    ports:
      - "8971:8971"
      - "8554:8554"    # RTSP
      - "8555:8555/tcp" # WebRTC
      - "8555:8555/udp"
    environment:
      FRIGATE_RTSP_PASSWORD: "ton_mot_de_passe_cam"
```

**frigate/config.yml**
```yaml
mqtt:
  enabled: true
  host: 192.168.10.50
  port: 8883
  user: frigate_user
  password: frigate_password
  tls_ca_certs: /config/ca.crt

cameras:
  salon:
    ffmpeg:
      inputs:
        - path: rtsp://user:pass@192.168.30.10:554/stream1
          roles:
            - detect
            - record
    detect:
      enabled: true
      width: 1280
      height: 720
      fps: 5
    record:
      enabled: true
      retain:
        days: 7
        mode: motion
      events:
        retain:
          default: 30
    objects:
      track:
        - person
        - cat
    snapshots:
      enabled: true

  entree:
    ffmpeg:
      inputs:
        - path: rtsp://user:pass@192.168.30.11:554/stream1
          roles:
            - detect
            - record
    detect:
      enabled: true
      width: 1280
      height: 720
      fps: 5
    record:
      enabled: true
      retain:
        days: 7
    objects:
      track:
        - person
```

### Politique de rétention
- **Enregistrement continu sur mouvement** : 7 jours
- **Événements (personne détectée)** : 30 jours
- Stockage estimé : ~500 Go pour 2 cams, 7 jours continu (prévoir un disque dédié)

---

## 6. Baby-Phone Maison

### Matériel
| Composant | Rôle | Prix estimé |
|-----------|------|-------------|
| Raspberry Pi Zero 2 W (ou Pi 3/4) | MCU + streaming | ~20-30 € |
| Caméra Pi NoIR (infrarouge) | Vision nocturne | ~25 € |
| Câble flex caméra (adapté au modèle) | Connexion | ~5 € |
| Micro USB | Capturer le son | ~5-10 € |
| Power bank ou alim murale 5V | Alimentation | ~10 € |
| Support imprimé 3D | Fixation | ~3 € |
| **TOTAL** | | **~70-85 €** |

### Installation logicielle

```bash
# Sur le Pi du baby-phone
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-picamera2 ffmpeg

# Créer un hotspot local (optionnel, si pas sur ton réseau)
sudo nmcli device wifi hotspot ssid "BabyMonitor" password "MotDePasse123"

# OU connecter au WiFi maison
sudo nmcli device wifi connect "MonReseau_Maison" password "MonMotDePasse"
```

### Streaming vidéo + audio

**Option 1 : MediaMTX (serveur RTSP léger)**
```bash
# Télécharger MediaMTX
wget https://github.com/bluenviron/mediamtx/releases/latest/download/mediamtx_vX.X.X_linux_arm64v8.tar.gz
tar xzf mediamtx_*.tar.gz

# Configurer mediamtx.yml pour la caméra Pi
# Lancer
./mediamtx &

# Streamer la caméra
libcamera-vid -t 0 --width 1280 --height 720 --codec h264 \
  --inline -o - | ffmpeg -i - -c copy -f rtsp rtsp://localhost:8554/baby
```

**Option 2 : Script Python simple avec picamera2**
```python
#!/usr/bin/env python3
from picamera2 import Picamera2
from picamera2.encoders import H264Encoder
from picamera2.outputs import FfmpegOutput
import subprocess

picam2 = Picamera2()
config = picam2.create_video_configuration(
    main={"size": (1280, 720)},
    controls={"FrameRate": 15}
)
picam2.configure(config)

encoder = H264Encoder(bitrate=2000000)
output = FfmpegOutput("-f rtsp rtsp://localhost:8554/baby")

picam2.start_recording(encoder, output)

# Garder le script actif
import time
while True:
    time.sleep(1)
```

### Détection de bruit (alerte si bébé pleure)
```python
#!/usr/bin/env python3
import sounddevice as sd
import numpy as np
import paho.mqtt.client as mqtt

THRESHOLD = 0.05  # à calibrer
MQTT_BROKER = "192.168.10.50"

client = mqtt.Client()
client.username_pw_set("baby_monitor", "password")
client.connect(MQTT_BROKER, 8883)

def audio_callback(indata, frames, time, status):
    volume = np.sqrt(np.mean(indata**2))
    if volume > THRESHOLD:
        client.publish("home/babyphone/alert",
                       f'{{"level":{volume:.4f},"alert":"noise"}}')

with sd.InputStream(callback=audio_callback, channels=1, samplerate=16000):
    while True:
        sd.sleep(1000)
```

---

## 7. Tunnel VPN Ultra-Sécurisé (WireGuard via PiVPN)

### Installation sur le Pi routeur

```bash
# Installer PiVPN
curl -L https://install.pivpn.io | bash

# Suivre l'assistant :
# 1. Choisir WireGuard
# 2. Port : 51820 (UDP)
# 3. DNS : adresse de ton Pi-hole / ou 1.1.1.1
# 4. Utiliser DynDNS si pas d'IP fixe (DuckDNS gratuit)
```

### Ajouter un profil client
```bash
pivpn add -n monphone
# Génère /home/pi/configs/monphone.conf

# Afficher QR code pour le téléphone
pivpn -qr monphone
```

### Port forwarding sur la box Bouygues
- Aller dans l'interface admin de la box (192.168.1.254)
- Rediriger **UDP 51820** vers l'IP de la Pi (côté WAN de la Pi)

### Config WireGuard serveur (/etc/wireguard/wg0.conf)
```ini
[Interface]
PrivateKey = <clé_privée_serveur>
Address = 10.6.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth1 -j MASQUERADE

[Peer]
# monphone
PublicKey = <clé_publique_client>
AllowedIPs = 10.6.0.2/32
```

### Sécurité
- WireGuard chiffre tout le trafic (ChaCha20, Poly1305, Curve25519)
- Seul un client avec la clé peut se connecter
- Pas de port SSH ouvert vers l'extérieur → tout passe par le VPN

---

## 8. Bus MQTT Sécurisé (Mosquitto + TLS)

### Installation
```bash
sudo apt install mosquitto mosquitto-clients -y
sudo systemctl enable mosquitto
```

### Créer les certificats TLS (auto-signés)
```bash
mkdir ~/mqtt_certs && cd ~/mqtt_certs

# CA (autorité de certification)
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
  -subj "/CN=HomeCA"

# Certificat serveur
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr \
  -subj "/CN=192.168.10.50"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key \
  -CAcreateserial -out server.crt -days 3650

sudo cp ca.crt server.crt server.key /etc/mosquitto/certs/
sudo chown mosquitto: /etc/mosquitto/certs/*
```

### Configuration Mosquitto (/etc/mosquitto/mosquitto.conf)
```
per_listener_settings true

# Port sécurisé TLS
listener 8883
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
tls_version tlsv1.2

# Authentification obligatoire
allow_anonymous false
password_file /etc/mosquitto/passwd

# Logs
log_dest file /var/log/mosquitto/mosquitto.log
log_type all
```

### Créer des utilisateurs
```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd admin
sudo mosquitto_passwd -b /etc/mosquitto/passwd prise_salon mdp_prise
sudo mosquitto_passwd -b /etc/mosquitto/passwd feeder_chat mdp_feeder
sudo mosquitto_passwd -b /etc/mosquitto/passwd frigate mdp_frigate
sudo mosquitto_passwd -b /etc/mosquitto/passwd babyphone mdp_baby

sudo systemctl restart mosquitto
```

### Test
```bash
# Subscribe
mosquitto_sub -h 192.168.10.50 -p 8883 --cafile ~/mqtt_certs/ca.crt \
  -u admin -P mdp_admin -t "home/#"

# Publish
mosquitto_pub -h 192.168.10.50 -p 8883 --cafile ~/mqtt_certs/ca.crt \
  -u admin -P mdp_admin -t "home/test" -m "Hello sécurisé"
```

---

## 9. Backend API Maison (FastAPI)

### Architecture du backend

```
backend/
├── app/
│   ├── main.py               # Point d'entrée FastAPI
│   ├── core/
│   │   ├── config.py          # Variables d'environnement
│   │   ├── security.py        # JWT, hashing, auth
│   │   └── database.py        # Connexion DB
│   ├── api/
│   │   └── v1/
│   │       ├── devices.py     # CRUD devices (prises, cams, etc.)
│   │       ├── energy.py      # Données conso énergie
│   │       ├── cameras.py     # Flux caméras / événements
│   │       ├── feeder.py      # Gamelle chat
│   │       ├── auth.py        # Login, register, tokens
│   │       └── automations.py # Règles d'automatisation
│   ├── models/
│   │   ├── device.py
│   │   ├── user.py
│   │   ├── energy_reading.py
│   │   └── event.py
│   ├── schemas/
│   │   ├── device.py          # Pydantic DTOs
│   │   ├── energy.py
│   │   └── auth.py
│   ├── services/
│   │   ├── mqtt_service.py    # Client MQTT (réception/envoi)
│   │   ├── device_service.py
│   │   └── energy_service.py
│   └── repositories/
│       ├── device_repo.py
│       └── energy_repo.py
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── alembic/                   # Migrations DB
```

### Exemple main.py
```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.v1 import devices, energy, cameras, feeder, auth, automations
from app.core.config import settings
from app.services.mqtt_service import mqtt_manager

app = FastAPI(
    title="HomeLab API",
    version="1.0.0",
    docs_url="/api/docs" if settings.DEBUG else None
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router,        prefix="/api/v1/auth",        tags=["Auth"])
app.include_router(devices.router,     prefix="/api/v1/devices",     tags=["Devices"])
app.include_router(energy.router,      prefix="/api/v1/energy",      tags=["Energy"])
app.include_router(cameras.router,     prefix="/api/v1/cameras",     tags=["Cameras"])
app.include_router(feeder.router,      prefix="/api/v1/feeder",      tags=["Feeder"])
app.include_router(automations.router, prefix="/api/v1/automations", tags=["Automations"])

@app.on_event("startup")
async def startup():
    await mqtt_manager.connect()

@app.on_event("shutdown")
async def shutdown():
    await mqtt_manager.disconnect()
```

### Sécurité API (JWT)
```python
# app/core/security.py
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
from app.core.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(hours=1))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm="HS256")

def verify_password(plain, hashed):
    return pwd_context.verify(plain, hashed)

def hash_password(password):
    return pwd_context.hash(password)
```

### Docker Compose complet
```yaml
version: "3.9"
services:
  api:
    build: .
    container_name: homelab-api
    restart: unless-stopped
    ports:
      - "5500:5500"
    environment:
      - DATABASE_URL=postgresql://homelab:secret@db:5432/homelab
      - SECRET_KEY=ta_cle_secrete_ultra_longue_aleatoire
      - MQTT_HOST=mosquitto
      - MQTT_PORT=8883
    depends_on:
      - db
      - mosquitto
    volumes:
      - ./app:/app/app

  db:
    image: postgres:16-alpine
    container_name: homelab-db
    restart: unless-stopped
    environment:
      POSTGRES_USER: homelab
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: homelab
    volumes:
      - pgdata:/var/lib/postgresql/data

  mosquitto:
    image: eclipse-mosquitto:2
    container_name: homelab-mqtt
    restart: unless-stopped
    ports:
      - "8883:8883"
    volumes:
      - ./mosquitto/config:/mosquitto/config
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/certs:/mosquitto/certs

  frigate:
    container_name: frigate
    privileged: true
    restart: unless-stopped
    image: ghcr.io/blakeblackshear/frigate:stable
    shm_size: "256mb"
    volumes:
      - ./frigate/config.yml:/config/config.yml:ro
      - ./frigate/storage:/media/frigate
    ports:
      - "8971:8971"
      - "8554:8554"

volumes:
  pgdata:
```

---

## 10. Interface Web & Mobile

### Stack recommandée
| Couche | Techno | Pourquoi |
|--------|--------|----------|
| Frontend Web | Vue.js 3 + Vite | Léger, réactif, facile à apprendre |
| UI Components | PrimeVue ou Vuetify | Dashboard-ready |
| Temps réel | WebSocket (via FastAPI) | Données live capteurs |
| Mobile | PWA (Progressive Web App) | Une seule codebase web+mobile |
| Alternative mobile | Flutter ou React Native | Si tu veux une vraie app native |

### Fonctionnalités de l'interface
- **Dashboard** : état de tous les devices, conso temps réel, flux caméras
- **Énergie** : graphiques par prise (journalier, hebdo, mensuel)
- **Caméras** : flux live, timeline événements, snapshots
- **Gamelle** : historique repas, tag détecté, horaires
- **Baby-phone** : flux audio/vidéo, historique alertes bruit
- **Contrôle** : on/off prises, lumières, scènes
- **Automatisations** : créer des règles (si mouvement + nuit → allumer lumière)
- **Admin** : gestion utilisateurs, logs, config réseau

---

## 11. Sécurité Globale & DMZ

### Récapitulatif couches de sécurité

```
┌─────────────────────────────────────────────┐
│              INTERNET                        │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────┴──────────────────────────┐
│  Box Bouygues (NAT, seul port 51820 ouvert) │
└──────────────────┬──────────────────────────┘
                   │
┌──────────────────┴──────────────────────────┐
│  Raspberry Pi 2 (OpenWrt)                    │
│  ┌─────────────────────────────────────┐    │
│  │ Firewall nftables                    │    │
│  │ WireGuard VPN (seul accès externe)   │    │
│  │ DHCP / DNS (dnsmasq)                │    │
│  │ Segmentation VLAN :                  │    │
│  │   VLAN 10 — LAN Perso (PC, tél)     │    │
│  │   VLAN 20 — Serveurs (API, NVR)     │    │
│  │   VLAN 30 — IoT (cams, prises, etc.)│    │
│  └─────────────────────────────────────┘    │
└──────────────────┬──────────────────────────┘
                   │
           ┌───────┼───────┐
           │       │       │
    VLAN 10    VLAN 20   VLAN 30
    (Perso)  (Serveurs)  (IoT)
      │         │          │
    PC/Tél    API/DB     Cams
              Frigate    Prises
              MQTT       Feeder
                         BabyPhone
```

### Règles de sécurité clés
1. **Aucun port ouvert** vers Internet sauf UDP 51820 (WireGuard)
2. **IoT ne peut PAS accéder** au LAN Perso ni aux Serveurs (sauf MQTT ciblé)
3. **LAN Perso peut accéder** à tout (admin)
4. **Serveurs** : accessible depuis LAN Perso + VPN uniquement
5. **TLS partout** : MQTT chiffré, API HTTPS, VPN chiffré
6. **Auth partout** : JWT pour l'API, mots de passe MQTT, clés WireGuard
7. **Mises à jour automatiques** de sécurité (unattended-upgrades)
8. **Logs centralisés** : tout remonte au serveur

---

## 12. Liste d'Achats Complète

| # | Composant | Quantité | Usage | Prix unitaire | Total estimé |
|---|-----------|----------|-------|---------------|--------------|
| 1 | Dongle USB-Ethernet (TP-Link UE300) | 1 | WAN pour Pi routeur | 15 € | 15 € |
| 2 | Carte microSD 32 Go | 2 | Pi routeur + baby-phone | 8 € | 16 € |
| 3 | Switch Ethernet 5 ports | 1 | Distribution LAN | 15 € | 15 € |
| 4 | Point d'accès Wi-Fi (TP-Link EAP225) | 1 | Wi-Fi maison | 55 € | 55 € |
| 5 | Module relais 5V 1 canal | 2 | Reboot box + spare | 3 € | 6 € |
| 6 | Câbles Dupont | 1 lot | Connexions | 3 € | 3 € |
| 7 | ESP32 WROOM-32D | 4 | Prises connectées | 6 € | 24 € |
| 8 | ACS712 20A | 4 | Mesure courant | 2 € | 8 € |
| 9 | ZMPT101B | 4 | Mesure tension | 3 € | 12 € |
| 10 | HI-Link HLK-PM01 5V | 4 | Alim 230V→5V | 4 € | 16 € |
| 11 | Module relais 5V | 4 | Commande prises | 3 € | 12 € |
| 12 | Prises mâle+femelle 230V | 4 sets | Boîtier prise | 3 € | 12 € |
| 13 | Module RFID FDX-B 134.2kHz + antenne | 1 | Gamelle chat | 20 € | 20 € |
| 14 | Servo MG90S métal | 1 | Trappe gamelle | 5 € | 5 € |
| 15 | Tags RFID 125kHz (lot de 10) | 1 | Collier chat (backup) | 3 € | 3 € |
| 16 | Caméras IP PoE RTSP (Reolink) | 2 | Surveillance | 50 € | 100 € |
| 17 | Switch PoE 4 ports | 1 | Alimenter caméras | 40 € | 40 € |
| 18 | Raspberry Pi Zero 2 W | 1 | Baby-phone | 25 € | 25 € |
| 19 | Caméra Pi NoIR V2 | 1 | Baby-phone IR | 25 € | 25 € |
| 20 | Micro USB | 1 | Baby-phone audio | 8 € | 8 € |
| 21 | Disque dur/SSD externe (1 To) | 1 | Stockage vidéo NVR | 40 € | 40 € |
| | | | | **TOTAL** | **~460 €** |

*Note : tu possèdes déjà la Pi 2 et un Arduino. Les prix sont indicatifs (AliExpress/Amazon).*

---

## Ordre de Réalisation Recommandé

### Phase 1 — Réseau sécurisé (Semaine 1-2)
1. Flasher OpenWrt sur Pi 2
2. Configurer routeur (WAN/LAN)
3. Firewall nftables de base
4. Installer WireGuard (PiVPN)
5. Brancher le relais reboot box

### Phase 2 — Infra serveur (Semaine 3-4)
6. Installer Docker sur serveur
7. Déployer Mosquitto (MQTT + TLS)
8. Déployer PostgreSQL
9. Coder le squelette FastAPI
10. Première route : /api/v1/devices

### Phase 3 — Premier device IoT (Semaine 5-6)
11. Monter une prise connectée ESP32
12. Connecter au MQTT
13. Afficher la conso dans l'API
14. Première page dashboard web

### Phase 4 — Caméras (Semaine 7-8)
15. Installer les caméras IP
16. Déployer Frigate
17. Configurer enregistrement + détection
18. Intégrer les événements dans l'API/dashboard

### Phase 5 — Gamelle chat (Semaine 9)
19. Monter le module RFID + servo
20. Tester avec le tag du chat
21. Connecter au MQTT + API

### Phase 6 — Baby-phone (Semaine 10)
22. Monter Pi Zero + caméra NoIR
23. Configurer le streaming
24. Alerte bruit via MQTT

### Phase 7 — Interface complète (Semaine 11-12)
25. Dashboard complet Vue.js
26. PWA mobile
27. Automatisations
28. Tests et hardening final
