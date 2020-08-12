from homework import db


class User(db.Model):
    id = db.Column('id', db.Integer, primary_key=True)
    username = db.Column('username', db.String(128),
                         unique=True, nullable=False)
    email = db.Column('email', db.String(255), unique=True, nullable=False)
    password_hash = db.Column('password_hash', db.String(187), nullable=False)
    courses = db.Column('courses', db.Text, nullable=False, default='[]')
    privilege = db.Column('privilege', db.Integer, default=0)

    def decode_courses(self):
        return json.loads(self.courses)

    def to_dict(self):
        return {"id": self.id, "username": self.username, "email": self.email, "courses": self.decode_courses(), "password_hash": self.password_hash,
                "privilege": self.privilege}

    def to_safe_dict(self):
        return {"id": self.id, "username": self.username, "email": self.email, "courses": self.decode_courses(),
                "privilege": self.privilege}
