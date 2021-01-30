import json
from re import search
from flask import Blueprint, jsonify, request, make_response

from ..database.assignment import Assignment
from ..database.user import User
from ..database.session import Session
from . import to_response, return_error
from .. import db
from flask_cors import CORS
from datetime import datetime
from homework.moodle import get_user_courses as m_get_user_courses

assignment_bp = Blueprint('assignment', __name__)
CORS(assignment_bp, supports_credentials=True)


@assignment_bp.route('/assignment', methods=['POST'])
def create_assignment():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid session")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return jsonify(return_error("invalid session")), 401

    data = request.json
    if not data:
        return jsonify(return_error('invalid request')), 400

    print("(routes/assignment.py):", data)

    title, raw_date, course, from_moodle = data.get('title'), data.get('dueDate'), data.get(
        'course'), data.get('fromMoodle')

    if title is None or raw_date is None or course is None:
        return jsonify(return_error('invalid request')), 400

    date = datetime.strptime(raw_date, '%d-%m-%Y')

    new_assignment = Assignment()
    new_assignment.title = title
    new_assignment.creator = user.id
    new_assignment.course = course
    new_assignment.due_date = date.date()

    if from_moodle is not None:
        new_assignment.from_moodle = from_moodle

    db.session.add(new_assignment)
    try:
        db.session.commit()
    except Exception as e:
        print(e)
        return jsonify(return_error('server error')), 500

    assignment_dict = new_assignment.to_dict()
    assignment_dict['creator'] = user.to_safe_dict()
    assignment_dict['dueDate'] = datetime.strftime(assignment_dict['dueDate'],
                                                   '%Y-%m-%d')

    return jsonify(to_response(assignment_dict))


@assignment_bp.route('/assignment', methods=['DELETE'])
def delete_assignment():
    assignment_id_str = request.args.get('id')
    if assignment_id_str is None:
        return jsonify(return_error("invalid request: missing parameter 'id'"), 400)

    try:
        assignment_id = int(assignment_id_str)
    except:
        return jsonify(return_error("invalid request: invalid format for parameter 'id'"), 400)

    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid session")), 401

    user = User.query.filter_by(id=session.user_id).first()

    if user is None:
        return jsonify(return_error("invalid session")), 401

    assignment = Assignment.query.filter_by(id=int(assignment_id)).first()
    if assignment is None:
        return jsonify(return_error("requested entry not found"), 404)

    if assignment.creator != user.id:
        return jsonify(return_error("permission denied", 403))

    db.session.delete(assignment)

    try:
        db.session.commit()
    except Exception as e:
        print(e)
        return jsonify(return_error('server error')), 500

    assignment_dict = assignment.to_dict()
    assignment_dict['creator'] = user.to_safe_dict()
    assignment_dict['dueDate'] = datetime.strftime(assignment_dict['dueDate'],
                                                   '%Y-%m-%d')

    return jsonify(to_response(assignment_dict)), 200


@assignment_bp.route('/assignment/auto-complete', methods=['GET'])
def autocomplete():
    searchterm = request.args.get('searchterm')
    if not searchterm:
        return jsonify(return_error("no searchterm")), 400

    searchterm = searchterm.lower()

    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error("invalid sesssion")), 401

    user = User.query.filter_by(id=session.user_id).first()
    if user is None:
        return jsonify(return_error("invalid session")), 401

    m_course_id = request.args.get('course')

    courses_with_assignments = m_get_user_courses(user, get_assignments=True)

    if m_course_id:
        course = filter(lambda course: (
            course['id'] == m_course_id), courses_with_assignments)[0]

        assignments = filter(lambda a: (
            a['name'].lower() in searchterm or searchterm in a['name'].lower()), course['assignments'])

        return jsonify(to_response(assignments))

    all_assignments = []
    for c in courses_with_assignments:
        assignments = filter(lambda a: (
            a['name'].lower() in searchterm or searchterm in a['name'].lower()), c['assignments'])

        if assignments:
            c['assignments'] = assignments
            all_assignments.append(c)

    return jsonify(to_response(all_assignments))
