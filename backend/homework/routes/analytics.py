from flask import Blueprint, request, jsonify

from homework.database.assignment import Assignment
from homework.database.course import Course
from homework.database.session import Session
from homework.database.user import User
from homework.routes import return_error, to_response
from homework import moodle

analytics_bp = Blueprint('analytics', __name__)


@analytics_bp.route('/analytics/courses')
def courses():
    to_tuples = request.args.get('tuples')

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

    courses = []
    for course_id in course_ids:
        course = Course.query.filter_by(id=course_id, from_moodle=False).first()
        if course is None:
            continue
        courses.append(course)

    """
    {
        <course-name>: <number of assignments>
    }
    """
    data = {}
    for course in course_ids:
        assignments = Assignment.query.filter_by(course=course.id).all()

        name = f'{course.teacher}: {course.subject}'
        if data.get(name) is not None:
            data[name] += len(assignments)

        else:
            data[name] = len(assignments)

    if user.moodle_token is None:
        return jsonify(to_response(data))

    moodle_courses = moodle.get_user_courses(user)
    if moodle_courses is None:
        return jsonify(to_response(data))

    for m_course in moodle_courses:
        assignments = Assignment.query.filter_by(course=m_course['id'], from_moodle=True).all()

        print(len(assignments))

        if len(assignments) > 0:
            if data.get(m_course['displayname']) is not None:
                data[m_course['displayname']] += len(assignments)
            else:
                data[m_course['displayname']] = len(assignments)

    print(data)

    if to_tuples is not None:
        return jsonify(to_response([(k, v) for k, v in data.items()]))
    else:
        return jsonify(to_response(data))
