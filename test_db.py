from app import create_app, db
from app.models import User

app = create_app()

with app.app_context():
    user = User(
        username="shamil",
        email="shamil@gmail.com",
        password="hashed_password"
    )

    db.session.add(user)
    db.session.commit()

print("User added successfully!")
