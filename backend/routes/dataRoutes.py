from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend.models.secretModel import User, LocalVault, StoredPassword, db
from backend.server import vault_client
import uuid

data_bp = Blueprint('data_bp', __name__)

@data_bp.route('/passwords', methods=['POST'])
@jwt_required()
def add_password():
    try:
        data = request.get_json()
        password_id = data.get('id')  # Get the UUID from the client
        title = data.get('title')
        username = data.get('username')
        password = data.get('password')

        if not password_id or not title or not username or not password:
            return jsonify({"message": "Missing id, title, username, or password"}), 400

        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({"message": "User not found"}), 404

        local_vault = user.local_vault
        if not local_vault:
            local_vault = LocalVault(user_id=user.id)
            db.session.add(local_vault)
            db.session.commit()

        new_password = StoredPassword(
            id=password_id.lower(),
            title=title,
            username=username,
            password=password,
            isDecrypted=False,
            local_vault_id=local_vault.id
        )

        db.session.add(new_password)
        db.session.commit()

        print(f"New password added with ID: {new_password.id}")

        # Store the password in HashiCorp Vault
        try:
            vault_client.secrets.kv.v2.create_or_update_secret(
                path=f'passwords/{new_password.id}',
                secret={
                    'title': title,
                    'username': username,
                    'password': password
                }
            )
            print(f"Password stored in Vault with id: {new_password.id}")
        except Exception as e:
            print(f"Error storing password in Vault: {str(e)}")

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
            "id": password.id.lower(),
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

@data_bp.route('/passwords/<password_id>', methods=['GET'])
@jwt_required()
def get_password(password_id):
    try:
        print(f"Fetching password with ID: {password_id}")  # Log the incoming ID
        user_id = get_jwt_identity()
        print(f"User ID: {user_id}")  # Log the user ID

        user = User.query.get(user_id)
        if not user:
            return jsonify({"message": "User not found"}), 404

        local_vault = user.local_vault
        if not local_vault:
            return jsonify({"message": "Vault not found for user"}), 404

        password = StoredPassword.query.filter_by(id=password_id.lower(), local_vault_id=local_vault.id).first()

        if not password:
            print(f"Password with ID {password_id} not found")  # Log if password not found
            return jsonify({"message": "Password not found"}), 404

        password_data = {
            "id": password.id.lower(),
            "title": password.title,
            "username": password.username,
            "password": password.password,
            "isDecrypted": password.isDecrypted
        }

        print(f"Returning password data: {password_data}")
        return jsonify(password=password_data), 200

    except Exception as e:
        print("Error fetching password:", str(e))
        return jsonify({"message": "Error fetching password", "error": str(e)}), 500

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

        password_id = password_id.lower()
        print(f"Attempting to delete password with id: {password_id}")

        # Print out all passwords to see their IDs
        passwords = StoredPassword.query.filter_by(local_vault_id=local_vault.id).all()
        for password in passwords:
            print(f"Stored password ID: {password.id.lower()}")

        # Query the password by converting stored IDs to lowercase
        password = StoredPassword.query.filter_by(id=password_id, local_vault_id=local_vault.id).first()

        if not password:
            print(f"Password not found for id: {password_id}")
            return jsonify({"message": "Password not found"}), 404

        print(f"Deleting password: {password_id}")
        db.session.delete(password)
        db.session.commit()

        # Remove the password from HashiCorp Vault
        try:
            vault_client.secrets.kv.v2.delete_metadata_and_all_versions(path=f'passwords/{password.id}')
            print(f"Password deleted from Vault with id: {password.id}")
        except Exception as e:
            print(f"Error deleting password from Vault: {str(e)}")

        return jsonify({"message": "Password deleted successfully"}), 200

    except Exception as e:
        db.session.rollback()
        print("Error deleting password:", str(e))
        return jsonify({"message": "Error deleting password", "error": str(e)}), 500
