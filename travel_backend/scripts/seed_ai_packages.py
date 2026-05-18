import asyncio
from datetime import datetime, timezone

from app.db.mongodb import get_database


PACKAGES = [
    {
        "title": "Rome First-Time Tour",
        "subtitle": "The Eternal City",
        "description": "A ready-made first-time tour package through Rome, designed for travelers who want to explore iconic landmarks, culture, history, and local atmosphere in one organized plan.",
        "city": "Rome",
        "country": "Italy",
        "mode": "Casual",
        "price": 320,
        "currency": "USD",
        "rating": 4.7,
        "tag": "Popular",
        "image_asset": "assets/images/rome.jpg",
        "included_rules": {
            "hotel": 1,
            "activity": 2,
            "restaurant": 0,
            "nightlife": 0,
        },
        "is_active": True,
    },
    {
        "title": "Dubai City Highlights",
        "subtitle": "Modern wonders await",
        "description": "A ready-made city package for discovering Dubai's modern skyline, iconic attractions, shopping areas, and cultural highlights in one smooth travel plan.",
        "city": "Dubai",
        "country": "UAE",
        "mode": "Casual",
        "price": 290,
        "currency": "USD",
        "rating": 4.6,
        "tag": "Trending",
        "image_asset": "assets/images/dubai.png",
        "included_rules": {
            "hotel": 1,
            "activity": 2,
            "restaurant": 0,
            "nightlife": 0,
        },
        "is_active": True,
    },
    {
        "title": "Tokyo Discovery Tour",
        "subtitle": "Tradition meets tomorrow",
        "description": "A ready-made discovery package through Tokyo, combining modern city life, traditional culture, famous districts, local food, and sightseeing stops.",
        "city": "Tokyo",
        "country": "Japan",
        "mode": "Casual",
        "price": 340,
        "currency": "USD",
        "rating": 4.8,
        "tag": "Sale",
        "image_asset": "assets/images/tokyo.webp",
        "included_rules": {
            "hotel": 1,
            "activity": 2,
            "restaurant": 0,
            "nightlife": 0,
        },
        "is_active": True,
    },
    {
        "title": "Halong Bay Seaplane Tour",
        "subtitle": "Skyline views & private cruise",
        "description": "A premium seaplane tour over Halong Bay, designed for travelers who want breathtaking aerial views, limestone islands, emerald waters, and a luxury scenic experience from above.",
        "city": "Halong Bay",
        "country": "Vietnam",
        "mode": "Luxury",
        "price": 980,
        "currency": "USD",
        "rating": 4.9,
        "tag": "Private",
        "image_asset": "assets/images/halongbay.jpg",
        "budget_level": "luxury",
        "interests": ["luxury", "private", "scenic"],
        "included_rules": {
            "hotel": 0,
            "activity": 3,
            "restaurant": 0,
            "nightlife": 0,
        },
        "is_active": True,
    },
    {
        "title": "Tanzania Serengeti Luxury Safari",
        "subtitle": "Safari lodge & private wildlife tours",
        "description": "A luxury Serengeti safari package with a premium lodge stay, private safari experiences, and scenic wildlife moments in Tanzania.",
        "city": "Serengeti National Park",
        "country": "Tanzania",
        "mode": "Luxury",
        "price": 1800,
        "currency": "USD",
        "rating": 5.0,
        "tag": "Safari",
        "image_asset": "assets/images/tanzaniasafari.jpg",
        "budget_level": "luxury",
        "interests": ["luxury", "safari", "wildlife"],
        "included_rules": {
            "hotel": 1,
            "activity": 2,
            "restaurant": 0,
            "nightlife": 0,
        },
        "is_active": True,
    },
    {
        "title": "Kenya Maasai Mara Safari Escape",
        "subtitle": "Luxury camp & wildlife experiences",
        "description": "A premium Maasai Mara escape with a luxury lodge stay, private safari experiences, and unforgettable wildlife views in Kenya.",
        "city": "Maasai Mara National Reserve",
        "country": "Kenya",
        "mode": "Luxury",
        "price": 1600,
        "currency": "USD",
        "rating": 5.0,
        "tag": "Luxury",
        "image_asset": "assets/images/kenyasafari.jpg",
        "budget_level": "luxury",
        "interests": ["luxury", "safari", "nature"],
        "included_rules": {
            "hotel": 1,
            "activity": 2,
            "restaurant": 0,
            "nightlife": 0,
        },
        "is_active": True,
    },
    {
        "title": "Marseille Red Club",
        "subtitle": "Waterfront beats",
        "description": "A nightlife package for travelers who want music, drinks, and a lively club atmosphere near the waterfront.",
        "city": "Marseille",
        "country": "France",
        "mode": "Night",
        "price": 250,
        "currency": "USD",
        "rating": 4.6,
        "tag": "Trending",
        "image_asset": None,
        "budget_level": "mid-range",
        "interests": ["nightlife", "club", "music"],
        "included_rules": {
            "hotel": 0,
            "activity": 0,
            "restaurant": 0,
            "nightlife": 3,
        },
        "is_active": True,
    },
    {
        "title": "Club Ibiza Nightclub",
        "subtitle": "Island party energy",
        "description": "A nightlife package for travelers who want club energy, music, dancing, and a party atmosphere.",
        "city": "Ibiza",
        "country": "Spain",
        "mode": "Night",
        "price": 300,
        "currency": "USD",
        "rating": 4.7,
        "tag": "Popular",
        "image_asset": None,
        "budget_level": "mid-range",
        "interests": ["nightlife", "club", "party"],
        "included_rules": {
            "hotel": 0,
            "activity": 0,
            "restaurant": 0,
            "nightlife": 3,
        },
        "is_active": True,
    },
    {
        "title": "Salento Dance Club",
        "subtitle": "Latin dance nights",
        "description": "A night package focused on Latin music, dancing, and a vibrant late-night atmosphere.",
        "city": "Salento",
        "country": "Colombia",
        "mode": "Night",
        "price": 180,
        "currency": "USD",
        "rating": 4.5,
        "tag": "New",
        "image_asset": None,
        "budget_level": "mid-range",
        "interests": ["nightlife", "dance", "music"],
        "included_rules": {
            "hotel": 0,
            "activity": 0,
            "restaurant": 0,
            "nightlife": 3,
        },
        "is_active": True,
    },
]


async def seed_ai_packages():
    db = get_database()
    collection = db["ai_packages"]

    now = datetime.now(timezone.utc)

    await collection.delete_many({
        "mode": {"$in": ["Luxury", "Night"]},
        "request.source": "seed",
    })

    for package in PACKAGES:
        document = {
            **package,
            "request": {
                "country": package["country"],
                "city": package["city"],
                "days": 1,
                "budget_level": package.get("budget_level", "mid-range"),
                "travelers": "couple",
                "interests": package.get("interests", ["culture", "activities", "sightseeing"]),
                "travel_mode": package["mode"].lower(),
                "requested_at": now,
                "package_type": "ready_made",
                "source": "seed",
            },
            "status": "generated",
            "created_at": now,
            "updated_at": now,
        }

        await collection.update_one(
            {"title": package["title"], "mode": package["mode"]},
            {"$set": document},
            upsert=True,
        )

    print("AI packages seeded successfully.")


if __name__ == "__main__":
    asyncio.run(seed_ai_packages())
