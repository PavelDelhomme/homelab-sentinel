from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import devices, energy, cameras, feeder, auth, automations
from app.core.config import settings
from app.services.mqtt_service import mqtt_manager

app = FastAPI(
    title="HomeLab API",
    version="1.0.0",
    docs_url="/api/docs" if settings.DEBUG else None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["Auth"])
app.include_router(devices.router, prefix="/api/v1/devices", tags=["Devices"])
app.include_router(energy.router, prefix="/api/v1/energy", tags=["Energy"])
app.include_router(cameras.router, prefix="/api/v1/cameras", tags=["Cameras"])
app.include_router(feeder.router, prefix="/api/v1/feeder", tags=["Feeder"])
app.include_router(automations.router, prefix="/api/v1/automations", tags=["Automations"])


@app.on_event("startup")
async def startup() -> None:
    await mqtt_manager.connect()


@app.on_event("shutdown")
async def shutdown() -> None:
    await mqtt_manager.disconnect()


@app.get("/")
async def root() -> dict:
    return {"service": "HomeLab API", "version": "1.0.0"}
