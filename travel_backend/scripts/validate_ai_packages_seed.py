import json
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SEED_PATH = ROOT / "data" / "ai_packages_seed_from_dataset.json"

REQUIRED_FIELDS = {
    "mode",
    "title",
    "city",
    "country",
    "currency",
    "description",
    "image_asset",
    "included_rules",
    "included_items",
    "is_active",
    "price",
    "rating",
    "request",
    "status",
    "subtitle",
    "tag",
    "created_at",
    "updated_at",
}

VALID_MODES = {"Casual", "Luxury", "Night"}
VALID_TRAVEL_MODES = {"casual", "luxury", "night"}


def main() -> int:
    errors = []

    try:
        data = json.loads(SEED_PATH.read_text(encoding="utf-8"))
    except Exception as exc:
        print(f"Validation failed: could not load JSON from {SEED_PATH}")
        print(f"Error: {exc}")
        return 1

    if not isinstance(data, list):
        print("Validation failed: seed file must contain a JSON array.")
        return 1

    by_country = defaultdict(list)
    for index, package in enumerate(data):
        label = f"package[{index}]"
        if not isinstance(package, dict):
            errors.append(f"{label}: package must be an object")
            continue

        missing = sorted(REQUIRED_FIELDS - set(package))
        if missing:
            errors.append(f"{label}: missing required fields: {', '.join(missing)}")

        country = package.get("country")
        city = package.get("city")
        if country:
            by_country[country].append(package)

        if package.get("mode") not in VALID_MODES:
            errors.append(f"{label}: invalid mode {package.get('mode')!r}")

        request = package.get("request")
        if not isinstance(request, dict):
            errors.append(f"{label}: request must be an object")
        else:
            if request.get("travel_mode") not in VALID_TRAVEL_MODES:
                errors.append(
                    f"{label}: invalid request.travel_mode {request.get('travel_mode')!r}"
                )
            if request.get("country") != country:
                errors.append(f"{label}: request.country does not match package country")
            if request.get("city") != city:
                errors.append(f"{label}: request.city does not match package city")

        if not isinstance(package.get("price"), (int, float)):
            errors.append(f"{label}: price must be a number")

        if not isinstance(package.get("rating"), (int, float)):
            errors.append(f"{label}: rating must be a number")

        included_items = package.get("included_items")
        if not isinstance(included_items, dict):
            errors.append(f"{label}: included_items must be an object")
        else:
            for key in ("hotel", "activities", "restaurants", "nightlife"):
                if key not in included_items:
                    errors.append(f"{label}: included_items.{key} is missing")

    for country, packages in sorted(by_country.items()):
        if len(packages) > 2:
            errors.append(f"{country}: has {len(packages)} packages, expected max 2")
        if len(packages) == 2 and packages[0].get("city") == packages[1].get("city"):
            errors.append(f"{country}: two packages use the same city")

    mode_counts = Counter(package.get("mode") for package in data if isinstance(package, dict))
    package_counts = Counter(
        package.get("country") for package in data if isinstance(package, dict)
    )
    two_package_countries = sorted(
        country for country, count in package_counts.items() if count == 2
    )
    one_package_countries = sorted(
        country for country, count in package_counts.items() if count == 1
    )

    print("AI package seed validation summary")
    print(f"Seed file: {SEED_PATH}")
    print(f"Total packages: {len(data)}")
    print(f"Countries: {len(package_counts)}")
    print(f"Mode counts: {dict(mode_counts)}")
    print(f"Countries with 2 packages: {len(two_package_countries)}")
    print(f"Countries with 1 package: {len(one_package_countries)}")

    if errors:
        print("\nValidation failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print("\nValidation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
