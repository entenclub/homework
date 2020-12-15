import requests
import eventlet
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
from homework import moodle

course_bp = Blueprint('course', __name__)
CORS(course_bp, supports_credentials=True)


def filter_course(course, searchterm):
    return searchterm in course.teacher or searchterm in course.subject


@course_bp.route('/courses/search/<searchterm>', methods=['GET'])
def search_courses(searchterm):
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid sesssion")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return jsonify(return_error("invalid session")), 401

    base_url = user.moodle_url
    token = user.moodle_token

    courses = Course.query.all()

    filtered_courses = filter(lambda course: filter_course(course, searchterm), courses)
    filtered_courses = [course.to_dict() for course in filtered_courses]

    if token is None or base_url is None:
        return to_response(filtered_courses)

    else:
        print("[ * ] getting something from moodle...")

        done = False
        try:
            with eventlet.Timeout(5):
                courses_reqest = requests.get(
                    base_url + '/webservice/rest/server.php' + '?wstoken=' + token + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + '&userid=412')
                done = True
        except eventlet.Timeout as t:
            print(f"[ - ] error connecting to {base_url}: timeout after {t}")
            return jsonify(return_error("error accessing moodle: timeout")), 408

        if not courses_reqest.ok or type(courses_reqest.json()) != list:
            return jsonify(to_response(filtered_courses, {'error': 'error accessing moodle'}))

        moodle_courses = courses_reqest.json()

        filtered_moodle_courses = filter(lambda course: (searchterm in course['fullname']),
                                         moodle_courses)

        filtered_moodle_courses = [{
            'id': course.get('id'),
            'fromMoodle': True,
            'name': course.get('displayname'),
            'subject': '',
            'teacher': '',
            'creator': user.id
        } for course in filtered_moodle_courses]

        return jsonify(to_response(filtered_courses + filtered_moodle_courses))


# active courses -> courses which have assignments due in the future
@course_bp.route('/courses/active', methods=['GET'])
def active_courses():
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

    has_outstanding_assignments = []
    now = datetime.datetime.utcnow().date()
    courses = []

    for course_id in course_ids:
        courses.append(Course.query.filter_by(id=course_id).first())

    for course in courses:
        assignments = [assignment.to_dict() for assignment in
                       Assignment.query.filter_by(course=course.id).all() if
                       assignment.due_date >= now]
        if not assignments:
            continue

        for i in range(len(assignments)):
            assignments[i]['dueDate'] = datetime.datetime.strftime(assignments[i]['dueDate'],
                                                                   '%Y-%m-%d')
            assignments[i]['creator'] = user.to_safe_dict()

        course_dict = course.to_dict()
        course_dict['assignments'] = assignments
        has_outstanding_assignments.append(course_dict)

    if user.moodle_token is None:
        return jsonify(to_response(has_outstanding_assignments))

    print(f"[ * ] accessing moodle at {user.moodle_url} ...")
    try:
        moodle_courses = moodle.get_user_courses(user)
    except eventlet.Timeout as t:
        print(f"[ - ] error accessing moodle: timeout after {t}")
        return jsonify(return_error("error accessing moodle: timeout")), 408

    if moodle_courses is None:
        return jsonify(to_response(has_outstanding_assignments))

    for m_course in moodle_courses:
        assignments = [assignment.to_dict() for assignment in
                       Assignment.query.filter(
                           Assignment.course == m_course['id'] and Assignment.from_moodle is True)
                       if
                       assignment.due_date >= now]
        if not assignments:
            continue

        # convert dates to iso
        for i in range(len(assignments)):
            assignments[i]['dueDate'] = datetime.datetime.strftime(assignments[i]['dueDate'],
                                                                   '%Y-%m-%d')
            assignment_creator = User.query.filter_by(id=assignments[i]['creator']).first()
            assignments[i]['creator'] = assignment_creator.to_safe_dict()

        course = {
            "id": m_course['id'],
            'name': m_course['displayname'],
            'creator': user.id,
            'assignments': assignments,
            'fromMoodle': True,
            'teacher': '',
            'subject': '',
        }

        has_outstanding_assignments.append(course)

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
        course = Course.query.filter_by(id=course_id).first()
        assignments = [assignment.to_dict() for assignment in
                       Assignment.query.filter_by(course=course_id).all()]

        for i in range(len(assignments)):
            assignments[i]['dueDate'] = datetime.datetime.strftime(assignments[i]['dueDate'],
                                                                   '%Y-%m-%d')
            creator = User.query.filter_by(id=assignments[i]['creator']).first()
            if creator is None:
                assignments.remove(assignments[i])
                i -= 1
                continue
            assignments[i]['creator'] = creator.to_safe_dict()

        course_dict = course.to_dict()
        course_dict['assignments'] = assignments
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
    new_course.creator = user.id

    db.session.add(new_course)

    try:
        db.session.commit()

    except Exception as e:
        print(e)
        db.session.rollback()
        return jsonify(return_error('invalid request')), 500

    user.set_courses((user.decode_courses() + [new_course.id]))
    db.session.add(user)
    db.session.commit()

    return jsonify(to_response(new_course.to_dict()))


@course_bp.route('/courses/<int:id>/enroll', methods=['POST'])
def enroll(id):
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid sesssion")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return jsonify(return_error("invalid session")), 401

    if Course.query.filter_by(id=id).first() is None:
        return jsonify(return_error("invalid course")), 400

    courses = user.decode_courses()
    courses.append(id)
    user.set_courses(courses)
    db.session.add(user)

    db.session.commit()

    return jsonify(to_response(user.to_safe_dict()))
