import pymysql

# Conecta con la base de datos de XAMPP.
conexion = pymysql.connect(
    host="localhost",
    user="root",
    password="",
    database="terror_db",
    charset="utf8mb4"
)

# Consulta las tablas sin modificar datos.
with conexion.cursor() as cursor:
    cursor.execute("SHOW TABLES")
    tablas = cursor.fetchall()

conexion.close()

print("Conexión correcta con terror_db.")
print("Tablas encontradas:")

for tabla in tablas:
    print("-", tabla[0])