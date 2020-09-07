from flask_api import FlaskAPI
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy

from flask_script import Manager
from flask_migrate import Migrate, MigrateCommand

app = FlaskAPI(__name__)
app.config.from_object('config')
CORS(app, supports_credentials=True)


# sqlalchemy
app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql://postgres:postgres@localhost:5432/postgres'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

migrate = Migrate(app, db)
manager = Manager(app)

manager.add_command('db', MigrateCommand)

# blueprints
from .routes.user import user_bp
from .routes.assignment import assignment_bp
from .routes.course import course_bp
from .routes.moodle import moodle_bp
from .routes.analytics import analytics_bp
app.register_blueprint(user_bp)
app.register_blueprint(assignment_bp)
app.register_blueprint(course_bp)
app.register_blueprint(moodle_bp)
app.register_blueprint(analytics_bp)
