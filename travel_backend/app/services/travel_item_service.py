import re
from typing import Any

from app.repositories.travel_item_repository import TravelItemRepository
from app.schemas.travel_item import FeaturedTravelItemsResponse, TravelItemResponse, TravelItemsSearchResponse
from app.utils.object_id import object_id_to_str


MAX_LIMIT = 100
DEFAULT_LIMIT = 20
FEATURED_DEFAULT_LIMIT = 12
FEATURED_MAX_LIMIT = 50
ALLOWED_TYPES = {"activity", "hotel", "restaurant", "nightlife"}
ALLOWED_BUDGET_LEVELS = {"low", "mid", "luxury"}


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip()).lower()


def parse_interests(value: str | None) -> list[str]:
    if not value:
        return []
    return [normalize_text(part) for part in value.split(",") if part.strip()]


class TravelItemService:
    def __init__(self, repository: TravelItemRepository):
        self.repository = repository

    async def list_travel_items(
        self,
        *,
        country: str | None = None,
        city: str | None = None,
        type: str | None = None,
        budget_level: str | None = None,
        interests: str | None = None,
        min_rating: float | None = None,
        family_friendly: bool | None = None,
        culture: bool | None = None,
        romantic: bool | None = None,
        adventure: bool | None = None,
        nightlife: bool | None = None,
        limit: int = DEFAULT_LIMIT,
    ) -> list[TravelItemResponse]:
        query = self._build_query(
            country=country,
            city=city,
            type=type,
            budget_level=budget_level,
            interests=interests,
            min_rating=min_rating,
            family_friendly=family_friendly,
            culture=culture,
            romantic=romantic,
            adventure=adventure,
            nightlife=nightlife,
        )
        documents = await self.repository.find_travel_items(query, self._clean_limit(limit))
        return [self._to_response(document) for document in documents]

    async def search_travel_items(
        self,
        *,
        q: str,
        limit: int = DEFAULT_LIMIT,
    ) -> TravelItemsSearchResponse:
        normalized_query = normalize_text(q)
        documents = await self.repository.search_travel_items(
            self._build_search_query(normalized_query),
            self._clean_limit(limit),
        )
        items = [self._to_search_response(document) for document in documents]
        return TravelItemsSearchResponse(query=normalized_query, items=items, count=len(items))

    async def list_featured_travel_items(
        self,
        *,
        country: str | None = None,
        city: str | None = None,
        type: str | None = None,
        budget_level: str | None = None,
        limit: int = FEATURED_DEFAULT_LIMIT,
    ) -> FeaturedTravelItemsResponse:
        query = self._build_featured_query(
            country=country,
            city=city,
            type=type,
            budget_level=budget_level,
        )
        documents = await self.repository.find_featured_travel_items(
            query,
            self._clean_limit(limit, default=FEATURED_DEFAULT_LIMIT, maximum=FEATURED_MAX_LIMIT),
        )
        items = [self._to_full_document_response(document) for document in documents]
        return FeaturedTravelItemsResponse(items=items, count=len(items))

    def _build_query(
        self,
        *,
        country: str | None,
        city: str | None,
        type: str | None,
        budget_level: str | None,
        interests: str | None,
        min_rating: float | None,
        family_friendly: bool | None,
        culture: bool | None,
        romantic: bool | None,
        adventure: bool | None,
        nightlife: bool | None,
    ) -> dict[str, Any]:
        query: dict[str, Any] = {"is_active": True}

        if country:
            query["country_normalized"] = normalize_text(country)
        if city:
            query["city_normalized"] = normalize_text(city)
        if type:
            normalized_type = normalize_text(type)
            if normalized_type in ALLOWED_TYPES:
                query["type"] = normalized_type
        if budget_level:
            normalized_budget = normalize_text(budget_level)
            if normalized_budget in ALLOWED_BUDGET_LEVELS:
                query["item_budget_level"] = normalized_budget
        interest_values = parse_interests(interests)
        if interest_values:
            query["interest_tags"] = {"$in": interest_values}
        if min_rating is not None:
            query["rating"] = {"$gte": min_rating}

        flag_filters = {
            "flags.family_friendly": family_friendly,
            "flags.culture_item": culture,
            "flags.romantic_item": romantic,
            "flags.adventure_item": adventure,
            "flags.nightlife_item": nightlife,
        }
        for key, value in flag_filters.items():
            if value is not None:
                query[key] = value

        return query

    def _build_search_query(self, query_text: str) -> dict[str, Any]:
        safe_pattern = re.escape(query_text)
        regex_filter = {"$regex": safe_pattern, "$options": "i"}
        return {
            "is_active": True,
            "$or": [
                {"name_normalized": regex_filter},
                {"country_normalized": regex_filter},
                {"city_normalized": regex_filter},
                {"category": regex_filter},
                {"interest_tags": regex_filter},
                {"type": regex_filter},
                {"item_budget_level": regex_filter},
            ],
        }

    def _build_featured_query(
        self,
        *,
        country: str | None,
        city: str | None,
        type: str | None,
        budget_level: str | None,
    ) -> dict[str, Any]:
        query: dict[str, Any] = {"is_active": True}

        if country:
            query["country_normalized"] = normalize_text(country)
        if city:
            query["city_normalized"] = normalize_text(city)
        if type:
            normalized_type = normalize_text(type)
            if normalized_type in ALLOWED_TYPES:
                query["type"] = normalized_type
        if budget_level:
            normalized_budget = normalize_text(budget_level)
            if normalized_budget in ALLOWED_BUDGET_LEVELS:
                query["item_budget_level"] = normalized_budget

        return query

    def _clean_limit(self, limit: int, *, default: int = DEFAULT_LIMIT, maximum: int = MAX_LIMIT) -> int:
        if limit < 1:
            return default
        return min(limit, maximum)

    def _to_response(self, document: dict[str, Any]) -> TravelItemResponse:
        return TravelItemResponse(
            id=object_id_to_str(document["_id"]),
            country=document["country"],
            city=document["city"],
            type=document["type"],
            name=document["name"],
            category=document["category"],
            cost=float(document["cost"]),
            currency=document.get("currency", "USD"),
            duration_hours=float(document["duration_hours"]),
            rating=float(document["rating"]),
            interest_tags=document.get("interest_tags", []),
            item_budget_level=document["item_budget_level"],
            flags=document["flags"],
            images=document.get("images", []),
        )

    def _to_search_response(self, document: dict[str, Any]) -> dict[str, Any]:
        return self._to_full_document_response(document)

    def _to_full_document_response(self, document: dict[str, Any]) -> dict[str, Any]:
        return {
            "_id": object_id_to_str(document["_id"]),
            "country": document["country"],
            "country_normalized": document["country_normalized"],
            "city": document["city"],
            "city_normalized": document["city_normalized"],
            "type": document["type"],
            "name": document["name"],
            "name_normalized": document["name_normalized"],
            "category": document["category"],
            "cost": float(document["cost"]),
            "currency": document.get("currency", "USD"),
            "duration_hours": float(document["duration_hours"]),
            "rating": float(document["rating"]),
            "interest_tags": document.get("interest_tags", []),
            "item_budget_level": document["item_budget_level"],
            "flags": document["flags"],
            "images": document.get("images", []),
            "source": document["source"],
            "is_active": document["is_active"],
            "created_at": document["created_at"],
            "updated_at": document["updated_at"],
        }
