from app.services.travel_ai.model_utils import load_tourism_data, load_package_quality_model


def normalize_text(value):
    return str(value).strip().lower()


def split_interests(interests):
    if isinstance(interests, list):
        return [normalize_text(i) for i in interests]

    return [
        normalize_text(i)
        for i in str(interests).replace(",", ";").split(";")
        if normalize_text(i)
    ]


def score_item(row, budget_level, trip_style, travelers, user_interests):
    score = 0

    item_budget = normalize_text(row.get("item_budget_level", ""))
    category = normalize_text(row.get("category", ""))
    tags = normalize_text(row.get("interest_tags", ""))
    rating = float(row.get("rating", 0) or 0)

    nightlife_keywords = [
        "nightlife",
        "night",
        "club",
        "clubs",
        "nightclub",
        "nightclubs",
        "bar",
        "bars",
        "party",
        "lounge",
        "dj",
    ]

    nightlife_requested = (
        normalize_text(trip_style) == "nightlife"
        or any(keyword in user_interests for keyword in nightlife_keywords)
    )

    item_looks_like_nightlife = (
        "nightlife" in tags
        or "nightclub" in tags
        or "club" in tags
        or "bar" in tags
        or "party" in tags
        or "lounge" in tags
        or "dj" in tags
        or "night" in category
        or "nightlife" in category
        or "nightclub" in category
        or "club" in category
        or "bar" in category
    )

    # In Casual mode, nightlife is allowed.
    # If the user asks for nightlife/club/bar interests, boost those items.
    if item_looks_like_nightlife and nightlife_requested:
        score += 12

    # Budget match uses ONLY item_budget_level.
    # Do not use interest_tags to decide budget.
    requested_budget = normalize_text(budget_level)

    if item_budget == requested_budget:
        score += 5

    # Interest tag match
    for interest in user_interests:
        if interest in tags or interest in category:
            score += 3

    # Trip style match using boolean columns
    style = normalize_text(trip_style)

    if style == "culture" and int(row.get("is_culture_item", 0)) == 1:
        score += 4

    if style == "romantic" and int(row.get("is_romantic_item", 0)) == 1:
        score += 4

    if style == "adventure" and int(row.get("is_adventure_item", 0)) == 1:
        score += 4

    if style == "nightlife" and int(row.get("is_nightlife_item", 0)) == 1:
        score += 4

    # Traveler match
    traveler_value = normalize_text(travelers)

    if traveler_value in ["family", "families"] and int(row.get("is_family_friendly", 0)) == 1:
        score += 4

    if traveler_value in ["couple", "couples"] and int(row.get("is_romantic_item", 0)) == 1:
        score += 3

    # Rating bonus
    score += rating

    return score


def estimate_package_quality(package):
    """
    Uses the trained model to predict if the package is good or bad.
    Returns a label and confidence score.
    """
    model = load_package_quality_model()

    package_text = (
        str(package.get("interests", "")) + " " +
        str(package.get("selected_city", "")) + " " +
        str(package.get("selected_hotel", "")) + " " +
        ";".join(package.get("selected_activities", [])) + " " +
        ";".join(package.get("selected_restaurants", []))
    )

    input_data = {
        "country": [package.get("country", "")],
        "days": [package.get("days", 1)],
        "budget_level": [package.get("budget_level", "")],
        "trip_style": [package.get("trip_style", "")],
        "travelers": [package.get("travelers", "")],
        "package_text": [package_text],
    }

    import pandas as pd

    input_df = pd.DataFrame(input_data)

    prediction = model.predict(input_df)[0]

    confidence = None
    if hasattr(model, "predict_proba"):
        probabilities = model.predict_proba(input_df)[0]
        confidence = float(max(probabilities))

    if int(prediction) == 1:
        quality = "good"
    else:
        quality = "bad"

    return {
        "quality": quality,
        "confidence": confidence
    }


def row_to_item_dict(row):
    """
    Converts a dataset row into a clean dictionary for the frontend.
    """
    return {
        "country": str(row.get("country", "")),
        "city": str(row.get("city", "")),
        "type": str(row.get("type", "")),
        "name": str(row.get("name", "")),
        "category": str(row.get("category", "")),
        "cost": float(row.get("cost", 0) or 0),
        "duration_hours": float(row.get("duration_hours", 0) or 0),
        "rating": float(row.get("rating", 0) or 0),
        "interest_tags": str(row.get("interest_tags", "")),
        "item_budget_level": str(row.get("item_budget_level", "")),
        "is_family_friendly": int(row.get("is_family_friendly", 0) or 0),
        "is_culture_item": int(row.get("is_culture_item", 0) or 0),
        "is_romantic_item": int(row.get("is_romantic_item", 0) or 0),
        "is_adventure_item": int(row.get("is_adventure_item", 0) or 0),
        "is_nightlife_item": int(row.get("is_nightlife_item", 0) or 0),
        "image_url": ""
    }


def build_daily_itinerary(days, hotel_name, activities, restaurants):
    """
    Builds a simple day-by-day itinerary using selected activities and restaurants.
    Avoids empty activity days.
    """
    days = int(days)
    itinerary = []

    for day in range(1, days + 1):
        day_activities = activities[(day - 1) * 2: day * 2]

        if not day_activities:
            day_activities = ["Free time / explore the city at your own pace"]

        if restaurants:
            day_restaurant = restaurants[(day - 1) % len(restaurants)]
            day_restaurants = [day_restaurant]
        else:
            day_restaurants = ["Restaurant suggestion not available"]

        itinerary.append({
            "day": day,
            "hotel": hotel_name,
            "activities": day_activities,
            "restaurants": day_restaurants
        })

    return itinerary


def generate_package(
    country,
    days,
    budget_level,
    trip_style,
    travelers,
    interests,
    mode="Casual",
    custom_budget=None,
):
    tourism_df = load_tourism_data()

    user_interests = split_interests(interests)
    mode_value = normalize_text(mode)

    if mode_value == "luxury":
        budget_level = "luxury"

    destination_value = normalize_text(country)
    forced_city = None
    selected_country_name = country

    country_rows = tourism_df[
        tourism_df["country"].str.lower() == destination_value
    ].copy()

    # If the user typed a city instead of a country, search by city.
    if country_rows.empty:
        city_rows = tourism_df[
            tourism_df["city"].str.lower() == destination_value
        ].copy()

        if not city_rows.empty:
            country_rows = city_rows
            forced_city = city_rows.iloc[0]["city"]
            selected_country_name = city_rows.iloc[0]["country"]

    # Luxury mode should only use luxury inventory based on item_budget_level only
    if mode_value == "luxury":
        country_rows = country_rows[
            country_rows["item_budget_level"].str.lower() == "luxury"
        ].copy()

    if country_rows.empty:
        return {
            "error": "not enough data",
            "reason": f"No tourism items found for destination: {country}"
        }

    # Score every row
    country_rows["score"] = country_rows.apply(
        lambda row: score_item(row, budget_level, trip_style, travelers, user_interests),
        axis=1
    )

    # Choose best city by total score
    city_scores = (
        country_rows
        .groupby("city")["score"]
        .sum()
        .sort_values(ascending=False)
    )

    if city_scores.empty:
        return {
            "error": "not enough data",
            "reason": "No valid city found for this country."
        }

    selected_city = forced_city if forced_city is not None else city_scores.index[0]

    city_rows = country_rows[country_rows["city"] == selected_city].copy()

    hotels = city_rows[city_rows["type"].str.lower() == "hotel"].sort_values(
        by=["score", "rating"],
        ascending=False
    )

    activities = city_rows[
        city_rows["type"].str.lower().isin(["activity", "nightlife"])
    ].sort_values(
        by=["score", "rating"],
        ascending=False
    )

    restaurants = city_rows[city_rows["type"].str.lower() == "restaurant"].sort_values(
        by=["score", "rating"],
        ascending=False
    )

    if hotels.empty or activities.empty or restaurants.empty:
        return {
            "error": "not enough data",
            "reason": "The selected city does not have enough hotels, activities, or restaurants."
        }

    custom_budget_value = None
    if custom_budget is not None:
        try:
            custom_budget_value = float(custom_budget)
        except (TypeError, ValueError):
            custom_budget_value = None

    if custom_budget_value is not None and custom_budget_value > 0:
        # Try to keep the hotel around 70% of the full package budget.
        hotel_budget_per_night = (custom_budget_value * 0.70) / int(days)

        affordable_hotels = hotels[
            hotels["cost"].astype(float) <= hotel_budget_per_night
        ]

        # If that is too strict, allow any hotel that still keeps hotel total under budget.
        if affordable_hotels.empty:
            affordable_hotels = hotels[
                (hotels["cost"].astype(float) * int(days)) <= custom_budget_value
            ]

        if affordable_hotels.empty:
            return {
                "error": "budget too low",
                "reason": (
                    f"No hotel package found within your custom budget of "
                    f"${custom_budget_value:.0f}. Try increasing your budget."
                )
            }

        hotels = affordable_hotels

    selected_hotel_row = hotels.iloc[0]
    selected_hotel = selected_hotel_row["name"]
    selected_hotel_details = row_to_item_dict(selected_hotel_row)

    # Simple rule for number of activities/restaurants
    number_of_activities = max(1, min(int(days) * 2, len(activities)))
    number_of_restaurants = max(1, min(int(days), len(restaurants)))

    if custom_budget_value is not None and custom_budget_value > 0:
        hotel_total_cost = float(selected_hotel_details["cost"]) * int(days)
        remaining_budget = custom_budget_value - hotel_total_cost

        if remaining_budget < 0:
            return {
                "error": "budget too low",
                "reason": (
                    f"The selected hotel already exceeds your custom budget of "
                    f"${custom_budget_value:.0f}. Try increasing your budget."
                )
            }

        selected_activity_indices = []
        selected_restaurant_indices = []

        for index, row in activities.iterrows():
            if len(selected_activity_indices) >= number_of_activities:
                break

            cost = float(row.get("cost", 0) or 0)
            if cost <= remaining_budget:
                selected_activity_indices.append(index)
                remaining_budget -= cost

        for index, row in restaurants.iterrows():
            if len(selected_restaurant_indices) >= number_of_restaurants:
                break

            cost = float(row.get("cost", 0) or 0)
            if cost <= remaining_budget:
                selected_restaurant_indices.append(index)
                remaining_budget -= cost

        if not selected_activity_indices or not selected_restaurant_indices:
            return {
                "error": "budget too low",
                "reason": (
                    f"No complete package found within your custom budget of "
                    f"${custom_budget_value:.0f}. Try increasing your budget."
                )
            }

        selected_activity_rows = activities.loc[selected_activity_indices]
        selected_restaurant_rows = restaurants.loc[selected_restaurant_indices]
    else:
        selected_activity_rows = activities.head(number_of_activities)
        selected_restaurant_rows = restaurants.head(number_of_restaurants)

    selected_activities = selected_activity_rows["name"].tolist()
    selected_restaurants = selected_restaurant_rows["name"].tolist()

    selected_activities_details = [
        row_to_item_dict(row)
        for _, row in selected_activity_rows.iterrows()
    ]

    selected_restaurants_details = [
        row_to_item_dict(row)
        for _, row in selected_restaurant_rows.iterrows()
    ]

    hotel_total_cost = float(selected_hotel_details["cost"]) * int(days)

    activities_total_cost = sum(
        float(item["cost"]) for item in selected_activities_details
    )

    restaurants_total_cost = sum(
        float(item["cost"]) for item in selected_restaurants_details
    )

    estimated_total_cost = hotel_total_cost + activities_total_cost + restaurants_total_cost

    daily_itinerary = build_daily_itinerary(
        days=days,
        hotel_name=selected_hotel,
        activities=selected_activities,
        restaurants=selected_restaurants
    )

    package = {
        "country": selected_country_name,
        "days": int(days),
        "budget_level": budget_level,
        "trip_style": trip_style,
        "travelers": travelers,
        "interests": ";".join(user_interests),
        "selected_city": selected_city,
        "estimated_total_cost": estimated_total_cost,
        "daily_itinerary": daily_itinerary,
        "selected_hotel": selected_hotel,
        "selected_hotel_details": selected_hotel_details,
        "selected_activities": selected_activities,
        "selected_activities_details": selected_activities_details,
        "selected_restaurants": selected_restaurants,
        "selected_restaurants_details": selected_restaurants_details,
        "package_quality_estimate": "not_checked_yet",
        "reason": (
            f"This package was created for a {budget_level} {trip_style} trip "
            f"for {travelers} in {selected_city}. It selects highly rated places "
            f"that match the requested interests: {'; '.join(user_interests)}. "
            f"The hotel, activities, and restaurants are all from the same city "
            f"and were chosen from the real tourism dataset."
        )
    }

    quality_result = estimate_package_quality(package)

    package["package_quality_estimate"] = quality_result["quality"]
    package["quality_confidence"] = quality_result["confidence"]

    return package
