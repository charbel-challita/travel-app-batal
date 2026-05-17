from fastapi import FastAPI

from app.api.routes.health import router as health_router
from app.api.v1.routes.destinations import router as destinations_router
from app.api.v1.routes.travel_items import router as travel_items_router


app = FastAPI(title="Travel Planning API")

app.include_router(health_router)
app.include_router(destinations_router, prefix="/api/v1")
app.include_router(travel_items_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {"status": "ok", "service": "travel_planning_api"}
