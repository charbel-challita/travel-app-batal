from typing import Optional

from pydantic import BaseModel, Field


class IncludedRules(BaseModel):
    hotel: int = 1
    activity: int = 2
    restaurant: int = 0
    nightlife: int = 0


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
