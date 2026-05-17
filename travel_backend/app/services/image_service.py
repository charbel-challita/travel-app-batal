from typing import Any

from app.core.config import Settings


PEXELS_SEARCH_URL = "https://api.pexels.com/v1/search"


class ImageService:
    def __init__(self, settings: Settings):
        self.settings = settings

    async def fetch_images_for_item(self, item: dict[str, Any]) -> list[dict[str, Any]]:
        if not self._is_enabled():
            return []

        query = self._build_query(item)
        if not query:
            return []

        try:
            import httpx

            async with httpx.AsyncClient(timeout=self.settings.image_request_timeout_seconds) as client:
                response = await client.get(
                    PEXELS_SEARCH_URL,
                    headers={"Authorization": self.settings.pexels_api_key},
                    params={
                        "query": query,
                        "per_page": self._result_limit(),
                    },
                )
                response.raise_for_status()
        except Exception:
            return []

        return self._normalize_pexels_response(response.json(), item)

    def _is_enabled(self) -> bool:
        return (
            self.settings.image_fetch_enabled
            and self.settings.image_provider.lower() == "pexels"
            and bool(self.settings.pexels_api_key.strip())
        )

    def _build_query(self, item: dict[str, Any]) -> str:
        name = str(item.get("name") or "").strip()
        city = str(item.get("city") or "").strip()
        country = str(item.get("country") or "").strip()
        category = str(item.get("category") or "").strip()
        item_type = str(item.get("type") or "").strip().lower()

        if item_type == "hotel":
            return self._clean_query(f"{name} hotel {city} {country}")
        if item_type == "restaurant":
            return self._clean_query(f"{name} restaurant food {city} {country}")
        if item_type == "nightlife":
            return self._clean_query(f"{name} nightlife club bar {city} {country}")
        if item_type == "activity":
            return self._clean_query(f"{name} {category} {city} {country} travel")
        return self._clean_query(f"{city} {country} travel {category}")

    def _clean_query(self, value: str) -> str:
        return " ".join(value.split())

    def _normalize_pexels_response(
        self,
        data: dict[str, Any],
        item: dict[str, Any],
    ) -> list[dict[str, Any]]:
        photos = data.get("photos")
        if not isinstance(photos, list):
            return []

        images: list[dict[str, Any]] = []
        limit = self._result_limit()
        fallback_alt = self._clean_query(
            f"{item.get('name', '')} {item.get('city', '')} {item.get('country', '')}"
        )

        for photo in photos[:limit]:
            if not isinstance(photo, dict):
                continue
            src = photo.get("src")
            if not isinstance(src, dict):
                continue

            url = src.get("large") or src.get("original")
            thumbnail_url = src.get("medium") or src.get("small") or src.get("tiny")
            if not url:
                continue

            images.append(
                {
                    "url": url,
                    "thumbnail_url": thumbnail_url,
                    "source": "pexels",
                    "alt": photo.get("alt") or fallback_alt,
                    "photographer": photo.get("photographer"),
                    "source_url": photo.get("url"),
                }
            )

        return images

    def _result_limit(self) -> int:
        return 1
