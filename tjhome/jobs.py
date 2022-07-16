from sources import AirQualityAPIClient
from devices import TuyaAirPurifier
from dagster import job, op, ScheduleDefinition
from os import environ
import json


@op
def current_aqi() -> int:
    client = AirQualityAPIClient(environ["AQI_API_TOKEN"])
    return client.fetch_aqi_in_latlng(*json.loads(environ["HOME_LOCATION"]))


@op
def air_purifier_control(current_aqi) -> None:
    for device_id in environ["AIR_PURIFIER_DEVICE_IDS"]:
        device = TuyaAirPurifier(
            device_id,
            environ["TUYA_CLIENT_ID"],
            environ["TUYA_CLIENT_SECRET"],
            "63",
            environ["TUYA_USERNAME"],
            environ["TUYA_PASSWORD"],
        )
        if current_aqi > 50:
            device.turn_on()
        else:
            device.turn_off()
        return


@job
def regulate_air_quality():
    air_purifier_control(current_aqi())


regulate_air_quality_schedule = ScheduleDefinition(
    job=regulate_air_quality, cron_schedule="*/15 * * * *"
)
