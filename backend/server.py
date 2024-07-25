import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager

db = SQLAlchemy()
bcrypt = Bcrypt()
jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    db_path = os.path.join(os.path.dirname(__file__), 'nfsee.db')
    app.config['SQLALCHEMY_DATABASE_URI'] = f'sqlite:///{db_path}'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = 'your_jwt_secret_key_here'
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
    app = create_app()
    app.run(debug=True)
