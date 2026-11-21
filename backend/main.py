# CRUPPIS — API de la aplicación móvil.
# Recibe las solicitudes de Flutter, revisa los datos y consulta MySQL.
# Las fotografías se guardan en backend/uploads y se consultan desde /portadas.
# Se conservan las rutas y las instrucciones para mantener el funcionamiento actual.


# Permite trabajar con fechas, duración y hora UTC para el vencimiento del token.
from datetime import datetime, timedelta, timezone
# Permite construir rutas de carpetas y archivos.
from pathlib import Path
# Permite separar y examinar las partes de una URL.
from urllib.parse import urlparse
# Genera valores aleatorios para la clave de sesión y los nombres de imágenes.
import secrets
# Permite revisar formatos de texto, como el correo electrónico.
import re
# Permite crear y comprobar hashes de contraseñas.
import bcrypt
# Permite firmar y verificar los tokens de acceso.
import jwt
# Permite consultar y modificar MySQL desde Python.
import pymysql
# Incluye las herramientas para crear las rutas de la API, recibir formularios y explicar los errores.
from fastapi import Depends, FastAPI, File, Form, HTTPException, Request, UploadFile
# Permite recibir el token que la app envía para identificarse.
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
# Permite servir las imágenes guardadas mediante la ruta /portadas.
from fastapi.staticfiles import StaticFiles
# Permite definir qué datos se reciben y qué límites deben cumplir.
from pydantic import BaseModel, Field
# Crea la API y establece Cruppis como nombre de su documentación.
app = FastAPI(title="Cruppis API")
# Guarda las imágenes dentro del backend, sin depender de la carpeta de la web.
CARPETA_PORTADAS = Path(__file__).resolve().parent / "uploads"
# Crea la carpeta de imágenes y sus carpetas superiores si todavía no existen.
CARPETA_PORTADAS.mkdir(parents=True, exist_ok=True)
# Permite consultar las imágenes desde la dirección /portadas de la API.
app.mount(
    "/portadas",
    StaticFiles(directory=str(CARPETA_PORTADAS)),
    name="portadas",
)
# Genera la clave que permite comprobar los tokens. Cambia al reiniciar la API, por lo que será necesario volver a iniciar sesión.
CLAVE_JWT = secrets.token_urlsafe(64)
# Define el método que se utiliza para firmar y comprobar los tokens.
ALGORITMO_JWT = "HS256"
# Establece el máximo permitido: 5 × 1024 × 1024 bytes.
MAXIMO_FOTO = 5 * 1024 * 1024
# Prepara una comparación de contraseña incluso si el correo no existe, para reducir diferencias en el tiempo de respuesta.
HASH_COMPROBACION = bcrypt.hashpw(
    secrets.token_bytes(32),
    bcrypt.gensalt(),
)
# Prepara la lectura del token. Si falta o no es válido, exigir_usuario devuelve el aviso correspondiente.
seguridad = HTTPBearer(auto_error=False)
# Las fotos nuevas se guardan con una ruta de la API, sin fijar una dirección IP.
RUTA_FOTOS_API = "/portadas/"

# Permite seguir leyendo las referencias antiguas sin cambiar la base de datos.
RUTA_FOTOS_ANTERIOR = "/proyecto_equipo/equipo_web/admin/uploads/"

# Convierte las fotos locales a la dirección actual de la API.
# Las direcciones externas se conservan para no cambiar imágenes ya registradas.
def foto_para_app(foto, request: Request):
    if not foto:
        return foto

    texto = str(foto).strip()
    nombre = texto

    for prefijo in (RUTA_FOTOS_ANTERIOR, RUTA_FOTOS_API, "portadas/"):
        if texto.startswith(prefijo):
            nombre = texto[len(prefijo):]
            break

    # Solo convierte nombres de archivo, no rutas a otras carpetas.
    if nombre and nombre not in (".", "..") and "/" not in nombre and chr(92) not in nombre:
        return str(request.url_for("portadas", path=nombre))

    return texto

# Adapta las fotografías de los actores antes de devolver las publicaciones a Flutter.
def preparar_fotos_publicaciones(publicaciones, request: Request):
    for publicacion in publicaciones:
        publicacion["foto_actor"] = foto_para_app(
            publicacion.get("foto_actor"), request
        )
    return publicaciones
# Agrupa los campos que se reciben en una solicitud y sus reglas de validación.
class DatosLogin(BaseModel):
    # Define el campo correo con un límite de 254 caracteres.
    correo: str = Field(min_length=1, max_length=254)
    # Recibe la contraseña; su tamaño en bytes se revisa antes de guardarla.
    password: str = Field(min_length=1, max_length=4096)
# Abre la conexión con la base de datos del proyecto. Debe cerrarse cuando termine de utilizarse.
def conectar():
    return pymysql.connect(
        host="localhost",
        user="root",
        password="",
        database="crupis",
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
    )
# Compara la contraseña recibida con el hash almacenado, sin recuperar la contraseña original.
def verificar_password(password: str, hash_guardado: bytes) -> bool:
    try:
        return bcrypt.checkpw(
            password.encode("utf-8")[:72],
            hash_guardado,
        )
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except (ValueError, TypeError):
        return False
# Valida el token de sesión y comprueba que la cuenta todavía existe en MySQL.
def exigir_usuario(
    # Recibe el token extraído del encabezado Authorization.
    credenciales: HTTPAuthorizationCredentials | None = Depends(seguridad),
):
    # Prepara el aviso que se devolverá cuando la sesión no sea válida.
    error = HTTPException(
        status_code=401,
        detail="Sesión inválida o vencida. Inicia sesión nuevamente.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if (
        credenciales is None
        or credenciales.scheme.lower() != "bearer"
    ):
        # Interrumpe la operación y comunica el error.
        raise error
    try:
        # Recupera los datos que se van a revisar en esta operación.
        datos = jwt.decode(
            credenciales.credentials,
            CLAVE_JWT,
            algorithms=[ALGORITMO_JWT],
            options={"require": ["sub", "exp", "iat"]},
        )
        # Obtiene el identificador de la cuenta para consultarla en la base de datos.
        id_usuario = int(datos["sub"])
        if id_usuario <= 0:
            # Interrumpe la operación y comunica el error.
            raise error
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except (jwt.InvalidTokenError, ValueError, TypeError):
        # Interrumpe la operación y comunica el error.
        raise error
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario, nombre, correo, rol
                FROM usuarios
                WHERE id_usuario = %s
                """,
                (id_usuario,),
            )
            # Recupera el registro encontrado; si no existe, el resultado es None.
            usuario = cursor.fetchone()
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
    if usuario is None:
        # Interrumpe la operación y comunica el error.
        raise error
    return usuario
# Permite continuar únicamente a la cuenta administrativa original: rol Administrador e identificador 1.
def exigir_administrador(
    # Recibe la cuenta autenticada después de comprobar su token.
    usuario: dict = Depends(exigir_usuario),
):
    if (
        int(usuario["id_usuario"]) != 1
        or usuario["rol"] != "Administrador"
    ):
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=403,
            detail="Esta acción requiere permisos de administrador.",
        )
    return usuario
# Permite comentar únicamente con una cuenta de lector.
# Permite continuar únicamente a una cuenta con rol Lector.
def exigir_lector(
    # Recibe la cuenta autenticada después de comprobar su token.
    usuario: dict = Depends(exigir_usuario),
):
    if usuario["rol"] != "Lector":
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=403,
            detail="Inicia sesión como lector para realizar esta acción.",
        )
    return usuario
# Lee como máximo 5 MB más un byte, identifica JPG/PNG/WEBP por su firma y guarda el archivo con nombre aleatorio.
def guardar_foto(
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None,
    # Distingue el tipo de imagen en el nombre generado.
    prefijo: str = "dir",
) -> str | None:
    if foto is None:
        return None
    try:
        if not foto.filename:
            return None
        # Lee el contenido de la imagen para revisar su tamaño y formato.
        contenido = foto.file.read(MAXIMO_FOTO + 1)
        if len(contenido) > MAXIMO_FOTO:
            # Interrumpe la operación y comunica el error.
            raise HTTPException(
                status_code=413,
                detail="La imagen no debe superar los 5 MB.",
            )
        if contenido.startswith(b"\xff\xd8\xff"):
            # Elige la extensión que corresponde al formato reconocido de la imagen.
            extension = ".jpg"
        elif contenido.startswith(b"\x89PNG\r\n\x1a\n"):
            # Elige la extensión que corresponde al formato reconocido de la imagen.
            extension = ".png"
        elif (
            len(contenido) >= 12
            and contenido[:4] == b"RIFF"
            and contenido[8:12] == b"WEBP"
        ):
            # Elige la extensión que corresponde al formato reconocido de la imagen.
            extension = ".webp"
        # Ejecuta esta alternativa cuando no se cumple la condición anterior.
        else:
            # Interrumpe la operación y comunica el error.
            raise HTTPException(
                status_code=422,
                detail="Selecciona una imagen JPG, PNG o WEBP.",
            )
        # Prepara el nombre que se utilizará en esta operación.
        nombre = f"{prefijo}_{secrets.token_hex(16)}{extension}"
        # Construye la ubicación del archivo dentro de la carpeta de imágenes.
        ruta = CARPETA_PORTADAS / nombre
        try:
            # Ejecuta esta operación auxiliar: ruta.write_bytes(contenido).
            ruta.write_bytes(contenido)
        # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
        except OSError:
            # Elimina el archivo indicado sin provocar otro error si ya no existe.
            ruta.unlink(missing_ok=True)
            # Interrumpe la operación y comunica el error.
            raise
        return nombre
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra el archivo temporal recibido en la carga de la imagen.
        foto.file.close()
@app.get("/")
# Devuelve un mensaje para comprobar que la API está encendida.
def inicio():
    return {"mensaje": "La API de Cruppis está funcionando"}
@app.post("/api/login")
# Comprueba las credenciales y entrega un token de acceso con vigencia de una hora.
def iniciar_sesion(datos: DatosLogin):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario, nombre, correo, password, rol
                FROM usuarios
                WHERE correo = %s
                LIMIT 1
                """,
                (datos.correo.strip(),),
            )
            # Recupera el registro encontrado; si no existe, el resultado es None.
            usuario = cursor.fetchone()
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
    # Utiliza el hash de la cuenta o uno de referencia si el correo no existe.
    hash_guardado = (
        str(usuario["password"]).encode("utf-8")
        if usuario
        else HASH_COMPROBACION
    )
    # Comprueba si la contraseña coincide con la que tiene guardada la cuenta.
    password_correcta = verificar_password(
        datos.password,
        hash_guardado,
    )
    # Revisa si la cuenta tiene uno de los roles autorizados para entrar.
    rol_permitido = usuario is not None and (
        usuario["rol"] == "Lector"
        or (
            usuario["rol"] == "Administrador"
            and int(usuario["id_usuario"]) == 1
        )
    )
    if not password_correcta or not rol_permitido:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=401,
            detail="Credenciales incorrectas o usuario no registrado.",
        )
    # Obtiene la fecha y hora actual en UTC.
    ahora = datetime.now(timezone.utc)
    # Firma el token que identifica al usuario y contiene su fecha de vencimiento.
    token = jwt.encode(
        {
            "sub": str(usuario["id_usuario"]),
            "iat": ahora,
            "exp": ahora + timedelta(hours=1),
        },
        CLAVE_JWT,
        algorithm=ALGORITMO_JWT,
    )
    return {
        "access_token": token,
        "token_type": "bearer",
        "usuario": {
            "id_usuario": usuario["id_usuario"],
            "nombre": usuario["nombre"],
            "correo": usuario["correo"],
            "rol": usuario["rol"],
        },
    }
# Consulta compartida por el catálogo y el panel.
# Agrega actor, etiquetas y promedio sin quitar los campos anteriores.
# Consulta reseñas con director, actor, etiquetas y resumen de estrellas; se reutiliza en catálogo, detalle y administración.
def consultar_publicaciones(
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int | None = None,
    # Recibe el texto de búsqueda; una cadena vacía no agrega ese filtro.
    buscar: str = "",
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Prepara la consulta que reúne las reseñas con sus datos relacionados. Los valores de los filtros se envían por separado.
            sql = """
                SELECT
                    p.id_publicacion,
                    p.id_director,
                    p.id_actor,
                    p.titulo,
                    p.tipo,
                    p.contenido AS sinopsis,
                    p.imagen AS portada,
                    p.destacada,
                    COALESCE(d.nombre, 'Sin información') AS director,
                    d.foto AS foto_director,
                    a.nombre AS actor,
                    a.foto AS foto_actor,
                    COALESCE(v.promedio, 0) AS promedio,
                    COALESCE(v.total_votos, 0) AS total_votos
                FROM publicaciones AS p
                LEFT JOIN directores AS d
                    ON p.id_director = d.id_director
                LEFT JOIN actores AS a
                    ON p.id_actor = a.id_actor
                LEFT JOIN (
                    SELECT
                        id_publicacion,
                        ROUND(AVG(estrellas), 1) AS promedio,
                        COUNT(*) AS total_votos
                    FROM calificaciones
                    GROUP BY id_publicacion
                ) AS v
                    ON v.id_publicacion = p.id_publicacion
            """
            # Reúne los filtros que se aplicarán si se busca una reseña específica o un texto.
            condiciones = []
            # Reúne los valores que se enviarán junto con la consulta.
            parametros = []
            if id_publicacion is not None:
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                condiciones.append("p.id_publicacion = %s")
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                parametros.append(id_publicacion)
            if buscar.strip():
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                condiciones.append(
                    "(LOWER(p.titulo) LIKE LOWER(%s) "
                    "OR LOWER(d.nombre) LIKE LOWER(%s))"
                )
                texto = f"%{buscar.strip()}%"
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                parametros.extend([texto, texto])
            if condiciones:
                # Prepara la consulta que después se completará con los filtros necesarios.
                sql += " WHERE " + " AND ".join(condiciones)
            # Prepara la consulta que después se completará con los filtros necesarios.
            sql += " ORDER BY p.id_publicacion DESC"
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(sql, tuple(parametros))
            # Recupera todos los registros encontrados.
            publicaciones = cursor.fetchall()
            if not publicaciones:
                return []
            # Reúne los identificadores de las reseñas para consultar sus etiquetas juntas.
            ids = [
                publicacion["id_publicacion"]
                for publicacion in publicaciones
            ]
            # Prepara un espacio %s para cada identificador que se consultará; sus valores se envían por separado.
            espacios = ", ".join(["%s"] * len(ids))
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                f"""
                SELECT
                    pe.id_publicacion,
                    e.nombre
                FROM publicacion_etiqueta AS pe
                JOIN etiquetas AS e
                    ON e.id_etiqueta = pe.id_etiqueta
                WHERE pe.id_publicacion IN ({espacios})
                ORDER BY e.nombre
                """,
                tuple(ids),
            )
            # Agrupa las etiquetas según la reseña a la que pertenecen.
            etiquetas_por_publicacion = {}
            for etiqueta in cursor.fetchall():
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                etiquetas_por_publicacion.setdefault(
                    etiqueta["id_publicacion"],
                    [],
                ).append(etiqueta["nombre"])
            for publicacion in publicaciones:
                publicacion["promedio"] = float(
                    publicacion["promedio"] or 0
                )
                publicacion["total_votos"] = int(
                    publicacion["total_votos"] or 0
                )
                publicacion["etiquetas"] = (
                    etiquetas_por_publicacion.get(
                        publicacion["id_publicacion"],
                        [],
                    )
                )
            return publicaciones
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.get("/api/publicaciones")
# Devuelve el catálogo y aplica la búsqueda opcional recibida por la API.
def obtener_publicaciones(request: Request, buscar: str = ""):
    return preparar_fotos_publicaciones(
        consultar_publicaciones(buscar=buscar), request
    )
@app.get("/api/publicaciones/{id_publicacion}")
# Devuelve una publicación por identificador o responde que no existe.
def obtener_publicacion(id_publicacion: int, request: Request):
    # Guarda las reseñas encontradas para completar su información.
    publicaciones = consultar_publicaciones(
        id_publicacion=id_publicacion,
    )
    if not publicaciones:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=404,
            detail="La publicación no existe.",
        )
    return preparar_fotos_publicaciones(publicaciones, request)[0]
@app.get("/api/publicaciones/{id_publicacion}/comentarios")
# Consulta los comentarios de una publicación y los datos de sus autores.
def obtener_comentarios(id_publicacion: int):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT
                    c.id_comentario,
                    c.id_publicacion,
                    c.id_usuario,
                    c.contenido,
                    c.fecha,
                    COALESCE(u.nombre, 'Usuario') AS usuario
                FROM comentarios AS c
                LEFT JOIN usuarios AS u
                    ON c.id_usuario = u.id_usuario
                WHERE c.id_publicacion = %s
                ORDER BY c.id_comentario DESC
                """,
                (id_publicacion,),
            )
            return cursor.fetchall()
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.get("/api/admin/directores")
# Devuelve los directores para las pantallas administrativas.
def listar_directores(
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT
                    id_director,
                    nombre,
                    COALESCE(
                        NULLIF(foto, ''),
                        'default_director.jpg'
                    ) AS foto
                FROM directores
                ORDER BY id_director DESC
                """
            )
            return cursor.fetchall()
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Guarda un director nuevo o actualiza uno existente.
# Reutiliza las validaciones y operaciones para registrar o editar un director.
def guardar_director(
    # Recibe el nombre que se validará y guardará.
    nombre: str,
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None,
    # Identifica al director seleccionado o que se va a modificar.
    id_director: int | None = None,
):
    # Prepara el nombre que se utilizará en esta operación.
    nombre = nombre.strip()
    if not nombre or len(nombre) > 100:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="El nombre debe contener entre 1 y 100 caracteres.",
        )
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    # Guarda el nombre de la imagen nueva o None si todavía no se ha elegido una.
    nueva_foto = None
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Conserva la referencia de la fotografía que ya tiene el registro.
            foto_actual = "default_director.jpg"
            if id_director is not None:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    SELECT foto
                    FROM directores
                    WHERE id_director = %s
                    FOR UPDATE
                    """,
                    (id_director,),
                )
                # Recupera el registro encontrado; si no existe, el resultado es None.
                director = cursor.fetchone()
                if director is None:
                    # Interrumpe la operación y comunica el error.
                    raise HTTPException(
                        status_code=404,
                        detail="El director no existe.",
                    )
                # Conserva la referencia de la fotografía que ya tiene el registro.
                foto_actual = director["foto"] or foto_actual
            # Guarda el nombre de la imagen nueva o None si todavía no se ha elegido una.
            nueva_foto = guardar_foto(foto)
            nombre_foto = nueva_foto or foto_actual
            if not nombre_foto or nombre_foto == "default_director.jpg":
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=422,
                    detail="Selecciona una fotografía para el director.",
                )
            if id_director is None:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    INSERT INTO directores (nombre, foto)
                    VALUES (%s, %s)
                    """,
                    (nombre, nombre_foto),
                )
                # Recupera el identificador que MySQL acaba de asignar al registro.
                id_director = cursor.lastrowid
            # Ejecuta esta alternativa cuando no se cumple la condición anterior.
            else:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    UPDATE directores
                    SET nombre = %s, foto = %s
                    WHERE id_director = %s
                    """,
                    (nombre, nombre_foto, id_director),
                )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Director guardado correctamente.",
            "director": {
                "id_director": id_director,
                "nombre": nombre,
                "foto": nombre_foto,
            },
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        if nueva_foto:
            # Elimina el archivo indicado sin provocar otro error si ya no existe.
            (CARPETA_PORTADAS / nueva_foto).unlink(missing_ok=True)
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.post("/api/admin/directores", status_code=201)
# Recibe el formulario administrativo y solicita crear un director.
def registrar_director(
    # Recibe el nombre que se validará y guardará.
    nombre: str = Form(...),
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None = File(default=None),
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    return guardar_director(nombre, foto)
@app.put("/api/admin/directores/{id_director}")
# Recibe el formulario administrativo y solicita actualizar un director existente.
def actualizar_director(
    # Identifica al director seleccionado o que se va a modificar.
    id_director: int,
    # Recibe el nombre que se validará y guardará.
    nombre: str = Form(...),
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None = File(default=None),
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    return guardar_director(nombre, foto, id_director)
# Nuevos modelos y funciones para actores.
# Agrupa los campos que se reciben en una solicitud y sus reglas de validación.
# Modelo conservado de la versión anterior: los endpoints actuales de este módulo reciben estos datos con Form y File.
class DatosActor(BaseModel):
    # Define el campo nombre con un límite de 150 caracteres.
    nombre: str = Field(min_length=1, max_length=150)
    # Define el campo foto con un límite de 2048 caracteres.
    foto: str = Field(min_length=1, max_length=2048)
# Comprueba el formato de una dirección web de fotografía. Esta función se conserva, aunque no se llama en este archivo.
def validar_url_foto(foto: str):
    try:
        partes = urlparse(foto)
        valida = (
            partes.scheme.lower() in ("http", "https")
            and bool(partes.hostname)
            and not any(caracter.isspace() for caracter in foto)
        )
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except ValueError:
        valida = False
    if not valida:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="La fotografía debe ser una URL http o https válida.",
        )
@app.get("/api/admin/actores")
# Devuelve los actores registrados y adapta sus fotografías para la app.
def listar_actores(
    # Contiene los datos de la petición; permite construir URLs de imágenes con la dirección del servidor.
    request: Request,
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_actor, nombre, foto
                FROM actores
                ORDER BY id_actor DESC
                """
            )
            # Recupera todos los registros encontrados.
            actores = cursor.fetchall()
            for actor in actores:
                actor["foto"] = foto_para_app(actor.get("foto"), request)
            return actores
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Registra o actualiza un actor, conserva su foto cuando corresponde y deshace cambios si ocurre un error.
def guardar_actor(
    # Recibe el nombre que se validará y guardará.
    nombre: str,
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None,
    # Contiene los datos de la petición; permite construir URLs de imágenes con la dirección del servidor.
    request: Request,
    # Identifica al actor seleccionado o que se va a modificar.
    id_actor: int | None = None,
):
    # Prepara el nombre que se utilizará en esta operación.
    nombre = nombre.strip()
    if not nombre or len(nombre) > 150:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="El nombre debe contener entre 1 y 150 caracteres.",
        )
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    # Guarda el nombre de la imagen nueva o None si todavía no se ha elegido una.
    nueva_foto = None
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Conserva la referencia de la fotografía que ya tiene el registro.
            foto_actual = ""
            if id_actor is not None:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    "SELECT foto FROM actores WHERE id_actor = %s FOR UPDATE",
                    (id_actor,),
                )
                # Recupera el registro encontrado; si no existe, el resultado es None.
                actor = cursor.fetchone()
                if actor is None:
                    # Interrumpe la operación y comunica el error.
                    raise HTTPException(404, detail="El actor no existe.")
                # Conserva la referencia de la fotografía que ya tiene el registro.
                foto_actual = (actor["foto"] or "").strip()
            # Guarda el nombre de la imagen nueva o None si todavía no se ha elegido una.
            nueva_foto = guardar_foto(foto, prefijo="actor")
            nombre_foto = (
                RUTA_FOTOS_API + nueva_foto if nueva_foto else foto_actual
            )
            if not nombre_foto:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=422,
                    detail="Selecciona una fotografía para el actor.",
                )
            if id_actor is None:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    "INSERT INTO actores (nombre, foto) VALUES (%s, %s)",
                    (nombre, nombre_foto),
                )
                # Recupera el identificador que MySQL acaba de asignar al registro.
                id_actor = cursor.lastrowid
            # Ejecuta esta alternativa cuando no se cumple la condición anterior.
            else:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    "UPDATE actores SET nombre = %s, foto = %s WHERE id_actor = %s",
                    (nombre, nombre_foto, id_actor),
                )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        if nueva_foto:
            # Elimina el archivo indicado sin provocar otro error si ya no existe.
            (CARPETA_PORTADAS / nueva_foto).unlink(missing_ok=True)
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
    return {
        "mensaje": "Actor guardado correctamente.",
        "actor": {
            "id_actor": id_actor,
            "nombre": nombre,
            "foto": foto_para_app(nombre_foto, request),
        },
    }
@app.post("/api/admin/actores", status_code=201)
# Recibe nombre y archivo de fotografía para registrar un actor.
def registrar_actor(
    # Contiene los datos de la petición; permite construir URLs de imágenes con la dirección del servidor.
    request: Request,
    # Recibe el nombre que se validará y guardará.
    nombre: str = Form(...),
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None = File(default=None),
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    return guardar_actor(nombre, foto, request)
@app.put("/api/admin/actores/{id_actor}")
# Recibe los cambios de un actor; la fotografía nueva es opcional si ya tiene una.
def actualizar_actor(
    # Identifica al actor seleccionado o que se va a modificar.
    id_actor: int,
    # Contiene los datos de la petición; permite construir URLs de imágenes con la dirección del servidor.
    request: Request,
    # Recibe el nombre que se validará y guardará.
    nombre: str = Form(...),
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None = File(default=None),
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    return guardar_actor(nombre, foto, request, id_actor)
@app.delete("/api/admin/actores/{id_actor}")
# Elimina un actor sin eliminar las reseñas relacionadas.
def eliminar_actor(
    # Identifica al actor seleccionado o que se va a modificar.
    id_actor: int,
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                "DELETE FROM actores WHERE id_actor = %s",
                (id_actor,),
            )
            if cursor.rowcount == 0:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="El actor no existe.",
                )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Actor eliminado correctamente.",
            "id_actor": id_actor,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.get("/api/admin/resenas")
# Devuelve las reseñas para el panel administrativo.
def listar_resenas(
    # Contiene los datos de la petición; permite construir URLs de imágenes con la dirección del servidor.
    request: Request,
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    return preparar_fotos_publicaciones(consultar_publicaciones(), request)
# Convierte las etiquetas separadas por comas en una lista.
# Separa las etiquetas por comas, elimina espacios y evita nombres repetidos.
def preparar_etiquetas(texto: str):
    # Prepara las etiquetas que se relacionarán con la reseña.
    etiquetas = []
    # Recuerda las etiquetas que ya se procesaron para no repetirlas.
    nombres_repetidos = set()
    for parte in texto.split(","):
        # Prepara el nombre que se utilizará en esta operación.
        nombre = parte.strip()
        if not nombre:
            # Omite este elemento y continúa con el siguiente.
            continue
        if len(nombre) > 60:
            # Interrumpe la operación y comunica el error.
            raise HTTPException(
                status_code=422,
                detail="Cada etiqueta admite hasta 60 caracteres.",
            )
        # Prepara el nombre de la etiqueta para compararlo sin distinguir mayúsculas de minúsculas.
        clave = nombre.casefold()
        if clave not in nombres_repetidos:
            # Ejecuta esta operación auxiliar: nombres_repetidos.add(clave).
            nombres_repetidos.add(clave)
            # Añade los valores a la lista que se utilizará en los siguientes pasos.
            etiquetas.append(nombre)
    return etiquetas
# Actualiza las relaciones entre una reseña y sus etiquetas, reutilizando las etiquetas existentes.
def guardar_etiquetas(cursor, id_publicacion: int, etiquetas: list):
    # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
    cursor.execute(
        """
        DELETE FROM publicacion_etiqueta
        WHERE id_publicacion = %s
        """,
        (id_publicacion,),
    )
    for nombre in etiquetas:
        # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
        cursor.execute(
            """
            INSERT INTO etiquetas (nombre)
            VALUES (%s)
            ON DUPLICATE KEY UPDATE nombre = nombre
            """,
            (nombre,),
        )
        # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
        cursor.execute(
            """
            SELECT id_etiqueta
            FROM etiquetas
            WHERE nombre = %s
            """,
            (nombre,),
        )
        # Recupera el registro encontrado; si no existe, el resultado es None.
        etiqueta = cursor.fetchone()
        # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
        cursor.execute(
            """
            INSERT INTO publicacion_etiqueta (
                id_publicacion,
                id_etiqueta
            )
            VALUES (%s, %s)
            ON DUPLICATE KEY UPDATE
                id_etiqueta = VALUES(id_etiqueta)
            """,
            (id_publicacion, etiqueta["id_etiqueta"]),
        )
# Publica o actualiza una reseña dentro de una transacción.
# Valida y guarda una reseña y sus etiquetas dentro de una transacción.
def guardar_resena(
    # Recibe el título de la película o serie.
    titulo: str,
    # Recibe la categoría Película o Serie.
    tipo: str,
    # Identifica al director seleccionado o que se va a modificar.
    id_director: int,
    # Recibe el contenido de la reseña.
    sinopsis: str,
    # Recibe la imagen de portada enviada en el formulario.
    portada: UploadFile | None,
    # Conserva el indicador de reseña destacada que también utiliza el proyecto web.
    destacada: bool,
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int | None = None,
    # Identifica al actor seleccionado o que se va a modificar.
    id_actor: int | None = None,
    # Recibe las etiquetas que se asociarán con la publicación.
    etiquetas: str | None = None,
):
    titulo = titulo.strip()
    sinopsis = sinopsis.strip()
    if not titulo or len(titulo) > 255:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="El título debe contener entre 1 y 255 caracteres.",
        )
    if tipo not in ("Película", "Serie"):
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Selecciona Película o Serie.",
        )
    if not sinopsis:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Escribe la sinopsis.",
        )
    if len(sinopsis.encode("utf-8")) > 65535:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="La sinopsis es demasiado extensa.",
        )
    if id_director <= 0:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Selecciona un director registrado.",
        )
    etiquetas_preparadas = (
        preparar_etiquetas(etiquetas)
        if etiquetas is not None
        else None
    )
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    # Guarda la referencia de la portada nueva para completar o deshacer la operación.
    nueva_portada = None
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_director, nombre
                FROM directores
                WHERE id_director = %s
                FOR UPDATE
                """,
                (id_director,),
            )
            # Recupera el registro encontrado; si no existe, el resultado es None.
            director = cursor.fetchone()
            if director is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=422,
                    detail="El director seleccionado ya no existe.",
                )
            if id_actor is not None:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    SELECT id_actor
                    FROM actores
                    WHERE id_actor = %s
                    FOR UPDATE
                    """,
                    (id_actor,),
                )
                if cursor.fetchone() is None:
                    # Interrumpe la operación y comunica el error.
                    raise HTTPException(
                        status_code=422,
                        detail="Selecciona un actor registrado.",
                    )
            # Bloquea las reseñas antes de cambiar la destacada.
            if destacada:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    SELECT id_publicacion
                    FROM publicaciones
                    ORDER BY id_publicacion
                    FOR UPDATE
                    """
                )
                # Ejecuta esta operación auxiliar: cursor.fetchall().
                cursor.fetchall()
            # Conserva la portada existente si no se envía otra imagen.
            portada_actual = "default_cover.jpg"
            if id_publicacion is not None:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    SELECT imagen, id_actor
                    FROM publicaciones
                    WHERE id_publicacion = %s
                    FOR UPDATE
                    """,
                    (id_publicacion,),
                )
                # Recupera el registro encontrado; si no existe, el resultado es None.
                publicacion = cursor.fetchone()
                if publicacion is None:
                    # Interrumpe la operación y comunica el error.
                    raise HTTPException(
                        status_code=404,
                        detail="La reseña no existe.",
                    )
                # Conserva la portada existente si no se envía otra imagen.
                portada_actual = (
                    publicacion["imagen"] or portada_actual
                )
                # Conserva el actor si Flutter todavía no envía el campo.
                if id_actor is None:
                    id_actor = publicacion["id_actor"]
            # Guarda la referencia de la portada nueva para completar o deshacer la operación.
            nueva_portada = guardar_foto(
                portada,
                prefijo="pub",
            )
            nombre_portada = nueva_portada or portada_actual
            if destacada:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    "UPDATE publicaciones SET destacada = %s",
                    (0,),
                )
            if id_publicacion is None:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    INSERT INTO publicaciones (
                        titulo, tipo, id_director, id_actor,
                        contenido, imagen, destacada
                    )
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        titulo,
                        tipo,
                        id_director,
                        id_actor,
                        sinopsis,
                        nombre_portada,
                        int(destacada),
                    ),
                )
                # Recupera el identificador que MySQL acaba de asignar al registro.
                id_publicacion = cursor.lastrowid
            # Ejecuta esta alternativa cuando no se cumple la condición anterior.
            else:
                # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
                cursor.execute(
                    """
                    UPDATE publicaciones
                    SET
                        titulo = %s,
                        tipo = %s,
                        id_director = %s,
                        id_actor = %s,
                        contenido = %s,
                        imagen = %s,
                        destacada = %s
                    WHERE id_publicacion = %s
                    """,
                    (
                        titulo,
                        tipo,
                        id_director,
                        id_actor,
                        sinopsis,
                        nombre_portada,
                        int(destacada),
                        id_publicacion,
                    ),
                )
            # Si el campo no se envía, conserva las etiquetas existentes.
            if etiquetas_preparadas is not None:
                # Ejecuta esta operación auxiliar: guardar_etiquetas(cursor, id_publicacion, etiquetas_preparadas).
                guardar_etiquetas(
                    cursor,
                    id_publicacion,
                    etiquetas_preparadas,
                )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Reseña guardada correctamente.",
            "publicacion": {
                "id_publicacion": id_publicacion,
                "id_director": id_director,
                "id_actor": id_actor,
                "titulo": titulo,
                "tipo": tipo,
                "sinopsis": sinopsis,
                "portada": nombre_portada,
                "director": director["nombre"],
                "destacada": int(destacada),
            },
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        if nueva_portada:
            # Elimina el archivo indicado sin provocar otro error si ya no existe.
            (CARPETA_PORTADAS / nueva_portada).unlink(
                missing_ok=True
            )
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.post("/api/admin/resenas", status_code=201)
# Recibe el formulario administrativo de una nueva reseña.
def publicar_resena(
    # Recibe el título de la película o serie.
    titulo: str = Form(...),
    # Recibe la categoría Película o Serie.
    tipo: str = Form(...),
    # Identifica al director seleccionado o que se va a modificar.
    id_director: int = Form(...),
    # Recibe el contenido de la reseña.
    sinopsis: str = Form(...),
    # Recibe la imagen de portada enviada en el formulario.
    portada: UploadFile | None = File(default=None),
    # Conserva el indicador de reseña destacada que también utiliza el proyecto web.
    destacada: bool = Form(False),
    # Identifica al actor seleccionado o que se va a modificar.
    id_actor: int | None = Form(default=None),
    # Recibe las etiquetas que se asociarán con la publicación.
    etiquetas: str | None = Form(default=None),
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    return guardar_resena(
        titulo,
        tipo,
        id_director,
        sinopsis,
        portada,
        destacada,
        id_actor=id_actor,
        etiquetas=etiquetas,
    )
@app.put("/api/admin/resenas/{id_publicacion}")
# Recibe el formulario para editar una reseña existente.
def actualizar_resena(
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int,
    # Recibe el título de la película o serie.
    titulo: str = Form(...),
    # Recibe la categoría Película o Serie.
    tipo: str = Form(...),
    # Identifica al director seleccionado o que se va a modificar.
    id_director: int = Form(...),
    # Recibe el contenido de la reseña.
    sinopsis: str = Form(...),
    # Recibe la imagen de portada enviada en el formulario.
    portada: UploadFile | None = File(default=None),
    # Conserva el indicador de reseña destacada que también utiliza el proyecto web.
    destacada: bool = Form(False),
    # Identifica al actor seleccionado o que se va a modificar.
    id_actor: int | None = Form(default=None),
    # Recibe las etiquetas que se asociarán con la publicación.
    etiquetas: str | None = Form(default=None),
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    return guardar_resena(
        titulo,
        tipo,
        id_director,
        sinopsis,
        portada,
        destacada,
        id_publicacion,
        id_actor=id_actor,
        etiquetas=etiquetas,
    )
@app.delete("/api/admin/resenas/{id_publicacion}")
# Elimina una reseña y gestiona sus registros relacionados.
def eliminar_resena(
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int,
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_publicacion
                FROM publicaciones
                WHERE id_publicacion = %s
                FOR UPDATE
                """,
                (id_publicacion,),
            )
            if cursor.fetchone() is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="La reseña no existe.",
                )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                "DELETE FROM comentarios WHERE id_publicacion = %s",
                (id_publicacion,),
            )
            comentarios_eliminados = cursor.rowcount
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                "DELETE FROM publicaciones WHERE id_publicacion = %s",
                (id_publicacion,),
            )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Reseña y comentarios eliminados correctamente.",
            "id_publicacion": id_publicacion,
            "comentarios_eliminados": comentarios_eliminados,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Lista los comentarios para su moderación.
@app.get("/api/admin/comentarios")
# Consulta los comentarios que el administrador puede moderar.
def listar_comentarios_admin(
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT
                    c.id_comentario,
                    c.id_publicacion,
                    c.id_usuario,
                    c.contenido,
                    c.fecha,
                    COALESCE(u.nombre, 'Usuario') AS usuario,
                    COALESCE(p.titulo, 'Publicación no disponible')
                        AS publicacion
                FROM comentarios AS c
                LEFT JOIN usuarios AS u
                    ON c.id_usuario = u.id_usuario
                LEFT JOIN publicaciones AS p
                    ON c.id_publicacion = p.id_publicacion
                ORDER BY c.fecha DESC, c.id_comentario DESC
                """
            )
            return cursor.fetchall()
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Elimina únicamente el comentario seleccionado.
@app.delete("/api/admin/comentarios/{id_comentario}")
# Permite al administrador eliminar un comentario.
def eliminar_comentario_admin(
    # Recibe el parámetro id_comentario para esta operación.
    id_comentario: int,
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                DELETE FROM comentarios
                WHERE id_comentario = %s
                """,
                (id_comentario,),
            )
            if cursor.rowcount == 0:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="El comentario ya no existe.",
                )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Comentario eliminado correctamente.",
            "id_comentario": id_comentario,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Consulta las cuentas sin exponer contraseñas ni sus hashes.
@app.get("/api/admin/usuarios")
# Consulta las cuentas de lectores para su gestión administrativa.
def listar_usuarios(
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT
                    id_usuario,
                    nombre,
                    correo,
                    rol
                FROM usuarios
                ORDER BY id_usuario DESC
                """
            )
            return cursor.fetchall()
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Elimina lectores y protege la cuenta administrativa.
@app.delete("/api/admin/usuarios/{id_usuario}")
# Valida las restricciones y elimina una cuenta autorizada.
def eliminar_usuario(
    # Identifica la cuenta de usuario.
    id_usuario: int,
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    if (
        id_usuario == 1
        or id_usuario == int(administrador["id_usuario"])
    ):
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=403,
            detail="No puedes eliminar la cuenta del administrador.",
        )
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario, rol
                FROM usuarios
                WHERE id_usuario = %s
                FOR UPDATE
                """,
                (id_usuario,),
            )
            # Recupera el registro encontrado; si no existe, el resultado es None.
            usuario = cursor.fetchone()
            if usuario is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="El usuario ya no existe.",
                )
            if usuario["rol"] != "Lector":
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=403,
                    detail="Solo puedes eliminar cuentas de lectores.",
                )
            # Conserva tu comprobación de comentarios.
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_comentario
                FROM comentarios
                WHERE id_usuario = %s
                LIMIT 1
                """,
                (id_usuario,),
            )
            if cursor.fetchone() is not None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=409,
                    detail=(
                        "El usuario tiene comentarios publicados. "
                        "Revísalos desde Moderación antes de eliminar "
                        "su cuenta."
                    ),
                )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                DELETE FROM usuarios
                WHERE id_usuario = %s
                """,
                (id_usuario,),
            )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Usuario eliminado correctamente.",
            "id_usuario": id_usuario,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except pymysql.err.IntegrityError:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=409,
            detail=(
                "No se puede eliminar la cuenta porque tiene "
                "otros registros asociados."
            ),
        )
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# El formulario público no acepta un campo de rol.
# Agrupa los campos que se reciben en una solicitud y sus reglas de validación.
class DatosRegistro(BaseModel):
    model_config = {"extra": "forbid"}
    # Define el campo nombre con un límite de 100 caracteres.
    nombre: str = Field(min_length=1, max_length=100)
    # Define el campo correo con un límite de 254 caracteres.
    correo: str = Field(min_length=1, max_length=254)
    # Recibe la contraseña; su tamaño en bytes se revisa antes de guardarla.
    password: str = Field(min_length=1, max_length=4096)
    # Recibe la confirmación para comprobar que ambas contraseñas coincidan.
    confirm_password: str = Field(min_length=1, max_length=4096)
# Registra exclusivamente cuentas de lectores.
@app.post("/api/registro", status_code=201)
# Valida el registro, comprueba el correo y guarda la contraseña como hash; el rol siempre es Lector.
def registrar_lector(datos: DatosRegistro):
    # Prepara el nombre que se utilizará en esta operación.
    nombre = datos.nombre.strip()
    correo = datos.correo.strip()
    if not nombre:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Escribe tu nombre.",
        )
    # Validación básica del formato del correo.
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", correo):
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Escribe un correo electrónico válido.",
        )
    if datos.password != datos.confirm_password:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Las contraseñas no coinciden.",
        )
    # Convierte la contraseña a bytes para revisar el tamaño que admite bcrypt.
    password_bytes = datos.password.encode("utf-8")
    if len(password_bytes) > 72:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="La contraseña admite un máximo de 72 bytes.",
        )
    if b"\x00" in password_bytes:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="La contraseña contiene un carácter no permitido.",
        )
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario
                FROM usuarios
                WHERE correo = %s
                LIMIT 1
                """,
                (correo,),
            )
            if cursor.fetchone() is not None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=409,
                    detail="El correo electrónico ya está registrado.",
                )
            # Hash compatible con password_verify de PHP.
            # Prepara el hash de la contraseña o su valor inicial cuando todavía no hay cambio.
            password_hash = bcrypt.hashpw(
                password_bytes,
                bcrypt.gensalt(rounds=12),
            ).decode("utf-8")
            # El rol se asigna en el servidor.
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                INSERT INTO usuarios (
                    nombre,
                    correo,
                    password,
                    rol
                )
                VALUES (%s, %s, %s, %s)
                """,
                (
                    nombre,
                    correo,
                    password_hash,
                    "Lector",
                ),
            )
            # Recupera el identificador que MySQL acaba de asignar al registro.
            id_usuario = cursor.lastrowid
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Cuenta creada correctamente. Inicia sesión.",
            "usuario": {
                "id_usuario": id_usuario,
                "nombre": nombre,
                "correo": correo,
                "rol": "Lector",
            },
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except pymysql.err.IntegrityError as error:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        if error.args[0] == 1062:
            # Interrumpe la operación y comunica el error.
            raise HTTPException(
                status_code=409,
                detail="El correo electrónico ya está registrado.",
            )
        # Interrumpe la operación y comunica el error.
        raise
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Agrupa los campos que se reciben en una solicitud y sus reglas de validación.
class DatosComentario(BaseModel):
    # Define el campo contenido con un límite de 500 caracteres.
    contenido: str = Field(min_length=1, max_length=500)
    emoji: str = "\U0001F9DF"
    # Configura las reglas del modelo de datos.
    class Config:
        extra = "forbid"
@app.post(
    "/api/publicaciones/{id_publicacion}/comentarios",
    status_code=201,
)
# Valida y publica un comentario del lector en una reseña.
def publicar_comentario(
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int,
    # Recibe los datos JSON ya validados mediante el modelo correspondiente.
    datos: DatosComentario,
    # Recibe la cuenta autorizada como lector.
    lector: dict = Depends(exigir_lector),
):
    texto = datos.contenido.strip()
    emojis_permitidos = {
        "\U0001F9DF",  # Zombi
        "\U0001F383",  # Calabaza
        "\U0001F47B",  # Fantasma
        "\U0001F480",  # Calavera
        "\U0001F47D",  # Alien
    }
    if not texto:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Escribe un comentario antes de publicarlo.",
        )
    if datos.emoji not in emojis_permitidos:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Selecciona una de las reacciones disponibles.",
        )
    # Lee el contenido de la imagen para revisar su tamaño y formato.
    contenido = f"{datos.emoji} {texto}"
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_publicacion
                FROM publicaciones
                WHERE id_publicacion = %s
                FOR UPDATE
                """,
                (id_publicacion,),
            )
            if cursor.fetchone() is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="La publicación ya no existe.",
                )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                INSERT INTO comentarios (
                    id_publicacion,
                    id_usuario,
                    contenido,
                    fecha
                )
                VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
                """,
                (
                    id_publicacion,
                    lector["id_usuario"],
                    contenido,
                ),
            )
            # Recupera el identificador que MySQL acaba de asignar al registro.
            id_comentario = cursor.lastrowid
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Comentario publicado correctamente.",
            "id_comentario": id_comentario,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.delete("/api/comentarios/{id_comentario}")
# Comprueba la propiedad del comentario antes de permitir que el lector lo elimine.
def eliminar_comentario_propio(
    # Recibe el parámetro id_comentario para esta operación.
    id_comentario: int,
    # Recibe la cuenta autorizada como lector.
    lector: dict = Depends(exigir_lector),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario
                FROM comentarios
                WHERE id_comentario = %s
                FOR UPDATE
                """,
                (id_comentario,),
            )
            # Recupera el registro encontrado; si no existe, el resultado es None.
            comentario = cursor.fetchone()
            if comentario is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="El comentario ya no existe.",
                )
            if (
                int(comentario["id_usuario"])
                != int(lector["id_usuario"])
            ):
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=403,
                    detail="Solo puedes eliminar tus propios comentarios.",
                )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                DELETE FROM comentarios
                WHERE id_comentario = %s
                  AND id_usuario = %s
                """,
                (id_comentario, lector["id_usuario"]),
            )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Comentario eliminado correctamente.",
            "id_comentario": id_comentario,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Nuevas funciones para consultar y actualizar el perfil.
# Agrupa los campos que se reciben en una solicitud y sus reglas de validación.
# Modelo conservado de la versión anterior: los endpoints actuales de este módulo reciben estos datos con Form y File.
class DatosPerfil(BaseModel):
    model_config = {"extra": "forbid"}
    # Define el campo nombre con un límite de 100 caracteres.
    nombre: str = Field(min_length=1, max_length=100)
    # Define el campo correo con un límite de 254 caracteres.
    correo: str = Field(min_length=1, max_length=254)
    # Define el campo foto con un límite de 255 caracteres.
    foto: str | None = Field(default=None, max_length=255)
    # Recibe la contraseña; su tamaño en bytes se revisa antes de guardarla.
    password: str | None = Field(default=None, max_length=4096)
@app.get("/api/perfil")
# Consulta el perfil de la cuenta autenticada, sin devolver su contraseña ni su hash.
def obtener_perfil(
    # Contiene los datos de la petición; permite construir URLs de imágenes con la dirección del servidor.
    request: Request,
    # Recibe la cuenta autenticada después de comprobar su token.
    usuario: dict = Depends(exigir_usuario),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario, nombre, correo, rol, foto
                FROM usuarios
                WHERE id_usuario = %s
                """,
                (usuario["id_usuario"],),
            )
            # Recupera el registro encontrado; si no existe, el resultado es None.
            perfil = cursor.fetchone()
            if perfil is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="La cuenta no existe.",
                )
            perfil["foto"] = foto_para_app(perfil.get("foto"), request)
            return perfil
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.put("/api/perfil")
# Actualiza nombre, correo y, si se solicita, fotografía o contraseña de la propia cuenta.
def actualizar_perfil(
    # Contiene los datos de la petición; permite construir URLs de imágenes con la dirección del servidor.
    request: Request,
    # Recibe el nombre que se validará y guardará.
    nombre: str = Form(..., min_length=1, max_length=100),
    # Recibe el correo que se validará y guardará.
    correo: str = Form(..., min_length=1, max_length=254),
    # Recibe el archivo de imagen; None significa que no se envió uno.
    foto: UploadFile | None = File(default=None),
    # Indica si se solicita retirar la fotografía actual del perfil.
    quitar_foto: bool = Form(False),
    # Recibe la contraseña; en la edición del perfil es opcional.
    password: str | None = Form(default=None, max_length=4096),
    # Recibe la cuenta autenticada después de comprobar su token.
    usuario: dict = Depends(exigir_usuario),
):
    # Prepara el nombre que se utilizará en esta operación.
    nombre = nombre.strip()
    correo = correo.strip()
    if not nombre:
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="El nombre no puede estar vacío.",
        )
    if not re.fullmatch(r"[^@\s]+@[^@\s]+\.[^@\s]+", correo):
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=422,
            detail="Escribe un correo electrónico válido.",
        )
    # Prepara el hash de la contraseña o su valor inicial cuando todavía no hay cambio.
    password_hash = None
    if password:
        # Convierte la contraseña a bytes para revisar el tamaño que admite bcrypt.
        password_bytes = password.encode("utf-8")
        if len(password_bytes) > 72:
            # Interrumpe la operación y comunica el error.
            raise HTTPException(
                status_code=422,
                detail="La contraseña admite un máximo de 72 bytes.",
            )
        if b"\x00" in password_bytes:
            # Interrumpe la operación y comunica el error.
            raise HTTPException(
                status_code=422,
                detail="La contraseña contiene un carácter no permitido.",
            )
        # Prepara el hash de la contraseña o su valor inicial cuando todavía no hay cambio.
        password_hash = bcrypt.hashpw(
            password_bytes,
            bcrypt.gensalt(rounds=12),
        ).decode("utf-8")
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    # Guarda el nombre de la imagen nueva o None si todavía no se ha elegido una.
    nueva_foto = None
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario
                FROM usuarios
                WHERE correo = %s
                  AND id_usuario <> %s
                LIMIT 1
                """,
                (correo, usuario["id_usuario"]),
            )
            if cursor.fetchone() is not None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=409,
                    detail="Ese correo ya pertenece a otra cuenta.",
                )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                "SELECT id_usuario FROM usuarios WHERE id_usuario = %s FOR UPDATE",
                (usuario["id_usuario"],),
            )
            if cursor.fetchone() is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(404, detail="La cuenta no existe.")
            # Guarda el nombre de la imagen nueva o None si todavía no se ha elegido una.
            nueva_foto = guardar_foto(foto, prefijo="perfil")
            # Reúne únicamente los campos del perfil que se van a modificar.
            cambios = ["nombre = %s", "correo = %s"]
            # Reúne los valores que se enviarán junto con la consulta.
            parametros = [nombre, correo]
            if nueva_foto or quitar_foto:
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                cambios.append("foto = %s")
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                parametros.append(
                    RUTA_FOTOS_API + nueva_foto if nueva_foto else None
                )
            if password_hash is not None:
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                cambios.append("password = %s")
                # Añade los valores a la lista que se utilizará en los siguientes pasos.
                parametros.append(password_hash)
            # Añade los valores a la lista que se utilizará en los siguientes pasos.
            parametros.append(usuario["id_usuario"])
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                "UPDATE usuarios SET "
                + ", ".join(cambios)
                + " WHERE id_usuario = %s",
                tuple(parametros),
            )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_usuario, nombre, correo, rol, foto
                FROM usuarios
                WHERE id_usuario = %s
                """,
                (usuario["id_usuario"],),
            )
            # Recupera el registro encontrado; si no existe, el resultado es None.
            perfil = cursor.fetchone()
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        perfil["foto"] = foto_para_app(perfil.get("foto"), request)
        return {
            "mensaje": "Perfil actualizado correctamente.",
            "usuario": perfil,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except pymysql.err.IntegrityError as error:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        if nueva_foto:
            # Elimina el archivo indicado sin provocar otro error si ya no existe.
            (CARPETA_PORTADAS / nueva_foto).unlink(missing_ok=True)
        if error.args[0] == 1062:
            # Interrumpe la operación y comunica el error.
            raise HTTPException(
                status_code=409,
                detail="Ese correo ya pertenece a otra cuenta.",
            )
        # Interrumpe la operación y comunica el error.
        raise
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        if nueva_foto:
            # Elimina el archivo indicado sin provocar otro error si ya no existe.
            (CARPETA_PORTADAS / nueva_foto).unlink(missing_ok=True)
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
# Agrupa los campos que se reciben en una solicitud y sus reglas de validación.
class DatosCalificacion(BaseModel):
    model_config = {"extra": "forbid"}
    # Acepta únicamente un número entero entre 1 y 5.
    estrellas: int = Field(strict=True, ge=1, le=5)
# Calcula el promedio, cuenta los votos y obtiene las estrellas del usuario actual.
def consultar_calificacion(
    # Recibe el cursor de una conexión abierta para ejecutar consultas.
    cursor,
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int,
    # Identifica la cuenta de usuario.
    id_usuario: int,
):
    # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
    cursor.execute(
        """
        SELECT
            ROUND(AVG(estrellas), 1) AS promedio,
            COUNT(*) AS total_votos
        FROM calificaciones
        WHERE id_publicacion = %s
        """,
        (id_publicacion,),
    )
    # Recupera el registro encontrado; si no existe, el resultado es None.
    resumen = cursor.fetchone()
    # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
    cursor.execute(
        """
        SELECT estrellas
        FROM calificaciones
        WHERE id_publicacion = %s
          AND id_usuario = %s
        """,
        (id_publicacion, id_usuario),
    )
    # Recupera el registro encontrado; si no existe, el resultado es None.
    voto = cursor.fetchone()
    return {
        "id_publicacion": id_publicacion,
        "promedio": float(resumen["promedio"] or 0),
        "total_votos": int(resumen["total_votos"]),
        "mi_voto": int(voto["estrellas"]) if voto else None,
    }
@app.get("/api/publicaciones/{id_publicacion}/calificaciones")
# Comprueba que la reseña existe y devuelve su resumen de calificaciones.
def obtener_calificaciones(
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int,
    # Recibe la cuenta autenticada después de comprobar su token.
    usuario: dict = Depends(exigir_usuario),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_publicacion
                FROM publicaciones
                WHERE id_publicacion = %s
                """,
                (id_publicacion,),
            )
            if cursor.fetchone() is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="La publicación no existe.",
                )
            return consultar_calificacion(
                cursor,
                id_publicacion,
                usuario["id_usuario"],
            )
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.post("/api/publicaciones/{id_publicacion}/calificaciones")
# Guarda o actualiza el voto del lector: la restricción única de la base permite un voto por cuenta y reseña.
def guardar_calificacion(
    # Identifica la reseña sobre la que se realiza la operación.
    id_publicacion: int,
    # Recibe los datos JSON ya validados mediante el modelo correspondiente.
    datos: DatosCalificacion,
    # Recibe la cuenta autorizada como lector.
    lector: dict = Depends(exigir_lector),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_publicacion
                FROM publicaciones
                WHERE id_publicacion = %s
                FOR UPDATE
                """,
                (id_publicacion,),
            )
            if cursor.fetchone() is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="La publicación no existe.",
                )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                INSERT INTO calificaciones (
                    id_publicacion,
                    id_usuario,
                    estrellas
                )
                VALUES (%s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    estrellas = VALUES(estrellas)
                """,
                (
                    id_publicacion,
                    lector["id_usuario"],
                    datos.estrellas,
                ),
            )
            # Prepara los datos que se devolverán cuando termine la operación.
            resultado = consultar_calificacion(
                cursor,
                id_publicacion,
                lector["id_usuario"],
            )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Calificación guardada correctamente.",
            **resultado,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
@app.delete("/api/admin/directores/{id_director}")
# Desvincula al director de sus reseñas y lo elimina, conservando las publicaciones.
def eliminar_director(
    # Identifica al director seleccionado o que se va a modificar.
    id_director: int,
    # Exige que quien llama sea el administrador autorizado.
    administrador: dict = Depends(exigir_administrador),
):
    # Abre la conexión que se utilizará en esta operación.
    conexion = conectar()
    try:
        # Prepara el cursor para ejecutar las consultas y lo cierra al salir de este bloque.
        with conexion.cursor() as cursor:
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                SELECT id_director
                FROM directores
                WHERE id_director = %s
                FOR UPDATE
                """,
                (id_director,),
            )
            if cursor.fetchone() is None:
                # Interrumpe la operación y comunica el error.
                raise HTTPException(
                    status_code=404,
                    detail="El director ya no existe.",
                )
            # Conserva las reseñas antes de borrar al director.
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                UPDATE publicaciones
                SET id_director = NULL
                WHERE id_director = %s
                """,
                (id_director,),
            )
            # Ejecuta la consulta enviando los valores por separado de la instrucción SQL.
            cursor.execute(
                """
                DELETE FROM directores
                WHERE id_director = %s
                """,
                (id_director,),
            )
        # Confirma los cambios para que queden guardados en MySQL.
        conexion.commit()
        return {
            "mensaje": "Director eliminado correctamente.",
            "id_director": id_director,
        }
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except pymysql.err.IntegrityError:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise HTTPException(
            status_code=409,
            detail=(
                "No se pudo eliminar el director porque "
                "la base de datos impide desvincular sus reseñas."
            ),
        )
    # Atiende este error para informar del problema y deshacer cambios cuando sea necesario.
    except Exception:
        # Deshace los cambios que todavía no se habían confirmado.
        conexion.rollback()
        # Interrumpe la operación y comunica el error.
        raise
    # Este paso se realiza al terminar, aunque haya ocurrido un error.
    finally:
        # Cierra la conexión con la base de datos al terminar.
        conexion.close()
