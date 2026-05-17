from typing import Any

from pydantic import BaseModel, Field


class TravelItemFlags(BaseModel):
    family_friendly: bool
    culture_item: bool
    romantic_item: bool
    adventure_item: bool
    nightlife_item: bool


class TravelItemResponse(BaseModel):
    id: str
    country: str
    city: str
    type: str
    name: str
    category: str
    cost: float
    currency: str = "USD"
    duration_hours: float
    rating: float
    interest_tags: list[str] = Field(default_factory=list)
    item_budget_level: str
    flags: TravelItemFlags
    images: list[str] = Field(default_factory=list)


class TravelItemsListResponse(BaseModel):
    items: list[TravelItemResponse]
    count: int


class TravelItemsSearchResponse(BaseModel):
    query: str
    items: list[dict[str, Any]]
    count: int


class FeaturedTravelItemsResponse(BaseModel):
    items: list[dict[str, Any]]
    count: int
