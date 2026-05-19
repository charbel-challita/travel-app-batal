from app.services.travel_ai.model_utils import load_tourism_data
from app.services.travel_ai.recommender import normalize_text


def validate_package(package):
    tourism_df = load_tourism_data()

    if "error" in package:
        return {
            "valid": False,
            "errors": [package["reason"]]
        }

    errors = []

    country = package.get("country", "")
    selected_city = package.get("selected_city", "")
    selected_hotel = package.get("selected_hotel", "")
    selected_activities = package.get("selected_activities", [])
    selected_restaurants = package.get("selected_restaurants", [])

    country_rows = tourism_df[
        tourism_df["country"].str.lower() == normalize_text(country)
    ].copy()

    if country_rows.empty:
        errors.append(f"Country does not exist in dataset: {country}")
        return {
            "valid": False,
            "errors": errors
        }

    city_rows = country_rows[
        country_rows["city"].str.lower() == normalize_text(selected_city)
    ].copy()

    if city_rows.empty:
        errors.append(f"Selected city does not exist in country rows: {selected_city}")
        return {
            "valid": False,
            "errors": errors
        }

    hotel_rows = city_rows[
        (city_rows["name"].str.lower() == normalize_text(selected_hotel))
        & (city_rows["type"].str.lower() == "hotel")
    ]

    if hotel_rows.empty:
        errors.append(f"Selected hotel is invalid or not from selected city: {selected_hotel}")

    for activity in selected_activities:
        activity_rows = city_rows[
            (city_rows["name"].str.lower() == normalize_text(activity))
            & (city_rows["type"].str.lower().isin(["activity", "nightlife"]))
        ]

        if activity_rows.empty:
            errors.append(f"Selected activity is invalid or not from selected city: {activity}")

    for restaurant in selected_restaurants:
        restaurant_rows = city_rows[
            (city_rows["name"].str.lower() == normalize_text(restaurant))
            & (city_rows["type"].str.lower() == "restaurant")
        ]

        if restaurant_rows.empty:
            errors.append(f"Selected restaurant is invalid or not from selected city: {restaurant}")

    return {
        "valid": len(errors) == 0,
        "errors": errors
    }
