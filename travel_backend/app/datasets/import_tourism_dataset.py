from __future__ import annotations

import argparse
import os
import re
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
from xml.etree import ElementTree as ET
from zipfile import ZipFile

try:
    from pymongo import ASCENDING, DESCENDING, MongoClient, UpdateOne
except ModuleNotFoundError as exc:
    raise SystemExit(
        "Missing dependency: pymongo. Install backend dependencies first with "
        "`pip install -r requirements.txt`."
    ) from exc


BACKEND_DIR = Path(__file__).resolve().parents[2]
PROJECT_DIR = BACKEND_DIR.parent
DEFAULT_EXCEL_PATH = PROJECT_DIR / "Dataset_tourism.xlsx"
ENV_PATH = BACKEND_DIR / ".env"
TARGET_COLLECTION = "travel_items"
SOURCE_FILE_NAME = "Dataset_tourism.xlsx"

EXPECTED_HEADERS = [
    "country",
    "city",
    "type",
    "name",
    "category",
    "cost",
    "duration_hours",
    "rating",
    "interest_tags",
    "item_budget_level",
    "is_family_friendly",
    "is_culture_item",
    "is_romantic_item",
    "is_adventure_item",
    "is_nightlife_item",
]

TEXT_NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}t"
NS = {
    "a": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
    "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships",
}


def load_env(path: Path) -> None:
    if not path.exists():
        return

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue

        key, value = stripped.split("=", 1)
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        os.environ.setdefault(key, value)


def normalize_text(value: Any) -> str:
    return re.sub(r"\s+", " ", str(value or "").strip()).lower()


def to_float(value: Any, field_name: str, row_number: int) -> float:
    try:
        return float(str(value).strip())
    except (TypeError, ValueError) as exc:
        raise ValueError(f"Invalid numeric value for {field_name} at Excel row {row_number}: {value!r}") from exc


def to_flag(value: Any, field_name: str, row_number: int) -> bool:
    normalized = str(value).strip()
    if normalized == "1":
        return True
    if normalized == "0":
        return False
    raise ValueError(f"Invalid flag value for {field_name} at Excel row {row_number}: {value!r}")


def split_tags(value: Any) -> list[str]:
    return [tag.strip() for tag in str(value or "").split(";") if tag.strip()]


def column_to_index(cell_reference: str) -> int:
    match = re.match(r"([A-Z]+)", cell_reference)
    if not match:
        raise ValueError(f"Invalid Excel cell reference: {cell_reference}")

    index = 0
    for char in match.group(1):
        index = index * 26 + ord(char) - ord("A") + 1
    return index - 1


def shared_strings(zip_file: ZipFile) -> list[str]:
    if "xl/sharedStrings.xml" not in zip_file.namelist():
        return []

    root = ET.fromstring(zip_file.read("xl/sharedStrings.xml"))
    strings = []
    for item in root.findall("a:si", NS):
        strings.append("".join(text.text or "" for text in item.iter(TEXT_NS)))
    return strings


def first_sheet_path(zip_file: ZipFile) -> str:
    workbook = ET.fromstring(zip_file.read("xl/workbook.xml"))
    first_sheet = workbook.find("a:sheets/a:sheet", NS)
    if first_sheet is None:
        raise ValueError("Workbook does not contain any sheets.")

    rel_id = first_sheet.attrib[f"{{{NS['r']}}}id"]
    relationships = ET.fromstring(zip_file.read("xl/_rels/workbook.xml.rels"))
    for relationship in relationships:
        if relationship.attrib["Id"] == rel_id:
            target = relationship.attrib["Target"]
            return target[1:] if target.startswith("/") else f"xl/{target}"

    raise ValueError("Could not resolve first worksheet path.")


def cell_value(cell: ET.Element, strings: list[str]) -> str:
    cell_type = cell.attrib.get("t")
    value_node = cell.find("a:v", NS)
    raw_value = value_node.text if value_node is not None else ""

    if cell_type == "s" and raw_value != "":
        return strings[int(raw_value)]

    if cell_type == "inlineStr":
        text_node = cell.find(".//a:t", NS)
        return text_node.text if text_node is not None else ""

    return raw_value


def read_xlsx_rows(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        raise FileNotFoundError(f"Excel file not found: {path}")

    with ZipFile(path) as zip_file:
        strings = shared_strings(zip_file)
        sheet_path = first_sheet_path(zip_file)
        worksheet = ET.fromstring(zip_file.read(sheet_path))

        rows = []
        for row in worksheet.findall(".//a:sheetData/a:row", NS):
            cells: dict[int, str] = {}
            for cell in row.findall("a:c", NS):
                reference = cell.attrib.get("r")
                if not reference:
                    continue
                cells[column_to_index(reference)] = cell_value(cell, strings)

            if not cells:
                continue

            row_values = [cells.get(index, "") for index in range(max(cells) + 1)]
            rows.append((int(row.attrib["r"]), row_values))

    if not rows:
        raise ValueError("Excel file is empty.")

    headers = [str(value).strip() for value in rows[0][1]]
    if headers != EXPECTED_HEADERS:
        raise ValueError(
            "Unexpected Excel headers.\n"
            f"Expected: {EXPECTED_HEADERS}\n"
            f"Actual:   {headers}"
        )

    records = []
    for excel_row_number, values in rows[1:]:
        padded_values = values + [""] * (len(headers) - len(values))
        records.append(
            {
                "excel_row_number": excel_row_number,
                "row": dict(zip(headers, padded_values[: len(headers)])),
            }
        )

    return records


def transform_record(record: dict[str, Any], timestamp: datetime) -> dict[str, Any]:
    row_number = record["excel_row_number"]
    row = record["row"]

    source_type = str(row["type"]).strip().lower()
    is_nightlife = to_flag(row["is_nightlife_item"], "is_nightlife_item", row_number)
    item_type = "nightlife" if is_nightlife else source_type

    country = str(row["country"]).strip()
    city = str(row["city"]).strip()
    name = str(row["name"]).strip()

    if not country or not city or not source_type or not name:
        raise ValueError(f"Missing required text field at Excel row {row_number}.")

    return {
        "country": country,
        "country_normalized": normalize_text(country),
        "city": city,
        "city_normalized": normalize_text(city),
        "type": item_type,
        "name": name,
        "name_normalized": normalize_text(name),
        "category": str(row["category"]).strip(),
        "cost": to_float(row["cost"], "cost", row_number),
        "currency": "USD",
        "duration_hours": to_float(row["duration_hours"], "duration_hours", row_number),
        "rating": to_float(row["rating"], "rating", row_number),
        "interest_tags": split_tags(row["interest_tags"]),
        "item_budget_level": str(row["item_budget_level"]).strip().lower(),
        "flags": {
            "family_friendly": to_flag(row["is_family_friendly"], "is_family_friendly", row_number),
            "culture_item": to_flag(row["is_culture_item"], "is_culture_item", row_number),
            "romantic_item": to_flag(row["is_romantic_item"], "is_romantic_item", row_number),
            "adventure_item": to_flag(row["is_adventure_item"], "is_adventure_item", row_number),
            "nightlife_item": is_nightlife,
        },
        "images": [],
        "source": {
            "file": SOURCE_FILE_NAME,
            "row_number": row_number,
        },
        "is_active": True,
        "created_at": timestamp,
        "updated_at": timestamp,
    }


def stable_filter(document: dict[str, Any]) -> dict[str, Any]:
    return {
        "country_normalized": document["country_normalized"],
        "city_normalized": document["city_normalized"],
        "type": document["type"],
        "name_normalized": document["name_normalized"],
        "source.file": SOURCE_FILE_NAME,
    }


def connect_database() -> Any:
    load_env(ENV_PATH)
    mongodb_uri = os.getenv("MONGODB_URI")
    database_name = os.getenv("DATABASE_NAME", "travel_planning_app")

    if not mongodb_uri:
        raise SystemExit("MONGODB_URI is not set. Add it to travel_backend/.env.")

    client = MongoClient(mongodb_uri, serverSelectionTimeoutMS=10000)
    client.admin.command("ping")
    return client[database_name]


def ensure_indexes(collection: Any) -> None:
    index_specs = [
        ([("country_normalized", ASCENDING)], {}),
        ([("city_normalized", ASCENDING)], {}),
        ([("type", ASCENDING)], {}),
        ([("item_budget_level", ASCENDING)], {}),
        ([("rating", DESCENDING)], {}),
        ([("is_active", ASCENDING)], {}),
        ([("flags.nightlife_item", ASCENDING)], {}),
        ([("name_normalized", ASCENDING)], {}),
        (
            [
                ("country_normalized", ASCENDING),
                ("city_normalized", ASCENDING),
                ("type", ASCENDING),
                ("name_normalized", ASCENDING),
            ],
            {"name": "unique_travel_item_identity", "unique": True},
        ),
    ]

    for keys, options in index_specs:
        collection.create_index(keys, **options)


def print_summary(documents: list[dict[str, Any]], current_count: int | None) -> None:
    stable_keys = [
        (
            document["country_normalized"],
            document["city_normalized"],
            document["type"],
            document["name_normalized"],
        )
        for document in documents
    ]
    duplicate_key_count = sum(count - 1 for count in Counter(stable_keys).values() if count > 1)

    print("Dataset_tourism.xlsx inspection")
    print(f"- Headers: {', '.join(EXPECTED_HEADERS)}")
    print(f"- Excel data rows: {len(documents)}")
    print(f"- Duplicate stable keys inside Excel: {duplicate_key_count}")
    if current_count is None:
        print("- Current travel_items documents: unavailable")
    else:
        print(f"- Current travel_items documents: {current_count}")

    print("\nWhat will be imported")
    print(f"- Target database: {os.getenv('DATABASE_NAME', 'travel_planning_app')}")
    print(f"- Target collection: {TARGET_COLLECTION}")
    print("- Source file: Dataset_tourism.xlsx")
    print("- Transform: semicolon tags to arrays, numeric fields to numbers, flags to nested booleans")
    print("- Nightlife rule: rows with is_nightlife_item=1 become type='nightlife'")

    print("\nPreview documents")
    for document in documents[:3]:
        preview = {
            "country": document["country"],
            "city": document["city"],
            "type": document["type"],
            "name": document["name"],
            "category": document["category"],
            "cost": document["cost"],
            "duration_hours": document["duration_hours"],
            "rating": document["rating"],
            "interest_tags": document["interest_tags"],
            "item_budget_level": document["item_budget_level"],
            "flags": document["flags"],
            "source": document["source"],
        }
        print(preview)

    print("\nPlanned import counts")
    print(f"- By type: {dict(Counter(document['type'] for document in documents))}")
    print(f"- By budget level: {dict(Counter(document['item_budget_level'] for document in documents))}")
    print(f"- Countries: {len(Counter(document['country'] for document in documents))}")


def warn_about_validator(collection: Any) -> None:
    options = collection.options()
    validator_text = str(options.get("validator", ""))
    warnings = []

    if "mid-range" in validator_text and "'mid'" not in validator_text and '"mid"' not in validator_text:
        warnings.append("collection validator may allow 'mid-range' but the Excel file uses 'mid'")

    for expected_key in ["culture_item", "romantic_item", "adventure_item", "nightlife_item"]:
        if expected_key not in validator_text and "flags" in validator_text:
            warnings.append(f"collection validator may not include flags.{expected_key}")

    if warnings:
        print("\nValidator warning")
        for warning in sorted(set(warnings)):
            print(f"- {warning}")
        print("- If MongoDB rejects the import, update the collection validator before importing.")


def import_documents(collection: Any, documents: list[dict[str, Any]], replace: bool) -> None:
    if replace:
        delete_result = collection.delete_many({})
        print(f"Deleted existing travel_items documents: {delete_result.deleted_count}")

    operations = []
    for document in documents:
        update_document = dict(document)
        update_document.pop("created_at", None)
        operations.append(
            UpdateOne(
                stable_filter(document),
                {
                    "$set": update_document,
                    "$setOnInsert": {"created_at": document["created_at"]},
                },
                upsert=True,
            )
        )

    result = collection.bulk_write(operations, ordered=False)
    print("\nImport result")
    print(f"- Inserted count: {result.upserted_count}")
    print(f"- Updated count: {result.modified_count}")
    print(f"- Matched existing count: {result.matched_count}")


def print_database_counts(collection: Any) -> None:
    type_counts = {
        item["_id"]: item["count"]
        for item in collection.aggregate([{"$group": {"_id": "$type", "count": {"$sum": 1}}}])
    }
    budget_counts = {
        item["_id"]: item["count"]
        for item in collection.aggregate([{"$group": {"_id": "$item_budget_level", "count": {"$sum": 1}}}])
    }

    print("\nFinal MongoDB counts")
    print(f"- Final document count: {collection.count_documents({})}")
    print(f"- Count by type: {type_counts}")
    print(f"- Count by budget level: {budget_counts}")
    country_counts = collection.aggregate(
        [
            {"$group": {"_id": "$country", "count": {"$sum": 1}}},
            {"$sort": {"count": -1, "_id": 1}},
        ]
    )
    print("- Count by country:")
    for item in country_counts:
        print(f"  {item['_id']}: {item['count']}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Import Dataset_tourism.xlsx into MongoDB travel_items.")
    parser.add_argument("--excel", type=Path, default=DEFAULT_EXCEL_PATH, help="Path to Dataset_tourism.xlsx.")
    parser.add_argument("--import", dest="do_import", action="store_true", help="Write transformed rows to MongoDB.")
    parser.add_argument(
        "--replace",
        action="store_true",
        help="Delete existing travel_items before importing. Only valid with --import.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if args.replace and not args.do_import:
        raise SystemExit("--replace can only be used together with --import.")

    timestamp = datetime.now(timezone.utc)
    records = read_xlsx_rows(args.excel)
    documents = [transform_record(record, timestamp) for record in records]

    database = connect_database()
    collection = database[TARGET_COLLECTION]
    current_count = collection.count_documents({})

    print_summary(documents, current_count)
    warn_about_validator(collection)

    if not args.do_import:
        print("\nDry run only. No MongoDB documents were changed.")
        print("Run again with --import to upsert rows, or --import --replace to clear travel_items first.")
        return

    if current_count and not args.replace:
        print("\nExisting documents found. Import will upsert by country/city/type/name/source file.")
        print("Use --replace only if you intentionally want to clear travel_items first.")

    import_documents(collection, documents, args.replace)
    ensure_indexes(collection)
    print_database_counts(collection)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"Import failed: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
