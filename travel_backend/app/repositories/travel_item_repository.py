from typing import Any

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
