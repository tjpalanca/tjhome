from dagster import repository
from tjhome.jobs import regulate_air_quality, regulate_air_quality_schedule


@repository
def tjhome():
    return [regulate_air_quality, regulate_air_quality_schedule]
