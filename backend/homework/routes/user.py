from flask import Blueprint, jsonify
from ..database.user import User
from ..database.session import Session
from . import to_response, return_error

user_bp = Blueprint('authentication', __name__)


# @user_bp.route('/user')
# def user():
#     session_id = request.cookies.get('hw_session')
#     if not session_id:
#         return jsonify({"content": None, "meta": {"error": "no session"}}), 401
#
#     session = Session.query
#

@user_bp.route('/username-taken/<username>')
def username_taken(username):
    return jsonify(to_response(len(User.query.filter_by(username=username).all()) > 0))
