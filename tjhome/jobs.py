from tjhome.sources import AirQualityAPIClient
from tjhome.devices import TuyaAirPurifier
from dagster import job, op, ScheduleDefinition
from os import environ
import json


@op
def current_aqi(context) -> int:
    client = AirQualityAPIClient(environ["AQI_API_TOKEN"])
    aqi = client.fetch_aqi_in_latlng(*json.loads(environ["HOME_LOCATION"]))
    context.log.info(f"AQI Index: {aqi}")
    return aqi


@op
def air_purifier_control(context, current_aqi, threshold=40) -> None:
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


@job
def regulate_air_quality():
    air_purifier_control(current_aqi())


regulate_air_quality_schedule = ScheduleDefinition(
    job=regulate_air_quality, cron_schedule="*/1 * * * *"
)
