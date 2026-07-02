from flask import Blueprint, render_template, request, session, redirect, url_for

main = Blueprint("main", __name__)


@main.route("/")
def home():
    return render_template("index.html")


@main.route("/about")
def about():
    return render_template("about.html")


@main.route("/contact")
def contact():
    return render_template("contact.html")


@main.route("/dashboard")
def dashboard():

    if "username" not in session:
        return redirect(url_for("main.login"))

    username = session["username"]
    return render_template("dashboard.html", username=username)


@main.route("/task/<int:id>")
def task(id):
    return render_template("task.html", id=id)


@main.route("/add-task", methods=["GET", "POST"])
def add_task():

    if request.method == "POST":

        task = request.form["task"]

        return f"Task Added: {task}"

    return render_template("add_task.html")


@main.route("/login", methods=["GET", "POST"])
def login():

    if request.method == "POST":

        username = request.form["username"]

        session["username"] = username

        return redirect(url_for("main.dashboard"))

    return render_template("login.html")


@main.route("/logout")
def logout():

    session.pop("username", None)

    return redirect(url_for("main.home"))
