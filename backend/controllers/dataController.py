from flask import jsonify

def get_data():
    return jsonify({"message": "This is protected data"}), 200
