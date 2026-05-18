from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException, status
from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import get_settings
from app.models.user import (
    DEFAULT_AUTH_PROVIDER,
    DEFAULT_PROFILE_LABEL,
    DEFAULT_TRAVEL_MODE,
    default_user_stats,
    public_user_fields,
)
from app.repositories.user_repository import DuplicateEmailError, UserRepository
from app.schemas.user import (
    AuthTokenResponse,
    UserLoginRequest,
    UserRegisterRequest,
    UserResponse,
    UserUpdateRequest,
)


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    def __init__(self, repository: UserRepository):
        self.repository = repository
        self.settings = get_settings()

    async def register(self, payload: UserRegisterRequest) -> AuthTokenResponse:
        email = payload.email.lower()
        existing_user = await self.repository.find_by_email(email)
        if existing_user is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email is already registered",
            )

        now = datetime.now(timezone.utc)
        full_name = f"{payload.first_name} {payload.last_name}"
        user_document = {
            "email": email,
            "password_hash": self.get_password_hash(payload.password),
            "full_name": full_name,
            "avatar_url": None,
            "default_travel_mode": DEFAULT_TRAVEL_MODE,
            "favorite_interests": [],
            "profile_label": DEFAULT_PROFILE_LABEL,
            "stats": default_user_stats(),
            "auth_provider": DEFAULT_AUTH_PROVIDER,
            "is_active": True,
            "created_at": now,
            "updated_at": now,
            "last_login_at": None,
        }

        try:
            user = await self.repository.create_user(user_document)
        except DuplicateEmailError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email is already registered",
            ) from None

        return self._auth_response(user)

    async def login(self, payload: UserLoginRequest) -> AuthTokenResponse:
        user = await self.repository.find_by_email(payload.email.lower())
        if user is None or not self.verify_password(payload.password, user.get("password_hash", "")):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if not user.get("is_active", True):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="User account is inactive",
            )

        now = datetime.now(timezone.utc)
        user_id = str(user["_id"])
        await self.repository.update_last_login(user_id, now)
        user["last_login_at"] = now
        user["updated_at"] = now
        return self._auth_response(user)

    async def get_current_user(self, token: str) -> UserResponse:
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

        try:
            payload = jwt.decode(
                token,
                self.settings.secret_key,
                algorithms=[self.settings.algorithm],
            )
            user_id = payload.get("sub")
        except JWTError as error:
            raise credentials_exception from error

        if not isinstance(user_id, str) or not user_id:
            raise credentials_exception

        user = await self.repository.find_by_id(user_id)
        if user is None or not user.get("is_active", True):
            raise credentials_exception

        return UserResponse(**public_user_fields(user))

    async def update_current_user(self, token: str, payload: UserUpdateRequest) -> UserResponse:
        credentials_exception = HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

        try:
            token_payload = jwt.decode(
                token,
                self.settings.secret_key,
                algorithms=[self.settings.algorithm],
            )
            user_id = token_payload.get("sub")
        except JWTError as error:
            raise credentials_exception from error

        if not isinstance(user_id, str) or not user_id:
            raise credentials_exception

        user = await self.repository.find_by_id(user_id)
        if user is None or not user.get("is_active", True):
            raise credentials_exception

        updates: dict[str, Any] = {}
        now = datetime.now(timezone.utc)

        first_name = payload.first_name
        last_name = payload.last_name

        if first_name is not None or last_name is not None:
            current_name_parts = str(user.get("full_name", "")).split(" ", 1)
            current_first_name = current_name_parts[0] if current_name_parts else ""
            current_last_name = current_name_parts[1] if len(current_name_parts) > 1 else ""

            final_first_name = first_name if first_name is not None else current_first_name
            final_last_name = last_name if last_name is not None else current_last_name

            full_name = f"{final_first_name} {final_last_name}".strip()
            if full_name:
                updates["full_name"] = full_name

        if payload.email is not None:
            new_email = payload.email.lower()
            existing_user = await self.repository.find_by_email(new_email)

            if existing_user is not None and str(existing_user["_id"]) != user_id:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail="Email is already registered",
                )

            updates["email"] = new_email

        if payload.password is not None:
            updates["password_hash"] = self.get_password_hash(payload.password)

        if payload.avatar_url is not None:
            updates["avatar_url"] = payload.avatar_url

        if not updates:
            return UserResponse(**public_user_fields(user))

        updates["updated_at"] = now

        updated_user = await self.repository.update_user(user_id, updates)
        if updated_user is None:
            raise credentials_exception

        return UserResponse(**public_user_fields(updated_user))

    def get_password_hash(self, password: str) -> str:
        return pwd_context.hash(password)

    def verify_password(self, plain_password: str, password_hash: str) -> bool:
        try:
            return pwd_context.verify(plain_password, password_hash)
        except (ValueError, TypeError):
            return False

    def create_access_token(self, user: dict[str, Any]) -> str:
        expires_delta = timedelta(minutes=self.settings.access_token_expire_minutes)
        expire = datetime.now(timezone.utc) + expires_delta
        payload = {
            "sub": str(user["_id"]),
            "email": user["email"],
            "exp": expire,
        }
        return jwt.encode(
            payload,
            self.settings.secret_key,
            algorithm=self.settings.algorithm,
        )

    def _auth_response(self, user: dict[str, Any]) -> AuthTokenResponse:
        return AuthTokenResponse(
            access_token=self.create_access_token(user),
            user=UserResponse(**public_user_fields(user)),
        )
