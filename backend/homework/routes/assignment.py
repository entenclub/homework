from flask import Blueprint, jsonify, request, make_response

from ..database.assignment import Assignment
from ..database.user import User
from ..database.session import Session
from . import to_response, return_error
from .. import db
from flask_cors import CORS
from datetime import datetime

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

    db.delete(User.query.filter_by(id=user.id))

    try:
        db.session.commit()
    except Exception as e:
        print(e)
        return jsonify(return_error('server error')), 500

    return jsonify(to_response(assignment)), 200