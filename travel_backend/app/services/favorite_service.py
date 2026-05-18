import hashlib

from bson import ObjectId
from fastapi import HTTPException, status

from app.models.favorite import create_favorite_document
from app.repositories.favorite_repository import FavoriteRepository
from app.schemas.favorite import (
    FavoriteCheckResponse,
    FavoriteCreateRequest,
    FavoriteResponse,
    FavoritesListResponse,
)


class FavoriteService:
    def __init__(self, repository: FavoriteRepository):
        self.repository = repository

    async def list_favorites(self, user_id: str) -> FavoritesListResponse:
        user_object_id = self._to_object_id(user_id, field_name="user_id")
        favorites = await self.repository.list_favorites(user_id=user_object_id)
        return FavoritesListResponse(items=favorites, count=len(favorites))

    async def add_favorite(
        self,
        request: FavoriteCreateRequest,
        user_id: str,
    ) -> FavoriteResponse:
        payload = request.model_dump()
        payload["user_id"] = self._to_object_id(user_id, field_name="user_id")
        payload["target_type"] = self._normalize_target_type(payload["target_type"])
        payload["target_id"] = self._target_object_id(payload["target_id"])
        payload["travel_mode"] = self._normalize_travel_mode(payload.get("selected_mode"))

        favorite_document = create_favorite_document(payload)
        favorite = await self.repository.upsert_favorite(favorite_document)
        return FavoriteResponse(**favorite)

    async def remove_favorite(
        self,
        target_id: str,
        user_id: str,
    ) -> bool:
        return await self.repository.delete_favorite(
            self._target_object_id(target_id),
            user_id=self._to_object_id(user_id, field_name="user_id"),
        )

    async def check_favorite(
        self,
        target_id: str,
        user_id: str,
    ) -> FavoriteCheckResponse:
        is_favorite = await self.repository.is_favorite(
            self._target_object_id(target_id),
            user_id=self._to_object_id(user_id, field_name="user_id"),
        )
        return FavoriteCheckResponse(is_favorite=is_favorite)

    def _to_object_id(self, value: str, *, field_name: str) -> ObjectId:
        if not ObjectId.is_valid(value):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid {field_name}",
            )

        return ObjectId(value)

    def _target_object_id(self, value: str) -> ObjectId:
        if ObjectId.is_valid(value):
            return ObjectId(value)

        digest = hashlib.md5(value.encode("utf-8")).hexdigest()[:24]
        return ObjectId(digest)

    def _normalize_target_type(self, value: str) -> str:
        normalized = value.strip().lower()

        if normalized in {"package", "ai_package", "hardcoded_package"}:
            return "ai_package"
        if normalized in {"activity", "hotel", "restaurant", "nightlife", "place", "travel_item"}:
            return "travel_item"
        if normalized == "trip":
            return "trip"

        return "travel_item"

    def _normalize_travel_mode(self, value: str | None) -> str | None:
        normalized = (value or "").strip().lower()

        if normalized in {"casual", "luxury", "night"}:
            return normalized

        return None
