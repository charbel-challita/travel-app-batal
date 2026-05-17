from typing import Any

from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase


class TravelItemRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.collection = database["travel_items"]

    async def find_travel_items(self, filters: dict[str, Any], limit: int) -> list[dict[str, Any]]:
        cursor = (
            self.collection.find(filters)
            .sort([("rating", -1), ("name_normalized", 1)])
            .limit(limit)
        )
        return await cursor.to_list(length=limit)

    async def search_travel_items(self, search_filter: dict[str, Any], limit: int) -> list[dict[str, Any]]:
        cursor = (
            self.collection.find(search_filter)
            .sort([("rating", -1), ("name_normalized", 1)])
            .limit(limit)
        )
        return await cursor.to_list(length=limit)

    async def find_featured_travel_items(self, filters: dict[str, Any], limit: int) -> list[dict[str, Any]]:
        cursor = (
            self.collection.find(filters)
            .sort([("rating", -1), ("name_normalized", 1)])
            .limit(limit)
        )
        return await cursor.to_list(length=limit)

    async def update_travel_item_images(self, item_id: Any, images: list[dict[str, Any]]) -> bool:
        try:
            object_id = item_id if isinstance(item_id, ObjectId) else ObjectId(str(item_id))
        except Exception:
            return False

        result = await self.collection.update_one(
            {"_id": object_id},
            {
                "$set": {
                    "images": images,
                    "updated_at": datetime.now(timezone.utc),
                }
            },
        )
        return result.modified_count > 0
