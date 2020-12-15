from flask import jsonify


def return_error(error):
    return to_response(None, {"error": error})


def to_response(content, meta=None):
    print({"content": content, "meta": meta})
    return {"content": content, "meta": meta}
