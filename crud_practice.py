from app import create_app, db
from app.models import User, Task

app = create_app()

with app.app_context():

    # Step 1: Get the first user
    user = User.query.first()

    if not user:
        print("No user found! Please create a user first.")
        exit()

    # Step 2: Create three tasks
    task1 = Task(
        title="Learn AWS",
        description="Complete AWS Basics",
        user_id=user.id
    )

    task2 = Task(
        title="Learn Docker",
        description="Complete Docker Basics",
        user_id=user.id
    )

    task3 = Task(
        title="Learn Jenkins",
        description="Complete Jenkins Basics",
        user_id=user.id
    )

    # Step 3: Add tasks to the database
    db.session.add(task1)
    db.session.add(task2)
    db.session.add(task3)
    db.session.commit()

    print("\n=== Tasks After Creating ===")
    tasks = Task.query.all()

    for task in tasks:
        print(task.id, task.title, "-", task.completed)

    # Step 4: Update one task
    task = Task.query.filter_by(title="Learn Docker").first()

    if task:
        task.title = "Master Docker"
        db.session.commit()

    print("\n=== Tasks After Updating ===")
    tasks = Task.query.all()

    for task in tasks:
        print(task.id, task.title, "-", task.completed)

    # Step 5: Delete one task
    task = Task.query.filter_by(title="Learn AWS").first()

    if task:
        db.session.delete(task)
        db.session.commit()

    print("\n=== Final Tasks ===")
    tasks = Task.query.all()

    for task in tasks:
        print(task.id, task.title, "-", task.completed)
