from bson import ObjectId

from app.db.mongodb import get_database


COLLECTION_NAME = "ai_packages"


def _serialize_package(package: dict) -> dict:
    package["_id"] = str(package["_id"])
    return package


async def list_ai_packages(
    mode: str | None = None,
    limit: int = 20,
) -> list[dict]:
    db = get_database()

    query: dict = {"is_active": True}

    if mode:
        query["mode"] = mode

    cursor = (
        db[COLLECTION_NAME]
        .find(query)
        .sort([("rating", -1), ("title", 1)])
        .limit(limit)
    )

    packages = await cursor.to_list(length=limit)
    return [_serialize_package(package) for package in packages]


async def get_ai_package_by_id(package_id: str) -> dict | None:
    db = get_database()

    if not ObjectId.is_valid(package_id):
        return None

    package = await db[COLLECTION_NAME].find_one(
        {
            "_id": ObjectId(package_id),
            "is_active": True,
        }
    )

    if not package:
        return None

    return _serialize_package(package)