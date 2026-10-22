import os
from urllib.parse import quote_plus


class Config:
    SECRET_KEY = os.environ.get("SECRET_KEY")
    if not SECRET_KEY:
        raise RuntimeError("SECRET_KEY environment variable is required.")

    DB_USER = os.environ.get("DB_USER")
    DB_PASSWORD = os.environ.get("DB_PASSWORD")

    DATABASE_URL = os.environ.get("DATABASE_URL")

    if DB_USER is not None and DB_PASSWORD is not None:
        DATABASE_HOST = os.environ.get("DATABASE_HOST", "postgres")
        DATABASE_PORT = os.environ.get("DATABASE_PORT", "5432")
        DATABASE_NAME = os.environ.get("DATABASE_NAME", "task_manager")

        SQLALCHEMY_DATABASE_URI = (
            f"postgresql://{quote_plus(DB_USER)}:"
            f"{quote_plus(DB_PASSWORD)}@"
            f"{DATABASE_HOST}:{DATABASE_PORT}/{DATABASE_NAME}"
        )
    elif DATABASE_URL:
        SQLALCHEMY_DATABASE_URI = DATABASE_URL
    else:
        raise RuntimeError(
            "Database configuration is missing. "
            "Set DB_USER and DB_PASSWORD, or DATABASE_URL."
        )

    SQLALCHEMY_TRACK_MODIFICATIONS = False
