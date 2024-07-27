import json
import os

class Config:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(Config, cls).__new__(cls)
            cls._instance.load_config()
        return cls._instance

    def load_config(self):
        config_path = os.path.join(os.path.dirname(__file__), 'models', 'config.json')
        try:
            with open(config_path, 'r') as file:
                config_data = json.load(file)
                self.server_ip_address = config_data['serverIPAddress']
                self.server_port = int(config_data['serverPort'])
        except (FileNotFoundError, KeyError, json.JSONDecodeError) as e:
            raise RuntimeError(f"Configuration error: {e}")

    @property
    def serverIPAddress(self):
        return self.server_ip_address

    @property
    def serverPort(self):
        return self.server_port
