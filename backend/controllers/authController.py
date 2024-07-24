from flask import request, jsonify
from backend.models.secretModel import User, LocalVault, db
from backend.server import bcrypt  # Import bcrypt from your server initialization
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity

def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    nfc_uid = data.get('nfc_uid')
    
    if not username or not password or not nfc_uid:
        return jsonify({"message": "Missing username, password, or NFC UID"}), 400
    
    hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')
    new_user = User(username=username, password=hashed_password, nfc_uid=nfc_uid)
    
    try:
        db.session.add(new_user)
        db.session.flush()  # This gets the new_user.id before commit

        new_vault = LocalVault(user_id=new_user.id)
        db.session.add(new_vault)
        db.session.commit()
        
        return jsonify({"message": "User registered successfully"}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"message": "Error registering user", "error": str(e)}), 500

def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    
    if not username or not password:
        return jsonify({"message": "Missing username or password"}), 400
    
    user = User.query.filter_by(username=username).first()
    
    if user and bcrypt.check_password_hash(user.password, password):
        access_token = create_access_token(identity=user.id)
        return jsonify({"message": "Login successful", "access_token": access_token}), 200
    else:
        return jsonify({"message": "Invalid username or password"}), 401
