import re
from typing import Any

from app.core.config import get_settings
from app.repositories.travel_item_repository import TravelItemRepository
from app.schemas.travel_item import (
    FeaturedTravelItemsResponse,
    TravelItemResponse,
    TravelItemSuggestion,
    TravelItemSuggestionsResponse,
    TravelItemsSearchResponse,
)
from app.services.image_service import ImageService
from app.utils.object_id import object_id_to_str


MAX_LIMIT = 100
DEFAULT_LIMIT = 20
FEATURED_DEFAULT_LIMIT = 12
FEATURED_MAX_LIMIT = 50
SUGGESTIONS_DEFAULT_LIMIT = 5
SUGGESTIONS_MAX_LIMIT = 5
SUGGESTIONS_MIN_QUERY_LENGTH = 2
ALLOWED_TYPES = {"activity", "hotel", "restaurant", "nightlife"}
ALLOWED_BUDGET_LEVELS = {"low", "mid", "luxury"}


def normalize_text(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip()).lower()


def parse_interests(value: str | None) -> list[str]:
    if not value:
        return []
    return [normalize_text(part) for part in value.split(",") if part.strip()]


class TravelItemService:
    def __init__(self, repository: TravelItemRepository, image_service: ImageService | None = None):
        self.repository = repository
        self.image_service = image_service or ImageService(get_settings())

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
        include_images: bool = False,
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
        if include_images:
            documents = await self._enrich_documents_with_images(documents)
        return [self._to_response(document) for document in documents]

    async def search_travel_items(
        self,
        *,
        q: str,
        include_images: bool = False,
        limit: int = DEFAULT_LIMIT,
        type: str | None = None,
        category: str | None = None,
        budget_level: str | None = None,
        interests: str | None = None,
        family_friendly: bool | None = None,
        culture: bool | None = None,
        romantic: bool | None = None,
        adventure: bool | None = None,
        nightlife: bool | None = None,
    ) -> TravelItemsSearchResponse:
        normalized_query = normalize_text(q)
        filters = self._build_filter_query(
            type=type,
            category=category,
            budget_level=budget_level,
            interests=interests,
            family_friendly=family_friendly,
            culture=culture,
            romantic=romantic,
            adventure=adventure,
            nightlife=nightlife,
        )
        documents = await self.repository.search_travel_items(
            self._build_search_query(normalized_query, filters),
            self._clean_limit(limit),
        )
        if include_images:
            documents = await self._enrich_documents_with_images(documents)
        items = [self._to_search_response(document) for document in documents]
        return TravelItemsSearchResponse(
            query=normalized_query,
            items=items,
            count=len(items),
        )

    async def suggest_travel_items(
        self,
        *,
        q: str,
        limit: int = SUGGESTIONS_DEFAULT_LIMIT,
        type: str | None = None,
        category: str | None = None,
        budget_level: str | None = None,
        interests: str | None = None,
        family_friendly: bool | None = None,
        culture: bool | None = None,
        romantic: bool | None = None,
        adventure: bool | None = None,
        nightlife: bool | None = None,
    ) -> TravelItemSuggestionsResponse:
        normalized_query = normalize_text(q)
        clean_limit = self._clean_limit(
            limit,
            default=SUGGESTIONS_DEFAULT_LIMIT,
            maximum=SUGGESTIONS_MAX_LIMIT,
        )
        if len(normalized_query) < SUGGESTIONS_MIN_QUERY_LENGTH:
            return TravelItemSuggestionsResponse(
                query=normalized_query,
                suggestions=[],
                count=0,
            )

        prefix_filter = self._build_suggestion_prefix_filter(normalized_query)
        filters = self._build_filter_query(
            type=type,
            category=category,
            budget_level=budget_level,
            interests=interests,
            family_friendly=family_friendly,
            culture=culture,
            romantic=romantic,
            adventure=adventure,
            nightlife=nightlife,
        )
        suggestions: list[TravelItemSuggestion] = []

        if filters:
            item_documents = await self.repository.find_filtered_item_suggestions(
                prefix_filter,
                clean_limit,
                filters,
            )
            for document in item_documents:
                suggestions.append(self._to_item_suggestion(document))

            return TravelItemSuggestionsResponse(
                query=normalized_query,
                suggestions=suggestions,
                count=len(suggestions),
            )

        city_documents = await self.repository.find_city_suggestions(
            prefix_filter,
            clean_limit,
        )
        for document in city_documents:
            suggestions.append(self._to_city_suggestion(document))
            if len(suggestions) >= clean_limit:
                return TravelItemSuggestionsResponse(
                    query=normalized_query,
                    suggestions=suggestions,
                    count=len(suggestions),
                )

        remaining_limit = clean_limit - len(suggestions)
        country_documents = await self.repository.find_country_suggestions(
            prefix_filter,
            remaining_limit,
        )
        for document in country_documents:
            suggestions.append(self._to_country_suggestion(document))
            if len(suggestions) >= clean_limit:
                return TravelItemSuggestionsResponse(
                    query=normalized_query,
                    suggestions=suggestions,
                    count=len(suggestions),
                )

        remaining_limit = clean_limit - len(suggestions)
        item_documents = await self.repository.find_item_suggestions(
            prefix_filter,
            remaining_limit,
        )
        for document in item_documents:
            suggestions.append(self._to_item_suggestion(document))

        return TravelItemSuggestionsResponse(
            query=normalized_query,
            suggestions=suggestions,
            count=len(suggestions),
        )

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

    def _build_filter_query(
        self,
        *,
        type: str | None,
        category: str | None,
        budget_level: str | None,
        interests: str | None,
        family_friendly: bool | None,
        culture: bool | None,
        romantic: bool | None,
        adventure: bool | None,
        nightlife: bool | None,
    ) -> dict[str, Any]:
        filters: dict[str, Any] = {}

        if type:
            normalized_type = normalize_text(type)
            if normalized_type in ALLOWED_TYPES:
                filters["type"] = normalized_type
        if category:
            filters["category"] = category.strip()
        if budget_level:
            normalized_budget = normalize_text(budget_level)
            if normalized_budget in ALLOWED_BUDGET_LEVELS:
                filters["item_budget_level"] = normalized_budget
        interest_values = parse_interests(interests)
        if interest_values:
            filters["interest_tags"] = {"$in": interest_values}

        flag_filters = {
            "flags.family_friendly": family_friendly,
            "flags.culture_item": culture,
            "flags.romantic_item": romantic,
            "flags.adventure_item": adventure,
            "flags.nightlife_item": nightlife,
        }
        for key, value in flag_filters.items():
            if value is not None:
                filters[key] = value

        return filters

    def _build_search_query(
        self,
        query_text: str,
        filters: dict[str, Any],
    ) -> dict[str, Any]:
        safe_pattern = re.escape(query_text)
        regex_filter = {"$regex": safe_pattern, "$options": "i"}
        return {
            "is_active": True,
            **filters,
            "$or": [
                {"name_normalized": regex_filter},
                {"country_normalized": regex_filter},
                {"city_normalized": regex_filter},
            ],
        }

    def _build_suggestion_prefix_filter(self, query_text: str) -> dict[str, Any]:
        return {"$regex": f"^{re.escape(query_text)}"}

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

    async def _enrich_documents_with_images(self, documents: list[dict[str, Any]]) -> list[dict[str, Any]]:
        for document in documents:
            if self._has_usable_images(document.get("images")):
                continue

            images = await self.image_service.fetch_images_for_item(document)
            if not images:
                document["images"] = []
                continue

            await self.repository.update_travel_item_images(document["_id"], images)
            document["images"] = images

        return documents

    def _has_usable_images(self, images: Any) -> bool:
        if not isinstance(images, list):
            return False

        for image in images:
            if isinstance(image, str) and image.strip():
                return True
            if isinstance(image, dict) and str(image.get("url") or "").strip():
                return True
        return False

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

    def _to_city_suggestion(self, document: dict[str, Any]) -> TravelItemSuggestion:
        city = document["city"]
        return TravelItemSuggestion(
            label=city,
            kind="city",
            value=city,
            city=city,
            country=document["country"],
        )

    def _to_country_suggestion(self, document: dict[str, Any]) -> TravelItemSuggestion:
        country = document["country"]
        return TravelItemSuggestion(
            label=country,
            kind="country",
            value=country,
            country=country,
        )

    def _to_item_suggestion(self, document: dict[str, Any]) -> TravelItemSuggestion:
        name = document["name"]
        return TravelItemSuggestion(
            label=name,
            kind="item",
            value=name,
            type=document["type"],
            city=document["city"],
            country=document["country"],
        )

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
