from app import create_app
from app.models import User

app = create_app()

with app.app_context():

    user = User.query.filter_by(username="shamil").first()

    print(user.username)

    print(user.tasks)
