from fastapi import APIRouter

router = APIRouter()


@router.get("")
async def automations_list() -> dict:
    return {"automations": []}
