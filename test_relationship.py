from app import create_app, db
from app.models import User, Task

app = create_app()

with app.app_context():
    # Create a user
    user = User(
        username="john",
        email="john@gmail.com",
        password="hashed_password"
    )

    db.session.add(user)
    db.session.commit()

    # Create two tasks for the user
    task1 = Task(
        title="Learn Flask",
        description="Complete Flask tutorial",
        user_id=user.id
    )

    task2 = Task(
        title="Learn Docker",
        description="Complete Docker basics",
        user_id=user.id
    )

    db.session.add(task1)
    db.session.add(task2)
    db.session.commit()

print("User and tasks added successfully!")
