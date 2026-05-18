from datetime import datetime, timezone
from typing import Any


def create_ai_package_document(package_data: dict[str, Any]) -> dict[str, Any]:
    now = datetime.now(timezone.utc)

    return {
        "title": package_data["title"],
        "subtitle": package_data.get("subtitle", ""),
        "description": package_data.get("description", ""),
        "city": package_data["city"],
        "country": package_data["country"],
        "mode": package_data.get("mode", "Casual"),
        "price": package_data.get("price", 0),
        "currency": package_data.get("currency", "USD"),
        "rating": package_data.get("rating", 4.5),
        "tag": package_data.get("tag", "Package"),
        "image_url": package_data.get("image_url"),
        "image_asset": package_data.get("image_asset"),
        "included_rules": package_data.get(
            "included_rules",
            {
                "hotel": 1,
                "activity": 2,
                "restaurant": 0,
                "nightlife": 0,
            },
        ),
        "is_active": True,
        "created_at": now,
        "updated_at": now,
    }