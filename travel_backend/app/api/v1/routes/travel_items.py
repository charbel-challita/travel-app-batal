from fastapi import APIRouter, Depends, HTTPException, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.repositories.travel_item_repository import TravelItemRepository
from app.schemas.travel_item import (
    FeaturedTravelItemsResponse,
    TravelItemSuggestionsResponse,
    TravelItemsListResponse,
    TravelItemsSearchResponse,
)
from app.services.travel_item_service import TravelItemService


router = APIRouter(prefix="/travel-items", tags=["travel-items"])


def get_travel_item_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> TravelItemService:
    repository = TravelItemRepository(database)
    return TravelItemService(repository)


@router.get("", response_model=TravelItemsListResponse)
async def list_travel_items(
    country: str | None = None,
    city: str | None = None,
    type: str | None = Query(default=None, pattern="^(activity|hotel|restaurant|nightlife)$"),
    budget_level: str | None = Query(default=None, pattern="^(low|mid|luxury)$"),
    interests: str | None = None,
    min_rating: float | None = Query(default=None, ge=0, le=5),
    family_friendly: bool | None = None,
    culture: bool | None = None,
    romantic: bool | None = None,
    adventure: bool | None = None,
    nightlife: bool | None = None,
    include_images: bool = False,
    limit: int = Query(default=20, ge=1, le=100),
    service: TravelItemService = Depends(get_travel_item_service),
) -> TravelItemsListResponse:
    items = await service.list_travel_items(
        country=country,
        city=city,
        type=type,
        budget_level=budget_level,
        interests=interests,
        min_rating=min_rating,
        family_friendly=family_friendly,
        culture=culture,
        romantic=romantic,
        adventure=adventure,
        nightlife=nightlife,
        include_images=include_images,
        limit=limit,
    )
    return TravelItemsListResponse(items=items, count=len(items))


@router.get(
    "/suggestions",
    response_model=TravelItemSuggestionsResponse,
    response_model_exclude_none=True,
)
async def suggest_travel_items(
    q: str = Query(..., min_length=1),
    limit: int = Query(default=5, ge=1),
    country: str | None = None,
    city: str | None = None,
    type: str | None = Query(
        default=None,
        pattern="^(activity|hotel|restaurant|nightlife)$",
    ),
    category: str | None = None,
    budget_level: str | None = Query(
        default=None,
        pattern="^(low|mid|luxury)$",
    ),
    interests: str | None = None,
    family_friendly: bool | None = None,
    culture: bool | None = None,
    romantic: bool | None = None,
    adventure: bool | None = None,
    nightlife: bool | None = None,
    service: TravelItemService = Depends(get_travel_item_service),
) -> TravelItemSuggestionsResponse:
    return await service.suggest_travel_items(
        q=q,
        limit=limit,
        country=country,
        city=city,
        type=type,
        category=category,
        budget_level=budget_level,
        interests=interests,
        family_friendly=family_friendly,
        culture=culture,
        romantic=romantic,
        adventure=adventure,
        nightlife=nightlife,
    )


@router.get("/search", response_model=TravelItemsSearchResponse)
async def search_travel_items(
    q: str = Query(..., min_length=1),
    include_images: bool = False,
    limit: int = Query(default=20, ge=1, le=100),
    country: str | None = None,
    city: str | None = None,
    type: str | None = Query(
        default=None,
        pattern="^(activity|hotel|restaurant|nightlife)$",
    ),
    category: str | None = None,
    budget_level: str | None = Query(
        default=None,
        pattern="^(low|mid|luxury)$",
    ),
    interests: str | None = None,
    family_friendly: bool | None = None,
    culture: bool | None = None,
    romantic: bool | None = None,
    adventure: bool | None = None,
    nightlife: bool | None = None,
    service: TravelItemService = Depends(get_travel_item_service),
) -> TravelItemsSearchResponse:
    if not q.strip():
        raise HTTPException(status_code=422, detail="q must contain search text")
    return await service.search_travel_items(
        q=q,
        include_images=include_images,
        limit=limit,
        country=country,
        city=city,
        type=type,
        category=category,
        budget_level=budget_level,
        interests=interests,
        family_friendly=family_friendly,
        culture=culture,
        romantic=romantic,
        adventure=adventure,
        nightlife=nightlife,
    )


@router.get("/featured", response_model=FeaturedTravelItemsResponse)
async def list_featured_travel_items(
    country: str | None = None,
    city: str | None = None,
    type: str | None = Query(default=None, pattern="^(activity|hotel|restaurant|nightlife)$"),
    budget_level: str | None = Query(default=None, pattern="^(low|mid|luxury)$"),
    limit: int = Query(default=12, ge=1, le=50),
    service: TravelItemService = Depends(get_travel_item_service),
) -> FeaturedTravelItemsResponse:
    return await service.list_featured_travel_items(
        country=country,
        city=city,
        type=type,
        budget_level=budget_level,
        limit=limit,
    )
