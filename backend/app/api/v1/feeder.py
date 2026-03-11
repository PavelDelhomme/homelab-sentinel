from fastapi import APIRouter

router = APIRouter()


@router.get("")
async def feeder_status() -> dict:
    return {"status": "ok", "events": []}
