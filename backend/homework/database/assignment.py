from homework import db
from datetime import datetime

class Assignment(db.Model):
    __tablename__ = 'assignments'
    id = db.Column('id', db.Integer, primary_key=True, nullable=False)
    course = db.Column('course', db.Integer, nullable=False)
    title = db.Column('title', db.Text, nullable=False)
    description = db.Column('description', db.Text, nullable=True)
    creator = db.Column('creator', db.Integer, nullable=False)
    created_at = db.Column('created_at', db.Float, nullable=False, default=datetime.utcnow)