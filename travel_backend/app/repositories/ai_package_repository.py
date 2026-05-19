import re
from datetime import datetime, timezone
from typing import Any

from bson import ObjectId
from fastapi import HTTPException, status

from app.db.mongodb import get_database
from app.schemas.ai_package import ManualPackageCreateRequest


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
        "source": str(document.get("source") or ""),
        "visibility": str(document.get("visibility") or ""),
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
                    {"visibility": {"$in": ["public", "global"]}},
                    {"visibility": {"$exists": False}},
                ]
            },
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
    return await get_accessible_ai_package_by_id(package_id, user_id=None)


async def get_accessible_ai_package_by_id(
    package_id: str,
    user_id: ObjectId | None = None,
) -> dict | None:
    db = get_database()

    if not ObjectId.is_valid(package_id):
        return None

    visibility_filter: dict[str, Any] = {
        "$or": [
            {"visibility": {"$in": ["public", "global"]}},
            {"visibility": {"$exists": False}},
        ]
    }
    if user_id is not None:
        visibility_filter = {
            "$or": [
                {"visibility": {"$in": ["public", "global"]}},
                {"visibility": {"$exists": False}},
                {"visibility": "private", "user_id": user_id},
            ]
        }

    package = await db[COLLECTION_NAME].find_one(
        {
            "_id": ObjectId(package_id),
            "$and": [
                {"$or": [{"is_active": True}, {"is_active": {"$exists": False}}]},
                visibility_filter,
            ],
        }
    )

    if not package:
        return None

    return _serialize_package(package)


async def list_user_manual_packages(user_id: ObjectId) -> list[dict]:
    db = get_database()
    cursor = (
        db[COLLECTION_NAME]
        .find(
            {
                "user_id": user_id,
                "visibility": "private",
                "source": "user_manual",
                "$or": [{"is_active": True}, {"is_active": {"$exists": False}}],
            }
        )
        .sort([("updated_at", -1), ("created_at", -1)])
    )
    packages = await cursor.to_list(length=None)
    return [_serialize_package(package) for package in packages]


async def create_user_manual_package(
    request: ManualPackageCreateRequest,
    user_id: ObjectId,
) -> dict:
    db = get_database()
    travel_items = await _load_selected_travel_items(
        request.hotel_id,
        request.activity_ids,
        request.restaurant_ids,
        request.nightlife_ids,
    )

    if not any(travel_items.values()):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Select at least one item.",
        )

    _validate_same_city(request.country, request.city, travel_items)

    now = datetime.now(timezone.utc)
    included_items = {
        "hotel": _snapshot_item(travel_items["hotel"][0])
        if travel_items["hotel"]
        else {},
        "activities": [_snapshot_item(item) for item in travel_items["activities"]],
        "restaurants": [_snapshot_item(item) for item in travel_items["restaurants"]],
        "nightlife": [_snapshot_item(item) for item in travel_items["nightlife"]],
    }
    included_rules = {
        "hotel": len(travel_items["hotel"]),
        "activity": len(travel_items["activities"]),
        "restaurant": len(travel_items["restaurants"]),
        "nightlife": len(travel_items["nightlife"]),
    }
    all_items = [
        *travel_items["hotel"],
        *travel_items["activities"],
        *travel_items["restaurants"],
        *travel_items["nightlife"],
    ]
    price = sum(float(item.get("cost") or 0) for item in all_items)
    ratings = [float(item.get("rating") or 0) for item in all_items if item.get("rating")]
    rating = round(sum(ratings) / len(ratings), 1) if ratings else 0
    image_url = _select_cover_image(travel_items)
    mode = _normalize_mode(request.mode)
    travel_mode = _manual_travel_mode(mode)
    budget_level = _manual_budget_level(mode)
    travelers = _manual_travelers(request.travelers)
    interests = [interest.strip() for interest in request.interests if interest.strip()]

    document = {
        "user_id": user_id,
        "visibility": "private",
        "source": "user_manual",
        "mode": mode,
        "title": request.title.strip(),
        "subtitle": request.subtitle.strip()
        or f"{request.days} day package in {request.city.strip()}",
        "city": request.city.strip(),
        "country": request.country.strip(),
        "currency": request.currency.strip() or "USD",
        "description": request.description.strip(),
        "image_asset": "",
        "image_url": image_url,
        "included_rules": included_rules,
        "included_items": included_items,
        "is_active": True,
        "price": price,
        "rating": rating,
        "tag": interests[0].title() if interests else mode,
        "interests": interests,
        "request": {
            "country": request.country.strip(),
            "city": request.city.strip(),
            "days": request.days,
            "budget_level": budget_level,
            "travelers": travelers,
            "interests": interests,
            "travel_mode": travel_mode,
            "requested_at": now,
            "package_type": "user_manual",
            "source": "user_manual",
        },
        "status": "generated",
        "created_at": now,
        "updated_at": now,
    }

    result = await db[COLLECTION_NAME].insert_one(document)
    document["_id"] = result.inserted_id
    return _serialize_package(document)


async def delete_user_manual_package(package_id: str, user_id: ObjectId) -> bool:
    if not ObjectId.is_valid(package_id):
        return False

    db = get_database()
    result = await db[COLLECTION_NAME].update_one(
        {
            "_id": ObjectId(package_id),
            "user_id": user_id,
            "visibility": "private",
            "source": "user_manual",
        },
        {
            "$set": {
                "is_active": False,
                "status": "archived",
                "updated_at": datetime.now(timezone.utc),
            }
        },
    )
    return result.modified_count == 1


def _manual_travel_mode(mode: str) -> str:
    normalized = mode.strip().lower()
    if normalized == "luxury":
        return "luxury"
    if normalized == "night":
        return "night"
    return "casual"


def _manual_budget_level(mode: str) -> str:
    return "luxury" if mode.strip().lower() == "luxury" else "mid-range"


def _manual_travelers(value: str) -> str:
    normalized = value.strip().lower()
    if normalized in {"solo", "couple", "friends", "family"}:
        return normalized
    return "solo"


async def _load_selected_travel_items(
    hotel_id: str | None,
    activity_ids: list[str],
    restaurant_ids: list[str],
    nightlife_ids: list[str],
) -> dict[str, list[dict[str, Any]]]:
    selected = {
        "hotel": [hotel_id] if hotel_id else [],
        "activities": activity_ids,
        "restaurants": restaurant_ids,
        "nightlife": nightlife_ids,
    }
    ids = {
        ObjectId(item_id)
        for group in selected.values()
        for item_id in group
        if ObjectId.is_valid(item_id)
    }
    requested_count = sum(len(group) for group in selected.values())

    if len(ids) != requested_count:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="One or more selected items are invalid.",
        )

    db = get_database()
    documents = await db["travel_items"].find(
        {"_id": {"$in": list(ids)}, "is_active": True}
    ).to_list(length=None)
    by_id = {str(document["_id"]): document for document in documents}

    def load_group(item_ids: list[str], expected_type: str) -> list[dict[str, Any]]:
        items = []
        for item_id in item_ids:
            item = by_id.get(item_id)
            if not item or item.get("type") != expected_type:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="One or more selected items are invalid.",
                )
            items.append(item)
        return items

    return {
        "hotel": load_group([hotel_id] if hotel_id else [], "hotel"),
        "activities": load_group(activity_ids, "activity"),
        "restaurants": load_group(restaurant_ids, "restaurant"),
        "nightlife": load_group(nightlife_ids, "nightlife"),
    }


def _validate_same_city(
    country: str,
    city: str,
    travel_items: dict[str, list[dict[str, Any]]],
) -> None:
    expected_country = country.strip().lower()
    expected_city = city.strip().lower()

    for items in travel_items.values():
        for item in items:
            if (
                str(item.get("country") or "").strip().lower() != expected_country
                or str(item.get("city") or "").strip().lower() != expected_city
            ):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="All package items must be from the same city.",
                )


def _snapshot_item(item: dict[str, Any]) -> dict[str, Any]:
    return {
        "_id": str(item["_id"]),
        "name": item.get("name", ""),
        "type": item.get("type", ""),
        "category": item.get("category", ""),
        "country": item.get("country", ""),
        "city": item.get("city", ""),
        "cost": float(item.get("cost") or 0),
        "currency": item.get("currency", "USD"),
        "duration_hours": float(item.get("duration_hours") or 0),
        "rating": float(item.get("rating") or 0),
        "interest_tags": item.get("interest_tags", []),
        "images": item.get("images", []),
    }


def _first_image_url(item: dict[str, Any] | None) -> str:
    if not item:
        return ""

    images = item.get("images")
    if not isinstance(images, list):
        return ""

    for image in images:
        if isinstance(image, str) and image.strip():
            return image.strip()
        if isinstance(image, dict):
            url = str(image.get("url") or image.get("thumbnail_url") or "").strip()
            if url:
                return url
    return ""


def _select_cover_image(travel_items: dict[str, list[dict[str, Any]]]) -> str:
    for group_name in ["activities", "hotel", "restaurants", "nightlife"]:
        for item in travel_items[group_name]:
            image_url = _first_image_url(item)
            if image_url:
                return image_url
    return ""
