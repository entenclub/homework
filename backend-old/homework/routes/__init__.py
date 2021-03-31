from flask import jsonify


def return_error(error):
    return to_response(None, [error])


def to_response(content, errors=[]):
    return {"content": content, "errors": errors}
