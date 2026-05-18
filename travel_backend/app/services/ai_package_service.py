from app.repositories.ai_package_repository import (
    get_ai_package_by_id,
    list_ai_packages,
)


async def get_ai_packages(mode: str | None = None, limit: int = 20) -> dict:
    packages = await list_ai_packages(mode=mode, limit=limit)

    return {
        "items": packages,
        "count": len(packages),
    }


async def get_ai_package(package_id: str) -> dict | None:
    return await get_ai_package_by_id(package_id)