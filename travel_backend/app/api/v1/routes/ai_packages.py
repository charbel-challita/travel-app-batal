from fastapi import APIRouter, HTTPException, Query

from app.schemas.ai_package import (
    AIPackageListResponse,
    AIPackageResponse,
    AIPackageSuggestionsResponse,
)
from app.services.ai_package_service import (
    get_ai_package,
    get_ai_package_suggestions,
    get_ai_packages,
)


router = APIRouter(prefix="/ai-packages", tags=["AI Packages"])


@router.get("", response_model=AIPackageListResponse)
async def list_packages(
    mode: str | None = Query(default=None),
    q: str | None = Query(default=None),
    interests: str | None = Query(default=None),
    city: str | None = Query(default=None),
    country: str | None = Query(default=None),
    limit: int = Query(default=10, ge=1, le=50),
):
    return await get_ai_packages(
        mode=mode,
        q=q,
        interests=interests,
        city=city,
        country=country,
        limit=limit,
    )


@router.get("/suggestions", response_model=AIPackageSuggestionsResponse)
async def package_suggestions(
    q: str = Query(..., min_length=1),
    mode: str | None = Query(default=None),
    interests: str | None = Query(default=None),
    limit: int = Query(default=5, ge=1, le=5),
):
    return await get_ai_package_suggestions(
        mode=mode,
        q=q,
        interests=interests,
        limit=limit,
    )


@router.get("/{package_id}", response_model=AIPackageResponse)
async def package_details(package_id: str):
    package = await get_ai_package(package_id)

    if not package:
        raise HTTPException(status_code=404, detail="Package not found")

    return package
