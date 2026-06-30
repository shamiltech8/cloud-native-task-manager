from flask import render_template, request, session, redirect, url_for
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

    if "username" not in session:
        return redirect(url_for("login"))

    username = session["username"]
    return render_template("dashboard.html",username=username)

@app.route("/task/<int:id>")
def task(id):
    return render_template("task.html", id=id)

@app.route("/add-task", methods=["GET","POST"])
def add_task():

    if request.method == "POST":

       task = request.form["task"]

       return f"Task Added: {task}"

    return render_template("add_task.html")

@app.route("/login", methods=["GET","POST"])
def login():

    if request.method == "POST":

        username = request.form["username"]

        session["username"] = username

        return redirect(url_for("dashboard"))

    return render_template("login.html")

@app.route("/logout")
def logout():

    session.pop("username", None)

    return redirect(url_for("home"))
