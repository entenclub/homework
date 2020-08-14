from flask import Blueprint, jsonify, request, make_response
from ..database.user import User
from ..database.session import Session
from . import to_response, return_error
from .. import db
from flask_cors import CORS

assignment_bp = Blueprint('assignment', __name__)
CORS(assignment_bp, supports_credentials=True)

"""
/assignments/outstanding - get outstanding assignments of courses user is enrolled in
"""

