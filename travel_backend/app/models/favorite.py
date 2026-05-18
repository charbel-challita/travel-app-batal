from datetime import datetime, timezone
from typing import Any


def create_favorite_document(favorite_data: dict[str, Any]) -> dict[str, Any]:
    now = datetime.now(timezone.utc)
    item_key = favorite_data.get("item_key") or favorite_data["target_id"]
    item_type = favorite_data.get("item_type") or favorite_data["target_type"]

    return {
        "user_id": favorite_data["user_id"],
        "target_type": favorite_data["target_type"],
        "target_id": favorite_data["target_id"],
        "item_key": item_key,
        "item_type": item_type,
        "title": favorite_data["title"],
        "location": favorite_data.get("location", ""),
        "image": favorite_data.get("image"),
        "selected_mode": favorite_data.get("selected_mode", "Casual"),
        "travel_mode": favorite_data.get("travel_mode"),
        "price": favorite_data.get("price", ""),
        "rating": favorite_data.get("rating", ""),
        "duration": favorite_data.get("duration", ""),
        "tags": favorite_data.get("tags", []),
        "source_collection": favorite_data.get("source_collection", ""),
        "created_at": now,
        "updated_at": now,
    }
