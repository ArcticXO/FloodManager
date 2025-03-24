from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView
import os

app = Flask(__name__)

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = "postgresql+psycopg2://avnadmin:AVNS_bFgCjYTcea6UNps0KB7@pg-210900-floodmanager.b.aivencloud.com:28895/defaultdb?sslmode=require"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.urandom(24)  # Required for Flask-Admin

db = SQLAlchemy(app)
admin = Admin(app, name='Database Admin', template_mode='bootstrap3')

# Example Table Model
class ExampleTable(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    value = db.Column(db.String(100), nullable=False)

    def __repr__(self):
        return f'<ExampleTable {self.name}>'

# Add the table to Flask-Admin
admin.add_view(ModelView(ExampleTable, db.session))

if __name__ == '__main__':
    with app.app_context():
        db.create_all()  # Ensure tables exist
    app.run(debug=True)
