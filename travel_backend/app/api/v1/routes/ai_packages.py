from typing import Any

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import OAuth2PasswordBearer
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.config import get_settings
from app.db.mongodb import get_database
from app.repositories.user_repository import UserRepository
from app.schemas.ai_package import (
    AIGeneratePackageRequest,
    AIGeneratePackageResponse,
    AIGeneratePackageValidation,
    AIPackageListResponse,
    AIPackageResponse,
    AIPackageSuggestionsResponse,
    ManualPackageCreateRequest,
)
from app.schemas.user import UserResponse
from app.services.ai_package_service import (
    create_manual_ai_package,
    delete_manual_ai_package,
    get_accessible_ai_package,
    get_ai_package,
    get_ai_package_suggestions,
    get_ai_packages,
    get_my_ai_packages,
)
from app.services.auth_service import AuthService
from app.services.image_service import ImageService
from app.services.travel_ai.recommender import generate_package
from app.services.travel_ai.validator import validate_package


router = APIRouter(prefix="/ai-packages", tags=["AI Packages"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")
optional_oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl="/api/v1/auth/login",
    auto_error=False,
)


def get_auth_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> AuthService:
    repository = UserRepository(database)
    return AuthService(repository)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    return await service.get_current_user(token)


async def get_optional_current_user(
    token: str | None = Depends(optional_oauth2_scheme),
    service: AuthService = Depends(get_auth_service),
) -> UserResponse | None:
    if not token:
        return None
    try:
        return await service.get_current_user(token)
    except HTTPException:
        return None


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


@router.post("/manual", response_model=AIPackageResponse, status_code=201)
async def create_manual_package(
    request: ManualPackageCreateRequest,
    current_user: UserResponse = Depends(get_current_user),
):
    return await create_manual_ai_package(request, ObjectId(current_user.id))


@router.get("/my", response_model=AIPackageListResponse)
async def list_my_packages(
    current_user: UserResponse = Depends(get_current_user),
):
    return await get_my_ai_packages(ObjectId(current_user.id))


@router.delete("/{package_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_manual_package(
    package_id: str,
    current_user: UserResponse = Depends(get_current_user),
) -> None:
    deleted = await delete_manual_ai_package(package_id, ObjectId(current_user.id))
    if not deleted:
        raise HTTPException(status_code=404, detail="Package not found")


@router.get("/{package_id}", response_model=AIPackageResponse)
async def package_details(
    package_id: str,
    current_user: UserResponse | None = Depends(get_optional_current_user),
):
    if current_user is None:
        package = await get_ai_package(package_id)
    else:
        package = await get_accessible_ai_package(
            package_id,
            user_id=ObjectId(current_user.id),
        )

    if not package:
        raise HTTPException(status_code=404, detail="Package not found")

    return package
