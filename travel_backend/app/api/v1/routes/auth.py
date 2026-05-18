from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordBearer
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.db.mongodb import get_database
from app.repositories.user_repository import UserRepository
from app.schemas.user import (
    AuthTokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
    UserUpdateRequest,
)
from app.services.auth_service import AuthService


router = APIRouter(prefix="/auth", tags=["auth"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_auth_service(
    database: AsyncIOMotorDatabase = Depends(get_database),
) -> AuthService:
    repository = UserRepository(database)
    return AuthService(repository)


@router.post("/register", response_model=AuthTokenResponse, status_code=201)
async def register(
    payload: UserRegisterRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthTokenResponse:
    return await service.register(payload)


@router.post("/login", response_model=AuthTokenResponse)
async def login(
    payload: UserLoginRequest,
    service: AuthService = Depends(get_auth_service),
) -> AuthTokenResponse:
    return await service.login(payload)


@router.get("/me", response_model=UserResponse)
async def get_me(
    token: str = Depends(oauth2_scheme),
    service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    return await service.get_current_user(token)


@router.put("/me", response_model=UserResponse)
async def update_me(
    payload: UserUpdateRequest,
    token: str = Depends(oauth2_scheme),
    service: AuthService = Depends(get_auth_service),
) -> UserResponse:
    return await service.update_current_user(token, payload)
