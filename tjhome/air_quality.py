# AUTOGENERATED! DO NOT EDIT! File to edit: ../notebooks/01-air_quality.ipynb.

# %% auto 0
__all__ = ['regulate_air_quality_schedule', 'Device', 'AirPurifier', 'TuyaAirPurifier', 'AirQualityAPIClient', 'current_aqi',
           'air_purifier_control', 'regulate_air_quality']

# %% ../notebooks/01-air_quality.ipynb 1
import json
import requests

from urllib.parse import urljoin
from tuya_iot import TuyaOpenAPI
from pydantic import BaseModel
from dagster import job, op, ScheduleDefinition
from os import environ

# %% ../notebooks/01-air_quality.ipynb 4
class Device:
    """Generic class that encapsulates all smart home devices"""


class AirPurifier(Device):
    """Air Purifiers purify the air and protect the home from pollution."""


class TuyaAirPurifier(BaseModel, AirPurifier):
    """Purifiers controlled by a Tuya Smart Switch"""

    device_id: str
    client_id: str
    client_secret: str
    country_code: str
    username: str
    password: str
    endpoint: str = "https://openapi.tuyaus.com"
    appschema: str = "smartLife"

    def __post_init__(self):
        self.client = TuyaOpenAPI(self.endpoint, self.client_id, self.client_secret)
        self.client.connect(
            self.username, self.password, self.country_code, self.appschema
        )

    def switch(self, on: bool = True):
        self.client.post(
            f"/v1.0/devices/{self.device_id}/commands",
            {"commands": [{"code": "switch_1", "value": on}]},
        )

    def turn_on(self):
        self.switch(True)

    def turn_off(self):
        self.switch(False)

# %% ../notebooks/01-air_quality.ipynb 6
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

# %% ../notebooks/01-air_quality.ipynb 8
@op
def current_aqi(context) -> int:
    "Fetch the current AQI from AQICN.org"
    client = AirQualityAPIClient(environ["AQI_API_TOKEN"])
    aqi = client.fetch_aqi_in_latlng(*json.loads(environ["HOME_LOCATION"]))
    context.log.info(f"AQI Index: {aqi}")
    return aqi

# %% ../notebooks/01-air_quality.ipynb 10
@op
def air_purifier_control(
    context,
    current_aqi,  # Current AQI reading
    threshold=50,  # AQI Threshold above which to turn on air purifier
) -> None:
    """
    If the current AQI exceeds the defined threshold, we turn on the air purifier.
    Otherwise, we turn it off.
    """
    for device_id in json.loads(environ["AIR_PURIFIER_DEVICE_IDS"]):
        device = TuyaAirPurifier(
            device_id,
            environ["TUYA_CLIENT_ID"],
            environ["TUYA_CLIENT_SECRET"],
            "63",
            environ["TUYA_USERNAME"],
            environ["TUYA_PASSWORD"],
        )
        if current_aqi > threshold:
            context.log.info(f"AQI {threshold} exceeded. Turning on purifier...")
            device.turn_on()
        else:
            context.log.info(f"AQI {threshold} reached. Turning off purifier...")
            device.turn_off()
        return

# %% ../notebooks/01-air_quality.ipynb 12
@job
def regulate_air_quality():
    "Dagster Job regulates air quality"
    air_purifier_control(current_aqi())


regulate_air_quality_schedule = ScheduleDefinition(
    job=regulate_air_quality, cron_schedule="*/1 * * * *"
)
