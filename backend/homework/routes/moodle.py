import requests
from flask import Blueprint, jsonify, request

from flask_cors import CORS

from homework.database.session import Session
from homework.database.user import User
from homework.routes import return_error, to_response

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

    base_url = 'https://gym-haan.lms.schulon.org'

    username, password = 'id4009', 'g0z89u1baISbAz4VAbUH2RKFL6JAZPdSIqft0GCAtd3G9YhWBMOPTwF1IOizV8XQ#'

    body = {'username': username, 'password': password}

    auth_request = requests.post(base_url + '/login/token.php?service=moodle_mobile_app', body)
    # print(r.status_code, r.text)

    if not auth_request.ok:
        return jsonify(return_error('invalid moodle credentials')), 403

    creds = auth_request.json()
    # print(creds)

    """
    $ curl "https://your.site.com/moodle/webservice/rest/server.php?wstoken=...&wsfunction=...&moodlewsrestformat=json"
    """

    courses_reqest = requests.get(base_url + '/webservice/rest/server.php' + '?wstoken=' + creds[
        'token'] + '&wsfunction=' + 'core_enrol_get_users_courses' + '&moodlewsrestformat=json' + '&userid=412')

    courses = courses_reqest.json()
    return to_response(courses)
