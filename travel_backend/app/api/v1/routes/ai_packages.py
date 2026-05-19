from typing import Any

from fastapi import APIRouter, HTTPException, Query

from app.core.config import get_settings
from app.schemas.ai_package import (
    AIGeneratePackageRequest,
    AIGeneratePackageResponse,
    AIGeneratePackageValidation,
    AIPackageListResponse,
    AIPackageResponse,
    AIPackageSuggestionsResponse,
)
from app.services.ai_package_service import (
    get_ai_package,
    get_ai_package_suggestions,
    get_ai_packages,
)
from app.services.image_service import ImageService
from app.services.travel_ai.recommender import generate_package
from app.services.travel_ai.validator import validate_package


router = APIRouter(prefix="/ai-packages", tags=["AI Packages"])


async def enrich_ai_item_with_image(
    item: dict[str, Any],
    image_service: ImageService,
) -> dict[str, Any]:
    if not item:
        return item

    if str(item.get("image_url") or "").strip():
        return item

    images = await image_service.fetch_images_for_item(item)

    if images:
        first_image = images[0]
        item["image_url"] = first_image.get("thumbnail_url") or first_image.get("url") or ""
        item["primary_image_url"] = first_image.get("url") or ""
        item["primary_thumbnail_url"] = first_image.get("thumbnail_url") or ""

    return item


async def enrich_ai_package_with_images(package: dict[str, Any]) -> dict[str, Any]:
    settings = get_settings()
    image_service = ImageService(settings)

    cover_images = await image_service.fetch_images_for_item(
        {
            "name": package.get("selected_city") or package.get("country") or "",
            "city": package.get("selected_city") or "",
            "country": package.get("country") or "",
            "category": "travel city destination",
            "type": "destination",
        }
    )

    if cover_images:
        first_cover = cover_images[0]
        package["cover_image_url"] = (
            first_cover.get("url")
            or first_cover.get("thumbnail_url")
            or ""
        )

    hotel_details = package.get("selected_hotel_details")
    if isinstance(hotel_details, dict):
        package["selected_hotel_details"] = await enrich_ai_item_with_image(
            hotel_details,
            image_service,
        )

    activity_details = package.get("selected_activities_details")
    if isinstance(activity_details, list):
        enriched_activities = []
        for item in activity_details:
            if isinstance(item, dict):
                enriched_activities.append(
                    await enrich_ai_item_with_image(item, image_service)
                )
        package["selected_activities_details"] = enriched_activities

    restaurant_details = package.get("selected_restaurants_details")
    if isinstance(restaurant_details, list):
        enriched_restaurants = []
        for item in restaurant_details:
            if isinstance(item, dict):
                enriched_restaurants.append(
                    await enrich_ai_item_with_image(item, image_service)
                )
        package["selected_restaurants_details"] = enriched_restaurants

    return package


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


@router.post("/generate", response_model=AIGeneratePackageResponse)
async def generate_ai_package(request: AIGeneratePackageRequest):
    interests_text = ";".join(request.interests)

    trip_style = request.trip_style
    budget_level = request.budget_level

    if request.mode.lower() == "luxury":
        budget_level = "luxury"

    if request.mode.lower() == "night":
        trip_style = "nightlife"

        night_interests = ["nightlife", "club", "bar", "party"]
        existing_interests = [interest.lower() for interest in request.interests]

        for interest in night_interests:
            if interest not in existing_interests:
                request.interests.append(interest)

        interests_text = ";".join(request.interests)

    package = generate_package(
        country=request.country,
        days=request.days,
        budget_level=budget_level,
        trip_style=trip_style,
        travelers=request.travelers,
        interests=interests_text,
        mode=request.mode,
        custom_budget=request.custom_budget,
    )

    validation_result = validate_package(package)

    if "error" not in package:
        package = await enrich_ai_package_with_images(package)

    return AIGeneratePackageResponse(
        package=package,
        validation=AIGeneratePackageValidation(**validation_result),
    )


@router.get("/{package_id}", response_model=AIPackageResponse)
async def package_details(package_id: str):
    package = await get_ai_package(package_id)

    if not package:
        raise HTTPException(status_code=404, detail="Package not found")

    return package
