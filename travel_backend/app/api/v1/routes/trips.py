from fastapi import APIRouter, Depends, HTTPException, Query, status
from fastapi.security import OAuth2PasswordBearer
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.repositories.favorite_repository import FavoriteRepository
from app.repositories.trip_repository import TripRepository
from app.repositories.user_repository import UserRepository
from app.schemas.trip import (
    ProfileStatsResponse,
    TripCountsResponse,
    TripCreateRequest,
    TripResponse,
    TripStatus,
    TripStatusUpdateRequest,
    TripsListResponse,
)
from app.schemas.user import UserResponse
from app.services.auth_service import AuthService
from app.services.trip_service import TripService


router = APIRouter(prefix="/trips", tags=["trips"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_trip_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> TripService:
    repository = TripRepository(database)
    return TripService(repository)


def get_auth_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> AuthService:
    repository = UserRepository(database)
    return AuthService(repository)


def get_favorite_repository(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> FavoriteRepository:
    return FavoriteRepository(database)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    return await service.get_current_user(token)


@router.get("", response_model=TripsListResponse)
async def list_trips(
    status: TripStatus | None = Query(default=None),
    service: TripService = Depends(get_trip_service),
    current_user: UserResponse = Depends(get_current_user),
) -> TripsListResponse:
    return await service.list_trips(status=status, user_id=current_user.id)


@router.get("/counts", response_model=TripCountsResponse)
async def get_trip_counts(
    service: TripService = Depends(get_trip_service),
    current_user: UserResponse = Depends(get_current_user),
) -> TripCountsResponse:
    return await service.get_counts(user_id=current_user.id)


@router.get("/profile-stats", response_model=ProfileStatsResponse)
async def get_profile_stats(
    service: TripService = Depends(get_trip_service),
    favorite_repository: FavoriteRepository = Depends(get_favorite_repository),
    current_user: UserResponse = Depends(get_current_user),
) -> ProfileStatsResponse:
    user_object_id = service._to_object_id(current_user.id)
    favorites_count = await favorite_repository.count_favorites(user_object_id)
    return await service.get_profile_stats(
        user_id=current_user.id,
        favorites_count=favorites_count,
    )


@router.post("", response_model=TripResponse)
async def save_trip(
    request: TripCreateRequest,
    service: TripService = Depends(get_trip_service),
    current_user: UserResponse = Depends(get_current_user),
) -> TripResponse:
    return await service.save_trip(request, user_id=current_user.id)


@router.put("/{trip_id}/status", response_model=TripResponse)
async def update_trip_status(
    trip_id: str,
    request: TripStatusUpdateRequest,
    service: TripService = Depends(get_trip_service),
    current_user: UserResponse = Depends(get_current_user),
) -> TripResponse:
    trip = await service.update_status(
        trip_id,
        request.status,
        user_id=current_user.id,
    )

    if trip is None:
        raise HTTPException(status_code=404, detail="Trip not found")

    return trip


@router.delete("/{trip_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_trip(
    trip_id: str,
    service: TripService = Depends(get_trip_service),
    current_user: UserResponse = Depends(get_current_user),
) -> None:
    deleted = await service.delete_trip(trip_id, user_id=current_user.id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Trip not found")
