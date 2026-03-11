#!/usr/bin/env python3
# Surveillance connexion Internet + reboot électrique de la box via relais.
# À utiliser UNIQUEMENT une fois le module relais 5V branché sur la Pi (GPIO 17, 5V, GND).
# Ne pas lancer sans relais : risque de faux positifs et pas d'action possible.
# Voir guide_domotique_complet.md section 2 pour le câblage et le service systemd.

import RPi.GPIO as GPIO
import subprocess
import time
import logging

RELAY_PIN = 17
PING_TARGET = "8.8.8.8"
PING_COUNT = 3
CHECK_INTERVAL = 60
FAIL_THRESHOLD = 3
POWER_OFF_DURATION = 10
BOOT_WAIT = 120

logging.basicConfig(
    filename="/var/log/watchdog_box.log",
    level=logging.INFO,
    format="%(asctime)s %(message)s"
)

GPIO.setmode(GPIO.BCM)
GPIO.setup(RELAY_PIN, GPIO.OUT)
GPIO.output(RELAY_PIN, GPIO.HIGH)

fail_count = 0

def ping_ok():
    result = subprocess.run(
        ["ping", "-c", str(PING_COUNT), "-W", "3", PING_TARGET],
        capture_output=True
    )
    return result.returncode == 0

def reboot_box():
    logging.info("REBOOT BOX — coupure alimentation")
    GPIO.output(RELAY_PIN, GPIO.LOW)
    time.sleep(POWER_OFF_DURATION)
    GPIO.output(RELAY_PIN, GPIO.HIGH)
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
