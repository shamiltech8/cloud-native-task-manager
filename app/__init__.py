import os
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_wtf.csrf import CSRFProtect

# Load the project's local .env without overriding existing environment variables.
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env", override=False)

db = SQLAlchemy()
csrf = CSRFProtect()


def create_app():
    app = Flask(__name__)

    app.config.from_object("config.Config")

    # Enable CSRF protection for state-changing requests.
    csrf.init_app(app)

    db.init_app(app)

    # Import models so SQLAlchemy knows about them.
    from app.models import User  # noqa: F401

    # Register the application routes.
    from app.routes import main
    app.register_blueprint(main)

    # Register Prometheus metrics.
    from app.metrics import register_metrics
    register_metrics(app)

    return app
