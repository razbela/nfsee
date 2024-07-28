import os
import hvac
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
from dotenv import load_dotenv

# Load environment variables from vault.env file
env_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'vault.env'))
load_dotenv(dotenv_path=env_path)

# Print to verify environment variables are loaded
print("VAULT_ADDR:", os.getenv('VAULT_ADDR'))
print("VAULT_TOKEN:", os.getenv('VAULT_TOKEN'))

# Configure HashiCorp Vault client
vault_client = hvac.Client(
    url=os.getenv('VAULT_ADDR'),  # Use the Vault address from the environment variable
    token=os.getenv('VAULT_TOKEN')  # Use the token from the environment variable
)

if not vault_client.is_authenticated():
    raise Exception("Vault authentication failed")

db = SQLAlchemy()
bcrypt = Bcrypt()
jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    db_path = os.path.join(os.path.dirname(__file__), 'nfsee.db')
    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = '3b6b7a4f4d374f4c506e5f525d5a70474d567870784255344352756f31657a42'
    app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
        'connect_args': {'timeout': 30}
    }

    db.init_app(app)
    bcrypt.init_app(app)
    jwt.init_app(app)

    @app.teardown_appcontext
    def shutdown_session(exception=None):
        db.session.remove()

    with app.app_context():
        from backend.routes.authRoutes import auth_bp
        from backend.routes.dataRoutes import data_bp
        app.register_blueprint(auth_bp)
        app.register_blueprint(data_bp)
        db.create_all()

    return app

if __name__ == "__main__":
    try:
        app = create_app()
        app.run(debug=True)
    except Exception as e:
        print(f"An error occurred: {e}")
