from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes.health import router as health_router
from app.api.v1.routes.auth import router as auth_router
from app.api.v1.routes.destinations import router as destinations_router
from app.api.v1.routes.travel_items import router as travel_items_router
from app.api.v1.routes.ai_packages import router as ai_packages_router
from app.api.v1.routes.trips import router as trips_router
from app.api.v1.routes.favorites import router as favorites_router


app = FastAPI(title="Travel Planning API")
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^http://(localhost|127\.0\.0\.1):\d+$",
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth_router, prefix="/api/v1")
app.include_router(destinations_router, prefix="/api/v1")
app.include_router(travel_items_router, prefix="/api/v1")
app.include_router(ai_packages_router, prefix="/api/v1")
app.include_router(trips_router, prefix="/api/v1")
app.include_router(favorites_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {"status": "ok", "service": "travel_planning_api"}
