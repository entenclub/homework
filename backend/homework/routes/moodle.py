import requests
from flask import Blueprint, jsonify, request

from flask_cors import CORS

from homework.database.session import Session
from homework.database.user import User
from homework.routes import return_error, to_response
from homework import db

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

    base_url = user.moodle_url
    token = user.moodle_token

    if token is None or base_url is None:
        return jsonify(return_error('no moodle connection')), 403

    """
    $ curl "https://your.site.com/moodle/webservice/rest/server.php?wstoken=...&wsfunction=...&moodlewsrestformat=json"
    """

    courses_reqest = requests.get(base_url + '/webservice/rest/server.php' + '?wstoken=' + token + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + '&userid=412')

    courses = courses_reqest.json()
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


    base_url, username, password = request.json.get('baseUrl'), request.json.get('username'), request.json.get('password')

    if username is None or password is None or base_url is None:
        return jsonify(return_error('missing credentials')), 400

    body = {'username': username, 'password': password}
    auth_request = requests.post(base_url + '/login/token.php?service=moodle_mobile_app', body)
    print(auth_request.json())

    if not auth_request.ok or auth_request.json().get('errorcode') is not None:
        return jsonify(return_error('invalid moodle credentials')), 401

    creds = auth_request.json()

    user.moodle_url = base_url
    user.moodle_token = creds['token']

    db.session.add(user)
    db.session.commit()

    return jsonify(to_response(user.to_safe_dict()))
