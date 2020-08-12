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

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid sesssion")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        print(e)
        return jsonify(return_error("invalid session")), 401

    course_ids = user.decode_courses()
    if not course_ids:
        return jsonify(to_response([])), 200

    has_outstanding_assignments = []
    now = datetime.datetime.utcnow().timetuple()[:3]
    print(now)
    courses = []

    for course_id in course_ids:
        courses.append(Course.filter_by(id=course_id).first())

    for course in course_ids:
        assignments = [assignment for assignment in Assignment.query.filter_by(course=course_id).all() if assignment.due_date >= now]

        course_dict = course.to_dict()
        course_dict['assignments'] = assignments
        has_outstanding_assignments.append(course_dict)

    print(to_response(has_outstanding_assignments))
    return jsonify(to_response(has_outstanding_assignments))