from homework import db


class Class(db.Model):
    __tablename__ = 'classes'

    id = db.Column('id', db.Integer, primary_key=True, nullable=False)
    subject = db.Column('subject', db.String(32), nullable=False)
    teacher = db.Column('teacher', db.String(128), nullable=False)
    name = db.Column('name', db.String(128))

    def to_dict(self):
        return {"id": self.id, "subject": self.subject,
                "teacher": self.teacher, "name": self.name}
