from app import create_app, db
from app.models import User, Task


def test_create_user():
    app = create_app()

    with app.app_context():
        # Create database tables for the test
        db.create_all()

        user = User(
            username="test_user",
            email="test@example.com",
            password="hashed_password"
        )

        db.session.add(user)
        db.session.commit()

        assert user.id is not None
        assert user.username == "test_user"

        # Clean up
        db.session.delete(user)
        db.session.commit()

