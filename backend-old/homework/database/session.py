from homework import db

import uuid
from datetime import datetime
from sqlalchemy.dialects.postgresql import UUID


class Session(db.Model):
    __tablename__ = 'sessions'

    id = db.Column('id', UUID(as_uuid=True), primary_key=True,
                   default=uuid.uuid4, nullable=False)
    user_id = db.Column('user_id', db.Integer, nullable=False)
    created_at = db.Column('created_at', db.DateTime,
                           default=datetime.utcnow, nullable=False)
