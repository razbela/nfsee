from flask import Blueprint
from backend.controllers import dataController

data_bp = Blueprint('data_bp', __name__)

@data_bp.route('/data', methods=['GET'])
def get_data():
    return dataController.get_data()
