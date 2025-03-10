from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os
from dotenv import load_dotenv
from sqlalchemy import text
import requests

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
    floods = db.relationship('Flood', backref='user', lazy=True)

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

# Route to register a new user
@app.route("/register", methods=["POST"])
def register():
    try:
        data = request.get_json()
        username = data.get("username")
        password = data.get("password")

        if not username or not password:
            return jsonify({"error": "Username and password are required"}), 400

        if Auth.query.filter_by(username=username).first():
            return jsonify({"error": "Username already exists"}), 400

        new_user = Auth(username=username)
        new_user.set_password(password)

        db.session.add(new_user)
        db.session.commit()

        return jsonify({"message": "User registered successfully"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Route to authenticate a user
@app.route("/authenticate", methods=["POST"])
def authenticate():
    try:
        data = request.get_json()
        username = data.get("username")
        password = data.get("password")

        if not username or not password:
            return jsonify({"error": "Username and password are required"}), 400

        user = Auth.query.filter_by(username=username).first()

        if user and user.check_password(password):
            return jsonify({"message": "Login successful"}), 200
        else:
            return jsonify({"error": "Incorrect username or password"}), 400

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Route to report a flood
@app.route('/report_flood', methods=['POST'])
def report_flood():
    try:
        data = request.get_json()

        if 'username' not in data or 'password' not in data:
            return jsonify({'error': 'Username and password are required'}), 400

        user = Auth.query.filter_by(username=data['username']).first()
        if not user or not user.check_password(data['password']):
            return jsonify({'error': 'Incorrect username or password'}), 400

        required_fields = ['gps_longitude', 'gps_latitude', 'radius', 'severity', 'title', 'description']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        if not (1 <= data['severity'] <= 5):
            return jsonify({'error': 'Severity must be between 1 and 5'}), 400

        try:
            gps_longitude = float(data['gps_longitude'])
            gps_latitude = float(data['gps_latitude'])
            radius = float(data['radius'])
            severity = int(data['severity'])
            title = data['title']
            description = data['description']
        except (ValueError, TypeError):
            return jsonify({'error': 'Incorrect data types in request'}), 400

        flood_report = Flood(
            user_id=user.id,
            gps_longitude=gps_longitude,
            gps_latitude=gps_latitude,
            radius=radius,
            severity=severity,
            title=title,
            description=description
        )

        db.session.add(flood_report)
        db.session.commit()

        return jsonify({'message': 'Flood reported successfully'}), 201

    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Internal server error'}), 500

# Route to view all floods
@app.route('/view_floods', methods=['GET'])
def view_floods():
    try:
        result = db.session.execute(
            text("""SELECT floods.flood_id, floods.user_id, floods.gps_longitude, floods.gps_latitude,
                    floods.radius, floods.severity, floods.report_time, auth.username, floods.title, floods.description
                    FROM floods
                    JOIN auth ON floods.user_id = auth.id""")
        )
        floods = result.fetchall()

        floods_list = []
        for flood in floods:
            flood_data = {
                'flood_id': flood.flood_id,
                'user_id': flood.user_id,
                'gps_longitude': flood.gps_longitude,
                'gps_latitude': flood.gps_latitude,
                'radius': flood.radius,
                'severity': flood.severity,
                'time_reported': flood.report_time.strftime('%Y-%m-%d %H:%M:%S') if flood.report_time else None,
                'username': flood.username,
                'title': flood.title,
                'description': flood.description
            }
            floods_list.append(flood_data)

        return jsonify(floods_list), 200

    except Exception as e:
        return jsonify({'error': 'Internal server error'}), 500

# Health check route
@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Flood Reporting API is running"}), 200

# Route to fetch flood warnings from the government API
@app.route('/flood_warnings', methods=['GET'])
def flood_warnings():
    try:
        api_url = "https://environment.data.gov.uk/flood-monitoring/id/floods"
        response = requests.get(api_url)
        response.raise_for_status()
        data = response.json()
        return jsonify(data), 200
    except requests.exceptions.RequestException as e:
        return jsonify({"error": f"Failed to fetch data from government API: {e}"}), 500
    except ValueError:
        return jsonify({"error": "Invalid JSON response from government API"}), 500

if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(host="0.0.0.0", port=4999, debug=True)