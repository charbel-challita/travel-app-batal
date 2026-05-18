from fastapi import APIRouter, HTTPException, Query

from app.schemas.ai_package import AIPackageListResponse, AIPackageResponse
from app.services.ai_package_service import get_ai_package, get_ai_packages


router = APIRouter(prefix="/ai-packages", tags=["AI Packages"])


@router.get("", response_model=AIPackageListResponse)
async def list_packages(
    mode: str | None = Query(default=None),
    limit: int = Query(default=20, ge=1, le=50),
):
    return await get_ai_packages(mode=mode, limit=limit)


@router.get("/{package_id}", response_model=AIPackageResponse)
async def package_details(package_id: str):
    package = await get_ai_package(package_id)

    if not package:
        raise HTTPException(status_code=404, detail="Package not found")

    return package