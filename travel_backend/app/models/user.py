from typing import Any


DEFAULT_TRAVEL_MODE = "casual"
DEFAULT_PROFILE_LABEL = "Casual traveler"
DEFAULT_AUTH_PROVIDER = "email"


def default_user_stats() -> dict[str, int]:
    return {
        "saved_trips_count": 0,
        "favorites_count": 0,
        "past_trips_count": 0,
        "casual_trips_count": 0,
        "luxury_trips_count": 0,
        "night_trips_count": 0,
    }


def public_user_fields(document: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": str(document["_id"]),
        "full_name": document["full_name"],
        "email": document["email"],
        "default_travel_mode": document.get("default_travel_mode", DEFAULT_TRAVEL_MODE),
        "profile_label": document.get("profile_label", DEFAULT_PROFILE_LABEL),
        "avatar_url": document.get("avatar_url"),
    }
