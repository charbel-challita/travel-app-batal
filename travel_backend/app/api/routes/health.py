from fastapi import APIRouter, HTTPException

from app.core.config import get_settings
from app.db.mongodb import ping_mongodb


router = APIRouter(prefix="/health", tags=["health"])


@router.get("/db")
async def health_db():
    settings = get_settings()

    try:
        await ping_mongodb()
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail={
                "status": "error",
                "database": settings.database_name,
                "mongodb": "disconnected",
                "error": str(exc),
            },
        ) from exc

    return {
        "status": "ok",
        "database": settings.database_name,
        "mongodb": "connected",
    }
