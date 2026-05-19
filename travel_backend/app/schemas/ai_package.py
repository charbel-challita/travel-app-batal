from typing import Optional

from pydantic import BaseModel, Field


class IncludedRules(BaseModel):
    hotel: int = 1
    activity: int = 2
    restaurant: int = 0
    nightlife: int = 0


class ManualPackageCreateRequest(BaseModel):
    title: str = Field(..., min_length=1)
    subtitle: str = ""
    description: str = ""
    country: str = Field(..., min_length=1)
    city: str = Field(..., min_length=1)
    mode: str = "Casual"
    currency: str = "USD"
    days: int = Field(default=1, ge=1, le=30)
    travelers: str = "Solo"
    interests: list[str] = Field(default_factory=list)
    hotel_id: str | None = None
    activity_ids: list[str] = Field(default_factory=list)
    restaurant_ids: list[str] = Field(default_factory=list)
    nightlife_ids: list[str] = Field(default_factory=list)


class ManualPackageAddItemRequest(BaseModel):
    item_id: str | None = None
    item_type: str | None = None
    item: dict = Field(default_factory=dict)


class AIPackageResponse(BaseModel):
    id: str = Field(alias="_id")
    title: str
    subtitle: str = ""
    description: str = ""
    city: str
    country: str
    mode: str = "Casual"
    price: float = 0
    currency: str = "USD"
    rating: float = 4.5
    tag: str = "Package"
    image_url: Optional[str] = None
    image_asset: Optional[str] = None
    included_rules: IncludedRules
    source: str = ""
    visibility: str = ""
    is_active: bool = True

    model_config = {
        "populate_by_name": True,
    }


class AIPackageListResponse(BaseModel):
    items: list[AIPackageResponse]
    count: int


class AIPackageSuggestion(BaseModel):
    label: str
    value: str
    package_id: str
    city: str = ""
    country: str = ""
    mode: str = "Casual"


class AIPackageSuggestionsResponse(BaseModel):
    suggestions: list[AIPackageSuggestion]
    count: int


class AIGeneratePackageRequest(BaseModel):
    country: str
    days: int = Field(default=3, ge=1, le=30)
    budget_level: str = "mid-range"
    custom_budget: float | None = Field(default=None, ge=1)
    trip_style: str = "culture"
    travelers: str = "friends"
    interests: list[str] = []
    mode: str = "Casual"


class AIGeneratePackageValidation(BaseModel):
    valid: bool
    errors: list[str] = []


class AIGeneratePackageResponse(BaseModel):
    package: dict
    validation: AIGeneratePackageValidation
