from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.repositories.favorite_repository import FavoriteRepository
from app.repositories.user_repository import UserRepository
from app.schemas.favorite import (
    FavoriteCheckResponse,
    FavoriteCreateRequest,
    FavoriteResponse,
    FavoritesListResponse,
)
from app.schemas.user import UserResponse
from app.services.auth_service import AuthService
from app.services.favorite_service import FavoriteService


router = APIRouter(prefix="/favorites", tags=["favorites"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_favorite_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> FavoriteService:
    repository = FavoriteRepository(database)
    return FavoriteService(repository)


def get_auth_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> AuthService:
    repository = UserRepository(database)
    return AuthService(repository)


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    return await service.get_current_user(token)


@router.get("", response_model=FavoritesListResponse)
async def list_favorites(
    service: FavoriteService = Depends(get_favorite_service),
    current_user: UserResponse = Depends(get_current_user),
) -> FavoritesListResponse:
    return await service.list_favorites(user_id=current_user.id)


@router.post("", response_model=FavoriteResponse)
async def add_favorite(
    request: FavoriteCreateRequest,
    service: FavoriteService = Depends(get_favorite_service),
    current_user: UserResponse = Depends(get_current_user),
) -> FavoriteResponse:
    return await service.add_favorite(request, user_id=current_user.id)


@router.delete("/{target_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite(
    target_id: str,
    service: FavoriteService = Depends(get_favorite_service),
    current_user: UserResponse = Depends(get_current_user),
) -> None:
    removed = await service.remove_favorite(target_id, user_id=current_user.id)

    if not removed:
        raise HTTPException(status_code=404, detail="Favorite not found")


@router.get("/check/{target_id}", response_model=FavoriteCheckResponse)
async def check_favorite(
    target_id: str,
    service: FavoriteService = Depends(get_favorite_service),
    current_user: UserResponse = Depends(get_current_user),
) -> FavoriteCheckResponse:
    return await service.check_favorite(target_id, user_id=current_user.id)
