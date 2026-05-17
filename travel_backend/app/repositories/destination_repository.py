from motor.motor_asyncio import AsyncIOMotorDatabase


class DestinationRepository:
    def __init__(self, database: AsyncIOMotorDatabase):
        self.collection = database["travel_items"]

    async def get_active_countries(self) -> list[str]:
        countries = await self.collection.distinct("country", {"is_active": True})
        return sorted(country for country in countries if country)

    async def get_active_cities_by_country(self, country_normalized: str) -> list[str]:
        cities = await self.collection.distinct(
            "city",
            {
                "is_active": True,
                "country_normalized": country_normalized,
            },
        )
        return sorted(city for city in cities if city)
