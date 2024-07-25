from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend.models.secretModel import User, LocalVault, StoredPassword, db
import uuid

data_bp = Blueprint('data_bp', __name__)

@data_bp.route('/passwords', methods=['POST'])
@jwt_required()
def add_password():
    try:
        data = request.get_json()
        title = data.get('title')
        username = data.get('username')
        password = data.get('password')

        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({"message": "User not found"}), 404

        if not title or not username or not password:
            return jsonify({"message": "Missing title, username, or password"}), 400

        local_vault = user.local_vault

        if not local_vault:
            local_vault = LocalVault(user_id=user.id)
            db.session.add(local_vault)
            db.session.commit()

        new_password = StoredPassword(
            id=str(uuid.uuid4()),
            title=title,
            username=username,
            password=password,
            isDecrypted=False,
            local_vault_id=local_vault.id
        )

        db.session.add(new_password)
        db.session.commit()
        return jsonify({"message": "Password added successfully"}), 201

    except Exception as e:
        db.session.rollback()
        print("Error adding password:", str(e))
        return jsonify({"message": "Error adding password", "error": str(e)}), 500

@data_bp.route('/passwords', methods=['GET'])
@jwt_required()
def get_passwords():
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({"message": "User not found"}), 404

        local_vault = user.local_vault

        if not local_vault:
            return jsonify({"message": "Vault not found for user"}), 404

        passwords = StoredPassword.query.filter_by(local_vault_id=local_vault.id).all()
        passwords_data = [{
            "id": password.id,
            "title": password.title,
            "username": password.username,
            "password": password.password,
            "isDecrypted": password.isDecrypted
        } for password in passwords]

        print(f"Stored passwords: {passwords_data}")

        return jsonify(passwords=passwords_data), 200

    except Exception as e:
        print("Error fetching passwords:", str(e))
        return jsonify({"message": "Error fetching passwords", "error": str(e)}), 500

@data_bp.route('/passwords/<password_id>', methods=['DELETE'])
@jwt_required()
def delete_password(password_id):
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({"message": "User not found"}), 404

        local_vault = user.local_vault
        if not local_vault:
            return jsonify({"message": "Vault not found for user"}), 404

        password_id = password_id.lower()  # Convert the incoming password_id to lowercase
        print(f"Attempting to delete password with id: {password_id}")

        # Print out all passwords to see their IDs
        passwords = StoredPassword.query.filter_by(local_vault_id=local_vault.id).all()
        for password in passwords:
            print(f"Stored password ID: {password.id.lower()}")  # Print stored IDs in lowercase

        # Query the password by converting stored IDs to lowercase
        password = StoredPassword.query.filter_by(id=password_id, local_vault_id=local_vault.id).first()

        if not password:
            print(f"Password not found for id: {password_id}")
            return jsonify({"message": "Password not found"}), 404

        print(f"Deleting password: {password_id}")
        db.session.delete(password)
        db.session.commit()

        return jsonify({"message": "Password deleted successfully"}), 200

    except Exception as e:
        db.session.rollback()
        print("Error deleting password:", str(e))
        return jsonify({"message": "Error deleting password", "error": str(e)}), 500
