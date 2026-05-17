from typing import Any

from pydantic import BaseModel, Field, field_validator


class TravelItemFlags(BaseModel):
    family_friendly: bool
    culture_item: bool
    romantic_item: bool
    adventure_item: bool
    nightlife_item: bool


class TravelItemImage(BaseModel):
    url: str | None = None
    thumbnail_url: str | None = None
    source: str | None = None
    alt: str | None = None
    photographer: str | None = None
    source_url: str | None = None


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
    images: list[TravelItemImage] = Field(default_factory=list)

    @field_validator("images", mode="before")
    @classmethod
    def normalize_images(cls, value: Any) -> list[Any]:
        if not value:
            return []
        if not isinstance(value, list):
            return []

        normalized_images: list[Any] = []
        for image in value:
            if isinstance(image, str):
                if image.strip():
                    normalized_images.append({"url": image})
            elif isinstance(image, dict):
                normalized_images.append(image)
        return normalized_images


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
