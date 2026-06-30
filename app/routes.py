from flask import render_template, request
from app import app

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/about")
def about():
    return render_template("about.html")

@app.route("/contact")
def contact():
    return render_template("contact.html")

@app.route("/dashboard")
def dashboard():
    return render_template("dashboard.html")

@app.route("/task/<int:id>")
def task(id):
    return render_template("task.html", id=id)

@app.route("/add-task", methods=["GET","POST"])
def add_task():

    if request.method == "POST":

       task = request.form["task"]

       return f"Task Added: {task}"

    return render_template("add_task.html")
