import re
from typing import Any

from bson import ObjectId

from app.db.mongodb import get_database


COLLECTION_NAME = "ai_packages"


def _read_nested(document: dict[str, Any], *path: str) -> Any:
    value: Any = document

    for key in path:
        if not isinstance(value, dict):
            return None
        value = value.get(key)

    return value


def _first_value(document: dict[str, Any], *paths: tuple[str, ...]) -> Any:
    for path in paths:
        value = _read_nested(document, *path)
        if value not in (None, "", []):
            return value
    return None


def _normalize_mode(value: Any) -> str:
    normalized = str(value or "Casual").strip().lower()
    if normalized == "luxury":
        return "Luxury"
    if normalized == "night":
        return "Night"
    return "Casual"


def _serialize_package(package: dict) -> dict:
    document = dict(package)
    package_id = str(document["_id"])
    title = _first_value(
        document,
        ("title",),
        ("package_name",),
        ("name",),
        ("validated_result", "title"),
        ("validated_result", "package_name"),
        ("ai_raw_response", "title"),
    )
    city = _first_value(
        document,
        ("city",),
        ("selected_city",),
        ("request", "city"),
        ("validated_result", "city"),
        ("validated_result", "selected_city"),
    )
    country = _first_value(
        document,
        ("country",),
        ("request", "country"),
        ("validated_result", "country"),
    )
    mode = _normalize_mode(
        _first_value(
            document,
            ("mode",),
            ("selected_mode",),
            ("trip_style",),
            ("request", "travel_mode"),
            ("request", "trip_style"),
        )
    )
    interests = _first_value(
        document,
        ("interests",),
        ("interest_tags",),
        ("tags",),
        ("request", "interests"),
        ("validated_result", "interests"),
        ("validated_result", "tags"),
    )
    first_interest = ""
    if isinstance(interests, list) and interests:
        first_interest = str(interests[0]).replace("_", " ").title()

    included_rules = document.get("included_rules")
    if not isinstance(included_rules, dict):
        included_rules = {"hotel": 1, "activity": 2, "restaurant": 0, "nightlife": 0}

    return {
        "_id": package_id,
        "title": str(title or "AI Travel Package"),
        "subtitle": str(
            _first_value(
                document,
                ("subtitle",),
                ("validated_result", "subtitle"),
                ("description",),
            )
            or f"{city or 'Selected city'}, {country or 'Selected country'}"
        ),
        "description": str(
            _first_value(
                document,
                ("description",),
                ("validated_result", "description"),
                ("ai_raw_response", "description"),
            )
            or ""
        ),
        "city": str(city or ""),
        "country": str(country or ""),
        "mode": mode,
        "price": float(
            _first_value(
                document,
                ("price",),
                ("estimated_price",),
                ("validated_result", "price"),
                ("validated_result", "estimated_total_cost"),
            )
            or 0
        ),
        "currency": str(document.get("currency") or "USD"),
        "rating": float(
            _first_value(document, ("rating",), ("validated_result", "rating")) or 4.5
        ),
        "tag": str(document.get("tag") or first_interest or mode),
        "image_url": document.get("image_url"),
        "image_asset": document.get("image_asset"),
        "included_rules": included_rules,
        "is_active": document.get("is_active", True),
    }


def _regex(value: str) -> dict[str, str]:
    return {"$regex": re.escape(value), "$options": "i"}


def _field_regex(fields: list[str], value: str) -> dict:
    return {"$or": [{field: _regex(value)} for field in fields]}


def _interest_aliases(value: str) -> list[str]:
    normalized = value.strip().lower()
    aliases = {
        "clubs": ["clubs", "club", "nightlife"],
        "bars": ["bars", "bar", "nightlife"],
        "rooftops": ["rooftops", "rooftop", "skyline"],
        "live music": ["live music", "music"],
        "fine dining": ["fine dining", "dining", "restaurant", "food"],
        "scenic flights": ["scenic flights", "scenic", "flight", "seaplane"],
        "exclusive stays": ["exclusive stays", "exclusive", "stay", "lodge"],
        "private": ["private", "luxury"],
        "beach": ["beach", "coast", "island"],
    }

    values = aliases.get(normalized, [normalized])
    return [alias for alias in values if alias]


def _base_query() -> dict:
    return {
        "$and": [
            {"$or": [{"is_active": True}, {"is_active": {"$exists": False}}]},
            {
                "$or": [
                    {"status": {"$in": ["generated", "saved"]}},
                    {"status": {"$exists": False}},
                ]
            },
        ]
    }


def _mode_query(mode: str | None) -> dict | None:
    normalized = (mode or "").strip().lower()
    if not normalized:
        return None

    if normalized == "luxury":
        return {
            "$or": [
                {"mode": _regex("luxury")},
                {"selected_mode": _regex("luxury")},
                {"trip_style": _regex("luxury")},
                {"budget_level": _regex("luxury")},
                {"request.travel_mode": _regex("luxury")},
                {"request.trip_style": _regex("luxury")},
                {"request.budget_level": _regex("luxury")},
            ]
        }

    if normalized == "night":
        night_terms = [
            "night",
            "nightlife",
            "club",
            "clubs",
            "bar",
            "bars",
            "rooftop",
            "rooftops",
            "live music",
        ]
        return {
            "$or": [
                {"mode": _regex("night")},
                {"selected_mode": _regex("night")},
                {"trip_style": _regex("night")},
                {"request.travel_mode": _regex("night")},
                {"request.trip_style": _regex("night")},
                {"included_rules.nightlife": {"$gt": 0}},
                *[
                    _field_regex(
                        [
                            "title",
                            "subtitle",
                            "description",
                            "tag",
                            "interests",
                            "tags",
                            "interest_tags",
                            "request.interests",
                            "validated_result.interests",
                            "validated_result.tags",
                        ],
                        term,
                    )
                    for term in night_terms
                ],
            ]
        }

    return {
        "$or": [
            {"mode": _regex("casual")},
            {"selected_mode": _regex("casual")},
            {"trip_style": _regex("casual")},
            {"request.travel_mode": _regex("casual")},
            {"request.trip_style": _regex("casual")},
        ]
    }


SEARCH_FIELDS = [
    "title",
    "name",
    "package_name",
    "subtitle",
    "description",
    "country",
    "city",
    "selected_city",
    "tag",
    "interests",
    "interest_tags",
    "tags",
    "mode",
    "selected_mode",
    "trip_style",
    "budget_level",
    "selected_activities",
    "selected_restaurants",
    "selected_hotel",
    "request.country",
    "request.city",
    "request.interests",
    "request.travel_mode",
    "request.trip_style",
    "request.budget_level",
    "validated_result.title",
    "validated_result.package_name",
    "validated_result.country",
    "validated_result.city",
    "validated_result.selected_city",
    "validated_result.interests",
    "validated_result.tags",
    "validated_result.selected_activities",
    "validated_result.selected_restaurants",
    "validated_result.selected_hotel",
]


async def list_ai_packages(
    mode: str | None = None,
    q: str | None = None,
    interests: str | None = None,
    city: str | None = None,
    country: str | None = None,
    limit: int = 20,
) -> list[dict]:
    db = get_database()

    query = _base_query()
    filters = query["$and"]

    mode_filter = _mode_query(mode)
    if mode_filter:
        filters.append(mode_filter)

    if q and q.strip():
        filters.append(_field_regex(SEARCH_FIELDS, q.strip()))

    if interests and interests.strip():
        for interest in [item.strip() for item in interests.split(",") if item.strip()]:
            filters.append(
                {
                    "$or": [
                        _field_regex(
                            [
                                "interests",
                                "interest_tags",
                                "tags",
                                "tag",
                                "description",
                                "request.interests",
                                "validated_result.interests",
                                "validated_result.tags",
                            ],
                            alias,
                        )
                        for alias in _interest_aliases(interest)
                    ]
                }
            )

    if city and city.strip():
        filters.append(
            _field_regex(
                [
                    "city",
                    "selected_city",
                    "request.city",
                    "validated_result.city",
                    "validated_result.selected_city",
                ],
                city.strip(),
            )
        )

    if country and country.strip():
        filters.append(
            _field_regex(
                ["country", "request.country", "validated_result.country"],
                country.strip(),
            )
        )

    cursor = (
        db[COLLECTION_NAME]
        .find(query)
        .sort([("rating", -1), ("title", 1)])
        .limit(limit)
    )

    packages = await cursor.to_list(length=limit)
    return [_serialize_package(package) for package in packages]


async def suggest_ai_packages(
    mode: str | None = None,
    q: str | None = None,
    interests: str | None = None,
    limit: int = 5,
) -> list[dict]:
    packages = await list_ai_packages(
        mode=mode,
        q=q,
        interests=interests,
        limit=limit,
    )

    return [
        {
            "label": package["title"],
            "value": package["title"],
            "package_id": package["_id"],
            "city": package["city"],
            "country": package["country"],
            "mode": package["mode"],
        }
        for package in packages
    ]


async def get_ai_package_by_id(package_id: str) -> dict | None:
    db = get_database()

    if not ObjectId.is_valid(package_id):
        return None

    package = await db[COLLECTION_NAME].find_one(
        {
            "_id": ObjectId(package_id),
            "$or": [{"is_active": True}, {"is_active": {"$exists": False}}],
        }
    )

    if not package:
        return None

    return _serialize_package(package)
