from homework import db
from datetime import datetime


class Assignment(db.Model):
    __tablename__ = 'assignments'
    id = db.Column('id', db.Integer, primary_key=True, nullable=False)
    course = db.Column('course', db.Integer, nullable=False)
    title = db.Column('title', db.Text, nullable=False)
    description = db.Column('description', db.Text, nullable=True)
    due_date = db.Column('due_date', db.Date, nullable=False)
    creator = db.Column('creator', db.Integer, nullable=False)
    created_at = db.Column('created_at', db.DateTime,
                           nullable=False, default=datetime.utcnow)
    from_moodle = db.Column('from_moodle', db.Boolean, default=False)

    def to_dict(self):
        return {'id': self.id, 'course': self.course, 'title': self.title,
                'description': self.description, 'dueDate': self.due_date, 'creator': self.creator,
                'createdAt': self.created_at, 'fromMoodle': self.from_moodle}
