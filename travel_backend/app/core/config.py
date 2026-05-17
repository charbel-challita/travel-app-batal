from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    mongodb_uri: str = "mongodb://127.0.0.1:27017"
    database_name: str = "travel_planning_app"
    pexels_api_key: str = ""
    image_provider: str = "pexels"
    image_fetch_enabled: bool = False
    image_results_per_item: int = 1
    image_request_timeout_seconds: float = 5

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()
