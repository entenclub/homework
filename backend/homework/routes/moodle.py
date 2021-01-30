import datetime
import re

import requests
from flask import Blueprint, jsonify, request

from flask_cors import CORS

from homework.database.assignment import Assignment
from homework.database.session import Session
from homework.database.user import User
from homework.database.course import Course
from homework.routes import return_error, to_response
from homework import db, moodle

moodle_bp = Blueprint('moodle', __name__)
CORS(moodle_bp, supports_credentials=True)


@moodle_bp.route('/moodle/get-courses')
def get_courses():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error('no session')), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error('invalid session')), 401

    user = User.query.filter_by(id=session.user_id).first()
    if user is None:
        return jsonify(return_error('invalid session')), 401

    courses_raw = moodle.get_user_courses(user)
    courses = []
    for course in courses_raw:
        assignments = [assignment.to_dict() for assignment in
                       Assignment.query.filter(Assignment.course == course['id'] and Assignment.from_moodle).all()]

        # convert dates to iso
        for i in range(len(assignments)):
            assignments[i]['dueDate'] = datetime.datetime.strftime(assignments[i]['dueDate'],
                                                                   '%Y-%m-%d')

        print(course)

        course = {
            "id": course['id'],
            'name': course['name'],
            'creator': user.id,
            'assignments': assignments,
            'fromMoodle': True
        }

        courses.append(course)

    return jsonify(to_response(courses))


@moodle_bp.route('/moodle/authenticate', methods=['POST'])
def authenticate():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error('no session')), 401

    session = Session.query.filter_by(id=session_cookie).first()
    if session is None:
        return jsonify(return_error('invalid session')), 401

    user = User.query.filter_by(id=session.user_id).first()
    if user is None:
        return jsonify(return_error('invalid session')), 401

    base_url, username, password = request.json.get('url'), request.json.get(
        'username'), request.json.get('password')

    if username is None or password is None or base_url is None:
        return jsonify(return_error('missing credentials')), 400

    body = {'username': username, 'password': password}
    auth_request = requests.post(base_url + '/login/token.php?service=moodle_mobile_app', body)
    print(auth_request.json())

    if not auth_request.ok or auth_request.json().get('errorcode') is not None:
        return jsonify(return_error('invalid moodle credentials')), 401

    creds = auth_request.json()

    # get user id
    user_request = requests.post(base_url + '/webservice/rest/server.php?wstoken={}&wsfunction=core_user_get_users_by_field&field=username&values[0]={}&moodlewsrestformat=json'.format(creds['token'], username))

    print(user_request.text)

    user.moodle_url = base_url
    user.moodle_token = creds['token']
    user.moodle_user_id = user_request.json()[0]['id']

    db.session.add(user)
    db.session.commit()

    return jsonify(to_response(user.to_safe_dict()))


@moodle_bp.route('/moodle/get-school-info', methods=['POST'])
def get_school_info():
    school_url = request.json.get('url')
    if school_url is None:
        return jsonify(return_error('no url provided')), 400

    regex = re.compile(
        r'^(?:http|ftp)s?://'  # http:// or https://
        r'(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|'  # domain...
        r'localhost|'  # localhost...
        r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})'  # ...or ip
        r'(?::\d+)?'  # optional port
        r'(?:/?|[/?]\S+)$', re.IGNORECASE)

    if re.match(regex, school_url) is None:
        return jsonify(return_error('invalid url')), 400

    # magic
    url = school_url + "/lib/ajax/service-nologin.php?args=%5B%7B%22index%22%3A0,%22methodname%22%3A%22tool_mobile_get_public_config%22,%22args%22%3A%5B%5D%7D%5D"

    try:
        r = requests.get(url)
    except Exception as e:
        print('[ - ] error retrieving school info: {}'.format(type(e)))
        return jsonify(return_error('invalid url')), 400

    if not r.ok:
        return jsonify(return_error('server error')), 500

    try:
        data = r.json()[0]['data']
    except KeyError:
        return jsonify(return_error('moodle error')), 500

    return jsonify(to_response(data))
