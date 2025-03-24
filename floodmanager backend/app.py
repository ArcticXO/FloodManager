from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from werkzeug.security import generate_password_hash, check_password_hash
import os
from dotenv import load_dotenv
from sqlalchemy import text
import requests
import numpy as np
from shapely.geometry import Polygon, MultiPolygon, mapping, shape, Point
from shapely.ops import unary_union
from shapely.validation import make_valid
# Fixed import for simplification
from simplification.cutil import simplify_coords

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

# Fixed helper functions for geometry processing with topology error handling
def simplify_geometry(polygon_data):
    """Simplify the polygon geometry to reduce the number of points with topology error handling."""
    try:
        # Convert GeoJSON to Shapely geometry
        features = polygon_data.get('features', [])
        if not features:
            return None
        
        # Process the geometry
        feature = features[0]
        geom = shape(feature['geometry'])
        
        # First, ensure the geometry is valid
        try:
            if not geom.is_valid:
                # Try to make the geometry valid
                geom = make_valid(geom)
                
                # If the geometry is still not valid or is empty, fallback to a simple representation
                if not geom.is_valid or geom.is_empty:
                    # Create a simplified representation based on the centroid
                    centroid = geom.centroid
                    # Return a simple polygon as a fallback
                    simple_poly = Point(centroid).buffer(0.01)
                    return mapping(simple_poly)
        except Exception as e:
            # If validation fix fails, fallback to simple representation
            try:
                bounds = geom.bounds
                centroid_x = (bounds[0] + bounds[2]) / 2
                centroid_y = (bounds[1] + bounds[3]) / 2
                simple_poly = Point(centroid_x, centroid_y).buffer(0.01)
                return mapping(simple_poly)
            except:
                # If that fails too, return a simple square
                return {
                    "type": "Polygon",
                    "coordinates": [[[-0.1, -0.1], [-0.1, 0.1], [0.1, 0.1], [0.1, -0.1], [-0.1, -0.1]]]
                }
        
        # Apply different simplification levels based on complexity
        try:
            if isinstance(geom, MultiPolygon):
                simplified_polys = []
                for poly in geom.geoms:
                    if poly.is_valid and not poly.is_empty:
                        try:
                            # Buffer with 0 distance can sometimes fix self-intersections
                            poly = poly.buffer(0)
                            # Use shapely's built-in simplify with preserve_topology=True as a safer alternative
                            simplified_poly = poly.simplify(0.0005, preserve_topology=True)
                            if simplified_poly.is_valid and not simplified_poly.is_empty:
                                simplified_polys.append(simplified_poly)
                        except:
                            # Skip problematic polygons
                            pass
                
                if not simplified_polys:
                    # If all polygons failed, return centroid buffer
                    return mapping(Point(geom.centroid).buffer(0.01))
                
                simplified_geom = unary_union(simplified_polys)
            else:
                # Buffer with 0 distance can sometimes fix self-intersections
                geom = geom.buffer(0)
                # Use shapely's built-in simplify with preserve_topology=True as a safer alternative
                simplified_geom = geom.simplify(0.0005, preserve_topology=True)
            
            # Convert back to GeoJSON format
            return mapping(simplified_geom)
        except Exception as e:
            # If simplification fails, return a simple representation
            return mapping(Point(geom.centroid).buffer(0.01))
            
    except Exception as e:
        return {"error": f"Failed to simplify geometry: {str(e)}"}

def calculate_centroid(polygon_data):
    """Calculate the centroid and radius for a circular representation."""
    try:
        features = polygon_data.get('features', [])
        if not features:
            return None
        
        try:
            geom = shape(features[0]['geometry'])
            # Try to ensure geometry is valid
            if not geom.is_valid:
                geom = make_valid(geom)
            
            if geom.is_empty:
                # If geometry is empty after validation, use the bounds to estimate location
                bounds = features[0]['geometry'].get('bbox', [0, 0, 0, 0])
                centroid_x = (bounds[0] + bounds[2]) / 2 if len(bounds) >= 4 else 0
                centroid_y = (bounds[1] + bounds[3]) / 2 if len(bounds) >= 4 else 0
                return {
                    "type": "Circle",
                    "coordinates": [centroid_x, centroid_y],
                    "radius": 0.01  # Default small radius
                }
            
            centroid = geom.centroid
            
            # Calculate a representative radius (distance to furthest point)
            max_distance = 0.01  # Default small radius
            
            try:
                if isinstance(geom, MultiPolygon):
                    # For multipolygons, find the maximum distance from centroid to any point
                    for poly in geom.geoms:
                        if poly.is_valid and not poly.is_empty:
                            for point in poly.exterior.coords:
                                distance = ((point[0] - centroid.x)**2 + (point[1] - centroid.y)**2)**0.5
                                max_distance = max(max_distance, distance)
                elif isinstance(geom, Polygon) and geom.is_valid and not geom.is_empty:
                    # For single polygons
                    for point in geom.exterior.coords:
                        distance = ((point[0] - centroid.x)**2 + (point[1] - centroid.y)**2)**0.5
                        max_distance = max(max_distance, distance)
            except:
                # If calculation fails, use a default radius
                max_distance = 0.01
            
            return {
                "type": "Circle",
                "coordinates": [centroid.x, centroid.y],
                "radius": max_distance  # This is in the same units as the coordinates (degrees)
            }
        except Exception as e:
            # Fallback for any geometry processing errors
            return {
                "type": "Circle",
                "coordinates": [0, 0],  # Default coordinates
                "radius": 0.01,  # Default radius
                "error": f"Geometry processing error: {str(e)}"
            }
            
    except Exception as e:
        return {"error": f"Failed to calculate centroid: {str(e)}"}

# Route to get simplified flood areas
@app.route('/simplified_flood_areas', methods=['GET'])
def simplified_flood_areas():
    try:
        # Get flood warnings to extract the polygon URLs
        api_url = "https://environment.data.gov.uk/flood-monitoring/id/floods"
        response = requests.get(api_url)
        response.raise_for_status()
        data = response.json()
        
        simplified_data = []
        
        # Process each flood item
        for item in data.get('items', []):
            flood_info = {
                "description": item.get('description', ''),
                "centroid": {
                    "coordinates": [0, 0],  # Default coordinates
                    "radius": 0.01          # Default radius
                }
            }
            
            # Get polygon data if available
            polygon_url = item.get('floodArea', {}).get('polygon')
            if polygon_url:
                try:
                    polygon_response = requests.get(polygon_url)
                    polygon_response.raise_for_status()
                    polygon_data = polygon_response.json()
                    
                    # Calculate centroid as an alternative representation
                    centroid_info = calculate_centroid(polygon_data)
                    flood_info['centroid'] = centroid_info
                    
                except Exception as e:
                    # Provide fallback centroid
                    flood_info['centroid'] = {
                        "coordinates": [0, 0],  # Default coordinates
                        "radius": 0.01           # Default radius
                    }
            
            simplified_data.append(flood_info)
        
        return jsonify({"items": simplified_data}), 200
    except Exception as e:
        return jsonify({"error": f"Error processing flood data: {str(e)}"}), 500
if __name__ == "__main__":
    with app.app_context():
        db.create_all()
    app.run(host="0.0.0.0", port=4999, debug=True)