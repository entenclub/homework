from flask import Blueprint, jsonify, request, make_response
from ..database.user import User
from ..database.session import Session
from ..database.course import Course
from ..database.assignment import Assignment
from . import to_response, return_error
from flask_cors import CORS
from .. import db
from random import sample
import datetime

course_bp = Blueprint('course', __name__)
CORS(course_bp, supports_credentials=True)

@course_bp.route('/courses/search/<searchterm>', methods=['GET'])
def search_courses(searchterm):
    courses_by_teacher = Course.query.filter(Course.teacher.ilike(f"%{searchterm}%")).all()
    courses_by_subject = Course.query.filter(Course.subject.ilike(f"%{searchterm}%")).all()

    joined_courses = courses_by_subject + courses_by_teacher

    courses_raw = list(dict.fromkeys(sample(joined_courses, len(joined_courses))))
    print(courses_raw)

    courses = [course.to_dict() for course in courses_raw]
    return to_response(courses)
@course_bp.route('/courses/active', methods=['GET'])
def outstanding_assignments():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid sesssion")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return jsonify(return_error("invalid session")), 401

    course_ids = user.decode_courses()
    if not course_ids:
        return jsonify(to_response([])), 200

    has_outstanding_assignments = []
    now = datetime.datetime.utcnow().timetuple()[:3]
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

@course_bp.route('/courses', methods=['GET'])
def my_courses():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid sesssion")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return jsonify(return_error("invalid session")), 401

    course_ids = user.decode_courses()
    if not course_ids:
        return jsonify(to_response([])), 200

    now = datetime.datetime.utcnow().timetuple()[:3]

    courses = []
    for course_id in course_ids:
        assignments = [assignment for assignment in Assignment.query.filter_by(course=course_id).all() if assignment.due_date >= now]
        course_dict = course_id.to_dict()
        course_ids['assignments'] = assignments
        courses.append(course_dict)


    return jsonify(to_response(courses))

@course_bp.route('/courses', methods=['POST'])
def create_course():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid sesssion")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return jsonify(return_error("invalid session")), 401

    data = request.json
    teacher, subject = data.get('teacher'), data.get('subject')

    if teacher is None or subject is None:
        return jsonify(return_error('invalid request')), 400

    new_course = Course()
    new_course.subject = subject
    new_course.teacher = teacher

    db.session.add(new_course)

    try:
        db.session.commit()

    except Exception as e:
        print(e)
        db.session.rollback()
        return jsonify(return_error('invalid request')), 500

    return jsonify(to_response(new_course.to_dict()))


