# Cruppis — Aplicación móvil

## Descripción del proyecto

Cruppis es una aplicación móvil dedicada a la consulta y publicación de reseñas de películas y series de terror. Permite explorar un catálogo visual, buscar producciones, consultar su información y participar mediante comentarios, reacciones y calificaciones con estrellas.

La aplicación cuenta con dos tipos de usuario: Lector y Administrador. Los lectores pueden consultar las reseñas, participar en la comunidad y actualizar su perfil. El administrador dispone de herramientas para gestionar directores, actores, reseñas, comentarios y cuentas de lectores.

La interfaz está desarrollada con Flutter y utiliza una API REST construida con FastAPI para comunicarse con una base de datos MySQL. La aplicación móvil no accede directamente a la base de datos.

## Objetivo

Ofrecer una aplicación móvil que permita consultar reseñas de terror y compartir opiniones desde una interfaz organizada, con navegación táctil y funciones diferenciadas según el rol del usuario.

## Tecnologías utilizadas

 Tecnología        Función dentro del proyecto 

 Flutter           Desarrollo de la interfaz y navegación de la aplicación móvil. 
 Dart              Implementación de la lógica de la aplicación. 
 FastAPI           Creación de los servicios que atienden las solicitudes de la app. 
 Python            Implementación de la lógica del backend. 
 MySQL             Almacenamiento de usuarios, reseñas y participación comunitaria. 
 HTTP y JSON       Intercambio de solicitudes y respuestas entre Flutter y la API. 
 JWT               Autenticación de las solicitudes que requieren una sesión válida. 
 bcrypt            Almacenamiento de contraseñas mediante hashes. 
 Flutter Secure Storage  Almacenamiento local del token de sesión. 
 Image Picker       Selección de fotografías desde la galería del dispositivo. 

## Organización y comunicación del sistema

El funcionamiento de Cruppis se divide en tres partes:

1. La aplicación Flutter presenta las pantallas y recibe las acciones del usuario.
2. La API REST valida las solicitudes, comprueba los permisos y procesa las operaciones.
3. MySQL almacena y proporciona la información solicitada por la API.

Por ejemplo, cuando un lector publica un comentario, Flutter envía el contenido y el token de sesión a FastAPI. El servidor verifica la identidad del usuario, valida los datos y guarda el comentario en MySQL. Finalmente, devuelve una respuesta que la aplicación muestra en pantalla.

## Requisitos previos

Para ejecutar la aplicación desde el código fuente se necesita:

- Flutter instalado y disponible desde la terminal.
- Dart, incluido con el SDK de Flutter.
- Android SDK y sus herramientas de desarrollo.
- Un emulador de Android configurado o un dispositivo físico preparado para desarrollo.
- Python y las dependencias del backend.
- MySQL en ejecución y la base de datos del proyecto importada.
- Acceso a los archivos del proyecto.
- Conexión entre el dispositivo donde se ejecuta la app y la computadora que aloja la API.

El entorno Android definido en los requisitos del proyecto es Android 8.0 o superior. La compatibilidad debe comprobarse mediante la configuración del proyecto y las pruebas de instalación correspondientes.

## Preparación del backend

La aplicación necesita que el backend esté disponible para iniciar sesión, consultar información y guardar cambios.

### 1. Preparar la base de datos

Iniciar MySQL e importar el archivo SQL entregado con el proyecto.

La base de datos del proyecto de equipo se llama:

    crupis

Revisar que la función de conexión de backend/main.py utilice el nombre de la base de datos y las credenciales correctas del entorno local.

### 2. Instalar las dependencias de Python

Abrir una terminal dentro de la carpeta backend.

Si todavía no existe el entorno virtual, crearlo con:

    python -m venv .venv

En Windows, instalar las dependencias con:

    .\.venv\Scripts\python.exe -m pip install fastapi "uvicorn[standard]" pymysql bcrypt PyJWT python-multipart

Si el proyecto incluye un archivo requirements.txt actualizado, instalar las dependencias indicadas en ese archivo:

    .\.venv\Scripts\python.exe -m pip install -r requirements.txt

### 3. Iniciar la API

Desde la carpeta backend ejecutar:

    .\.venv\Scripts\python.exe -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

Mantener esta terminal abierta mientras se utiliza la aplicación.

La opción --reload reinicia el servidor cuando se modifica el código del backend y se utiliza durante el desarrollo.

### 4. Comprobar que el servidor responde

Desde el navegador de la computadora abrir:

    http://127.0.0.1:8000/docs

Esta dirección permite consultar la documentación interactiva de los servicios de la API.

La dirección 0.0.0.0 se utiliza al iniciar el servidor para escuchar conexiones; para abrir la documentación en la misma computadora se utiliza 127.0.0.1.

## Instalación y ejecución de la aplicación móvil

### 1. Abrir la carpeta del proyecto

Abrir la carpeta flutter_app en el editor de código y una terminal ubicada dentro de ella.

Esta carpeta contiene el archivo pubspec.yaml, las dependencias y el código fuente de la aplicación.

### 2. Comprobar el entorno de Flutter

Ejecutar:

    flutter doctor

Revisar los resultados y resolver los problemas que afecten al desarrollo para Android antes de continuar.

### 3. Instalar las dependencias

Ejecutar:

    flutter pub get

El comando descarga las dependencias declaradas en pubspec.yaml.

### 4. Preparar el dispositivo

Iniciar el emulador de Android y esperar a que termine de cargar la pantalla de inicio.

Consultar los dispositivos disponibles con:

    flutter devices

Identificar el dispositivo donde se ejecutará la aplicación.

### 5. Revisar la dirección del servidor

Cuando se utiliza el emulador de Android, la aplicación accede al backend mediante:

    http://10.0.2.2:8000

Esta dirección permite que el emulador se comunique con el servidor que está ejecutándose en la computadora.

### 6. Ejecutar la aplicación

Usar el identificador mostrado por flutter devices:

    flutter run -d IDENTIFICADOR_DEL_DISPOSITIVO

Ejemplo:

    flutter run -d emulator-5554

Esperar a que Flutter termine de compilar, instalar y abrir la aplicación. La primera ejecución puede tardar más porque se preparan las herramientas y dependencias de Android.

## Ejecución en un teléfono físico

Para probar la aplicación en un teléfono Android:

1. Conectar la computadora y el teléfono a la misma red Wi-Fi.
2. Habilitar las opciones de desarrollador y la depuración USB en el teléfono.
3. Conectar el teléfono a la computadora mediante un cable USB.
4. Autorizar la depuración cuando el teléfono lo solicite.
5. Ejecutar flutter devices y comprobar que el teléfono aparece en la lista.
6. Obtener la dirección IPv4 de la computadora mediante ipconfig.
7. Sustituir 10.0.2.2 por esa dirección en las direcciones del backend utilizadas por Flutter.
8. Mantener el puerto 8000 en las direcciones de conexión.
9. Comprobar que el firewall permita el acceso al backend desde la red local.
10. Ejecutar flutter run con el identificador del teléfono.

Ejemplo de dirección del backend en una red local:

    http://192.168.1.10:8000

La dirección anterior es únicamente un ejemplo. Debe reemplazarse por la IPv4 real de la computadora.

Antes de abrir la aplicación, puede comprobarse la conexión desde el navegador del teléfono accediendo a la dirección del backend seguida de /docs.

## Uso como lector

### Registro de una cuenta

En la pantalla de inicio de sesión, seleccionar la opción de registro.

Completar los datos solicitados y confirmar el formulario. El registro público crea únicamente cuentas con rol de Lector.

El sistema valida la información y comprueba que el correo electrónico no esté registrado previamente. Una vez creada la cuenta, el usuario puede iniciar sesión.

### Inicio de sesión

Introducir el correo electrónico y la contraseña de una cuenta registrada.

La aplicación envía las credenciales a la API. Si son correctas, permite el acceso a las funciones correspondientes al usuario. Si son incorrectas, muestra un mensaje de error.

La contraseña permanece oculta en pantalla y puede mostrarse temporalmente mediante el botón de visibilidad.

### Pantalla de Inicio

Inicio presenta un banner con la última reseña agregada y una cuadrícula con las publicaciones adicionales.

Las tarjetas muestran la portada, el tipo de producción y el título. Al tocar una tarjeta se abre la pantalla de detalle.

Para obtener los datos más recientes del catálogo, deslizar hacia abajo.

### Búsqueda de reseñas

Seleccionar Buscar en la barra de navegación inferior.

Escribir parte del título, el nombre del director o el nombre del actor para filtrar las publicaciones.

El botón con el icono X permite vaciar el campo y volver a mostrar el catálogo completo.

### Consulta del detalle

Al seleccionar una publicación se muestra su información, que incluye:

- Portada.
- Tipo: película o serie.
- Título.
- Etiquetas.
- Sinopsis.
- Información del director.
- Información del actor.
- Calificaciones.
- Comentarios de la comunidad.

Las etiquetas y la información de las personas relacionadas se consultan dentro del detalle.

### Comentarios y reacciones

Escribir una opinión en el campo de comentarios y seleccionar una reacción temática de terror.

Cada comentario admite un máximo de 500 caracteres. La aplicación impide escribir por encima de ese límite.

Al enviar el comentario, la API comprueba la sesión y guarda la participación del lector.

Cada lector puede eliminar sus propios comentarios mediante la opción correspondiente y su confirmación. No puede eliminar los comentarios de otros usuarios.

Para actualizar la información de la sección, deslizar hacia abajo en la pantalla de detalle.

### Calificación con estrellas

Seleccionar una calificación de una a cinco estrellas dentro del detalle de la reseña.

El sistema registra el voto del lector y muestra el promedio y la cantidad de votos. Si el usuario modifica su calificación, se actualiza su voto existente.

### Edición del perfil

Seleccionar Perfil desde la barra de navegación inferior.

Desde esta pantalla se pueden modificar el nombre, el correo electrónico y la fotografía del lector.

El sistema valida que el correo tenga un formato válido y que no pertenezca a otra cuenta.

La fotografía se selecciona desde la galería y es opcional para el perfil del lector. Los cambios se aplican al presionar Guardar cambios.

### Cierre de sesión

Presionar el botón de salida del encabezado.

La aplicación elimina el token guardado en el dispositivo y regresa a la pantalla de inicio de sesión.

## Uso como administrador

El acceso administrativo corresponde a la cuenta existente en la base de datos con identificador 1 y rol Administrador.

El registro público no permite crear cuentas administrativas.

Después de iniciar sesión con esa cuenta, se muestra el panel de administración.

### Gestión de directores

El administrador puede:

- Consultar los directores registrados.
- Registrar un director con nombre y fotografía.
- Editar los datos de un director.
- Eliminar un director después de confirmar la acción.

La fotografía es obligatoria al registrar. Al editar, se conserva la imagen actual si no se selecciona otra.

Si se elimina un director, sus reseñas se conservan y quedan sin la asociación a ese director. Posteriormente pueden editarse para asignar otro director registrado.

### Gestión de actores

El administrador puede:

- Consultar los actores registrados.
- Registrar un actor con nombre y fotografía.
- Editar sus datos.
- Eliminarlo después de confirmar la acción.

La fotografía se selecciona desde la galería y es obligatoria al registrar. Al editar, se conserva la imagen actual si no se reemplaza.

Al eliminar un actor, las reseñas relacionadas se conservan sin la asociación a ese actor.

### Gestión de reseñas

El administrador puede crear, editar y eliminar reseñas.

El formulario incluye los datos de la producción, como título, tipo, director, actor, etiquetas, sinopsis y portada.

Al guardar una reseña nueva, esta queda disponible para el catálogo. El banner de Inicio muestra la última reseña agregada al actualizar la información.

Editar una reseña anterior no modifica su orden de creación.

### Moderación de comentarios

El módulo de moderación permite revisar los comentarios publicados y eliminar aquellos que contengan spam, insultos u otro contenido inapropiado.

La eliminación requiere seleccionar el comentario correspondiente y confirmar la operación.

### Gestión de lectores

El administrador puede consultar las cuentas registradas y gestionar la eliminación de lectores según las validaciones del sistema.

La cuenta administrativa está protegida y no puede eliminarse desde este módulo.

Si una cuenta tiene comentarios publicados, el sistema solicita revisarlos desde Moderación antes de permitir su eliminación.

## Selección y almacenamiento de imágenes

Las fotografías se seleccionan desde la galería del dispositivo y se envían al backend para su validación y almacenamiento.

Se admiten:

- JPG.
- PNG.
- WEBP.

El tamaño máximo por archivo es de 5 MB.

Las fotografías de actores y directores son obligatorias al registrarlos. La fotografía del perfil del lector es opcional.

Al editar un registro, no es necesario seleccionar nuevamente la fotografía si se desea conservar la existente.

El backend guarda los archivos y los proporciona a la aplicación mediante la ruta /portadas. La carpeta de almacenamiento debe mantenerse disponible para que las imágenes puedan visualizarse.

## Sesiones y permisos

La aplicación utiliza un token JWT para identificar al usuario en las solicitudes protegidas.

El token se almacena localmente para permitir recuperar la sesión mientras siga siendo válido. Al cerrar sesión, se elimina del dispositivo.

Los permisos se validan también en el servidor. Ocultar una opción en la interfaz no sustituye la comprobación del rol en la API.

En la configuración actual:

- El token tiene una duración limitada.
- Al vencer, es necesario iniciar sesión nuevamente.
- Reiniciar el backend invalida los tokens anteriores.
- Las contraseñas se almacenan en la base de datos mediante hashes bcrypt.
- Las contraseñas no deben incluirse en el README ni compartirse como parte de las evidencias.

## Revisión del código

Desde la carpeta flutter_app ejecutar:

    flutter analyze

El comando revisa el código y muestra errores, advertencias o recomendaciones del analizador.

Un resultado sin incidencias confirma que el analizador no detectó problemas, pero no sustituye las pruebas de funcionamiento, conexión, instalación o uso en dispositivos físicos.

## Pruebas de funcionamiento

Antes de entregar la aplicación, comprobar los siguientes casos:
Prueba — Resultado esperado

Registro de lector: Se crea una cuenta con rol Lector.

Correo duplicado: El sistema rechaza el registro y muestra un mensaje.

Credenciales incorrectas: Se muestra un error y no se autoriza el acceso.

Inicio de sesión válido: Se abre la pantalla correspondiente al rol.

Catálogo: Se muestran las publicaciones registradas.

Selección de tarjeta: Se abre el detalle de la publicación seleccionada.

Búsqueda: Se filtran las publicaciones por título, director o actor.

Limpieza de búsqueda: El botón X vacía el campo.

Comentario de más de 500 caracteres: No se permite superar el límite establecido.

Eliminación de comentario propio: Se elimina el comentario después de confirmar.

Calificación: Se guarda el voto y se actualiza el resumen de calificaciones.

Edición del perfil: Se guardan los datos válidos y se actualizan en pantalla.

Selección de imágenes: Se guarda y muestra una fotografía admitida.

Registro sin foto de actor o director: Se solicita seleccionar una fotografía.

Gestión administrativa: Se registran, editan o eliminan los elementos autorizados.

Actualización del catálogo: Al deslizar se consultan nuevamente los datos.

Cierre de sesión: Se elimina el token local y se muestra el login.

Instalación en teléfono físico: La aplicación se instala, abre y se comunica con la API.

## Solución de problemas frecuentes

### La aplicación no se conecta con la API

Comprobar que:

- El backend esté ejecutándose.
- MySQL esté encendido.
- El puerto configurado sea 8000.
- Se utilice la dirección adecuada para el emulador o teléfono.
- El firewall permita la conexión cuando se utiliza un dispositivo físico.

### Aparece un mensaje de sesión vencida

Cerrar sesión e iniciar nuevamente.

También será necesario hacerlo después de reiniciar el backend.

### El emulador aparece como desconectado

Esperar a que Android termine de iniciar y comprobar que aparezca en:

    flutter devices

No ejecutar varias veces el mismo comando mientras la primera ejecución continúa activa.

### Las imágenes no aparecen

Comprobar la conexión con el backend, la disponibilidad de los archivos almacenados y que la dirección /portadas responda correctamente.

### No aparecen cambios recientes

Deslizar hacia abajo para actualizar el catálogo o regresar a la pantalla correspondiente y volver a consultarla.

Durante el desarrollo, guardar los archivos y utilizar la terminal donde se está ejecutando Flutter:

- r: recarga en caliente.
- R: reinicio de la aplicación.
- q: finalizar la ejecución.

Los cambios en el icono o nombre de Android requieren volver a compilar e instalar la aplicación.

## Estado de verificación

Durante las pruebas realizadas en el emulador se confirmó:

- Navegación desde las tarjetas hacia el detalle.
- Límite de 500 caracteres en los comentarios.
- Guardado de fotografías.
- Funcionamiento general de los módulos revisados.
- Ejecución de flutter analyze sin incidencias en la revisión realizada.

La prueba en un teléfono físico y la validación del APK de entrega permanecen pendientes.

## Consideraciones finales

Para utilizar Cruppis se necesita mantener disponibles el backend y la base de datos.

Esta configuración corresponde a un entorno de desarrollo local. Si cambia la computadora que aloja el servidor o su dirección de red, deben revisarse las direcciones utilizadas por la aplicación.

Las capturas y los reportes de prueba deben corresponder a la versión final entregada. No deben incluir contraseñas, tokens ni otros datos privados.


# spooky_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.