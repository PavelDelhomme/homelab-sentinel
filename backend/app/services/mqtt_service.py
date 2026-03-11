# Client MQTT — stub pour démarrage sans broker. À compléter avec paho-mqtt ou aiomqtt.
# Voir guide_domotique_complet.md sections 8 et 9.

from app.core.config import settings


class MQTTManager:
    def __init__(self) -> None:
        self._connected = False

    async def connect(self) -> None:
        if not settings.MQTT_HOST:
            return
        # TODO: connexion réelle au broker (TLS, auth)
        self._connected = True

    async def disconnect(self) -> None:
        self._connected = False

    @property
    def connected(self) -> bool:
        return self._connected


mqtt_manager = MQTTManager()
