from app.repositories.ai_package_repository import (
    get_ai_package_by_id,
    list_ai_packages,
    suggest_ai_packages,
)


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
