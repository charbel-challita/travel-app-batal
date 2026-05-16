from fastapi import FastAPI

from app.api.routes.health import router as health_router


app = FastAPI(title="Travel Planning API")

app.include_router(health_router)


@app.get("/")
async def root():
    return {"status": "ok", "service": "travel_planning_api"}
