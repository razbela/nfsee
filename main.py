import sys
import os

# Set the path to include the backend directory
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), 'backend')))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__))))

from backend.server import create_app
from config import Config  

app = create_app()

if __name__ == '__main__':
    try:
        ipAddress = Config().serverIPAddress
        port = Config().serverPort
        app.run(debug=True, host='0.0.0.0', port=port)
    except RuntimeError as e:
        print(f"Failed to start the server: {e}")
