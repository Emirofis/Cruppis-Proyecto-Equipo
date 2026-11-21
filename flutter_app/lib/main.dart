// CRUPPIS — Inicio de la aplicación, sesión y catálogo del lector.
// Recupera el token guardado, comprueba la cuenta y abre el contenido según su rol.
// Inicio y Buscar comparten el catálogo; Perfil y el detalle se abren en otras pantallas.
// Se conservan los nombres internos Spooky... y spooky_access_token para mantener la compatibilidad.

// Permite interpretar las respuestas JSON de la API.
import 'dart:convert';
// Incluye los componentes de la pantalla, los formularios y la navegación.
import 'package:flutter/material.dart';
// Permite conservar el token en el almacenamiento protegido del dispositivo.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Permite enviar la solicitud de inicio de sesión a la API.
import 'package:http/http.dart' as http;
// Importa el tema visual compartido. Se conserva el nombre interno para mantener las referencias existentes.
import 'estilos/spooky_tema.dart';
// Permite abrir el panel cuando inicia sesión el administrador autorizado.
import 'pantallas/admin/admin_panel_page.dart';
// Importa la pantalla que solicita el correo y la contraseña.
import 'pantallas/auth/login_page.dart';
// Permite abrir el contenido completo de la reseña seleccionada.
import 'pantallas/lector/detalle_publicacion_page.dart';
// Permite consultar y editar el perfil de la cuenta actual.
import 'pantallas/lector/perfil_page.dart';
// Punto de entrada: desde aquí comienza la aplicación.
void main() {
  // Prepara Flutter antes de utilizar servicios del dispositivo, como el almacenamiento del token.
  WidgetsFlutterBinding.ensureInitialized();
  // Inicia la aplicación y muestra su primer widget.
  runApp(const MyApp());
}
// Define la configuración general de Cruppis: nombre, tema y pantalla inicial.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Configura el nombre, el tema y la pantalla inicial de Cruppis.
  Widget build(BuildContext context) {
    return MaterialApp(
      // Oculta la cinta de depuración en la esquina de la pantalla.
      debugShowCheckedModeBanner: false,
      // Establece el nombre de la aplicación dentro de esta configuración.
      title: 'Cruppis',
      // Aplica el tema oscuro y los colores morados compartidos.
      theme: SpookyTema.oscuro,
      // Utiliza esta pantalla para comprobar la sesión y mostrar el contenido correspondiente.
      home: const PublicacionesPage(),
    );
  }
}
// Controla la sesión y el catálogo del lector; su contenido cambia según el acceso y la sección elegida.
class PublicacionesPage extends StatefulWidget {
  const PublicacionesPage({super.key});
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Crea el estado que gestiona la sesión, las consultas y la navegación.
  State<PublicacionesPage> createState() => _PublicacionesPageState();
}
// Reúne el comportamiento de la pantalla principal.
class _PublicacionesPageState extends State<PublicacionesPage> {
  // Dirección de la API en la computadora. Debe actualizarse si cambia su IPv4.
  static const String _servidor = 'http://192.168.1.65:8000';
  // Nombre interno usado para guardar el token. Se conserva para poder leer las sesiones guardadas por versiones anteriores.
  static const String _claveToken = 'spooky_access_token';
  // Prepara el acceso al almacenamiento protegido donde se conserva el token.
  final _almacenamiento = const FlutterSecureStorage();
  // Conserva el texto escrito en el buscador y permite limpiarlo.
  final _busqueda = TextEditingController();
  // Guarda la consulta que traerá las reseñas del catálogo.
  late Future<List<Map<String, dynamic>>> _publicaciones;
  // Conserva en memoria el token y los datos de la cuenta que está utilizando la app.
  Map<String, dynamic>? _sesion;
  // Indica si se debe mostrar el acceso antes de utilizar el catálogo.
  bool _requiereLogin = true;
  // Muestra una espera mientras se intenta recuperar o preparar la sesión.
  bool _comprobandoSesion = true;
  // Evita ejecutar varias veces el cierre y bloquea acciones mientras termina.
  bool _cerrandoSesion = false;
  // Recuerda si no se pudo borrar el token y todavía hace falta reintentar su eliminación.
  bool _borradoPendiente = false;
  // Guarda el problema que impidió recuperar o cerrar correctamente la sesión.
  String? _errorSesion;
  // Identifica la sección visible: 0 es Inicio y 1 es Buscar. Perfil se abre en otra pantalla.
  int _seccion = 0;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Prepara el estado y programa la recuperación de la sesión al abrir la app.
  void initState() {
    // Ejecuta primero la inicialización que necesita la clase de Flutter.
    super.initState();
    // Empieza con una lista vacía para no consultar el catálogo antes de resolver la sesión.
    _publicaciones = Future.value(<Map<String, dynamic>>[]);
    // Espera a que se construya el primer cuadro de la pantalla antes de comprobar la sesión.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Intenta recuperar la sesión guardada y comprobarla con la API.
      _restaurarSesion();
    });
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Libera los recursos de los campos cuando esta pantalla deja de utilizarse.
  void dispose() {
    // Libera el controlador del buscador cuando se deja de utilizar la pantalla.
    _busqueda.dispose();
    // Completa la limpieza que necesita Flutter.
    super.dispose();
  }
  void _mostrarMensaje(String mensaje) {
    // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
    if (!mounted) return;
    // Muestra un aviso temporal con el mensaje correspondiente.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
  // Lee el token guardado y consulta el perfil para comprobar que la sesión siga siendo válida.
  Future<void> _restaurarSesion() async {
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Muestra la espera mientras se comprueba o prepara la sesión.
      _comprobandoSesion = true;
      // Retira el mensaje anterior para permitir un nuevo intento.
      _errorSesion = null;
    });
    // Intenta completar la operación y atiende los errores si algo falla.
    try {
      // Busca el token que quedó guardado en el dispositivo.
      final token = await _almacenamiento.read(key: _claveToken);
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Si no hay un token utilizable, la aplicación debe pedir el inicio de sesión.
      if (token == null || token.trim().isEmpty) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Retira de memoria los datos de la sesión actual.
          _sesion = null;
          // Deja indicado que se debe volver al login.
          _requiereLogin = true;
          // Termina la espera por la comprobación de la sesión.
          _comprobandoSesion = false;
        });
        // Termina esta operación sin continuar con los pasos siguientes.
        return;
      }
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Solicita datos al servidor utilizando el método GET.
          .get(
            // Consulta el perfil asociado al token para verificar que la cuenta siga disponible.
            Uri.parse('$_servidor/api/perfil'),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Envía el token que se acaba de recuperar o validar.
              'Authorization': 'Bearer $token',
            },
          )
          // Limita la espera de la respuesta a 20 segundos.
          .timeout(const Duration(seconds: 20));
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Cierra la sesión si la API la rechaza, niega el acceso o ya no encuentra la cuenta.
      if (respuesta.statusCode == 401 ||
          respuesta.statusCode == 403 ||
          respuesta.statusCode == 404) {
        // Borra la sesión local y prepara el regreso al login.
        await _cerrarSesion();
        // Termina esta operación sin continuar con los pasos siguientes.
        return;
      }
      // Informa que el servidor no confirmó el inicio de sesión.
      if (respuesta.statusCode != 200) {
        throw Exception('No se pudo comprobar la sesión.');
      }
      // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (datos is! Map) {
        throw const FormatException('Respuesta de usuario inválida.');
      }
      // Entrega el perfil confirmado al mismo proceso que se utiliza después de iniciar sesión.
      await _procesarSesion(
        {
          'access_token': token,
          'token_type': 'bearer',
          'usuario': Map<String, dynamic>.from(datos),
        },
        // No vuelve a escribir el token, porque en este caso ya estaba guardado.
        guardarToken: false,
      );
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Termina la espera por la comprobación de la sesión.
        _comprobandoSesion = false;
        _errorSesion =
            'No se pudo recuperar tu sesión. '
            'Comprueba que el backend esté encendido y vuelve a intentar.';
      });
    }
  }
  // Consulta el catálogo de reseñas. Esta ruta de lectura no necesita enviar el token.
  Future<List<Map<String, dynamic>>> _obtenerPublicaciones() async {
    // Espera la respuesta de la API sin bloquear toda la aplicación.
    final respuesta = await http
        // Solicita todas las publicaciones disponibles.
        .get(Uri.parse('$_servidor/api/publicaciones'))
        // Limita la espera de la respuesta a 20 segundos.
        .timeout(const Duration(seconds: 20));
    // Informa que el servidor no confirmó el inicio de sesión.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar las publicaciones '
        '(${respuesta.statusCode}).',
      );
    }
    // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la respuesta sea una lista antes de convertir las publicaciones.
    if (datos is! List) {
      // Indica que la respuesta no tiene el formato esperado por esta pantalla.
      throw const FormatException('Respuesta inválida.');
    }
    // Devuelve la lista después de convertir cada elemento en un mapa de claves String.
    return datos
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        // Materializa los elementos transformados en una lista de Dart.
        .toList();
  }
  // Inicia una nueva consulta del catálogo para mostrar los cambios recientes.
  void _recargar() {
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Asigna la nueva consulta al componente que muestra el catálogo.
      _publicaciones = _obtenerPublicaciones();
    });
  }
  // Actualiza el catálogo al deslizar hacia abajo y mantiene el indicador hasta que termina la consulta.
  Future<void> _actualizarDeslizando() async {
    // Prepara una sola consulta que compartirán la lista y el indicador de actualización.
    final consulta = _obtenerPublicaciones();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Entrega la nueva consulta al catálogo.
      _publicaciones = consulta;
    });
    // Intenta completar la operación y atiende los errores si algo falla.
    try {
      // Mantiene el indicador de actualización hasta que la consulta termina.
      await consulta;
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      _mostrarMensaje('No se pudo actualizar el catálogo.');
    }
  }
  // Utiliza el cierre y la limpieza de la sesión para volver al acceso.
  Future<void> _abrirLogin() async {
    // Borra la sesión local y prepara el regreso al login.
    await _cerrarSesion();
  }
  // Valida los datos recibidos, guarda el token y abre el contenido según el rol.
  Future<void> _procesarSesion(
    Map<String, dynamic> resultado, {
    // Guarda el token por defecto; al restaurar una sesión se utiliza false.
    bool guardarToken = true,
  }) async {
    // Recupera los datos de la cuenta que confirmó la API.
    final datosUsuario = resultado['usuario'];
    // Recupera el token entregado al iniciar sesión.
    final token = resultado['access_token'];
    // Comprueba que haya datos de usuario y un token de texto no vacío.
    if (datosUsuario is! Map ||
        token is! String ||
        token.trim().isEmpty) {
      throw const FormatException('Respuesta de sesión inválida.');
    }
    // Prepara una copia de los datos de la cuenta para utilizarlos en las pantallas.
    final usuario = Map<String, dynamic>.from(datosUsuario);
    // Reconoce como administrador únicamente el rol y el identificador autorizados por el proyecto.
    final esAdministrador =
        // Comprueba que la cuenta tenga el rol Administrador.
        usuario['rol'] == 'Administrador' &&
        // También exige que sea la cuenta original con identificador 1.
        usuario['id_usuario'].toString() == '1';
    // Rechaza los roles que no tienen acceso a esta aplicación. La API también verifica los permisos en cada operación protegida.
    if (!esAdministrador && usuario['rol'] != 'Lector') {
      // Borra la sesión local y prepara el regreso al login.
      await _cerrarSesion();
      _mostrarMensaje('La cuenta no tiene acceso.');
      // Termina esta operación sin continuar con los pasos siguientes.
      return;
    }
    // Conserva la sesión en el dispositivo cuando se trata de un acceso nuevo.
    if (guardarToken) {
      // Intenta completar la operación y atiende los errores si algo falla.
      try {
        // Espera a que el token se guarde antes de permitir que continúe el acceso.
        await _almacenamiento.write(
          // Utiliza el mismo nombre interno al leer, guardar o borrar el token.
          key: _claveToken,
          // Valor del token que se conservará para recuperar la sesión después.
          value: token,
        );
      // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
      } catch (_) {
        _mostrarMensaje(
          'No se pudo guardar la sesión en el dispositivo. '
          'Intenta iniciar sesión nuevamente.',
        );
        // Termina esta operación sin continuar con los pasos siguientes.
        return;
      }
    }
    // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
    if (!mounted) return;
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Prepara en memoria los datos de la sesión que utilizará la aplicación.
      _sesion = {
        // Copia los campos de la respuesta y después permite reemplazar usuario por el mapa preparado.
        ...resultado,
        'usuario': usuario,
      };
      // Retira el mensaje anterior para permitir un nuevo intento.
      _errorSesion = null;
      // Indica que no queda pendiente la eliminación del token.
      _borradoPendiente = false;
      // Mantiene el catálogo del lector oculto cuando se va a abrir el panel administrativo.
      _requiereLogin = esAdministrador;
      // Muestra la espera detrás del panel administrativo; para un lector permite mostrar el catálogo.
      _comprobandoSesion = esAdministrador;
    });
    // Abre el panel administrativo en lugar del catálogo del lector.
    if (esAdministrador) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          // Construye el panel con la cuenta y el token confirmados.
          builder: (context) => AdminPanelPage(
            usuario: usuario,
            // Comparte el token con la pantalla que se abrirá.
            token: token,
          ),
        ),
      );
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Borra la sesión local y prepara el regreso al login.
      await _cerrarSesion();
      // Termina esta operación sin continuar con los pasos siguientes.
      return;
    }
    // Vuelve a consultar la API para mostrar la información actualizada.
    _recargar();
  }
  // Borra el token guardado y limpia la sesión que utiliza esta pantalla.
  Future<void> _cerrarSesion() async {
    // Evita repetir el cierre o abrir otra pantalla mientras se está cerrando la sesión.
    if (_cerrandoSesion) return;
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Bloquea las acciones mientras intenta borrar el token.
      _cerrandoSesion = true;
    });
    // Intenta completar la operación y atiende los errores si algo falla.
    try {
      // Elimina el token del dispositivo. Esto no revoca por sí mismo un token que el servidor ya haya emitido.
      await _almacenamiento.delete(key: _claveToken);
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Limpia el buscador para que no conserve el texto al cambiar de sesión.
      _busqueda.clear();
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Retira de memoria los datos de la sesión actual.
        _sesion = null;
        // Deja indicado que se debe volver al login.
        _requiereLogin = true;
        // Termina la espera por la comprobación de la sesión.
        _comprobandoSesion = false;
        // Retira el mensaje anterior para permitir un nuevo intento.
        _errorSesion = null;
        // Indica que no queda pendiente la eliminación del token.
        _borradoPendiente = false;
        // Prepara Inicio como sección inicial de la siguiente sesión.
        _seccion = 0;
      });
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Retira de memoria los datos de la sesión actual.
        _sesion = null;
        // Deja indicado que se debe volver al login.
        _requiereLogin = true;
        // Termina la espera por la comprobación de la sesión.
        _comprobandoSesion = false;
        // Impide tratar el cierre como terminado hasta que se pueda eliminar el token guardado.
        _borradoPendiente = true;
        _errorSesion =
            'No se pudo borrar la sesión guardada. '
            'Presiona Reintentar para terminar de cerrar sesión.';
      });
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Comprueba que esta pantalla siga abierta antes de actualizar su contenido.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Termina el intento de cierre y permite reintentar si algo falló.
          _cerrandoSesion = false;
        });
      }
    }
  }
  // Comprueba los datos de sesión antes de abrir el perfil.
  Future<void> _abrirPerfil() async {
    // Evita repetir el cierre o abrir otra pantalla mientras se está cerrando la sesión.
    if (_cerrandoSesion) return;
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Trabaja con una referencia local de la sesión para revisar sus datos.
    final sesion = _sesion;
    // Si la sesión no está disponible, vuelve al proceso de acceso.
    if (_requiereLogin || sesion == null) {
      // Borra la sesión local y prepara el regreso al login.
      await _cerrarSesion();
      // Termina esta operación sin continuar con los pasos siguientes.
      return;
    }
    // Recupera la cuenta de la sesión que está en memoria.
    final datosUsuario = sesion['usuario'];
    // Recupera el token para enviarlo a la pantalla que se abrirá.
    final token = sesion['access_token'];
    // Comprueba que haya datos de usuario y un token de texto no vacío.
    if (datosUsuario is! Map ||
        token is! String ||
        token.trim().isEmpty) {
      // Borra la sesión local y prepara el regreso al login.
      await _cerrarSesion();
      // Termina esta operación sin continuar con los pasos siguientes.
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        // Abre el perfil con los datos y el token de la cuenta actual.
        builder: (context) => PerfilPage(
          usuario: Map<String, dynamic>.from(datosUsuario),
          // Comparte el token con la pantalla que se abrirá.
          token: token,
          // Recibe los datos confirmados desde PerfilPage para actualizar también la pantalla principal.
          onActualizado: (perfil) {
            // No aplica cambios del perfil si la pantalla se cerró o ya no existe una sesión activa.
            if (!mounted || _sesion == null || _requiereLogin) {
              // Termina esta operación sin continuar con los pasos siguientes.
              return;
            }
            // Actualiza los valores y refleja el cambio en la pantalla.
            setState(() {
              // Prepara en memoria los datos de la sesión que utilizará la aplicación.
              _sesion = {
                // Conserva el token y los demás campos de la sesión actual.
                ..._sesion!,
                // Reemplaza únicamente los datos de la cuenta con la versión actualizada.
                'usuario': perfil,
              };
            });
          },
        ),
      ),
    );
  }
  // Abre el detalle de una publicación después de revisar la sesión.
  Future<void> _abrirDetalle(
    Map<String, dynamic> publicacion,
  ) async {
    // Evita repetir el cierre o abrir otra pantalla mientras se está cerrando la sesión.
    if (_cerrandoSesion) return;
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Trabaja con una referencia local de la sesión para revisar sus datos.
    final sesion = _sesion;
    // Si la sesión no está disponible, vuelve al proceso de acceso.
    if (_requiereLogin || sesion == null) {
      // Borra la sesión local y prepara el regreso al login.
      await _cerrarSesion();
      // Termina esta operación sin continuar con los pasos siguientes.
      return;
    }
    // Recupera la cuenta de la sesión que está en memoria.
    final datosUsuario = sesion['usuario'];
    // Recupera el token para enviarlo a la pantalla que se abrirá.
    final token = sesion['access_token'];
    // Comprueba que haya datos de usuario y un token de texto no vacío.
    if (datosUsuario is! Map ||
        token is! String ||
        token.trim().isEmpty) {
      // Borra la sesión local y prepara el regreso al login.
      await _cerrarSesion();
      // Termina esta operación sin continuar con los pasos siguientes.
      return;
    }
    // Prepara una copia de los datos de la cuenta para utilizarlos en las pantallas.
    final usuario = Map<String, dynamic>.from(datosUsuario);
    // Reserva esta navegación para las cuentas de lectores.
    if (usuario['rol'] != 'Lector') {
      // Termina esta operación sin continuar con los pasos siguientes.
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        // Entrega al detalle la reseña, la cuenta y el token para comentar y calificar.
        builder: (context) => DetallePublicacionPage(
          publicacion: publicacion,
          usuario: usuario,
          // Comparte el token con la pantalla que se abrirá.
          token: token,
        ),
      ),
    );
    // Al regresar, continúa solo si esta pantalla sigue abierta y todavía hay acceso.
    if (!mounted || _requiereLogin) return;
    // Vuelve a consultar la API para mostrar la información actualizada.
    _recargar();
  }
  // Construye la dirección de la portada o utiliza el nombre de la imagen de respaldo.
  String _urlPortada(Map<String, dynamic> publicacion) {
    final nombre = (publicacion['portada'] ?? '').toString().trim();
    return Uri.parse(_servidor).replace(
      pathSegments: [
        'portadas',
        nombre.isEmpty ? 'default_cover.jpg' : nombre,
      ],
    ).toString();
  }
  // Prepara las etiquetas para mostrarlas sin textos vacíos ni repeticiones exactas.
  List<String> _obtenerEtiquetas(
    Map<String, dynamic> publicacion,
  ) {
    final datos = publicacion['etiquetas'];
    if (datos is! List) return [];
    // Devuelve la lista después de convertir cada elemento en un mapa de claves String.
    return datos
        .whereType<String>()
        .map((etiqueta) => etiqueta.trim())
        .where((etiqueta) => etiqueta.isNotEmpty)
        .toSet()
        // Materializa los elementos transformados en una lista de Dart.
        .toList();
  }
  // Construye una etiqueta con el estilo compartido y su texto en mayúsculas.
  Widget _etiqueta(String texto) {
    return Container(
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyLectorEstilos.margenEtiqueta,
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyLectorEstilos.etiqueta,
      // Widget que se coloca dentro de este contenedor.
      child: Text(
        texto.toUpperCase(),
        // Estilo del texto o del botón.
        style: SpookyLectorEstilos.etiquetaTexto,
      ),
    );
  }
  // Construye el encabezado de sección con su línea morada lateral.
  Widget _tituloSeccion(String titulo) {
    return Container(
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyLectorEstilos.bordeTitulo,
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyLectorEstilos.margenTitulo,
      // Widget que se coloca dentro de este contenedor.
      child: Text(
        titulo,
        // Estilo del texto o del botón.
        style: SpookyLectorEstilos.tituloSeccion,
      ),
    );
  }
  // Muestra la reseña principal con portada, etiquetas, resumen y acceso al detalle.
  Widget _banner(Map<String, dynamic> publicacion) {
    final etiquetas = _obtenerEtiquetas(publicacion);
    return ClipRRect(
      // Redondea las esquinas de la imagen o del botón.
      borderRadius: BorderRadius.circular(SpookyTema.radio),
      // Widget que se coloca dentro de este contenedor.
      child: Stack(
        // Lista de widgets que se colocarán dentro del componente.
        children: [
          Positioned.fill(
            // Widget que se coloca dentro de este contenedor.
            child: Image.network(
              _urlPortada(publicacion),
              // cover llena el espacio de la portada manteniendo su proporción, aunque recorte parte de la imagen.
              fit: BoxFit.cover,
              // Alinea la imagen o el contenido dentro de su espacio.
              alignment: Alignment.topCenter,
              // Presenta un respaldo cuando la portada no se puede cargar.
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  // Color tomado del tema o del esquema de colores.
                  color: SpookyTema.superficie,
                );
              },
            ),
          ),
          const Positioned.fill(
            // Widget que se coloca dentro de este contenedor.
            child: DecoratedBox(
              // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
              decoration: SpookyLectorEstilos.degradadoPortada,
            ),
          ),
          Padding(
            // Establece el espacio interior alrededor del contenido.
            padding: SpookyLectorEstilos.margen,
            // Widget que se coloca dentro de este contenedor.
            child: Column(
              // stretch estira los elementos horizontalmente dentro de la columna.
              crossAxisAlignment: CrossAxisAlignment.start,
              // Lista de widgets que se colocarán dentro del componente.
              children: [
                const SizedBox(height: 150),
                Wrap(
                  // Separación horizontal entre los botones del Wrap.
                  spacing: 8,
                  // Separación entre filas cuando los botones no caben en una sola línea.
                  runSpacing: 8,
                  // Lista de widgets que se colocarán dentro del componente.
                  children: [
                    _etiqueta('${publicacion['tipo'] ?? ''}'),
                    _etiqueta('Reseña destacada'),
                  ],
                ),
                SpookyLectorEstilos.espacio,
                Text(
                  '${publicacion['titulo'] ?? 'Sin título'}',
                  // Estilo del texto o del botón.
                  style: SpookyLectorEstilos.tituloDestacada,
                ),
                if (etiquetas.isNotEmpty) ...[
                  SpookyLectorEstilos.espacio,
                  Wrap(
                    // Separación horizontal entre los botones del Wrap.
                    spacing: 8,
                    // Separación entre filas cuando los botones no caben en una sola línea.
                    runSpacing: 8,
                    // Lista de widgets que se colocarán dentro del componente.
                    children: etiquetas.map(_etiqueta).toList(),
                  ),
                ],
                SpookyLectorEstilos.espacio,
                Text(
                  '${publicacion['sinopsis'] ?? ''}',
                  // Limita las líneas visibles del texto; el contenido completo sigue disponible en el detalle.
                  maxLines: 3,
                  // Muestra puntos suspensivos cuando el texto supera las líneas disponibles.
                  overflow: TextOverflow.ellipsis,
                  // Estilo del texto o del botón.
                  style: SpookyLectorEstilos.descripcion,
                ),
                SpookyLectorEstilos.espacio,
                DecoratedBox(
                  // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                  decoration: SpookyPanelEstilos.resplandorBoton,
                  // Widget que se coloca dentro de este contenedor.
                  child: FilledButton.icon(
                    // Estilo del texto o del botón.
                    style: SpookyLectorEstilos.boton,
                    // Asigna la acción del botón y puede desactivarla mientras se cierra la sesión.
                    onPressed: () {
                      _abrirDetalle(publicacion);
                    },
                    // Icono que acompaña la acción.
                    icon: const Icon(Icons.play_arrow),
                    // Texto visible del botón.
                    label: const Text('Ver reseña completa'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Construye una tarjeta compacta con portada, tipo y título. Toda la tarjeta se puede tocar.
  Widget _tarjeta(Map<String, dynamic> publicacion) {
    final titulo = (publicacion['titulo'] ?? 'Sin título').toString();
    final tipo = (publicacion['tipo'] ?? 'Película').toString();
    return Container(
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyLectorEstilos.tarjeta,
      // Dibuja el borde por encima del contenido para conservar el contorno de la tarjeta.
      foregroundDecoration: BoxDecoration(
        // Redondea las esquinas de la imagen o del botón.
        borderRadius: BorderRadius.circular(16),
        // Define el borde del campo.
        border: Border.all(
          // Color tomado del tema o del esquema de colores.
          color: const Color(0xFF9D62FF),
          // Ancho solicitado en unidades lógicas de Flutter.
          width: 1.2,
        ),
      ),
      // Recorta el contenido siguiendo la forma redondeada del contenedor.
      clipBehavior: Clip.antiAlias,
      // Widget que se coloca dentro de este contenedor.
      child: Material(
        // Color tomado del tema o del esquema de colores.
        color: Colors.transparent,
        // Widget que se coloca dentro de este contenedor.
        child: InkWell(
          // Abre la reseña al tocar cualquier parte de la tarjeta.
          onTap: () {
            _abrirDetalle(publicacion);
          },
          // Widget que se coloca dentro de este contenedor.
          child: Column(
            // stretch estira los elementos horizontalmente dentro de la columna.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              AspectRatio(
                // Mantiene la proporción vertical del cartel, aunque cambie el ancho de la tarjeta.
                aspectRatio: 2 / 3,
                // Widget que se coloca dentro de este contenedor.
                child: Image.network(
                  _urlPortada(publicacion),
                  // cover llena el espacio de la portada manteniendo su proporción, aunque recorte parte de la imagen.
                  fit: BoxFit.cover,
                  // Alinea la imagen o el contenido dentro de su espacio.
                  alignment: Alignment.topCenter,
                  // Permite mostrar una espera mientras se descarga la imagen.
                  loadingBuilder: (context, child, progreso) {
                    if (progreso == null) return child;
                    return const Center(
                      // Widget que se coloca dentro de este contenedor.
                      child: CircularProgressIndicator(),
                    );
                  },
                  // Presenta un respaldo cuando la portada no se puede cargar.
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      // Widget que se coloca dentro de este contenedor.
                      child: Icon(
                        Icons.broken_image_outlined,
                        // Color tomado del tema o del esquema de colores.
                        color: SpookyTema.textoSecundario,
                        // Tamaño del icono en unidades lógicas.
                        size: 36,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                // Establece el espacio interior alrededor del contenido.
                padding: const EdgeInsets.all(8),
                // Widget que se coloca dentro de este contenedor.
                child: Column(
                  // stretch estira los elementos horizontalmente dentro de la columna.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // Lista de widgets que se colocarán dentro del componente.
                  children: [
                    Text(
                      tipo.toUpperCase(),
                      // Estilo del texto o del botón.
                      style: SpookyLectorEstilos.etiquetaTexto.copyWith(
                        // Ajusta el tamaño del texto dentro de la tarjeta compacta.
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      // Añade un salto de línea para reservar espacio para dos líneas incluso cuando el título es corto.
                      '$titulo\n',
                      // Limita las líneas visibles del texto; el contenido completo sigue disponible en el detalle.
                      maxLines: 2,
                      // Muestra puntos suspensivos cuando el texto supera las líneas disponibles.
                      overflow: TextOverflow.ellipsis,
                      // Estilo del texto o del botón.
                      style: SpookyLectorEstilos.tituloTarjeta.copyWith(
                        // Ajusta el tamaño del texto dentro de la tarjeta compacta.
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Organiza las tarjetas en filas calculadas según el ancho disponible.
  Widget _rejilla(List<Map<String, dynamic>> publicaciones) {
    return SliverLayoutBuilder(
      // Construye el contenido del diálogo o de la sección según el estado actual.
      builder: (context, constraints) {
        // Separa las tarjetas por diez unidades de Flutter.
        const separacion = 10.0;
        // Muestra tres columnas desde 600 unidades de ancho y dos en tamaños menores; no depende del tamaño de letra del sistema.
        final columnas = constraints.crossAxisExtent >= 600 ? 3 : 2;
        // Calcula el ancho de cada tarjeta después de descontar los espacios entre columnas.
        final ancho = (
          constraints.crossAxisExtent -
          separacion * (columnas - 1)
        ) / columnas;
        // Calcula las filas necesarias, incluyendo la última aunque no esté completa.
        final filas = (publicaciones.length / columnas).ceil();
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, fila) {
              // Encuentra la primera publicación que corresponde a esta fila.
              final inicio = fila * columnas;
              return Padding(
                // Establece el espacio interior alrededor del contenido.
                padding: const EdgeInsets.only(
                  bottom: separacion,
                ),
                // Widget que se coloca dentro de este contenedor.
                child: Row(
                  // stretch estira los elementos horizontalmente dentro de la columna.
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // Lista de widgets que se colocarán dentro del componente.
                  children: [
                    for (
                      int columna = 0;
                      columna < columnas;
                      columna++
                    ) ...[
                      // Deja espacio entre columnas, pero no antes de la primera.
                      if (columna > 0)
                        const SizedBox(width: separacion),
                      SizedBox(
                        // Ancho solicitado en unidades lógicas de Flutter.
                        width: ancho,
                        // Comprueba si hay una publicación para esta posición de la fila.
                        child: inicio + columna < publicaciones.length
                            // Construye la tarjeta que corresponde a esa posición.
                            ? _tarjeta(publicaciones[inicio + columna])
                            // Si la última fila está incompleta, conserva el espacio sin agregar una tarjeta.
                            : null,
                      ),
                    ],
                  ],
                ),
              );
            },
            // Indica cuántas filas debe construir la lista.
            childCount: filas,
          ),
        );
      },
    );
  }
  // Construye el campo y el botón que permite limpiar la búsqueda.
  Widget _campoBusqueda() {
    return Padding(
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyLectorEstilos.margen,
      // Widget que se coloca dentro de este contenedor.
      child: TextField(
        // Conecta el campo con el texto del buscador.
        controller: _busqueda,
        // Muestra la acción de finalizar en el teclado.
        textInputAction: TextInputAction.search,
        // Quita el foco al tocar fuera del campo.
        onTapOutside: (_) {
          // Cierra el teclado antes de continuar con la acción.
          FocusScope.of(context).unfocus();
        },
        // Reconstruye los resultados cuando cambia el texto, sin volver a consultar la API por cada letra.
        onChanged: (_) {
          setState(() {});
        },
        // Cierra el teclado al confirmar la búsqueda.
        onSubmitted: (_) {
          // Cierra el teclado antes de continuar con la acción.
          FocusScope.of(context).unfocus();
        },
        // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
        decoration: SpookyLectorEstilos.buscador.copyWith(
          // Muestra el botón para limpiar solo cuando hay texto escrito.
          suffixIcon: _busqueda.text.isEmpty
              ? null
              : IconButton(
                  // Descripción de ayuda y accesibilidad del botón.
                  tooltip: 'Limpiar búsqueda',
                  // Asigna la acción del botón y puede desactivarla mientras se cierra la sesión.
                  onPressed: () {
                    // Limpia el buscador para que no conserve el texto al cambiar de sesión.
                    _busqueda.clear();
                    setState(() {});
                  },
                  // Icono que acompaña la acción.
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );
  }
  // Prepara los resultados, el banner y la lista según se muestre Inicio o Buscar.
  Widget _contenido(List<Map<String, dynamic>> publicaciones) {
    // Reconoce si la sección activa es Buscar.
    final buscando = _seccion == 1;
    // Prepara la búsqueda para comparar sin distinguir mayúsculas de minúsculas; no elimina las diferencias de acentos.
    final consulta = _busqueda.text.trim().toLowerCase();
    // Filtra las publicaciones que ya están cargadas en el teléfono.
    final resultados = publicaciones.where((publicacion) {
      // En Inicio conserva todas las publicaciones, sin aplicar el texto del buscador.
      if (!buscando) return true;
      final titulo =
          (publicacion['titulo'] ?? '').toString().toLowerCase();
      final director =
          (publicacion['director'] ?? '').toString().toLowerCase();
      final actor =
          (publicacion['actor'] ?? '').toString().toLowerCase();
      // Busca coincidencias parciales en el título, el director o el actor.
      return titulo.contains(consulta) ||
          director.contains(consulta) ||
          actor.contains(consulta);
    }).toList();
    // Reserva la publicación que se mostrará en el banner.
    Map<String, dynamic>? ultimaPublicacion;
    // Revisa los registros para encontrar el identificador más alto.
    for (final publicacion in publicaciones) {
      // Intenta leer el identificador de la publicación que se está revisando.
      final idActual = int.tryParse(
            '${publicacion['id_publicacion']}',
          ) ??
          0;
      // Recupera el identificador de la publicación elegida hasta ese momento.
      final idUltima = int.tryParse(
            '${ultimaPublicacion?['id_publicacion']}',
          ) ??
          0;
      // Elige el registro con el identificador más alto como la última reseña agregada. Aquí no se consulta el campo destacada.
      if (ultimaPublicacion == null || idActual > idUltima) {
        // Conserva la publicación encontrada para mostrarla en el banner.
        ultimaPublicacion = publicacion;
      }
    }
    // Utiliza la publicación elegida como encabezado de Inicio.
    final banner = ultimaPublicacion;
    // En Buscar muestra todas las coincidencias; en Inicio retira de las tarjetas la publicación que ya aparece en el banner.
    final tarjetas = buscando
        ? resultados
        : resultados.where((publicacion) {
            return publicacion['id_publicacion'].toString() !=
                banner?['id_publicacion'].toString();
          }).toList();
    return Column(
      // Lista de widgets que se colocarán dentro del componente.
      children: [
        if (buscando) _campoBusqueda(),
        Expanded(
          // Widget que se coloca dentro de este contenedor.
          child: RefreshIndicator(
            // Vuelve a consultar el catálogo al deslizar hacia abajo.
            onRefresh: _actualizarDeslizando,
            // Widget que se coloca dentro de este contenedor.
            child: CustomScrollView(
              // Permite deslizar incluso si la lista es corta o solo muestra el mensaje de vacío.
              physics: const AlwaysScrollableScrollPhysics(),
              // Permite ocultar el teclado al desplazar el contenido.
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              // Reúne el banner, el título y las filas dentro de un mismo recorrido de desplazamiento.
              slivers: [
                if (!buscando && banner != null)
                  SliverPadding(
                    // Establece el espacio interior alrededor del contenido.
                    padding: SpookyLectorEstilos.margen,
                    // Contenido que se integra al área de desplazamiento.
                    sliver: SliverToBoxAdapter(
                      // Widget que se coloca dentro de este contenedor.
                      child: _banner(banner),
                    ),
                  ),
                SliverPadding(
                  // Establece el espacio interior alrededor del contenido.
                  padding: SpookyLectorEstilos.margen,
                  // Contenido que se integra al área de desplazamiento.
                  sliver: SliverToBoxAdapter(
                    // Widget que se coloca dentro de este contenedor.
                    child: _tituloSeccion(
                      buscando
                          ? consulta.isEmpty
                              ? 'CATÁLOGO COMPLETO'
                              : 'RESULTADOS (${resultados.length})'
                          : 'RESEÑAS DE TERROR',
                    ),
                  ),
                ),
                if (tarjetas.isEmpty)
                  SliverFillRemaining(
                    // Permite que el aviso ocupe el espacio restante sin agregar un desplazamiento propio.
                    hasScrollBody: false,
                    // Widget que se coloca dentro de este contenedor.
                    child: Center(
                      // Widget que se coloca dentro de este contenedor.
                      child: Padding(
                        // Establece el espacio interior alrededor del contenido.
                        padding: SpookyLectorEstilos.margen,
                        // Widget que se coloca dentro de este contenedor.
                        child: Text(
                          publicaciones.isEmpty
                              ? 'Todavía no hay publicaciones.'
                              : buscando
                                  ? 'No se encontraron reseñas.'
                                  : 'No hay publicaciones adicionales.',
                          // Alineación del texto dentro del espacio disponible.
                          textAlign: TextAlign.center,
                          // Estilo del texto o del botón.
                          style: SpookyLectorEstilos.descripcion,
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    // Establece el espacio interior alrededor del contenido.
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                    // Contenido que se integra al área de desplazamiento.
                    sliver: _rejilla(tarjetas),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  // Muestra la carga, un error o el contenido según el resultado de la consulta de publicaciones.
  Widget _catalogo() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // Consulta asíncrona que FutureBuilder debe observar.
      future: _publicaciones,
      // Construye el contenido del diálogo o de la sección según el estado actual.
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            // Widget que se coloca dentro de este contenedor.
            child: CircularProgressIndicator(),
          );
        }
        // Muestra el mensaje de error y una opción para volver a consultar.
        if (snapshot.hasError) {
          return Center(
            // Widget que se coloca dentro de este contenedor.
            child: Padding(
              // Establece el espacio interior alrededor del contenido.
              padding: SpookyLectorEstilos.margen,
              // Widget que se coloca dentro de este contenedor.
              child: Column(
                // min evita que la columna ocupe más altura de la necesaria.
                mainAxisSize: MainAxisSize.min,
                // Lista de widgets que se colocarán dentro del componente.
                children: [
                  const Text(
                    'No se pudo cargar el catálogo.',
                    // Estilo del texto o del botón.
                    style: SpookyLectorEstilos.descripcion,
                  ),
                  SpookyLectorEstilos.espacio,
                  FilledButton(
                    // Asigna la acción del botón y puede desactivarla mientras se cierra la sesión.
                    onPressed: _recargar,
                    // Widget que se coloca dentro de este contenedor.
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }
        return _contenido(snapshot.data ?? []);
      },
    );
  }
  // Muestra la comprobación de acceso o las opciones para recuperarse de un problema de sesión.
  Widget _pantallaSesion() {
    return Scaffold(
      // Contenido principal de la pantalla.
      body: DecoratedBox(
        // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
        decoration: SpookyLectorEstilos.fondo,
        // Widget que se coloca dentro de este contenedor.
        child: SizedBox.expand(
          // Widget que se coloca dentro de este contenedor.
          child: SafeArea(
            // Widget que se coloca dentro de este contenedor.
            child: Center(
              // Widget que se coloca dentro de este contenedor.
              child: Padding(
                // Establece el espacio interior alrededor del contenido.
                padding: SpookyLectorEstilos.margen,
                // Widget que se coloca dentro de este contenedor.
                child: _comprobandoSesion
                    ? const CircularProgressIndicator()
                    : Column(
                        // min evita que la columna ocupe más altura de la necesaria.
                        mainAxisSize: MainAxisSize.min,
                        // Lista de widgets que se colocarán dentro del componente.
                        children: [
                          Text(
                            _errorSesion ?? '',
                            // Alineación del texto dentro del espacio disponible.
                            textAlign: TextAlign.center,
                            // Estilo del texto o del botón.
                            style: SpookyLectorEstilos.descripcion,
                          ),
                          SpookyLectorEstilos.espacio,
                          FilledButton(
                            // Asigna la acción del botón y puede desactivarla mientras se cierra la sesión.
                            onPressed: _cerrandoSesion
                                ? null
                                : () {
                                    // Si todavía falta borrar el token, el botón reintenta completar el cierre.
                                    if (_borradoPendiente) {
                                      _cerrarSesion();
                                    // Utiliza esta alternativa cuando no se cumple la condición anterior.
                                    } else {
                                      // Intenta recuperar la sesión guardada y comprobarla con la API.
                                      _restaurarSesion();
                                    }
                                  },
                            // Widget que se coloca dentro de este contenedor.
                            child: Text(
                              _cerrandoSesion
                                  ? 'Cerrando sesión...'
                                  : 'Reintentar',
                            ),
                          ),
                          if (!_borradoPendiente)
                            TextButton(
                              // Asigna la acción del botón y puede desactivarla mientras se cierra la sesión.
                              onPressed: _cerrandoSesion
                                  ? null
                                  : _cerrarSesion,
                              // Widget que se coloca dentro de este contenedor.
                              child: const Text(
                                'Ir al inicio de sesión',
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Decide si corresponde mostrar la comprobación de sesión, el login o el catálogo del lector.
  Widget build(BuildContext context) {
    // Da prioridad a la comprobación o a un error de sesión antes de mostrar otras pantallas.
    if (_comprobandoSesion || _errorSesion != null) {
      return _pantallaSesion();
    }
    // Muestra el login cuando todavía no se cuenta con una sesión lista para el catálogo.
    if (_requiereLogin) {
      return PopScope(
        // Evita regresar desde el login hacia una pantalla anterior mediante esta ruta.
        canPop: false,
        // Widget que se coloca dentro de este contenedor.
        child: LoginPage(
          // Recibe la respuesta del login y continúa con el guardado del token y la navegación por rol.
          onSesion: _procesarSesion,
        ),
      );
    }
    final usuario = _sesion == null
        ? null
        : Map<String, dynamic>.from(
            _sesion!['usuario'] as Map,
          );
    return Scaffold(
      // Configura la barra superior de esta pantalla.
      appBar: AppBar(
        // Texto de la barra superior o del cuadro de confirmación.
        title: const Text(
          'Cruppis',
          // Estilo del texto o del botón.
          style: SpookyPanelEstilos.logo,
        ),
        // Lista de botones de la barra superior o del diálogo.
        actions: [
          IconButton(
            // Descripción de ayuda y accesibilidad del botón.
            tooltip: _sesion == null
                ? 'Iniciar sesión'
                : 'Cerrar sesión',
            // Asigna la acción del botón y puede desactivarla mientras se cierra la sesión.
            onPressed: _cerrandoSesion
                ? null
                : _sesion == null
                    ? _abrirLogin
                    : _cerrarSesion,
            // Icono que acompaña la acción.
            icon: Icon(
              _sesion == null ? Icons.login : Icons.logout,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            SpookyPanelEstilos.altoBorde,
          ),
          // Widget que se coloca dentro de este contenedor.
          child: Container(
            // Altura solicitada en unidades lógicas de Flutter.
            height: SpookyPanelEstilos.altoBorde,
            // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
            decoration: SpookyPanelEstilos.bordeEncabezado,
          ),
        ),
      ),
      // Contenido principal de la pantalla.
      body: DecoratedBox(
        // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
        decoration: SpookyLectorEstilos.fondo,
        // Widget que se coloca dentro de este contenedor.
        child: SafeArea(
          // Widget que se coloca dentro de este contenedor.
          child: Column(
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              if (usuario != null)
                Padding(
                  // Establece el espacio interior alrededor del contenido.
                  padding: const EdgeInsets.all(SpookyTema.espacio),
                  // Widget que se coloca dentro de este contenedor.
                  child: Align(
                    // Alinea la imagen o el contenido dentro de su espacio.
                    alignment: Alignment.centerLeft,
                    // Widget que se coloca dentro de este contenedor.
                    child: Text(
                      '${usuario['nombre']} · ${usuario['rol']}',
                      // Estilo del texto o del botón.
                      style: SpookyLectorEstilos.descripcion,
                    ),
                  ),
                ),
              Expanded(child: _catalogo()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBarTheme(
  // Aplica los estilos compartidos de la barra inferior.
  data: SpookyLectorEstilos.barraNavegacion,
  // Widget que se coloca dentro de este contenedor.
  child: NavigationBar(
    // Indica si se está mostrando Inicio o Buscar.
    selectedIndex: _seccion,
    // Recibe el destino elegido en la barra inferior.
    onDestinationSelected: (valor) {
      // Evita repetir el cierre o abrir otra pantalla mientras se está cerrando la sesión.
      if (_cerrandoSesion) return;
      // Cierra el teclado antes de continuar con la acción.
      FocusScope.of(context).unfocus();
      // Perfil se abre en otra pantalla; conserva la sección de Inicio o Buscar para cuando se regrese.
      if (valor == 2) {
        // Abre la consulta y edición del perfil.
        _abrirPerfil();
        // Termina esta operación sin continuar con los pasos siguientes.
        return;
      }
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Cambia entre Inicio y Buscar y actualiza el contenido.
        _seccion = valor;
      });
    },
    // Define los accesos de Inicio, Buscar y Perfil.
    destinations: const [
      NavigationDestination(
        // Icono que acompaña la acción.
        icon: Icon(Icons.home_outlined),
        // Icono que se muestra cuando este destino está seleccionado.
        selectedIcon: Icon(Icons.home),
        // Texto visible del botón.
        label: 'Inicio',
      ),
      NavigationDestination(
        // Icono que acompaña la acción.
        icon: Icon(Icons.search),
        // Texto visible del botón.
        label: 'Buscar',
      ),
      NavigationDestination(
        // Icono que acompaña la acción.
        icon: Icon(Icons.person_outline),
        // Icono que se muestra cuando este destino está seleccionado.
        selectedIcon: Icon(Icons.person),
        // Texto visible del botón.
        label: 'Perfil',
      ),
    ],
  ),
      ),
    );
  }
}
