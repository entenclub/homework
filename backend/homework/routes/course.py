from flask import Blueprint, jsonify, request, make_response
from ..database.user import User
from ..database.session import Session
from . import to_response, return_error
from .. import db

course_bp = Blueprint('course', __name__)
CORS(course_bp)

@course_bp.route('/course')