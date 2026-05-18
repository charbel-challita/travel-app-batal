from datetime import datetime, timezone
from typing import Any

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument


COLLECTION_NAME = "user_favorites"


def _serialize_favorite(favorite: dict[str, Any]) -> dict[str, Any]:
    favorite["_id"] = str(favorite["_id"])
    favorite["user_id"] = str(favorite["user_id"])
    favorite["target_id"] = str(favorite["target_id"])
    return favorite


class FavoriteRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.collection = database[COLLECTION_NAME]

    async def list_favorites(self, user_id: ObjectId) -> list[dict[str, Any]]:
        query: dict[str, Any] = {"user_id": user_id}

        cursor = self.collection.find(query).sort([("updated_at", -1), ("created_at", -1)])
        favorites = await cursor.to_list(length=None)
        return [_serialize_favorite(favorite) for favorite in favorites]

    async def count_favorites(self, user_id: ObjectId) -> int:
        return await self.collection.count_documents({"user_id": user_id})

    async def upsert_favorite(self, favorite_document: dict[str, Any]) -> dict[str, Any]:
        now = datetime.now(timezone.utc)
        query: dict[str, Any] = {
            "user_id": favorite_document["user_id"],
            "target_type": favorite_document["target_type"],
            "target_id": favorite_document["target_id"],
        }

        set_document = {
            key: value
            for key, value in favorite_document.items()
            if key not in {"created_at", "_id"}
        }

        favorite = await self.collection.find_one_and_update(
            query,
            {
                "$set": {
                    **set_document,
                    "updated_at": now,
                },
                "$setOnInsert": {
                    "created_at": favorite_document.get("created_at", now),
                },
            },
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )

        return _serialize_favorite(favorite)

    async def delete_favorite(
        self,
        target_id: ObjectId,
        user_id: ObjectId,
        target_type: str | None = None,
    ) -> bool:
        query: dict[str, Any] = {"user_id": user_id, "target_id": target_id}

        if target_type:
            query["target_type"] = target_type

        result = await self.collection.delete_one(query)
        return result.deleted_count == 1

    async def is_favorite(
        self,
        target_id: ObjectId,
        user_id: ObjectId,
        target_type: str | None = None,
    ) -> bool:
        query: dict[str, Any] = {"user_id": user_id, "target_id": target_id}

        if target_type:
            query["target_type"] = target_type

        favorite = await self.collection.find_one(query, {"_id": 1})
        return favorite is not None
