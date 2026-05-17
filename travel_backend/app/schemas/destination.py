from pydantic import BaseModel


class CountriesResponse(BaseModel):
    countries: list[str]
    count: int


class CitiesResponse(BaseModel):
    country: str
    cities: list[str]
    count: int
