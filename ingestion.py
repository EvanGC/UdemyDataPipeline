import dlt
import os
import glob
import pandas as pd

def sanitize_table_name(filename_without_ext: str) -> str:
    """
    Convierte un nombre de archivo en un nombre de tabla SQL seguro y normalizado.
    Ej: "Mi Archivo-123.csv" -> "mi_archivo_123"
    """
    name = filename_without_ext.lower()
    name = ''.join(c if c.isalnum() else '_' for c in name)
    name = '_'.join(filter(None, name.split('_')))

    if name and name[0].isdigit():
        name = f"_{name}"
    if not name: 
        raise ValueError(f"No se pudo generar un nombre de tabla válido de '{filename_without_ext}'")
    return name

def _create_resource_for_csv(filepath: str, table_name: str, write_disposition_strategy: str = "append"):
    """
    Función auxiliar que crea una función de recurso dlt para un único archivo CSV.
    Esta función interna captura 'filepath' y 'table_name'.
    """
    @dlt.resource(name=table_name, write_disposition=write_disposition_strategy)
    def _single_csv_loader():
        print(f"Procesando archivo: {filepath} para la tabla: {table_name}")
        try:
            if table_name == "users" or table_name == "campaigns":
                df = pd.read_csv(filepath, sep=',')
            else:
                df = pd.read_csv(filepath, sep=';')
            if df.empty:
                print(f"Advertencia: El archivo CSV '{filepath}' está vacío o solo contiene cabeceras. No se generarán datos para la tabla '{table_name}'.")
                return
            yield df 
        except pd.errors.EmptyDataError:
            print(f"Advertencia: El archivo CSV '{filepath}' está completamente vacío (EmptyDataError). No se generarán datos para la tabla '{table_name}'.")
        except Exception as e:
            print(f"Error al leer el archivo CSV '{filepath}': {e}")
            raise
    return _single_csv_loader

@dlt.source(name="csv_to_tables_source")
def dynamic_csv_ingestion_source(csv_folder_path: str, file_pattern: str = "*.csv", write_disposition: str = "replace"):
    """
    Una fuente dlt que descubre archivos CSV y crea un recurso dlt (y por tanto una tabla destino)
    para cada archivo CSV.
    """
    csv_filepaths = glob.glob(os.path.join(csv_folder_path, file_pattern))

    if not csv_filepaths:
        print(f"Advertencia: No se encontraron archivos CSV en '{csv_folder_path}' con el patrón '{file_pattern}'.")
        return [] 

    generated_resources = []
    for filepath in csv_filepaths:
        filename_with_ext = os.path.basename(filepath)
        filename_without_ext = os.path.splitext(filename_with_ext)[0]

        try:
            table_name_normalized = sanitize_table_name(filename_without_ext)
            if not table_name_normalized:
                print(f"Advertencia: Nombre de tabla vacío para {filename_with_ext} tras sanitización. Omitiendo.")
                continue
        except ValueError as ve:
            print(f"Advertencia: {ve}. Omitiendo archivo {filename_with_ext}.")
            continue

        print(f"Definiendo recurso para archivo '{filename_with_ext}' -> tabla '{table_name_normalized}'")
        resource_fn = _create_resource_for_csv(filepath, table_name_normalized, write_disposition)
        generated_resources.append(resource_fn)

    return generated_resources

# --- Configuración y Ejecución del Pipeline ---
def run_csv_folder_to_snowflake_pipeline():
    """
    Configura y ejecuta el pipeline para ingestar múltiples CSVs en tablas separadas.
    """
    csv_input_folder = "./raw"

    if not os.path.exists(csv_input_folder):
        os.makedirs(csv_input_folder)
        print(f"Carpeta de ejemplo '{csv_input_folder}' creada.")

    pipeline = dlt.pipeline(
        pipeline_name="local_csv_to_dynamic_snowflake_tables",
        destination="snowflake",
        dataset_name="bronze",
        progress="log"
    )

    csv_source = dynamic_csv_ingestion_source(
        csv_folder_path=csv_input_folder,
        file_pattern="*.csv",
        write_disposition="replace"
    )

    print(f"Iniciando la carga de datos desde '{csv_input_folder}' a Snowflake...")
    load_info = pipeline.run(csv_source)

    print("\n--- Información de la Carga ---")
    print(load_info)

    if load_info.has_failed_jobs:
        print("\nALERTA: Algunos trabajos fallaron durante la carga.")
    else:
        print(f"\nIngestadas las tablas en el esquema '{pipeline.dataset_name}' de tu base de datos Snowflake.")


if __name__ == "__main__":
    run_csv_folder_to_snowflake_pipeline()