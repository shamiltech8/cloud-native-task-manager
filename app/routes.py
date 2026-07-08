from flask import Blueprint, render_template, request, session, redirect, url_for
from werkzeug.security import generate_password_hash, check_password_hash

from app import db
from app.models import User, Task

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

    return render_template(
        "dashboard.html",
        username=session["username"]
    )

@main.route("/task/<int:id>")
def task(id):
    return render_template("task.html", id=id)


@main.route("/add-task", methods=["GET", "POST"])
def add_task():

    if "username" not in session:
        return redirect(url_for("main.login"))

    if request.method == "POST":

        title = request.form["title"]
        description = request.form["description"]

        user = User.query.filter_by(
            username=session["username"]
        ).first()

        task = Task(
            title=title,
            description=description,
            user_id=user.id
        )

        db.session.add(task)
        db.session.commit()

        return redirect(url_for("main.dashboard"))

    return render_template("add_task.html")

@main.route("/tasks")
def view_tasks():

    if "username" not in session:
        return redirect(url_for("main.login"))

    user = User.query.filter_by(
        username=session["username"]
    ).first()

    tasks = Task.query.filter_by(
        user_id=user.id
    ).all()

    return render_template(
        "tasks.html",
        tasks=tasks
    )

@main.route("/edit-task/<int:task_id>", methods=["GET", "POST"])
def edit_task(task_id):

    if "username" not in session:
        return redirect(url_for("main.login"))

    user = User.query.filter_by(
        username=session["username"]
    ).first()

    task = Task.query.filter_by(
        id=task_id,
        user_id=user.id
    ).first()

    if not task:
        return "Task not found!"

    if request.method == "POST":

        task.title = request.form["title"]
        task.description = request.form["description"]

        db.session.commit()

        return redirect(url_for("main.view_tasks"))

    return render_template(
        "edit_task.html",
        task=task
    )

@main.route("/register", methods=["GET", "POST"])
def register():

    if "username" in session:
        return redirect(url_for("main.dashboard"))


    if request.method == "POST":

        username = request.form["username"]
        email = request.form["email"]
        password = request.form["password"]

        existing_user = User.query.filter_by(username=username).first()

        if existing_user:
            return "Username already exists!"

        existing_email = User.query.filter_by(email=email).first()

        if existing_email:
            return "Email already exists!"

        hashed_password = generate_password_hash(password)

        user = User(
            username=username,
            email=email,
            password=hashed_password
        )

        db.session.add(user)
        db.session.commit()

        return redirect(url_for("main.login"))
    return render_template("register.html")

@main.route("/login", methods=["GET", "POST"])
def login():

    if request.method == "POST":

        username = request.form["username"]
        password = request.form["password"]

        # Find the user
        user = User.query.filter_by(username=username).first()

        if user and check_password_hash(user.password, password):

            session["username"] = user.username

            return redirect(url_for("main.dashboard"))

        return "Invalid username or password!"

    return render_template("login.html")
    return render_template("register.html")




@main.route("/logout")
def logout():

    session.pop("username", None)

    return redirect(url_for("main.home"))
