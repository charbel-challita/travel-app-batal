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

    async def find_city_suggestions(
        self,
        prefix_filter: dict[str, Any],
        limit: int,
        filters: dict[str, Any] | None = None,
    ) -> list[dict[str, Any]]:
        pipeline: list[dict[str, Any]] = [
            {
                "$match": {
                    "is_active": True,
                    **(filters or {}),
                    "city_normalized": prefix_filter,
                }
            },
            {"$sort": {"city_normalized": 1, "country_normalized": 1, "city": 1, "country": 1}},
            {
                "$group": {
                    "_id": {
                        "city_normalized": "$city_normalized",
                        "country_normalized": "$country_normalized",
                    },
                    "city": {"$first": "$city"},
                    "country": {"$first": "$country"},
                }
            },
            {"$sort": {"city": 1, "country": 1}},
            {"$limit": limit},
            {"$project": {"_id": 0, "city": 1, "country": 1}},
        ]
        cursor = self.collection.aggregate(pipeline)
        return await cursor.to_list(length=limit)

    async def find_country_suggestions(
        self,
        prefix_filter: dict[str, Any],
        limit: int,
        filters: dict[str, Any] | None = None,
    ) -> list[dict[str, Any]]:
        pipeline: list[dict[str, Any]] = [
            {
                "$match": {
                    "is_active": True,
                    **(filters or {}),
                    "country_normalized": prefix_filter,
                }
            },
            {"$sort": {"country_normalized": 1, "country": 1}},
            {
                "$group": {
                    "_id": "$country_normalized",
                    "country": {"$first": "$country"},
                }
            },
            {"$sort": {"country": 1}},
            {"$limit": limit},
            {"$project": {"_id": 0, "country": 1}},
        ]
        cursor = self.collection.aggregate(pipeline)
        return await cursor.to_list(length=limit)

    async def find_item_suggestions(
        self,
        prefix_filter: dict[str, Any],
        limit: int,
        filters: dict[str, Any] | None = None,
    ) -> list[dict[str, Any]]:
        pipeline: list[dict[str, Any]] = [
            {
                "$match": {
                    "is_active": True,
                    **(filters or {}),
                    "name_normalized": prefix_filter,
                }
            },
            {
                "$sort": {
                    "name_normalized": 1,
                    "city_normalized": 1,
                    "country_normalized": 1,
                    "type": 1,
                    "rating": -1,
                }
            },
            {
                "$group": {
                    "_id": {
                        "name_normalized": "$name_normalized",
                        "city_normalized": "$city_normalized",
                        "country_normalized": "$country_normalized",
                        "type": "$type",
                    },
                    "name": {"$first": "$name"},
                    "type": {"$first": "$type"},
                    "city": {"$first": "$city"},
                    "country": {"$first": "$country"},
                }
            },
            {"$sort": {"name": 1, "city": 1, "country": 1, "type": 1}},
            {"$limit": limit},
            {"$project": {"_id": 0, "name": 1, "type": 1, "city": 1, "country": 1}},
        ]
        cursor = self.collection.aggregate(pipeline)
        return await cursor.to_list(length=limit)

    async def find_filtered_item_suggestions(
        self,
        prefix_filter: dict[str, Any],
        limit: int,
        filters: dict[str, Any],
    ) -> list[dict[str, Any]]:
        pipeline: list[dict[str, Any]] = [
            {
                "$match": {
                    "is_active": True,
                    **filters,
                    "name_normalized": prefix_filter,
                }
            },
            {
                "$sort": {
                    "name_normalized": 1,
                    "city_normalized": 1,
                    "country_normalized": 1,
                    "type": 1,
                    "rating": -1,
                }
            },
            {
                "$group": {
                    "_id": {
                        "name_normalized": "$name_normalized",
                        "city_normalized": "$city_normalized",
                        "country_normalized": "$country_normalized",
                        "type": "$type",
                    },
                    "name": {"$first": "$name"},
                    "type": {"$first": "$type"},
                    "city": {"$first": "$city"},
                    "country": {"$first": "$country"},
                }
            },
            {"$sort": {"name": 1, "city": 1, "country": 1, "type": 1}},
            {"$limit": limit},
            {"$project": {"_id": 0, "name": 1, "type": 1, "city": 1, "country": 1}},
        ]
        cursor = self.collection.aggregate(pipeline)
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
