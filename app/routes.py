from app import app

@app.route("/")
def home():
    return "Welcome to Cloud-Native Task Manager!"
