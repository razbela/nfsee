from backend.server import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    nfc_uid = db.Column(db.String(150), nullable=True)

    def __repr__(self):
        return f'<User {self.username}>'
