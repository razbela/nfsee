from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from backend.models.secretModel import User
from backend.server import bcrypt  # Import bcrypt from server.py

auth_bp = Blueprint('auth_bp', __name__)

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    
    user = User.query.filter_by(username=username).first()
    if user and bcrypt.check_password_hash(user.password, password):
        access_token = create_access_token(identity=user.id)  # Use user.id as the identity
        return jsonify(access_token=access_token), 200
    
    return jsonify({'message': 'Invalid credentials'}), 401
