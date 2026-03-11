from fastapi import APIRouter

router = APIRouter()


@router.get("")
async def list_devices() -> dict:
    return {"devices": []}
