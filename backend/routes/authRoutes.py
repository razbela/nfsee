from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token, get_jwt_identity, jwt_required
from sqlalchemy import func
from backend.models.secretModel import User, LocalVault, StoredPassword, db
from backend.server import bcrypt

auth_bp = Blueprint('auth_bp', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        print(f"Incoming data: {data}")

        username = data.get('username')
        password = data.get('password')
        nfc_uid = data.get('nfc_uid')

        if not username or not password or not nfc_uid:
            return jsonify({'message': 'Username, password, and NFC UID are required'}), 400

        # Check if the user already exists
        existing_user = User.query.filter(func.lower(User.username) == func.lower(username)).first()
        if existing_user:
            return jsonify({'message': 'User already exists'}), 409

         Check if the NFC UID already exists
         existing_nfc_uid = User.query.filter_by(nfc_uid=nfc_uid).first()
         if existing_nfc_uid:
            return jsonify({'message': 'NFC UID already exists'}), 409

        # Hash the password and create a new user
        hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
        new_user = User(username=username, password=hashed_password, nfc_uid=nfc_uid)
        db.session.add(new_user)
        db.session.flush()  # Ensure new_user.id is available
        print(f"New user created: {new_user.id}")

        # Create a LocalVault for the new user
        new_vault = LocalVault(user_id=new_user.id)
        db.session.add(new_vault)
        db.session.commit()
        print(f"LocalVault created for user: {new_user.id}")

        access_token = create_access_token(identity=new_user.id)
        return jsonify(access_token=access_token), 201

    except Exception as e:
        db.session.rollback()
        print(f"Error occurred: {str(e)}")
        return jsonify({'message': 'An error occurred', 'error': str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        username = data.get('username')
        password = data.get('password')
        
        user = User.query.filter(func.lower(User.username) == func.lower(username)).first()
        if user and bcrypt.check_password_hash(user.password, password):
            access_token = create_access_token(identity=user.id)  # Use user.id as the identity
            
            # Load the passwords from the user's local vault
            local_vault = user.local_vault
            if local_vault:
                passwords = StoredPassword.query.filter_by(local_vault_id=local_vault.id).all()
                passwords_data = [{
                    "id": pw.id,
                    "title": pw.title,
                    "username": pw.username,
                    "password": pw.password,
                    "isDecrypted": pw.isDecrypted
                } for pw in passwords]
            else:
                passwords_data = []

            response = {
                "access_token": access_token,
                "passwords": passwords_data
            }

            return jsonify(response), 200
        
        return jsonify({'message': 'Invalid credentials'}), 401
    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return jsonify({'message': 'An error occurred', 'error': str(e)}), 500
