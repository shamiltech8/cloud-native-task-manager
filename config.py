import os

class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY") or "dev-secret-key"

    SQLALCHEMY_DATABASE_URI = os.environ.get(
        "DATABASE_URL",
        "postgresql://task_user:password@postgres/task_manager"
    )

    SQLALCHEMY_TRACK_MODIFICATIONS = False
