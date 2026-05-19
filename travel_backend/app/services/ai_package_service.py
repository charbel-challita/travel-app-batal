from app.repositories.ai_package_repository import (
    add_item_to_user_manual_package,
    create_user_manual_package,
    delete_user_manual_package,
    get_accessible_ai_package_by_id,
    get_ai_package_by_id,
    list_user_manual_packages,
    list_ai_packages,
    suggest_ai_packages,
)
from app.schemas.ai_package import ManualPackageCreateRequest


async def get_ai_packages(
    mode: str | None = None,
    q: str | None = None,
    interests: str | None = None,
    city: str | None = None,
    country: str | None = None,
    limit: int = 20,
) -> dict:
    packages = await list_ai_packages(
        mode=mode,
        q=q,
        interests=interests,
        city=city,
        country=country,
        limit=limit,
    )

    return {
        "items": packages,
        "count": len(packages),
    }


async def get_ai_package_suggestions(
    mode: str | None = None,
    q: str | None = None,
    interests: str | None = None,
    limit: int = 5,
) -> dict:
    suggestions = await suggest_ai_packages(
        mode=mode,
        q=q,
        interests=interests,
        limit=limit,
    )

    return {
        "suggestions": suggestions,
        "count": len(suggestions),
    }


async def get_ai_package(package_id: str) -> dict | None:
    return await get_ai_package_by_id(package_id)


async def get_accessible_ai_package(
    package_id: str,
    user_id=None,
) -> dict | None:
    return await get_accessible_ai_package_by_id(package_id, user_id=user_id)


async def get_my_ai_packages(user_id) -> dict:
    packages = await list_user_manual_packages(user_id)
    return {
        "items": packages,
        "count": len(packages),
    }


async def create_manual_ai_package(
    request: ManualPackageCreateRequest,
    user_id,
) -> dict:
    return await create_user_manual_package(request, user_id)


async def delete_manual_ai_package(package_id: str, user_id) -> bool:
    return await delete_user_manual_package(package_id, user_id)


async def add_item_to_manual_ai_package(
    package_id: str,
    user_id,
    item_id: str | None,
    item_type: str | None,
    item: dict,
) -> dict | None:
    return await add_item_to_user_manual_package(
        package_id,
        user_id,
        item_id,
        item_type,
        item,
    )
