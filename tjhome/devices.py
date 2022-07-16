from tuya_iot import TuyaOpenAPI
from dataclasses import dataclass


class Device:
    """Generic class that encapsulates all smart home devices"""


class AirPurifier(Device):
    """Air Purifiers purify the air and protect the home from pollution."""


@dataclass
class TuyaAirPurifier(AirPurifier):
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
