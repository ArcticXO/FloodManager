from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

# Define User model
class Auth(db.Model):
    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    floods = db.relationship('Flood', backref='user', lazy=True)  # Add relationship

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

# Define Flood report model
class Flood(db.Model):
    __tablename__ = 'floods'
    flood_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey('auth.id'), nullable=False)
    gps_longitude = db.Column(db.Float, nullable=False)
    gps_latitude = db.Column(db.Float, nullable=False)
    radius = db.Column(db.Float, nullable=False)
    severity = db.Column(db.Integer, nullable=False)
    report_time = db.Column(db.DateTime, default=db.func.now())
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=False)

class Admin(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

# Health check route
@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Flood Reporting API is running"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=4999, debug=True)