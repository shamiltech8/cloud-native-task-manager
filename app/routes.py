from app import app

@app.route("/")
def home():
    return "Welcome to Cloud-Native Task Manager!"

@app.route("/about")
def about():
    return "About Page"

@app.route("/contact")
def contact():
    return "Contact Page"

@app.route("/dashboard")
def dashboard():
    return "Dashboard Page"

@app.route("/task/<int:id>")
def task(id):
    return f"Displaying Task {id}"
