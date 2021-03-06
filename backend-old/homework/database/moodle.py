from homework import db
from datetime import datetime
from json import loads as json_loads


class MoodleCache(db.Model):
    __tablename__ = 'moodle_cache'

    id = db.Column('id', db.Integer, primary_key=True, nullable=False)
    course_id = db.Column('course_id', db.Integer, nullable=False)
    name = db.Column('name', db.Text, nullable=False)
    teacher = db.Column('teacher', db.Text, nullable=False)
    moodle_url = db.Column('moodle_url', db.Text, nullable=False)
    user_id = db.Column('user_id', db.Integer, nullable=False)
    cached_at = db.Column('cached_at', db.DateTime,
                          nullable=False, default=datetime.utcnow)
    assignments_json = db.Column(
        'assignments_json', db.Text, nullable=True, default='[]')

    def to_dict(self):
        return {"id": self.id, "courseId": self.course_id, "subject": "", "teacher": self.teacher,
                "fromMoodle": True, "name": self.name, "creator": self.user_id, "assignments": json_loads(self.assignments_json)}
