from app.repositories.destination_repository import DestinationRepository
from app.schemas.destination import CitiesResponse, CountriesResponse
from app.services.travel_item_service import normalize_text


class DestinationService:
    def __init__(self, repository: DestinationRepository):
        self.repository = repository

    async def list_countries(self) -> CountriesResponse:
        countries = await self.repository.get_active_countries()
        return CountriesResponse(countries=countries, count=len(countries))

    async def list_cities(self, country: str) -> CitiesResponse:
        cities = await self.repository.get_active_cities_by_country(normalize_text(country))
        return CitiesResponse(country=country, cities=cities, count=len(cities))
