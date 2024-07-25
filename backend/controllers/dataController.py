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

        # Encrypt the password using the NFC session
        encrypted_password = nfc_module.encrypt(password)

        new_password = StoredPassword(
            title=title,
            username=username,
            password=encrypted_password,
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

        return jsonify(passwords=passwords_data), 200

    except Exception as e:
        print("Error fetching passwords:", str(e))
        return jsonify({"message": "Error fetching passwords", "error": str(e)}), 500
