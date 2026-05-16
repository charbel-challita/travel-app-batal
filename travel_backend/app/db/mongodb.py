from motor.motor_asyncio import AsyncIOMotorClient

from app.core.config import get_settings


settings = get_settings()
client = AsyncIOMotorClient(settings.mongodb_uri)
database = client[settings.database_name]


async def ping_mongodb() -> bool:
    await client.admin.command("ping")
    return True


def get_database():
    return database
