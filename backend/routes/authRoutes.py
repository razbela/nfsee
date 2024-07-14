from flask import Blueprint, request, jsonify
from backend.controllers import authController

auth_bp = Blueprint('auth_bp', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    return authController.register()

@auth_bp.route('/login', methods=['POST'])
def login():
    return authController.login()
