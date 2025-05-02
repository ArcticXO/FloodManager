from flask import Flask, render_template_string
from flask_sqlalchemy import SQLAlchemy
from flask_admin import Admin
from flask_admin.contrib.sqla import ModelView
from sqlalchemy import inspect, text
import os

app = Flask(__name__)

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = "postgresql+psycopg2://avnadmin:AVNS_bFgCjYTcea6UNps0KB7@pg-210900-floodmanager.b.aivencloud.com:28895/defaultdb?sslmode=require"
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SECRET_KEY'] = os.urandom(24)

db = SQLAlchemy(app)
admin = Admin(app, name='Database Admin', template_mode='bootstrap3')

# Safe table viewer - no schema modifications
@app.route('/table/<table_name>')
def view_table(table_name):
    try:
        inspector = inspect(db.engine)
        
        # Verify table exists
        if table_name not in inspector.get_table_names():
            return f"Table '{table_name}' not found", 404
            
        # Get column info
        columns = inspector.get_columns(table_name)
        column_names = [col['name'] for col in columns]
        
        # Safely get data using parameterized query
        result = db.session.execute(text(f'SELECT * FROM "{table_name}"'))
        rows = result.fetchall()
        
        # Generate HTML
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>{table_name} Contents</title>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}
                h1 {{ color: #333; }}
                table {{ border-collapse: collapse; width: 100%; }}
                th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
                th {{ background-color: #f2f2f2; }}
                tr:nth-child(even) {{ background-color: #f9f9f9; }}
                .action-buttons {{ margin: 20px 0; }}
                .back-link {{ margin-top: 20px; display: inline-block; }}
            </style>
        </head>
        <body>
            <h1>Contents of {table_name}</h1>
            <div class="action-buttons">
                <a href="/admin/{table_name.lower()}/" class="btn btn-primary">Edit in Admin</a>
                <a href="/" class="btn btn-secondary">Back to Tables</a>
            </div>
            <table>
                <thead>
                    <tr>
                        {"".join(f'<th>{name}</th>' for name in column_names)}
                    </tr>
                </thead>
                <tbody>
                    {"".join(
                        f'<tr>{"".join(f"<td>{value}</td>" for value in row)}</tr>'
                        for row in rows
                    )}
                </tbody>
            </table>
            <div class="back-link">
                <a href="/">← Back to all tables</a>
            </div>
        </body>
        </html>
        """
        return html
        
    except Exception as e:
        return f"Error accessing table '{table_name}': {str(e)}", 500

# Main route showing all tables
@app.route('/')
def show_tables():
    try:
        inspector = inspect(db.engine)
        table_names = inspector.get_table_names()
        
        html = """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Database Tables</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1 { color: #333; }
                ul { list-style-type: none; padding: 0; }
                li { padding: 8px; margin-bottom: 5px; background: #f0f0f0; border-radius: 4px; }
                li a { text-decoration: none; color: #0066cc; }
                li a:hover { text-decoration: underline; }
                .admin-link { display: block; margin-top: 20px; }
            </style>
        </head>
        <body>
            <h1>Tables in the Database</h1>
            <ul>
                {% for table in tables %}
                <li><a href="/table/{{ table }}">{{ table }}</a></li>
                {% endfor %}
            </ul>
            <div class="admin-link">
                <a href="/admin/">Advanced Admin Interface →</a>
            </div>
        </body>
        </html>
        """
        return render_template_string(html, tables=table_names)
        
    except Exception as e:
        return f"Error accessing database: {str(e)}", 500

# Safe admin setup using reflection
def setup_safe_admin_views():
    with app.app_context():
        try:
            inspector = inspect(db.engine)
            for table_name in inspector.get_table_names():
                # Skip system tables
                if table_name in ('alembic_version', 'spatial_ref_sys'):
                    continue
                    
                try:
                    # Create model dynamically using reflection
                    model = type(
                        table_name.capitalize(),
                        (db.Model,),
                        {
                            '__tablename__': table_name,
                            '__table_args__': {'autoload': True, 'autoload_with': db.engine},
                            'id': db.Column(db.Integer, primary_key=True)  # Add synthetic PK
                        }
                    )
                    
                    # Create read-only view by default
                    class SafeModelView(ModelView):
                        can_edit = True
                        can_create = True
                        can_delete = True
                        column_display_pk = True
                        
                    admin.add_view(SafeModelView(model, db.session, name=table_name))
                    
                except Exception as e:
                    print(f"Skipping admin view for {table_name}: {str(e)}")
                    
        except Exception as e:
            print(f"Error setting up admin views: {str(e)}")

if __name__ == '__main__':
    with app.app_context():
        try:
            setup_safe_admin_views()
            app.run(debug=True)
        except Exception as e:
            print(f"Failed to start application: {str(e)}")