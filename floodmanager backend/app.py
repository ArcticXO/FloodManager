from flask import Flask, request, jsonify

app = Flask(__name__)

# Health check route
@app.route("/", methods=["GET"])
def home():
    return jsonify({"message": "Flood Reporting API is running"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=4999, debug=True)