from datetime import datetime, timezone
from typing import Any

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument


COLLECTION_NAME = "trips"
ALLOWED_STATUSES = {"saved", "ongoing", "completed"}


def _serialize_trip(trip: dict[str, Any]) -> dict[str, Any]:
    trip["_id"] = str(trip["_id"])
    trip["user_id"] = str(trip["user_id"])
    if trip.get("ai_package_id") is not None:
        trip["ai_package_id"] = str(trip["ai_package_id"])
    trip["status"] = "past" if trip.get("status") == "completed" else trip.get("status")
    return trip


class TripRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.collection = database[COLLECTION_NAME]

    async def list_trips(
        self,
        *,
        user_id: ObjectId,
        status: str | None = None,
    ) -> list[dict[str, Any]]:
        query: dict[str, Any] = {"user_id": user_id}

        if status in ALLOWED_STATUSES:
            query["status"] = status

        cursor = self.collection.find(query).sort([("updated_at", -1), ("created_at", -1)])
        trips = await cursor.to_list(length=None)
        return [_serialize_trip(trip) for trip in trips]

    async def count_by_status(self, user_id: ObjectId) -> dict[str, int]:
        counts = {status: 0 for status in ALLOWED_STATUSES}

        pipeline = [
            {
                "$match": {
                    "user_id": user_id,
                    "status": {"$in": list(ALLOWED_STATUSES)},
                },
            },
            {"$group": {"_id": "$status", "count": {"$sum": 1}}},
        ]

        async for row in self.collection.aggregate(pipeline):
            counts[row["_id"]] = row["count"]

        return counts

    async def count_by_travel_mode(self, user_id: ObjectId) -> dict[str, int]:
        counts = {
            "casual": 0,
            "night": 0,
            "luxury": 0,
        }

        pipeline = [
            {"$match": {"user_id": user_id}},
            {"$group": {"_id": "$travel_mode", "count": {"$sum": 1}}},
        ]

        async for row in self.collection.aggregate(pipeline):
            mode = row["_id"]
            if mode in counts:
                counts[mode] = row["count"]

        return counts

    async def upsert_trip_by_item_key(
        self,
        trip_document: dict[str, Any],
    ) -> dict[str, Any]:
        now = datetime.now(timezone.utc)
        set_document = {
            key: value
            for key, value in trip_document.items()
            if key not in {"created_at", "_id"}
        }

        update_document = {
            "$set": {
                **set_document,
                "updated_at": now,
            },
            "$setOnInsert": {
                "created_at": trip_document.get("created_at", now),
            },
        }

        trip = await self.collection.find_one_and_update(
            {
                "user_id": trip_document["user_id"],
                "item_key": trip_document["item_key"],
            },
            update_document,
            upsert=True,
            return_document=ReturnDocument.AFTER,
        )

        return _serialize_trip(trip)

    async def update_status(
        self,
        trip_id: str,
        user_id: ObjectId,
        status: str,
    ) -> dict[str, Any] | None:
        if not ObjectId.is_valid(trip_id):
            return None

        trip = await self.collection.find_one_and_update(
            {"_id": ObjectId(trip_id), "user_id": user_id},
            {
                "$set": {
                    "status": status,
                    "updated_at": datetime.now(timezone.utc),
                    "completed_at": datetime.now(timezone.utc)
                    if status == "completed"
                    else None,
                },
            },
            return_document=ReturnDocument.AFTER,
        )

        if not trip:
            return None

        return _serialize_trip(trip)

    async def delete_trip(self, trip_id: str, user_id: ObjectId) -> bool:
        if not ObjectId.is_valid(trip_id):
            return False

        result = await self.collection.delete_one(
            {"_id": ObjectId(trip_id), "user_id": user_id}
        )
        return result.deleted_count == 1
