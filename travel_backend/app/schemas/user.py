from pydantic import BaseModel, EmailStr, Field, field_validator


class UserRegisterRequest(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=80)
    last_name: str = Field(..., min_length=1, max_length=80)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=72)

    @field_validator("first_name", "last_name")
    @classmethod
    def clean_name(cls, value: str) -> str:
        cleaned = " ".join(value.strip().split())
        if not cleaned:
            raise ValueError("Name cannot be blank")
        return cleaned


class UserLoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=1, max_length=72)


class UserUpdateRequest(BaseModel):
    first_name: str | None = Field(default=None, min_length=1, max_length=80)
    last_name: str | None = Field(default=None, min_length=1, max_length=80)
    email: EmailStr | None = None
    password: str | None = Field(default=None, min_length=6, max_length=72)
    avatar_url: str | None = None

    @field_validator("first_name", "last_name")
    @classmethod
    def clean_optional_name(cls, value: str | None) -> str | None:
        if value is None:
            return None

        cleaned = " ".join(value.strip().split())
        if not cleaned:
            raise ValueError("Name cannot be blank")
        return cleaned

    @field_validator("avatar_url")
    @classmethod
    def clean_avatar_url(cls, value: str | None) -> str | None:
        if value is None:
            return None

        cleaned = value.strip()
        return cleaned or None


class UserResponse(BaseModel):
    id: str
    full_name: str
    email: EmailStr
    default_travel_mode: str
    profile_label: str | None = None
    avatar_url: str | None = None


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
