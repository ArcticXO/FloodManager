from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = os.getenv("DATABASE_URL")
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

# Health check route
@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Flood Reporting API is running"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=4999, debug=True)