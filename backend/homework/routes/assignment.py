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

@assignment_bp.route('/assignments/outstanding', methods=['GET'])
def outstanding_assignments():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    try:
        session = Session.query.filter_by(id=session_cookie).first
    except Exception as e:
        print(e)
        return jsonify(return_error("invalid sesssion")), 401

    try:
        user = User.query.filter_by(id=session.user_id).first()

    except Exception as e:
        print(e)
        return jsonify(return_error("invalid session")), 401

    courses_raw = user.decode_courses()
    if not courses:
        return jsonify(to_response([])), 200

    has_outstanding_assignments = []
    now = datetime.datetime.utcnow().timetuple()[:3]
    print(now)
    for course in courses:
        assignments = [assignment for assignment in Assignment.query.filter_by(course=course.id).all() if assignment.due_date >= now]

        course_dict = course.to_dict()
        course_dict['assignments'] = assignments
        has_outstanding_assignments.append(course_dict)

    return jsonify(to_response(has_outstanding_assignments))