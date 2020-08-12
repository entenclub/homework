from flask import Blueprint, jsonify, request, make_response
from ..database.user import User
from ..database.session import Session
from ..database.course import Course
from . import to_response, return_error
from flask_cors import CORS
from .. import db

course_bp = Blueprint('course', __name__)
CORS(course_bp, supports_credentials=True)

@course_bp.route('/courses/search/<searchterm>', methods=['GET'])
def search_courses(searchterm):
    courses_raw = Course.query.filter(Course.teacher.ilike(f"%{searchterm}%")).all()

    courses = [course.to_dict() for course in courses_raw]
    return to_response(courses)
