from flask import Blueprint, jsonify, request, make_response, Response
from ..database.user import User
from ..database.session import Session
from . import to_response, return_error
from .. import db
import bcrypt
from flask_cors import CORS

user_bp = Blueprint('authentication', __name__)
CORS(user_bp, supports_credentials=True)


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


@user_bp.route('/user/login', methods=["POST"])
def login():
    data = request.json
    if not data:
        return jsonify(return_error("missing credentials")), 400

    username, password = data.get('username'), data.get('password')
    if username is None or password is None:
        return jsonify(return_error("missing credentials")), 400

    user = User.query.filter_by(username=username).first()
    if user is None:
        return jsonify(return_error("invalid username")), 401

    correct = bcrypt.checkpw(
        password.encode('utf-8'), user.password_hash.encode('utf-8'))
    if not correct:
        return jsonify(return_error("incorrect password")), 401

    new_session = Session()
    new_session.user_id = user.id
    db.session.add(new_session)
    db.session.commit()

    resp = make_response(jsonify(to_response(user.to_safe_dict())))
    resp.set_cookie('hw_session', str(new_session.id),
                    max_age=60 * 60 * 24 * 183)

    return resp, 200


@user_bp.route('/user/<int:id>')
def user_by_id(id):
    user = User.query.filter_by(id=id).first()
    if user:
        return jsonify(to_response(user.to_safe_dict()))
    else:
        return jsonify(return_error("user not found")), 404


@user_bp.route('/user')
def user_by_session():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    try:
        session = Session.query.filter_by(id=session_cookie).first()

    except Exception as e:
        print(e)
        return jsonify(return_error("invalid sesssion")), 401

    try:
        user = User.query.filter_by(id=session.user_id).first()

    except Exception as e:
        print(e)
        return jsonify(return_error("invalid session")), 401

    return jsonify(to_response(user.to_safe_dict())), 200


@user_bp.route('/user/register', methods=['POST'])
def register():
    data = request.json

    username, password, email = data.get(
        'username'), data.get('password'), data.get('email')
    if not username or not password or not email:
        return jsonify(return_error("missing credentials")), 400

    new_user = User()
    new_user.username = username
    new_user.email = email

    password_hash = bcrypt.hashpw(password.encode(
        'utf-8'), bcrypt.gensalt()).decode('utf-8')
    new_user.password_hash = password_hash

    db.session.add(new_user)
    db.session.commit()

    new_session = Session()
    new_session.user_id = new_user.id
    db.session.add(new_session)
    db.session.commit()


    resp = make_response(jsonify(to_response(new_user.to_safe_dict())))
    resp.set_cookie('hw_session', str(new_session.id),
                    max_age=60 * 60 * 24 * 183)

    return resp, 200


@user_bp.route('/user/logout', methods=['POST'])
def logout():
    session_cookie = request.cookies.get('hw_session')
    if not session_cookie:
        return jsonify(return_error("no session")), 401

    try:
        Session.query.filter_by(id=session_cookie).delete()

    except Exception as e:
        print(e)
        return jsonify(return_error("invalid sesssion")), 401

    return jsonify(to_response(None)), 200
