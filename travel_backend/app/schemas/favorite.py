from datetime import datetime

from pydantic import BaseModel, Field


class FavoriteCreateRequest(BaseModel):
    target_id: str
    target_type: str
    item_key: str | None = None
    item_type: str | None = None
    title: str = ""
    location: str = ""
    image: str | None = None
    selected_mode: str = "Casual"
    price: str = ""
    rating: str = ""
    duration: str = ""
    tags: list[str] = Field(default_factory=list)
    source_collection: str = ""


class FavoriteResponse(BaseModel):
    id: str = Field(alias="_id")
    user_id: str
    target_id: str
    target_type: str
    item_key: str = ""
    item_type: str = "place"
    title: str = ""
    location: str = ""
    image: str | None = None
    selected_mode: str = "Casual"
    price: str = ""
    rating: str = ""
    duration: str = ""
    tags: list[str] = Field(default_factory=list)
    source_collection: str = ""
    created_at: datetime | None = None
    updated_at: datetime | None = None

    model_config = {
        "populate_by_name": True,
    }


class FavoritesListResponse(BaseModel):
    items: list[FavoriteResponse]
    count: int


class FavoriteCheckResponse(BaseModel):
    is_favorite: bool
