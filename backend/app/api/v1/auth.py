from fastapi import APIRouter

router = APIRouter()


@router.post("/login")
async def login() -> dict:
    return {"message": "TODO: JWT login"}
