from app import create_app, db
from app.models import User, Task


def test_database_connection():
    app = create_app()

    with app.app_context():
        # Create database tables for the test
        db.create_all()

        # Verify that we can access the database
        user = User(
            username="db_test_user",
            email="dbtest@example.com",
            password="hashed_password"
        )

        db.session.add(user)
        db.session.commit()

        assert user.id is not None

        # Clean up
        db.session.delete(user)
        db.session.commit()

