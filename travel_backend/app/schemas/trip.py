from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


TripStatus = Literal["saved", "ongoing", "past"]


class TripCreateRequest(BaseModel):
    item_key: str = ""
    title: str
    location: str = ""
    image: str | None = None
    selected_mode: str = "Casual"
    status: TripStatus = "saved"
    tags: list[str] = Field(default_factory=list)
    price: str = ""
    rating: str = ""
    duration: str = ""
    item_type: str = ""
    target_type: str = ""
    source_collection: str = ""


class TripStatusUpdateRequest(BaseModel):
    status: TripStatus


class TripResponse(BaseModel):
    id: str = Field(alias="_id")
    item_key: str
    title: str
    location: str = ""
    image: str | None = None
    selected_mode: str = "Casual"
    status: TripStatus
    tags: list[str] = Field(default_factory=list)
    price: str = ""
    rating: str = ""
    duration: str = ""
    item_type: str = ""
    target_type: str = ""
    source_collection: str = ""
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {
        "populate_by_name": True,
    }


class TripsListResponse(BaseModel):
    items: list[TripResponse]
    count: int


class TripCountsResponse(BaseModel):
    ongoing: int = 0
    saved: int = 0
    past: int = 0


class ProfileStatsResponse(BaseModel):
    saved_trips: int = 0
    favorites: int = 0
    past_trips: int = 0
    casual_trips: int = 0
    nightlife_trips: int = 0
    luxury_trips: int = 0
