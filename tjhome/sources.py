import requests
from urllib.parse import urljoin


class AirQualityAPIClient:
    """
    Air Quality Index API Client

    [Documentation](https://aqicn.org/json-api/doc/)
    """

    base_url = "http://api.waqi.info/"

    def __init__(self, token: str):
        self.token = token

    def fetch_aqi_in_latlng(self, lat: float, lng: float):
        resp = requests.get(
            urljoin(self.base_url, f"/feed/geo:{lat};{lng}/"),
            params={"token": self.token},
        )
        return int(resp.json()["data"]["aqi"])
