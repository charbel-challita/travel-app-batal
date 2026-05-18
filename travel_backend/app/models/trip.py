from datetime import datetime, timezone
from typing import Any


def create_trip_document(trip_data: dict[str, Any]) -> dict[str, Any]:
    now = datetime.now(timezone.utc)

    return {
        "user_id": trip_data["user_id"],
        "ai_package_id": trip_data.get("ai_package_id"),
        "item_key": trip_data["item_key"],
        "title": trip_data["title"],
        "location": trip_data.get("location", ""),
        "country": trip_data.get("country"),
        "city": trip_data.get("city"),
        "image": trip_data.get("image"),
        "selected_mode": trip_data.get("selected_mode", "Casual"),
        "travel_mode": trip_data["travel_mode"],
        "status": trip_data.get("status", "saved"),
        "tags": trip_data.get("tags", []),
        "interests": trip_data.get("tags", []),
        "price": trip_data.get("price", ""),
        "estimated_cost": trip_data.get("estimated_cost"),
        "rating": trip_data.get("rating", ""),
        "duration": trip_data.get("duration", ""),
        "duration_label": trip_data.get("duration", ""),
        "selected_item_ids": [],
        "cover_image_url": trip_data.get("image"),
        "notes": None,
        "start_date": None,
        "end_date": None,
        "completed_at": trip_data.get("completed_at"),
        "created_at": now,
        "updated_at": now,
    }
