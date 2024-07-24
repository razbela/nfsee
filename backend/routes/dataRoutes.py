from flask import Blueprint
from backend.controllers import dataController
from flask_jwt_extended import jwt_required

data_bp = Blueprint('data_bp', __name__)

@data_bp.route('/passwords', methods=['POST'])
@jwt_required()
def add_password():
    return dataController.add_password()

@data_bp.route('/passwords', methods=['GET'])
@jwt_required()
def get_passwords():
    return dataController.get_passwords()
