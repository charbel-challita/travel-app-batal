from typing import Any

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError


class DuplicateEmailError(Exception):
    pass


class UserRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.collection = database["users"]

    async def find_by_email(self, email: str) -> dict[str, Any] | None:
        return await self.collection.find_one({"email": email.lower()})

    async def find_by_id(self, user_id: str) -> dict[str, Any] | None:
        try:
            object_id = ObjectId(user_id)
        except Exception:
            return None
        return await self.collection.find_one({"_id": object_id})

    async def create_user(self, user: dict[str, Any]) -> dict[str, Any]:
        try:
            result = await self.collection.insert_one(user)
        except DuplicateKeyError as error:
            raise DuplicateEmailError from error

        created_user = await self.collection.find_one({"_id": result.inserted_id})
        if created_user is None:
            raise RuntimeError("Created user could not be loaded")
        return created_user

    async def update_last_login(self, user_id: str, last_login_at: Any) -> None:
        try:
            object_id = ObjectId(user_id)
        except Exception:
            return

        await self.collection.update_one(
            {"_id": object_id},
            {"$set": {"last_login_at": last_login_at, "updated_at": last_login_at}},
        )

    async def update_user(self, user_id: str, updates: dict[str, Any]) -> dict[str, Any] | None:
        try:
            object_id = ObjectId(user_id)
        except Exception:
            return None

        await self.collection.update_one(
            {"_id": object_id},
            {"$set": updates},
        )

        return await self.collection.find_one({"_id": object_id})
