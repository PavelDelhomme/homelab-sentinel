from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    DEBUG: bool = True
    SECRET_KEY: str = "change-me-in-production"
    ALLOWED_ORIGINS: list[str] = ["http://localhost:5173", "http://localhost:3000"]
    DATABASE_URL: str = "postgresql+asyncpg://homelab:secret@localhost:5432/homelab"
    MQTT_HOST: str | None = None
    MQTT_PORT: int = 8883

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
