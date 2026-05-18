import re
from datetime import datetime, timezone

from bson import ObjectId
from fastapi import HTTPException, status

from app.models.trip import create_trip_document
from app.repositories.trip_repository import TripRepository
from app.schemas.trip import (
    ProfileStatsResponse,
    TripCountsResponse,
    TripCreateRequest,
    TripResponse,
    TripsListResponse,
)


class TripService:
    def __init__(self, repository: TripRepository):
        self.repository = repository

    async def list_trips(
        self,
        *,
        user_id: str,
        status: str | None = None,
    ) -> TripsListResponse:
        trips = await self.repository.list_trips(
            user_id=self._to_object_id(user_id),
            status=self._to_stored_status(status),
        )
        return TripsListResponse(items=trips, count=len(trips))

    async def get_counts(self, user_id: str) -> TripCountsResponse:
        counts = await self.repository.count_by_status(self._to_object_id(user_id))
        return TripCountsResponse(
            ongoing=counts.get("ongoing", 0),
            saved=counts.get("saved", 0),
            past=counts.get("completed", 0),
        )

    async def get_profile_stats(
        self,
        *,
        user_id: str,
        favorites_count: int,
    ) -> ProfileStatsResponse:
        user_object_id = self._to_object_id(user_id)
        status_counts = await self.repository.count_by_status(user_object_id)
        mode_counts = await self.repository.count_by_travel_mode(user_object_id)

        return ProfileStatsResponse(
            saved_trips=status_counts.get("saved", 0),
            favorites=favorites_count,
            past_trips=status_counts.get("completed", 0),
            casual_trips=mode_counts.get("casual", 0),
            nightlife_trips=mode_counts.get("night", 0),
            luxury_trips=mode_counts.get("luxury", 0),
        )

    async def save_trip(
        self,
        request: TripCreateRequest,
        user_id: str,
    ) -> TripResponse:
        payload = request.model_dump()
        payload["user_id"] = self._to_object_id(user_id)
        payload["travel_mode"] = self._normalize_travel_mode(payload.get("selected_mode"))
        payload["status"] = self._to_stored_status(payload.get("status")) or "saved"
        payload["estimated_cost"] = self._price_to_number(payload.get("price"))
        payload["completed_at"] = (
            datetime.now(timezone.utc) if payload["status"] == "completed" else None
        )

        trip_document = create_trip_document(payload)
        trip = await self.repository.upsert_trip_by_item_key(trip_document)
        return TripResponse(**trip)

    async def update_status(
        self,
        trip_id: str,
        status: str,
        user_id: str,
    ) -> TripResponse | None:
        trip = await self.repository.update_status(
            trip_id,
            user_id=self._to_object_id(user_id),
            status=self._to_stored_status(status) or "saved",
        )

        if not trip:
            return None

        return TripResponse(**trip)

    async def delete_trip(self, trip_id: str, user_id: str) -> bool:
        return await self.repository.delete_trip(trip_id, self._to_object_id(user_id))

    def _to_object_id(self, value: str) -> ObjectId:
        if not ObjectId.is_valid(value):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid user_id",
            )

        return ObjectId(value)

    def _normalize_travel_mode(self, value: str | None) -> str:
        normalized = (value or "").strip().lower()

        if normalized in {"casual", "luxury", "night"}:
            return normalized

        return "casual"

    def _to_stored_status(self, value: str | None) -> str | None:
        if value is None:
            return None

        normalized = value.strip().lower()

        if normalized == "past":
            return "completed"
        if normalized in {"saved", "ongoing", "completed"}:
            return normalized

        return None

    def _price_to_number(self, value: str | None) -> float | None:
        if not value:
            return None

        match = re.search(r"\d+(?:\.\d+)?", value.replace(",", ""))
        if not match:
            return None

        return float(match.group(0))
