from backend.server import db
import uuid

class User(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    username = db.Column(db.String(150), unique=True, nullable=False)
    password = db.Column(db.String(150), nullable=False)
    nfc_uid = db.Column(db.String(150), unique=True, nullable=True)
    local_vault = db.relationship('LocalVault', backref='user', uselist=False)

class LocalVault(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('user.id'), nullable=False)
    stored_passwords = db.relationship('StoredPassword', backref='local_vault', lazy=True)

class StoredPassword(db.Model):
    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    title = db.Column(db.String(150), nullable=False)
    username = db.Column(db.String(150), nullable=False)
    password = db.Column(db.String(150), nullable=False)
    isDecrypted = db.Column(db.Boolean, default=False)
    local_vault_id = db.Column(db.String(36), db.ForeignKey('local_vault.id'), nullable=False)
