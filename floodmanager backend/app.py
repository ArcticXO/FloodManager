from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")  # Replace with your DB URL
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

class Auth(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    floods = db.relationship('Flood', backref='user', lazy=True)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Flood(db.Model):
    flood_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('auth.id'), nullable=False)
    gps_longitude = db.Column(db.Float, nullable=False)
    gps_latitude = db.Column(db.Float, nullable=False)
    radius = db.Column(db.Float, nullable=False)
    severity = db.Column(db.Integer, nullable=False)
    # ... other flood fields

# ... (rest of the app.py file will be added in later commits)