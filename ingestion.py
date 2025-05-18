"""
Script DLT para automatizar la ingesta de CSVs al stage de Snowflake y COPY INTO
Requisitos: 
  - Instalar snowflake-connector-python
  - Variables de entorno: SNOWFLAKE_USER, SNOWFLAKE_PASSWORD, SNOWFLAKE_ACCOUNT, 
    SNOWFLAKE_ROLE, SNOWFLAKE_WAREHOUSE, SNOWFLAKE_DATABASE, SNOWFLAKE_SCHEMA
"""

import os
import snowflake.connector
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()

# Parámetros de conexión
conn = snowflake.connector.connect(
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    role=os.getenv("SNOWFLAKE_ROLE"),
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
    database=os.getenv("SNOWFLAKE_DATABASE"),
    schema=os.getenv("SNOWFLAKE_SCHEMA")
)

CURSOR = conn.cursor()

# Configuración general del stage
STAGE_NAME = "raw_csv_stage"
FILE_FORMAT = "csv_format"

def setup_stage_and_format():
    # Crear un internal stage
    CURSOR.execute(f"CREATE OR REPLACE STAGE {STAGE_NAME};")
    # Crear un file format para CSV
    CURSOR.execute(f"""
        CREATE OR REPLACE FILE FORMAT {FILE_FORMAT}
        TYPE = 'CSV'
        FIELD_DELIMITER = ','
        SKIP_HEADER = 1
        NULL_IF = ('', 'NULL');
    """)
    conn.commit()

def upload_and_copy(table_name, local_path):
    """
    Sube el CSV al stage y ejecuta COPY INTO
    :param table_name: nombre de la tabla destino (raw)
    :param local_path: ruta local al CSV
    """
    filename = os.path.basename(local_path)
    # PUT al stage
    CURSOR.execute(f"PUT file://{local_path} @{STAGE_NAME}/{filename} OVERWRITE = TRUE;")
    # COPY INTO
    CURSOR.execute(f"""
        COPY INTO {os.getenv('SNOWFLAKE_DATABASE')}.{os.getenv('SNOWFLAKE_SCHEMA')}.{table_name}
        FROM @{STAGE_NAME}/{filename}
        FILE_FORMAT = (FORMAT_NAME = {FILE_FORMAT})
        ON_ERROR = 'CONTINUE';
    """)
    conn.commit()
    print(f"[{datetime.now()}] {filename} cargado en {table_name}")

if __name__ == "__main__":
    # 1) Preparar stage y formato
    setup_stage_and_format()

    # 2) Directorio con CSVs
    csv_dir = "./raw"
    mapping = {
        "users.csv": "users",
        "instructors.csv": "instructors",
        "courses.csv": "courses",
        "enrollments.csv": "enrollments",
        "completions.csv": "completions",
        "feedbacks.csv": "feedbacks",
        "campaigns.csv": "campaigns",
        "user_interactions.csv": "user_interactions",
        "views.csv": "views"
    }

    for fname, table in mapping.items():
        local_path = os.path.join(csv_dir, fname)
        if os.path.exists(local_path):
            upload_and_copy(table, local_path)
        else:
            print(f"¡Aviso! No existe {local_path}")
