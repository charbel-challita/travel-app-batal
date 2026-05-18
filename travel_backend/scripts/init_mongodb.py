from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from pymongo import ASCENDING, DESCENDING, TEXT, MongoClient
from pymongo.errors import CollectionInvalid, OperationFailure


ROOT_DIR = Path(__file__).resolve().parents[1]
load_dotenv(ROOT_DIR / ".env")

MONGODB_URI = os.getenv("MONGODB_URI", "mongodb://127.0.0.1:27017")
DATABASE_NAME = os.getenv("DATABASE_NAME", "travel_planning_app")


def now() -> datetime:
    return datetime.now(timezone.utc)


def object_schema(
    required: list[str],
    properties: dict[str, Any],
    *,
    additional_properties: bool = True,
) -> dict[str, Any]:
    schema = {
        "$jsonSchema": {
            "bsonType": "object",
            "required": required,
            "properties": properties,
        }
    }

    if not additional_properties:
        schema["$jsonSchema"]["additionalProperties"] = False
        schema["$jsonSchema"]["properties"] = {
            "_id": {"bsonType": "objectId"},
            **properties,
        }

    return schema


VALIDATORS: dict[str, dict[str, Any]] = {
    "users": object_schema(
        ["email", "password_hash", "full_name", "default_travel_mode", "created_at", "updated_at"],
        {
            "email": {"bsonType": "string"},
            "password_hash": {"bsonType": "string"},
            "full_name": {"bsonType": "string"},
            "avatar_url": {"bsonType": ["string", "null"]},
            "default_travel_mode": {"enum": ["casual", "luxury", "night"]},
            "preferred_budget_level": {"enum": ["low", "mid-range", "luxury", None]},
            "preferred_travelers": {"enum": ["solo", "couple", "friends", "family", None]},
            "favorite_interests": {"bsonType": "array", "items": {"bsonType": "string"}},
            "profile_label": {"bsonType": ["string", "null"]},
            "stats": {"bsonType": "object"},
            "auth_provider": {"enum": ["email", "local", "google", "apple"]},
            "is_active": {"bsonType": "bool"},
            "created_at": {"bsonType": "date"},
            "updated_at": {"bsonType": "date"},
            "last_login_at": {"bsonType": ["date", "null"]},
        },
    ),
    "travel_items": object_schema(
        [
            "country",
            "country_normalized",
            "city",
            "city_normalized",
            "type",
            "name",
            "name_normalized",
            "category",
            "cost",
            "currency",
            "duration_hours",
            "rating",
            "interest_tags",
            "item_budget_level",
            "flags",
            "images",
            "source",
            "is_active",
            "created_at",
            "updated_at",
        ],
        {
            "country": {"bsonType": "string"},
            "country_normalized": {"bsonType": "string"},
            "city": {"bsonType": "string"},
            "city_normalized": {"bsonType": "string"},
            "type": {"enum": ["hotel", "activity", "restaurant", "nightlife"]},
            "name": {"bsonType": "string"},
            "name_normalized": {"bsonType": "string"},
            "category": {"bsonType": "string"},
            "cost": {"bsonType": ["double", "int", "long", "decimal"]},
            "currency": {"bsonType": "string"},
            "duration_hours": {"bsonType": ["double", "int", "long", "decimal"]},
            "rating": {"bsonType": ["double", "int", "long", "decimal"], "minimum": 0, "maximum": 5},
            "interest_tags": {"bsonType": "array", "items": {"bsonType": "string"}},
            "item_budget_level": {"enum": ["low", "mid", "luxury"]},
            "flags": {
                "bsonType": "object",
                "required": ["family_friendly", "culture_item", "romantic_item", "adventure_item", "nightlife_item"],
                "additionalProperties": False,
                "properties": {
                    "family_friendly": {"bsonType": "bool"},
                    "culture_item": {"bsonType": "bool"},
                    "romantic_item": {"bsonType": "bool"},
                    "adventure_item": {"bsonType": "bool"},
                    "nightlife_item": {"bsonType": "bool"},
                },
            },
            "images": {"bsonType": "array"},
            "source": {
                "bsonType": "object",
                "required": ["file", "row_number"],
                "additionalProperties": False,
                "properties": {
                    "file": {"bsonType": "string"},
                    "row_number": {"bsonType": ["int", "long"]},
                },
            },
            "is_active": {"bsonType": "bool"},
            "created_at": {"bsonType": "date"},
            "updated_at": {"bsonType": "date"},
        },
        additional_properties=False,
    ),
    "ai_packages": object_schema(
        ["request", "status", "created_at", "updated_at"],
        {
            "user_id": {"bsonType": ["objectId", "null"]},
            "request": {
                "bsonType": "object",
                "required": ["country", "days", "budget_level", "travelers", "interests", "travel_mode", "requested_at"],
                "properties": {
                    "country": {"bsonType": "string"},
                    "country_normalized": {"bsonType": "string"},
                    "days": {"bsonType": ["int", "long"], "minimum": 1},
                    "budget_level": {"enum": ["low", "mid-range", "luxury"]},
                    "trip_style": {"enum": ["casual", "luxury", "night"]},
                    "travelers": {"enum": ["solo", "couple", "friends", "family"]},
                    "interests": {"bsonType": "array", "items": {"bsonType": "string"}},
                    "travel_mode": {"enum": ["casual", "luxury", "night"]},
                    "allow_multi_city": {"bsonType": "bool"},
                    "requested_at": {"bsonType": "date"},
                },
            },
            "ai_context": {"bsonType": "object"},
            "ai_raw_response": {"bsonType": "object"},
            "validated_result": {"bsonType": "object"},
            "status": {"enum": ["generated", "validation_failed", "saved", "archived"]},
            "feedback": {"bsonType": "object"},
            "created_at": {"bsonType": "date"},
            "updated_at": {"bsonType": "date"},
        },
    ),
    "trips": object_schema(
        ["user_id", "title", "location", "travel_mode", "status", "created_at", "updated_at"],
        {
            "user_id": {"bsonType": "objectId"},
            "ai_package_id": {"bsonType": ["objectId", "null"]},
            "title": {"bsonType": "string"},
            "location": {"bsonType": "string"},
            "country": {"bsonType": ["string", "null"]},
            "city": {"bsonType": ["string", "null"]},
            "travel_mode": {"enum": ["casual", "luxury", "night"]},
            "status": {"enum": ["saved", "upcoming", "ongoing", "completed", "cancelled"]},
            "start_date": {"bsonType": ["date", "null"]},
            "end_date": {"bsonType": ["date", "null"]},
            "duration_label": {"bsonType": ["string", "null"]},
            "estimated_cost": {"bsonType": ["double", "int", "long", "decimal", "null"]},
            "interests": {"bsonType": "array", "items": {"bsonType": "string"}},
            "selected_item_ids": {"bsonType": "array", "items": {"bsonType": "objectId"}},
            "cover_image_url": {"bsonType": ["string", "null"]},
            "notes": {"bsonType": ["string", "null"]},
            "created_at": {"bsonType": "date"},
            "updated_at": {"bsonType": "date"},
            "completed_at": {"bsonType": ["date", "null"]},
        },
    ),
    "training_packages": object_schema(
        ["country", "days", "budget_level", "trip_style", "travelers", "interests", "package_quality", "created_at"],
        {
            "country": {"bsonType": "string"},
            "country_normalized": {"bsonType": "string"},
            "days": {"bsonType": ["int", "long"], "minimum": 1},
            "budget_level": {"enum": ["low", "mid-range", "luxury"]},
            "trip_style": {"enum": ["casual", "luxury", "night"]},
            "travelers": {"enum": ["solo", "couple", "friends", "family"]},
            "interests": {"bsonType": "array", "items": {"bsonType": "string"}},
            "selected_city": {"bsonType": ["string", "null"]},
            "selected_hotel_name": {"bsonType": ["string", "null"]},
            "selected_activity_names": {"bsonType": "array", "items": {"bsonType": "string"}},
            "selected_restaurant_names": {"bsonType": "array", "items": {"bsonType": "string"}},
            "package_quality": {"enum": [0, 1]},
            "reason": {"bsonType": ["string", "null"]},
            "resolved_refs": {"bsonType": "object"},
            "source": {"bsonType": "object"},
            "created_at": {"bsonType": "date"},
        },
    ),
    "user_favorites": object_schema(
        ["user_id", "target_type", "target_id", "created_at"],
        {
            "user_id": {"bsonType": "objectId"},
            "target_type": {"enum": ["travel_item", "ai_package", "trip"]},
            "target_id": {"bsonType": "objectId"},
            "travel_mode": {"enum": ["casual", "luxury", "night", None]},
            "created_at": {"bsonType": "date"},
        },
    ),
    "dataset_imports": object_schema(
        ["dataset_name", "original_filename", "row_count", "status", "created_at"],
        {
            "dataset_name": {"enum": ["Dataset_tourism", "training_packages"]},
            "original_filename": {"bsonType": "string"},
            "imported_by": {"bsonType": ["objectId", "null"]},
            "row_count": {"bsonType": ["int", "long"]},
            "inserted_count": {"bsonType": ["int", "long"]},
            "updated_count": {"bsonType": ["int", "long"]},
            "skipped_count": {"bsonType": ["int", "long"]},
            "errors": {"bsonType": "array"},
            "status": {"enum": ["pending", "completed", "failed"]},
            "created_at": {"bsonType": "date"},
            "completed_at": {"bsonType": ["date", "null"]},
        },
    ),
    "app_taxonomy": object_schema(
        ["type", "key", "label", "is_active"],
        {
            "type": {"enum": ["interest", "category", "country", "city", "budget_level", "travel_mode", "travelers"]},
            "key": {"bsonType": "string"},
            "label": {"bsonType": "string"},
            "parent_key": {"bsonType": ["string", "null"]},
            "travel_modes": {"bsonType": "array", "items": {"bsonType": "string"}},
            "icon_key": {"bsonType": ["string", "null"]},
            "sort_order": {"bsonType": ["int", "long"]},
            "is_active": {"bsonType": "bool"},
        },
    ),
}


INDEXES: dict[str, list[tuple[Any, dict[str, Any]]]] = {
    "users": [
        ([("email", ASCENDING)], {"unique": True}),
        ([("is_active", ASCENDING)], {}),
    ],
    "travel_items": [
        ([("country_normalized", ASCENDING)], {}),
        ([("country_normalized", ASCENDING), ("city_normalized", ASCENDING)], {}),
        ([("country_normalized", ASCENDING), ("type", ASCENDING)], {}),
        ([("country_normalized", ASCENDING), ("type", ASCENDING), ("item_budget_level", ASCENDING)], {}),
        ([("country_normalized", ASCENDING), ("city_normalized", ASCENDING), ("type", ASCENDING)], {}),
        ([("interest_tags", ASCENDING)], {}),
        ([("rating", DESCENDING)], {}),
        ([("cost", ASCENDING)], {}),
        ([("flags.nightlife_item", ASCENDING)], {}),
        ([("flags.family_friendly", ASCENDING)], {}),
        (
            [
                ("country_normalized", ASCENDING),
                ("city_normalized", ASCENDING),
                ("type", ASCENDING),
                ("name_normalized", ASCENDING),
            ],
            {"unique": True, "name": "unique_travel_item_identity"},
        ),
        (
            [
                ("name", TEXT),
                ("city", TEXT),
                ("country", TEXT),
                ("category", TEXT),
                ("interest_tags", TEXT),
            ],
            {"name": "travel_items_text_search"},
        ),
        (
            [
                ("country_normalized", ASCENDING),
                ("type", ASCENDING),
                ("item_budget_level", ASCENDING),
                ("rating", DESCENDING),
            ],
            {"name": "ai_filter_by_country_type_budget_rating"},
        ),
        (
            [
                ("country_normalized", ASCENDING),
                ("flags.nightlife_item", ASCENDING),
                ("rating", DESCENDING),
            ],
            {"name": "night_mode_country_rating"},
        ),
    ],
    "ai_packages": [
        ([("user_id", ASCENDING), ("created_at", DESCENDING)], {}),
        ([("request.country_normalized", ASCENDING), ("created_at", DESCENDING)], {}),
        ([("request.travel_mode", ASCENDING)], {}),
        ([("status", ASCENDING)], {}),
        ([("validated_result.validation_status", ASCENDING)], {}),
        ([("user_id", ASCENDING), ("status", ASCENDING), ("created_at", DESCENDING)], {}),
    ],
    "trips": [
        ([("user_id", ASCENDING), ("status", ASCENDING)], {}),
        ([("user_id", ASCENDING), ("created_at", DESCENDING)], {}),
        ([("user_id", ASCENDING), ("start_date", ASCENDING)], {}),
        ([("ai_package_id", ASCENDING)], {}),
        ([("selected_item_ids", ASCENDING)], {}),
    ],
    "training_packages": [
        ([("country_normalized", ASCENDING)], {}),
        ([("budget_level", ASCENDING), ("trip_style", ASCENDING), ("travelers", ASCENDING)], {}),
        ([("package_quality", ASCENDING)], {}),
        ([("interests", ASCENDING)], {}),
    ],
    "user_favorites": [
        ([("user_id", ASCENDING), ("created_at", DESCENDING)], {}),
        ([("user_id", ASCENDING), ("target_type", ASCENDING), ("target_id", ASCENDING)], {"unique": True}),
    ],
    "dataset_imports": [
        ([("dataset_name", ASCENDING), ("created_at", DESCENDING)], {}),
        ([("status", ASCENDING)], {}),
    ],
    "app_taxonomy": [
        ([("type", ASCENDING), ("key", ASCENDING)], {"unique": True}),
        ([("type", ASCENDING), ("is_active", ASCENDING), ("sort_order", ASCENDING)], {}),
    ],
}


def ensure_collection(db, name: str, validator: dict[str, Any]) -> None:
    if name in db.list_collection_names():
        db.command(
            "collMod",
            name,
            validator=validator,
            validationLevel="moderate",
            validationAction="error",
        )
        print(f"OK collection exists, validator updated: {name}")
        return

    try:
        db.create_collection(
            name,
            validator=validator,
            validationLevel="moderate",
            validationAction="error",
        )
        print(f"OK collection created with validator: {name}")
    except CollectionInvalid:
        print(f"OK collection already exists: {name}")


def ensure_indexes(db, name: str) -> None:
    collection = db[name]
    for keys, options in INDEXES.get(name, []):
        index_name = collection.create_index(keys, **options)
        print(f"OK index ensured on {name}: {index_name}")


def seed_users(db) -> None:
    if db.users.estimated_document_count() > 0:
        print("OK users already has documents; seed skipped")
        return

    timestamp = now()
    db.users.insert_one(
        {
            "email": "maria@example.com",
            "password_hash": "sample-user-not-for-login",
            "full_name": "Maria Tabet",
            "avatar_url": None,
            "default_travel_mode": "casual",
            "preferred_budget_level": "mid-range",
            "preferred_travelers": "friends",
            "favorite_interests": ["beach", "culture", "food", "nature"],
            "profile_label": "Casual traveler",
            "stats": {
                "saved_trips_count": 0,
                "favorites_count": 0,
                "past_trips_count": 0,
                "casual_trips_count": 0,
                "luxury_trips_count": 0,
                "night_trips_count": 0,
            },
            "auth_provider": "local",
            "is_active": True,
            "created_at": timestamp,
            "updated_at": timestamp,
            "last_login_at": None,
        }
    )
    print("OK sample user inserted: maria@example.com")


def seed_travel_items(db) -> None:
    if db.travel_items.estimated_document_count() > 0:
        print("OK travel_items already has documents; seed skipped")
        return

    timestamp = now()
    items = [
        {
            "country": "Indonesia",
            "country_normalized": "indonesia",
            "city": "Bali",
            "city_normalized": "bali",
            "type": "activity",
            "name": "Island Sightseeing Tour",
            "name_normalized": "island sightseeing tour",
            "category": "Nature",
            "cost": 80,
            "currency": "USD",
            "duration_hours": 4.5,
            "rating": 4.8,
            "interest_tags": ["nature", "beach", "culture"],
            "item_budget_level": "mid",
            "flags": {
                "family_friendly": True,
                "culture_item": True,
                "romantic_item": False,
                "adventure_item": False,
                "nightlife_item": False,
            },
            "images": [],
            "source": {"file": "sample_seed", "row_number": 1},
            "is_active": True,
            "created_at": timestamp,
            "updated_at": timestamp,
        },
        {
            "country": "Italy",
            "country_normalized": "italy",
            "city": "Rome",
            "city_normalized": "rome",
            "type": "activity",
            "name": "Old City Culture Walk",
            "name_normalized": "old city culture walk",
            "category": "Culture",
            "cost": 45,
            "currency": "USD",
            "duration_hours": 3,
            "rating": 4.7,
            "interest_tags": ["culture", "history", "walking"],
            "item_budget_level": "low",
            "flags": {
                "family_friendly": True,
                "culture_item": True,
                "romantic_item": False,
                "adventure_item": False,
                "nightlife_item": False,
            },
            "images": [],
            "source": {"file": "sample_seed", "row_number": 2},
            "is_active": True,
            "created_at": timestamp,
            "updated_at": timestamp,
        },
        {
            "country": "Italy",
            "country_normalized": "italy",
            "city": "Rome",
            "city_normalized": "rome",
            "type": "restaurant",
            "name": "Pasta House",
            "name_normalized": "pasta house",
            "category": "Italian food",
            "cost": 42,
            "currency": "USD",
            "duration_hours": 1.5,
            "rating": 4.8,
            "interest_tags": ["food", "culture", "local"],
            "item_budget_level": "mid",
            "flags": {
                "family_friendly": True,
                "culture_item": True,
                "romantic_item": True,
                "adventure_item": False,
                "nightlife_item": False,
            },
            "images": [],
            "source": {"file": "sample_seed", "row_number": 3},
            "is_active": True,
            "created_at": timestamp,
            "updated_at": timestamp,
        },
        {
            "country": "UAE",
            "country_normalized": "uae",
            "city": "Dubai",
            "city_normalized": "dubai",
            "type": "nightlife",
            "name": "Skyline Rooftop Night",
            "name_normalized": "skyline rooftop night",
            "category": "Rooftop lounge",
            "cost": 120,
            "currency": "USD",
            "duration_hours": 3,
            "rating": 4.7,
            "interest_tags": ["nightlife", "luxury", "city"],
            "item_budget_level": "luxury",
            "flags": {
                "family_friendly": False,
                "culture_item": False,
                "romantic_item": True,
                "adventure_item": False,
                "nightlife_item": True,
            },
            "images": [],
            "source": {"file": "sample_seed", "row_number": 4},
            "is_active": True,
            "created_at": timestamp,
            "updated_at": timestamp,
        },
    ]
    db.travel_items.insert_many(items)
    print(f"OK sample travel_items inserted: {len(items)}")


def seed_taxonomy(db) -> None:
    if db.app_taxonomy.estimated_document_count() > 0:
        print("OK app_taxonomy already has documents; seed skipped")
        return

    records = []
    for index, key in enumerate(["casual", "luxury", "night"], start=1):
        records.append(
            {
                "type": "travel_mode",
                "key": key,
                "label": key.title(),
                "parent_key": None,
                "travel_modes": [key],
                "icon_key": None,
                "sort_order": index,
                "is_active": True,
            }
        )

    for index, key in enumerate(["nature", "culture", "beach", "food", "shopping", "adventure", "luxury", "relax", "history", "hidden gems", "nightlife"], start=1):
        records.append(
            {
                "type": "interest",
                "key": key,
                "label": key.title(),
                "parent_key": None,
                "travel_modes": ["casual", "luxury", "night"],
                "icon_key": None,
                "sort_order": index,
                "is_active": True,
            }
        )

    for index, key in enumerate(["low", "mid-range", "luxury"], start=1):
        records.append(
            {
                "type": "budget_level",
                "key": key,
                "label": key.title(),
                "parent_key": None,
                "travel_modes": ["casual", "luxury", "night"],
                "icon_key": None,
                "sort_order": index,
                "is_active": True,
            }
        )

    for index, key in enumerate(["solo", "couple", "friends", "family"], start=1):
        records.append(
            {
                "type": "travelers",
                "key": key,
                "label": key.title(),
                "parent_key": None,
                "travel_modes": ["casual", "luxury", "night"],
                "icon_key": None,
                "sort_order": index,
                "is_active": True,
            }
        )

    db.app_taxonomy.insert_many(records)
    print(f"OK sample app_taxonomy inserted: {len(records)}")


def seed_dataset_imports(db) -> None:
    if db.dataset_imports.estimated_document_count() > 0:
        print("OK dataset_imports already has documents; seed skipped")
        return

    timestamp = now()
    db.dataset_imports.insert_one(
        {
            "dataset_name": "Dataset_tourism",
            "original_filename": "sample_seed",
            "imported_by": None,
            "row_count": 4,
            "inserted_count": 4,
            "updated_count": 0,
            "skipped_count": 0,
            "errors": [],
            "status": "completed",
            "created_at": timestamp,
            "completed_at": timestamp,
        }
    )
    print("OK sample dataset_imports document inserted")


def seed_empty_safe_samples(db) -> None:
    seed_users(db)
    seed_travel_items(db)
    seed_taxonomy(db)
    seed_dataset_imports(db)

    for name in ["ai_packages", "trips", "training_packages", "user_favorites"]:
        if db[name].estimated_document_count() == 0:
            print(f"OK {name} is empty; no sample document required")
        else:
            print(f"OK {name} already has documents")


def verify_database(db) -> None:
    print("\nVerification")
    print(f"OK database: {db.name}")
    for name in sorted(VALIDATORS):
        count = db[name].estimated_document_count()
        index_count = len(list(db[name].list_indexes()))
        print(f"OK {name}: documents={count}, indexes={index_count}")


def main() -> None:
    print("Connecting to MongoDB using configured URI")
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=5000)
    client.admin.command("ping")
    print("OK MongoDB ping successful")

    db = client[DATABASE_NAME]
    print(f"Using database: {DATABASE_NAME}")

    for name, validator in VALIDATORS.items():
        try:
            ensure_collection(db, name, validator)
        except OperationFailure as exc:
            raise RuntimeError(f"Failed configuring collection {name}: {exc}") from exc

    for name in VALIDATORS:
        ensure_indexes(db, name)

    seed_empty_safe_samples(db)
    verify_database(db)
    print("\nMongoDB initialization completed successfully.")


if __name__ == "__main__":
    main()
