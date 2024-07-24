from flask import request, jsonify
from backend.models.secretModel import User, LocalVault, StoredPassword, db
from flask_jwt_extended import jwt_required, get_jwt_identity
import traceback

@jwt_required()
def add_password():
    try:
        data = request.get_json()
        title = data.get('title')
        username = data.get('username')
        password = data.get('password')

        # Get the current user's identity from the JWT token
        user_id = get_jwt_identity()
        user = User.query.get(user_id)

        if not user:
            return jsonify({"message": "User not found"}), 404

        # Check for missing fields
        if not title or not username or not password:
            return jsonify({"message": "Missing title, username, or password"}), 400

        # Ensure the user has a local vault
        local_vault = user.local_vault

        if not local_vault:
            return jsonify({"message": "Vault not found for user"}), 404

        # Create and store the new password
        new_password = StoredPassword(
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
        print(traceback.format_exc())  # Print the full traceback for debugging
        return jsonify({"message": "Error adding password", "error": str(e)}), 500
