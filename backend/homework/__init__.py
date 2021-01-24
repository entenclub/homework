from flask_api import FlaskAPI
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv
import os
from os.path import join, dirname
import eventlet
import config

eventlet.monkey_patch()


app = FlaskAPI(__name__)

app.config.from_object('config')
CORS(app, supports_credentials=True)

# FIXME: remove in production
app.config['DEBUG'] = True

dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

# sqlalchemy
db_string = f'postgresql://homework:{os.getenv("DBPASSWORD")}@db:5432/homework'
app.config['SQLALCHEMY_DATABASE_URI'] = db_string
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

# blueprints
from .routes.user import user_bp
from .routes.assignment import assignment_bp
from .routes.course import course_bp
from .routes.moodle import moodle_bp
app.register_blueprint(user_bp)
app.register_blueprint(assignment_bp)
app.register_blueprint(course_bp)
app.register_blueprint(moodle_bp)

# initialize database
db.create_all()
db.session.commit()
