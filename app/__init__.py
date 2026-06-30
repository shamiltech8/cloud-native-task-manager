# app/__init__.py

from flask import Flask

app = Flask(__name__)

app.secret_key = "my_user_key"

from app import routes
