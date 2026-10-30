from app import create_app, db
from app.models import User, Task


def test_user_task_relationship():
    app = create_app()

    with app.app_context():
        db.create_all()

        user = User(
            username="relationship_user",
            email="relationship@example.com",
            password="hashed_password"
        )

        db.session.add(user)
        db.session.commit()

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

        db.session.add_all([task1, task2])
        db.session.commit()

        fetched_user = User.query.filter_by(username="relationship_user").first()

        assert fetched_user is not None
        assert len(fetched_user.tasks) == 2
        assert task1 in fetched_user.tasks
        assert task2 in fetched_user.tasks
        assert task1.user == user
        assert task2.user == user

        db.session.delete(task1)
        db.session.delete(task2)
        db.session.delete(user)
        db.session.commit()
