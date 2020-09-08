import datetime

from homework import db
import json


class User(db.Model):
    __tablename__ = 'users'
    id = db.Column('id', db.Integer, primary_key=True)
    username = db.Column('username', db.String(128),
                         unique=True, nullable=False)
    email = db.Column('email', db.String(255), unique=True, nullable=False)
    password_hash = db.Column('password_hash', db.String(187), nullable=False)
    courses = db.Column('courses', db.Text, nullable=False, default='[]')
    privilege = db.Column('privilege', db.Integer, default=0)
    moodle_url = db.Column('moodle_url', db.String(255), nullable=True)
    moodle_token = db.Column('moodle_token', db.String(255), nullable=True)
    moodle_user_id = db.Column('moodle_user_id', db.Integer, nullable=True)
    joined_at = db.Column('joined_at', db.DateTime, default=datetime.datetime.now, nullable=False)

    def decode_courses(self):
        return json.loads(self.courses)

    def set_courses(self, courses):
        self.courses = json.dumps(courses)

    def to_dict(self):
        return {"id": self.id, "username": self.username, "email": self.email,
                "courses": self.decode_courses(), "passwordHash": self.password_hash,
                "privilege": self.privilege, 'moodleUrl': self.moodle_url,
                'moodleToken': self.moodle_token, 'moodleUserId': self.moodle_user_id}

    def to_safe_dict(self):
        if self.moodle_url is None:
            moodle_url = ''
        else:
            moodle_url = self.moodle_url
        return {"id": self.id, "username": self.username, "email": self.email,
                "courses": self.decode_courses(),
                "privilege": self.privilege, 'moodleUrl': moodle_url}
