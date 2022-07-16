from dagster import repository
from jobs import regulate_air_quality


@repository
def tjhome():
    return [
        regulate_air_quality,
    ]
