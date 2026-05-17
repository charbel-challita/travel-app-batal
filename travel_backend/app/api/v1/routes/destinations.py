from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.repositories.destination_repository import DestinationRepository
from app.schemas.destination import CitiesResponse, CountriesResponse
from app.services.destination_service import DestinationService


router = APIRouter(prefix="/destinations", tags=["destinations"])


def get_destination_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> DestinationService:
    repository = DestinationRepository(database)
    return DestinationService(repository)


@router.get("/countries", response_model=CountriesResponse)
async def list_countries(
    service: DestinationService = Depends(get_destination_service),
) -> CountriesResponse:
    return await service.list_countries()


@router.get("/cities", response_model=CitiesResponse)
async def list_cities(
    country: str = Query(..., min_length=1),
    service: DestinationService = Depends(get_destination_service),
) -> CitiesResponse:
    return await service.list_cities(country)
