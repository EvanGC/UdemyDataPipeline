import dlt
import os
import glob
import pandas as pd

def sanitize_table_name(filename_without_ext: str) -> str:
    """
    Convierte un nombre de archivo en un nombre de tabla SQL seguro y normalizado.
    Ej: "Mi Archivo-123.csv" -> "mi_archivo_123"
    """
    # Convertir a minúsculas
    name = filename_without_ext.lower()
    # Reemplazar caracteres no alfanuméricos (excepto guion bajo) por guion bajo
    name = ''.join(c if c.isalnum() else '_' for c in name)
    # Eliminar guiones bajos duplicados
    name = '_'.join(filter(None, name.split('_')))
    # Asegurar que no empiece con un número
    # dlt se encarga de citar si es necesario, así que esto es más por convención.
    if name and name[0].isdigit():
        name = f"_{name}"
    if not name: # Si el nombre queda vacío
        raise ValueError(f"No se pudo generar un nombre de tabla válido de '{filename_without_ext}'")
    return name

def _create_resource_for_csv(filepath: str, table_name: str, write_disposition_strategy: str = "append"):
    """
    Función auxiliar que crea una función de recurso dlt para un único archivo CSV.
    Esta función interna captura 'filepath' y 'table_name'.
    """
    # El nombre limpio de la tabla ya debería estar sanitizado antes de pasar a esta función
    @dlt.resource(name=table_name, write_disposition=write_disposition_strategy)
    def _single_csv_loader():
        print(f"Procesando archivo: {filepath} para la tabla: {table_name}")
        try:
            df = pd.read_csv(filepath, encoding='utf-8', sep=';') # Ajusta sep=',' u otros según necesidad
            if df.empty:
                print(f"Advertencia: El archivo CSV '{filepath}' está vacío o solo contiene cabeceras. No se generarán datos para la tabla '{table_name}'.")
                # No hacer yield si está vacío, dlt no creará la tabla.
                return
            yield df # Yield el DataFrame completo
        except pd.errors.EmptyDataError:
            print(f"Advertencia: El archivo CSV '{filepath}' está completamente vacío (EmptyDataError). No se generarán datos para la tabla '{table_name}'.")
        except Exception as e:
            print(f"Error al leer el archivo CSV '{filepath}': {e}")
            # Podrías elegir propagar el error o simplemente omitir este archivo:
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
        return [] # dlt espera un iterable de recursos

    generated_resources = []
    for filepath in csv_filepaths:
        filename_with_ext = os.path.basename(filepath)
        filename_without_ext = os.path.splitext(filename_with_ext)[0]

        try:
            table_name_normalized = sanitize_table_name(filename_without_ext)
            if not table_name_normalized: # Doble chequeo por si sanitize devuelve vacío
                print(f"Advertencia: Nombre de tabla vacío para {filename_with_ext} tras sanitización. Omitiendo.")
                continue
        except ValueError as ve:
            print(f"Advertencia: {ve}. Omitiendo archivo {filename_with_ext}.")
            continue

        print(f"Definiendo recurso para archivo '{filename_with_ext}' -> tabla '{table_name_normalized}'")
        # Crea y añade la función de recurso a la lista
        resource_fn = _create_resource_for_csv(filepath, table_name_normalized, write_disposition)
        generated_resources.append(resource_fn)

    return generated_resources

# --- Configuración y Ejecución del Pipeline ---
def run_csv_folder_to_snowflake_pipeline():
    """
    Configura y ejecuta el pipeline para ingestar múltiples CSVs en tablas separadas.
    """
    # Define la ruta a tu carpeta de CSVs
    csv_input_folder = "./raw"

    # Crear carpeta y archivos CSV de ejemplo si no existen
    if not os.path.exists(csv_input_folder):
        os.makedirs(csv_input_folder)
        print(f"Carpeta de ejemplo '{csv_input_folder}' creada.")

    # Configura el pipeline
    pipeline = dlt.pipeline(
        pipeline_name="local_csv_to_dynamic_snowflake_tables",
        destination="snowflake",
        dataset_name="bronze",
        progress="log"
    )

    # Crea la fuente. Esta función DEVOLVERÁ una lista de funciones de recursos.
    csv_source = dynamic_csv_ingestion_source(
        csv_folder_path=csv_input_folder,
        file_pattern="*.csv",
        write_disposition="replace" # O "replace" si prefieres esa estrategia
    )

    # Ejecuta el pipeline con la fuente que genera múltiples recursos
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