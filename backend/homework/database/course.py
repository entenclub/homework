from homework import db


class Course(db.Model):
    __tablename__ = 'courses'

    id = db.Column('id', db.Integer, primary_key=True, nullable=False)
    subject = db.Column('subject', db.String(32), nullable=False)
    teacher = db.Column('teacher', db.String(128), nullable=False)
    creator = db.Column('creator', db.Integer, nullable=False)

    def to_dict(self):
        return {"id": self.id, "subject": self.subject,
                "teacher": self.teacher, "fromMoodle": False}
