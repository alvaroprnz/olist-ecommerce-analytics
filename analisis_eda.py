import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine

server = 'localhost'
database = 'Olist'

connection_string = (
    f"mssql+pyodbc://@{server}/{database}?"
    "driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
)

try:
    engine = create_engine(connection_string)
    print("¡Conexión exitosa a SQL Server!")
except Exception as e:
    print(f"Error al conectar: {e}")

# extraccion de datos desde SQL
query = """
SELECT 
    o.order_id,
    c.customer_state,
    DATEDIFF(day, TRY_CAST(o.order_purchase_timestamp AS DATETIME2), TRY_CAST(o.order_delivered_customer_date AS DATETIME2)) AS dias_entrega_real,
    DATEDIFF(day, TRY_CAST(o.order_purchase_timestamp AS DATETIME2), TRY_CAST(o.order_estimated_delivery_date AS DATETIME2)) AS dias_entrega_prometida,
    CASE 
        WHEN TRY_CAST(o.order_delivered_customer_date AS DATETIME2) > TRY_CAST(o.order_estimated_delivery_date AS DATETIME2) THEN 1 
        ELSE 0 
    END AS es_retrasado,
    CAST(i.price AS FLOAT) / 100.0 AS precio,
    CAST(i.freight_value AS FLOAT) / 100.0 AS flete,
    CAST(r.review_score AS INT) AS review_score
FROM olist_orders_dataset o
INNER JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
INNER JOIN olist_order_items_dataset i ON o.order_id = i.order_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';
"""

df = pd.read_sql(query, engine)

print(f"\nTotal de registros cargados: {len(df):,}")
print("\nPrimeras 5 filas del dataset:")
print(df.head())

# EDA
print("\n--- RESUMEN ESTADÍSTICO ---")
print(df[['dias_entrega_real', 'dias_entrega_prometida', 'precio', 'flete', 'review_score']].describe())

p95_entrega = df['dias_entrega_real'].quantile(0.95)
p99_entrega = df['dias_entrega_real'].quantile(0.99)
print(f"\n--- DETECCIÓN DE OUTLIERS ---")
print(f"El 95% de los envíos tarda menos de {p95_entrega:.1f} días.")
print(f"El 99% de los envíos tarda menos de {p99_entrega:.1f} días.")
print(f"El tiempo máximo registrado de entrega es de {df['dias_entrega_real'].max()} días.")

correlation_vars = ['dias_entrega_real', 'es_retrasado', 'precio', 'flete', 'review_score']
corr_matrix = df[correlation_vars].corr()

# Graficas
plt.style.use('seaborn-v0_8-whitegrid' if 'seaborn-v0_8-whitegrid' in plt.style.available else 'default')

plt.figure(figsize=(8, 6))
sns.heatmap(corr_matrix, annot=True, cmap='coolwarm', vmin=-1, vmax=1, fmt=".2f")
plt.title('Matriz de Correlación de Variables Clave (Olist)', fontsize=12, fontweight='bold')
plt.tight_layout()
plt.show()

plt.figure(figsize=(8, 5))
sns.boxplot(x='es_retrasado', y='review_score', data=df, palette=['#2ec4b6', '#e71d36'])
plt.xticks([0, 1], ['A Tiempo', 'Con Retraso'])
plt.title('Distribución de Review Score: A Tiempo vs Con Retraso', fontsize=12, fontweight='bold')
plt.xlabel('Estado de la Entrega')
plt.ylabel('Puntuación (1-5 Estrellas)')
plt.tight_layout()
plt.show()

#Mapa de calor edicion de variables
#Definir variables y diccionario de nombres legibles
correlation_vars = ['dias_entrega_real', 'es_retrasado', 'precio', 'flete', 'review_score']

# Diccionario para mapear nombres técnicos a nombres ejecutivos
nombres_ejecutivos = {
    'dias_entrega_real': 'Días Entrega Real',
    'es_retrasado': 'Entrega Retrasada (S/N)',
    'precio': 'Precio Producto (R$)',
    'flete': 'Costo Flete (R$)',
    'review_score': 'Calificación (1-5)'
}

# 2. Renombrar las columnas en la matriz de correlación
df_corr = df[correlation_vars].rename(columns=nombres_ejecutivos)
corr_matrix = df_corr.corr()

# 3. Generar el gráfico mejorado
plt.figure(figsize=(9, 6))
sns.heatmap(
    corr_matrix, 
    annot=True, 
    cmap='coolwarm', 
    vmin=-1, 
    vmax=1, 
    fmt=".2f",
    linewidths=0.5
)

plt.title('Matriz de Correlación: Factores Operativos vs. Satisfacción', fontsize=12, fontweight='bold', pad=15)
plt.xticks(rotation=15, ha='right', fontsize=10)
plt.yticks(rotation=0, fontsize=10)
plt.tight_layout()

