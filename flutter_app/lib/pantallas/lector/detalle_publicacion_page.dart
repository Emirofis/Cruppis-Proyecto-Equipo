// CRUPPIS — Detalle de una reseña.
// Presenta la información recibida y permite comentar, elegir una reacción y calificar.
// Las acciones protegidas se envían a la API, que comprueba la sesión y los permisos.
// Actualizar vuelve a consultar comentarios y calificaciones, no la ficha de la publicación.
// StatefulWidget permite actualizar el contenido; State conserva los datos de la pantalla.
// Future representa un resultado pendiente; async y await permiten esperar sin bloquear la interfaz.
// Map guarda campos por nombre y List reúne varios registros; dynamic admite distintos tipos de valores.
// JSON es el formato utilizado para comunicarse con la API y UTF-8 conserva acentos y emojis.
// GlobalKey permite validar el Form; TextEditingController permite leer y limpiar lo escrito.
// setState pide actualizar la interfaz; mounted comprueba que la pantalla siga activa.
// try intenta la operación, catch atiende un error y finally libera los indicadores al terminar.
// ?? elige otro valor si falta el primero; ?. permite acceder a un dato solo si el objeto existe.
// ! indica que se espera un valor no nulo; condición ? opción : otraOpción elige entre dos valores.
// FutureBuilder observa una consulta; snapshot contiene su estado, sus datos o el error.
// Semantics y Tooltip describen los controles para facilitar su identificación y accesibilidad.
// Unicode identifica caracteres y emojis; runes.length cuenta puntos de código, no siempre símbolos visibles.
// Las reacciones son opciones reales del formulario, no comentarios ni votos de prueba.

// Permite enviar comentarios y votos como JSON y leer las respuestas de la API.
import 'dart:convert';
// Incluye los componentes de la pantalla, los formularios y la navegación.
import 'package:flutter/material.dart';
// Permite consultar comentarios y calificaciones y enviar sus cambios a la API.
import 'package:http/http.dart' as http;
// Utiliza los estilos compartidos de Cruppis. El nombre del archivo se conserva para no romper las referencias.
import '../../estilos/spooky_tema.dart';
// Pantalla de la reseña seleccionada, con su información, calificaciones y comentarios.
class DetallePublicacionPage extends StatefulWidget {
  // Recibe la publicación, la cuenta actual y el token para las acciones protegidas.
  const DetallePublicacionPage({
    // Permite que Flutter identifique este widget dentro del árbol de la interfaz.
    super.key,
    required this.publicacion,
    required this.usuario,
    // Obliga a proporcionar el token al abrir la pantalla.
    required this.token,
  });
  // Conserva los datos de la publicación que se recibió al abrir el detalle.
  final Map<String, dynamic> publicacion;
  // Permite identificar los comentarios que pertenecen a la cuenta actual.
  final Map<String, dynamic> usuario;
  // Se envía a la API al consultar el voto, calificar, publicar o eliminar comentarios.
  final String token;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Crea el estado encargado de las consultas, los comentarios y las estrellas.
  State<DetallePublicacionPage> createState() =>
      _DetallePublicacionPageState();
}
// Agrupa el comportamiento y los datos que cambian dentro de esta pantalla.
class _DetallePublicacionPageState
    extends State<DetallePublicacionPage> {
  // Dirección del backend; debe actualizarse si cambia la IPv4 de la computadora.
  static const String _servidor = 'http://10.13.40.223:8000';
  // Guarda la consulta pendiente de comentarios que observará la pantalla.
  late Future<List<Map<String, dynamic>>> _comentarios;
  // Permite validar y restablecer el formulario de opinión.
  final _formularioComentario = GlobalKey<FormState>();
  // Conserva el comentario escrito y permite limpiar el campo después de publicarlo.
  final _textoComentario = TextEditingController();
  // Relaciona cada emoji con su nombre. Las secuencias Unicode evitan depender de cómo se pegue el símbolo en el archivo.
  static const _reacciones = {
    '\u{1F9DF}': 'Zombi',
    '\u{1F383}': 'Calabaza',
    '\u{1F47B}': 'Fantasma',
    '\u{1F480}': 'Calavera',
    '\u{1F47D}': 'Alien',
  };
  // Selecciona Zombi como reacción inicial.
  String _emojiSeleccionado = '\u{1F9DF}';
  // Evita publicar o eliminar otro comentario mientras una de esas acciones está en curso.
  bool _procesandoComentario = false;
  // Guarda el promedio de estrellas que devuelve la API.
  double _promedio = 0;
  // Guarda cuántas cuentas han calificado la publicación.
  int _totalVotos = 0;
  // Conserva la calificación de la cuenta actual; null indica que todavía no hay voto.
  int? _miVoto;
  // Indica que se está consultando el resumen de las calificaciones.
  bool _cargandoCalificacion = true;
  // Evita enviar varios votos mientras se espera la confirmación del servidor.
  bool _guardandoCalificacion = false;
  // Guarda la explicación del problema al consultar o confirmar un voto.
  String? _errorCalificacion;
  // Numera las consultas para que una respuesta antigua no reemplace datos más recientes.
  int _consultaCalificacion = 0;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Carga los comentarios y el resumen de estrellas cuando se abre la pantalla.
  void initState() {
    // Ejecuta primero la inicialización que necesita la clase de Flutter.
    super.initState();
    // Inicia una consulta y la guarda para mostrar su resultado.
    _comentarios = _obtenerComentarios();
    // Solicita el promedio, la cantidad de votos y la calificación de la cuenta actual.
    _cargarCalificacion();
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Libera los recursos de los campos cuando esta pantalla deja de utilizarse.
  void dispose() {
    // Libera el controlador del comentario cuando se cierra esta pantalla.
    _textoComentario.dispose();
    // Completa la limpieza que necesita Flutter.
    super.dispose();
  }
  // Consulta los comentarios de esta publicación. Esta ruta no envía un token porque su lectura es pública en la API.
  Future<List<Map<String, dynamic>>> _obtenerComentarios() async {
    // Obtiene el identificador de la reseña para consultar o modificar sus datos relacionados.
    final id = widget.publicacion['id_publicacion'];
    // Espera la respuesta de la API sin bloquear toda la aplicación.
    final respuesta = await http
        // Solicita datos al servidor utilizando el método GET.
        .get(
          // Construye la dirección de los comentarios de esta reseña.
          Uri.parse('$_servidor/api/publicaciones/$id/comentarios'),
        )
        // Limita la espera de la respuesta a 20 segundos.
        .timeout(const Duration(seconds: 20));
    // Informa si la API no pudo devolver la lista de comentarios.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar los comentarios '
        '(${respuesta.statusCode}).',
      );
    }
    // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la respuesta sea una lista antes de convertir los comentarios.
    if (datos is! List) {
      throw const FormatException('La respuesta no es una lista.');
    }
    // Devuelve la lista después de convertir cada elemento en un mapa de claves String.
    return datos
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        // Devuelve los resultados organizados como una lista.
        .toList();
  }
  // Actualiza la consulta que muestra los comentarios.
  void _recargarComentarios() {
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Inicia una consulta y la guarda para mostrar su resultado.
      _comentarios = _obtenerComentarios();
    });
  }
  // Actualiza comentarios y calificaciones. No vuelve a consultar el título, la sinopsis ni las fotografías de la ficha.
  Future<void> _actualizarDetalle() async {
    // Prepara una sola consulta de comentarios para compartir su resultado con la interfaz y el indicador de actualización.
    final consultaComentarios = _obtenerComentarios();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Entrega la nueva consulta al componente que muestra la lista.
      _comentarios = consultaComentarios;
    });
    // Espera los comentarios y muestra un aviso si no se pudieron actualizar.
    Future<void> esperarComentarios() async {
      // Intenta completar la operación y atiende sus posibles errores.
      try {
        // Espera que termine la consulta antes de dar por finalizada esta parte de la actualización.
        await consultaComentarios;
      // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
      } catch (_) {
        _mostrarMensaje('No se pudieron actualizar los comentarios.');
      }
    }
    // Espera ambas tareas sin obligar a que una termine antes de empezar la otra.
    await Future.wait<void>([
      // Espera la actualización de los comentarios.
      esperarComentarios(),
      // Actualiza también el resumen de estrellas.
      _cargarCalificacion(),
    ]);
  }
  // Acepta nombres de archivo o direcciones /portadas/ del backend actual.
  // No acepta fotografías alojadas en sitios externos.
  String _urlImagen(String valor) {
    // ?? utiliza texto vacío cuando no hay una foto; no crea una imagen de prueba.
    final foto = valor.trim();
    if (foto.isEmpty) return '';

    // Uri separa una dirección en protocolo, servidor, puerto y ruta.
    final base = Uri.parse(_servidor);
    final uri = Uri.tryParse(foto);
    if (uri == null) return '';

    String ruta;
    if (uri.hasScheme) {
      // Una dirección completa debe pertenecer a nuestro backend.
      // Las fotos de uploads se consultan públicamente mediante /portadas/.
      if (uri.scheme != base.scheme ||
          uri.host != base.host ||
          uri.port != base.port ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          !uri.path.startsWith('/portadas/')) {
        return '';
      }
      ruta = uri.path;
    } else {
      ruta = foto;
    }

    // Retira el prefijo local para conservar únicamente el nombre del archivo.
    String nombre = ruta;
    for (final prefijo in ['/portadas/', 'portadas/']) {
      if (ruta.startsWith(prefijo)) {
        nombre = ruta.substring(prefijo.length);
        break;
      }
    }

    // Rechaza nombres vacíos y rutas hacia otras carpetas.
    if (nombre.isEmpty ||
        nombre == '.' ||
        nombre == '..' ||
        nombre.contains('/') ||
        nombre.contains(String.fromCharCode(92)) ||
        nombre.contains(':')) {
      return '';
    }

    // replace construye la ruta; pathSegments codifica el nombre del archivo.
    return base.replace(pathSegments: ['portadas', nombre]).toString();
  }

  // Obtiene la portada real sin asignar una imagen predeterminada.
  String get _urlPortada {
    final nombre =
        (widget.publicacion['portada'] ?? '').toString().trim();
    return _urlImagen(nombre);
  }

  // Prepara las etiquetas de la reseña para mostrarlas sin textos vacíos ni repeticiones exactas.
  List<String> _obtenerEtiquetas() {
    // Lee las etiquetas que se recibieron junto con la publicación.
    final datos = widget.publicacion['etiquetas'];
    // Si no se recibió una lista de etiquetas, continúa sin mostrar ninguna.
    if (datos is! List) return [];
    // Prepara las etiquetas recibidas como una lista de textos.
    return datos
        // Conserva únicamente los elementos de texto.
        .whereType<String>()
        // Elimina los espacios sobrantes de cada etiqueta.
        .map((etiqueta) => etiqueta.trim())
        // Descarta las etiquetas que quedaron vacías.
        .where((etiqueta) => etiqueta.isNotEmpty)
        // Elimina las etiquetas repetidas que tienen exactamente el mismo texto.
        .toSet()
        // Devuelve los resultados organizados como una lista.
        .toList();
  }
  // Da formato de día/mes/año y hora a la fecha recibida, sin convertirla a la zona horaria del teléfono.
  String _fechaComentario(dynamic valor) {
    // Intenta interpretar la fecha; devuelve null si el valor no se puede leer.
    final fecha = DateTime.tryParse((valor ?? '').toString());
    // No muestra fecha cuando el dato no se pudo interpretar.
    if (fecha == null) return '';
    // Añade un cero a los números de un solo dígito, por ejemplo 09 en lugar de 9.
    String dos(int numero) => numero.toString().padLeft(2, '0');
    return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
        '${dos(fecha.hour)}:${dos(fecha.minute)}';
  }
  // Construye el icono de respaldo. Aunque conserva este nombre, se reutiliza para director y actor.
  Widget _sinFotoDirector() {
    return const ColoredBox(
      // Color tomado del tema o del esquema de colores.
      color: SpookyDetalleEstilos.fondoFoto,
      // Widget que se coloca dentro de este contenedor.
      child: SizedBox(
        // Ancho solicitado en unidades lógicas de Flutter.
        width: SpookyDetalleEstilos.tamanoFoto,
        // Altura solicitada en unidades lógicas de Flutter.
        height: SpookyDetalleEstilos.tamanoFoto,
        // Widget que se coloca dentro de este contenedor.
        child: Icon(
          Icons.person_outline,
          // Tamaño del icono en unidades lógicas.
          size: 40,
          // Color tomado del tema o del esquema de colores.
          color: SpookyTema.textoSecundario,
        ),
      ),
    );
  }
  // Busca la explicación enviada por la API o prepara un mensaje general.
  String _mensajeError(http.Response respuesta) {
    // Reconoce que la API rechazó las credenciales o el acceso de la cuenta.
    if (respuesta.statusCode == 401) {
      // Devuelve instrucciones para que la persona vuelva a autenticarse.
      return 'Tu sesión venció. Cierra sesión e inicia nuevamente.';
    }
    // Intenta completar la operación y atiende sus posibles errores.
    try {
      // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      // Comprueba que la respuesta tenga un mensaje detail de tipo texto antes de leerlo.
      if (datos is Map && datos['detail'] is String) {
        // Devuelve el mensaje enviado por FastAPI.
        return datos['detail'] as String;
      }
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
    }
    // Si no hay un mensaje específico, prepara un mensaje general con el estado HTTP.
    return 'No se pudo completar la operación '
        '(${respuesta.statusCode}).';
  }
  // Muestra avisos sin repetir su construcción en cada acción.
  void _mostrarMensaje(String mensaje) {
    // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
    if (!mounted) return;
    // Muestra un aviso temporal para indicar el resultado del registro.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
  // Actualiza los valores de las estrellas con el resumen que devolvió el servidor. Se llama dentro de setState.
  void _aplicarCalificacion(Map<String, dynamic> datos) {
    // Lee el promedio calculado por la API.
    final promedio = datos['promedio'];
    // Lee la cantidad de votos registrados.
    final votos = datos['total_votos'];
    // Lee el voto de la cuenta actual.
    final miVoto = datos['mi_voto'];
    // Acepta el promedio como número o intenta convertirlo si llegó en texto.
    _promedio = promedio is num
        ? promedio.toDouble()
        : double.tryParse(promedio?.toString() ?? '') ?? 0;
    // Convierte la cantidad de votos a un número entero.
    _totalVotos = votos is num
        ? votos.toInt()
        : int.tryParse(votos?.toString() ?? '') ?? 0;
    // Convierte el voto propio a un entero o lo deja en null si no hay uno.
    _miVoto = miVoto is num
        ? miVoto.toInt()
        : int.tryParse(miVoto?.toString() ?? '');
  }
  // Consulta el resumen de calificaciones y el voto propio de esta reseña.
  Future<void> _cargarCalificacion() async {
    // No inicia una consulta mientras todavía se está guardando un voto.
    if (_guardandoCalificacion) return;
    // Asigna un número nuevo a esta consulta para reconocer su respuesta al regresar.
    final consultaActual = ++_consultaCalificacion;
    // Obtiene el identificador de la reseña para consultar o modificar sus datos relacionados.
    final id = widget.publicacion['id_publicacion'];
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Muestra la carga y desactiva las estrellas mientras llegan los datos.
      _cargandoCalificacion = true;
      // Limpia el problema anterior antes de intentar la operación.
      _errorCalificacion = null;
    });
    // Intenta completar la operación y atiende sus posibles errores.
    try {
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Solicita datos al servidor utilizando el método GET.
          .get(
            Uri.parse(
              // Dirección para consultar o enviar las calificaciones de esta publicación.
              '$_servidor/api/publicaciones/$id/calificaciones',
            ),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          // Limita la espera de la respuesta a 20 segundos.
          .timeout(const Duration(seconds: 20));
      // Descarta la respuesta si la pantalla se cerró o ya comenzó una consulta más reciente.
      if (!mounted || consultaActual != _consultaCalificacion) {
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Informa si la API no pudo devolver la lista de comentarios.
      if (respuesta.statusCode != 200) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Guarda la explicación enviada por la API para mostrarla junto a las estrellas.
          _errorCalificacion = _mensajeError(respuesta);
        });
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      // Comprueba que la respuesta incluya campos con nombre antes de utilizarla.
      if (datos is! Map) {
        // Indica que la respuesta no tiene el formato esperado por esta pantalla.
        throw const FormatException('Respuesta inválida.');
      }
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Actualiza el promedio, la cantidad de votos y las estrellas seleccionadas.
        _aplicarCalificacion(Map<String, dynamic>.from(datos));
      });
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Descarta la respuesta si la pantalla se cerró o ya comenzó una consulta más reciente.
      if (!mounted || consultaActual != _consultaCalificacion) {
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        _errorCalificacion = 'No se pudo cargar la calificación.';
      });
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Solo la consulta vigente puede terminar el indicador de carga.
      if (mounted && consultaActual == _consultaCalificacion) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Retira el indicador cuando termina la consulta vigente.
          _cargandoCalificacion = false;
        });
      }
    }
  }
  // Envía las estrellas elegidas para registrar o cambiar el voto de esta cuenta.
  Future<void> _guardarCalificacion(int estrellas) async {
    // No permite votar mientras se consulta o se guarda otra calificación.
    if (_guardandoCalificacion || _cargandoCalificacion) {
      // Termina esta operación sin continuar con las instrucciones siguientes.
      return;
    }
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Obtiene el identificador de la reseña para consultar o modificar sus datos relacionados.
    final id = widget.publicacion['id_publicacion'];
    // Deja sin efecto las respuestas de consultas anteriores para que no reemplacen el voto nuevo.
    _consultaCalificacion++;
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Bloquea temporalmente las estrellas mientras la API confirma el voto.
      _guardandoCalificacion = true;
      // Limpia el problema anterior antes de intentar la operación.
      _errorCalificacion = null;
    });
    // Intenta completar la operación y atiende sus posibles errores.
    try {
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Envía las credenciales mediante una solicitud POST.
          .post(
            Uri.parse(
              // Dirección para consultar o enviar las calificaciones de esta publicación.
              '$_servidor/api/publicaciones/$id/calificaciones',
            ),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
              'Authorization': 'Bearer ${widget.token}',
              // Indica al servidor que el cuerpo de la solicitud contiene JSON.
              'Content-Type': 'application/json; charset=UTF-8',
            },
            // Convierte el correo y la contraseña al formato que espera la API.
            body: jsonEncode({
              // Envía la cantidad de estrellas seleccionadas como un número.
              'estrellas': estrellas,
            }),
          )
          // Limita la espera de la respuesta a 20 segundos.
          .timeout(const Duration(seconds: 20));
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Informa si la API no pudo devolver la lista de comentarios.
      if (respuesta.statusCode != 200) {
        _mostrarMensaje(_mensajeError(respuesta));
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      // Comprueba que la respuesta incluya campos con nombre antes de utilizarla.
      if (datos is! Map) {
        // Indica que la respuesta no tiene el formato esperado por esta pantalla.
        throw const FormatException('Respuesta inválida.');
      }
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Actualiza el promedio, la cantidad de votos y las estrellas seleccionadas.
        _aplicarCalificacion(Map<String, dynamic>.from(datos));
      });
      _mostrarMensaje('Calificación guardada correctamente.');
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        _errorCalificacion =
            'No se pudo confirmar el voto. '
            'Actualiza la calificación antes de intentarlo nuevamente.';
      });
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Comprueba que la pantalla de detalle siga activa antes de modificarla.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Vuelve a permitir acciones sobre las calificaciones al terminar el envío.
          _guardandoCalificacion = false;
        });
      }
    }
  }
  // Valida el texto y publica el comentario con la reacción seleccionada.
  Future<void> _publicarComentario() async {
    // Evita comenzar otra publicación o eliminación mientras se está procesando un comentario.
    if (_procesandoComentario) return;
    // No envía el comentario si el formulario no existe o no pasó la validación.
    if (!(_formularioComentario.currentState?.validate() ?? false)) {
      // Termina esta operación sin continuar con las instrucciones siguientes.
      return;
    }
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Retira los espacios sobrantes del comentario antes de enviarlo.
    final texto = _textoComentario.text.trim();
    // Obtiene el identificador de la reseña para consultar o modificar sus datos relacionados.
    final id = widget.publicacion['id_publicacion'];
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Bloquea las acciones de comentarios hasta terminar esta solicitud.
      _procesandoComentario = true;
    });
    // Intenta completar la operación y atiende sus posibles errores.
    try {
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Envía las credenciales mediante una solicitud POST.
          .post(
            // Construye la dirección de los comentarios de esta reseña.
            Uri.parse('$_servidor/api/publicaciones/$id/comentarios'),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
              'Authorization': 'Bearer ${widget.token}',
              // Indica al servidor que el cuerpo de la solicitud contiene JSON.
              'Content-Type': 'application/json; charset=UTF-8',
            },
            // Convierte el correo y la contraseña al formato que espera la API.
            body: jsonEncode({
              // Envía el contenido del comentario.
              'contenido': texto,
              // Envía la reacción elegida; el backend se encarga de guardarla con el comentario.
              'emoji': _emojiSeleccionado,
            }),
          )
          // Limita la espera de la respuesta a 20 segundos.
          .timeout(const Duration(seconds: 20));
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Exige la confirmación de creación del comentario antes de limpiar el formulario.
      if (respuesta.statusCode != 201) {
        _mostrarMensaje(_mensajeError(respuesta));
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Limpia el texto después de una publicación confirmada.
      _textoComentario.clear();
      // Retira los avisos de validación del formulario.
      _formularioComentario.currentState?.reset();
      // Consulta nuevamente para mostrar los comentarios actuales.
      _recargarComentarios();
      _mostrarMensaje('Comentario publicado correctamente.');
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      _mostrarMensaje(
        'No se pudo confirmar la publicación. '
        'Actualiza los comentarios antes de intentarlo nuevamente.',
      );
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Comprueba que la pantalla de detalle siga activa antes de modificarla.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Libera las acciones de comentarios al terminar, incluso si hubo un error.
          _procesandoComentario = false;
        });
      }
    }
  }
  // Comprueba la propiedad del comentario y solicita confirmación antes de eliminarlo.
  Future<void> _eliminarComentario(
    Map<String, dynamic> comentario,
  ) async {
    // Evita comenzar otra publicación o eliminación mientras se está procesando un comentario.
    if (_procesandoComentario) return;
    // Compara al autor del comentario con la cuenta que inició sesión.
    final esPropio = comentario['id_usuario'].toString() ==
        // Usa texto en ambos identificadores para compararlos aunque uno haya llegado como número.
        widget.usuario['id_usuario'].toString();
    // No permite solicitar desde esta función la eliminación de un comentario ajeno. La API también comprueba quién es su autor.
    if (!esPropio) return;
    // Abre un diálogo y espera la decisión de la persona.
    final confirmar = await showDialog<bool>(
      // Indica el contexto de la pantalla donde se abrirá el diálogo.
      context: context,
      // Construye el contenido del diálogo o de la sección según el estado actual.
      builder: (context) => AlertDialog(
        // Texto de la barra superior o del cuadro de confirmación.
        title: const Text('Eliminar comentario'),
        // Contenido principal del mensaje o del diálogo.
        content: const Text(
          '¿Quieres eliminar tu comentario definitivamente?',
        ),
        // Lista de botones de la barra superior o del diálogo.
        actions: [
          TextButton(
            // Cierra el diálogo y devuelve false: se canceló la eliminación.
            onPressed: () => Navigator.of(context).pop(false),
            // Widget que se coloca dentro de este contenedor.
            child: const Text('Cancelar'),
          ),
          FilledButton(
            // Cierra el diálogo y devuelve true: se confirmó la eliminación.
            onPressed: () => Navigator.of(context).pop(true),
            // Widget que se coloca dentro de este contenedor.
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    // Continúa solo si se confirmó, la pantalla sigue abierta y no empezó otra acción de comentarios.
    if (!mounted || confirmar != true || _procesandoComentario) {
      // Termina esta operación sin continuar con las instrucciones siguientes.
      return;
    }
    // Obtiene el identificador del comentario que se quiere eliminar.
    final id = comentario['id_comentario'];
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Bloquea las acciones de comentarios hasta terminar esta solicitud.
      _procesandoComentario = true;
    });
    // Intenta completar la operación y atiende sus posibles errores.
    try {
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Envía una solicitud DELETE a la API para eliminar el registro.
          .delete(
            // Construye la dirección de eliminación del comentario seleccionado.
            Uri.parse('$_servidor/api/comentarios/$id'),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          // Limita la espera de la respuesta a 20 segundos.
          .timeout(const Duration(seconds: 20));
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Si el comentario ya no existe, actualiza la lista y avisa al usuario.
      if (respuesta.statusCode == 404) {
        // Consulta nuevamente para mostrar los comentarios actuales.
        _recargarComentarios();
        _mostrarMensaje('El comentario ya no existe.');
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Informa si la API no pudo devolver la lista de comentarios.
      if (respuesta.statusCode != 200) {
        _mostrarMensaje(_mensajeError(respuesta));
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Consulta nuevamente para mostrar los comentarios actuales.
      _recargarComentarios();
      _mostrarMensaje('Comentario eliminado correctamente.');
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      _mostrarMensaje(
        'No se pudo confirmar la eliminación. '
        'Actualiza los comentarios para comprobarlo.',
      );
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Comprueba que la pantalla de detalle siga activa antes de modificarla.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Libera las acciones de comentarios al terminar, incluso si hubo un error.
          _procesandoComentario = false;
        });
      }
    }
  }
  // Construye el campo de opinión, las reacciones y el botón para publicar.
  Widget _formularioOpinion() {
    return Container(
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyDetalleEstilos.margenPanel,
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyDetalleEstilos.panel,
      // Widget que se coloca dentro de este contenedor.
      child: Form(
        // Vincula el Form con la clave utilizada para ejecutar sus validadores.
        key: _formularioComentario,
        // Widget que se coloca dentro de este contenedor.
        child: Column(
          // stretch estira los elementos horizontalmente dentro de la columna.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // Lista de widgets que se colocarán dentro del componente.
          children: [
            const Text(
              'DEJA TU OPINIÓN',
              // Estilo del texto o del botón.
              style: SpookyDetalleEstilos.encabezado,
            ),
            SpookyDetalleEstilos.separador,
            TextFormField(
              // Conecta el campo con el texto del comentario.
              controller: _textoComentario,
              // Evita modificar el comentario mientras se está publicando o eliminando uno.
              enabled: !_procesandoComentario,
              // Deja tres líneas visibles para escribir la opinión.
              minLines: 3,
              // Permite que el campo crezca hasta seis líneas visibles sin limitar por ello el texto total.
              maxLines: 6,
              // Limita la escritura a 500 caracteres visibles; el validador también revisa el límite que utiliza la API.
              maxLength: 500,
              // Quita el foco al tocar fuera del campo.
              onTapOutside: (_) {
                // Cierra el teclado antes de continuar con la acción.
                FocusScope.of(context).unfocus();
              },
              // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
              decoration: const InputDecoration(
                hintText: 'Escribe tu comentario...',
                alignLabelWithHint: true,
              ),
              // Revisa el texto y devuelve un mensaje si el nombre no es válido.
              validator: (valor) {
                final texto = (valor ?? '').trim();
                if (texto.isEmpty) {
                  return 'Escribe un comentario.';
                }
                // Comprueba el límite de 500 puntos de código Unicode que utiliza la API; algunos emojis combinados cuentan como más de uno.
                if (texto.runes.length > 500) {
                  return 'El comentario supera los 500 caracteres.';
                }
                // Indica que este campo pasó la validación.
                return null;
              },
            ),
            SpookyDetalleEstilos.espacioCorto,
            Wrap(
              // Separación horizontal entre los botones del Wrap.
              spacing: 8,
              // Separación entre filas cuando los botones no caben en una sola línea.
              runSpacing: 8,
              // Construye un botón por cada emoji y utiliza su nombre como descripción.
              children: _reacciones.entries.map((reaccion) {
                // Comprueba si este botón corresponde a la reacción elegida.
                final seleccionado =
                    // Compara el emoji del botón con el que se enviará al publicar.
                    _emojiSeleccionado == reaccion.key;
                return Tooltip(
                  // Describe el emoji para ayudar a reconocer la reacción.
                  message: reaccion.value,
                  // Widget que se coloca dentro de este contenedor.
                  child: Semantics(
                    // Indica a las herramientas de accesibilidad si esta reacción está seleccionada.
                    selected: seleccionado,
                    // Widget que se coloca dentro de este contenedor.
                    child: OutlinedButton(
                      // Estilo del texto o del botón.
                      style: SpookyComentarioEstilos.reaccion(
                        seleccionado,
                      ),
                      // Define la acción del botón y puede desactivarla mientras se procesa una operación.
                      onPressed: _procesandoComentario
                          ? null
                          : () {
                              // Actualiza los valores y refleja el cambio en la pantalla.
                              setState(() {
                                // Guarda la nueva reacción y actualiza el botón que aparece seleccionado.
                                _emojiSeleccionado = reaccion.key;
                              });
                            },
                      // Widget que se coloca dentro de este contenedor.
                      child: Text(
                        reaccion.key,
                        // Proporciona una descripción del emoji para los lectores de pantalla.
                        semanticsLabel: reaccion.value,
                        // Estilo del texto o del botón.
                        style: SpookyComentarioEstilos.emoji,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SpookyDetalleEstilos.espacio,
            DecoratedBox(
              // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
              decoration: SpookyPanelEstilos.resplandorBoton,
              // Widget que se coloca dentro de este contenedor.
              child: FilledButton(
                // Estilo del texto o del botón.
                style: SpookyPanelEstilos.boton,
                // Define la acción del botón y puede desactivarla mientras se procesa una operación.
                onPressed: _procesandoComentario
                    ? null
                    : _publicarComentario,
                // Widget que se coloca dentro de este contenedor.
                child: Text(
                  _procesandoComentario
                      ? 'Procesando...'
                      : 'Publicar comentario',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Reutiliza una misma tarjeta para mostrar al director y al actor.
  Widget _fichaPersona({
    required String etiqueta,
    required String nombre,
    required String foto,
  }) {
    // Las fichas de director y actor utilizan la misma validación de fotos locales.
    final direccion = _urlImagen(foto);
    // null indica que se mostrará la silueta porque no hay una dirección válida.
    final String? url = direccion.isEmpty ? null : direccion;
    return Container(
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyDetalleEstilos.fichaDirector,
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyDetalleEstilos.margenPanel,
      // Widget que se coloca dentro de este contenedor.
      child: Row(
        // Lista de widgets que se colocarán dentro del componente.
        children: [
          Container(
            // Establece el espacio interior alrededor del contenido.
            padding: const EdgeInsets.all(2),
            // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
            decoration: SpookyDetalleEstilos.marcoFoto,
            // Widget que se coloca dentro de este contenedor.
            child: ClipOval(
              // Widget que se coloca dentro de este contenedor.
              child: url == null
                  ? _sinFotoDirector()
                  : Image.network(
                      url,
                      // Ancho solicitado en unidades lógicas de Flutter.
                      width: SpookyDetalleEstilos.tamanoFoto,
                      // Altura solicitada en unidades lógicas de Flutter.
                      height: SpookyDetalleEstilos.tamanoFoto,
                      // Ajusta la imagen al espacio indicado: contain la muestra completa y cover llena el marco recortando lo necesario.
                      fit: BoxFit.cover,
                      // Muestra un icono si falla la imagen; no intenta cargar fotografías de prueba.
                      errorBuilder: (context, error, stackTrace) {
                        return _sinFotoDirector();
                      },
                    ),
            ),
          ),
          SpookyDetalleEstilos.espacioHorizontal,
          Expanded(
            // Widget que se coloca dentro de este contenedor.
            child: Column(
              // start alinea el contenido al inicio horizontal de la columna.
              crossAxisAlignment: CrossAxisAlignment.start,
              // Lista de widgets que se colocarán dentro del componente.
              children: [
                Text(
                  etiqueta,
                  // Estilo del texto o del botón.
                  style: SpookyDetalleEstilos.etiquetaDirector,
                ),
                SpookyDetalleEstilos.espacioCorto,
                Text(
                  nombre,
                  // Estilo del texto o del botón.
                  style: SpookyDetalleEstilos.nombreDirector,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Prepara la tarjeta con el nombre y la fotografía del director.
  Widget _seccionDirector() {
    final foto =
        (widget.publicacion['foto_director'] ?? '').toString().trim();
    final nombre =
        (widget.publicacion['director'] ?? 'Sin información').toString();
    return _fichaPersona(
      // Texto que identifica si la ficha corresponde al director o al protagonista.
      etiqueta: 'DIRECTOR RESPONSABLE',
      // Nombre de la persona que aparecerá en la ficha.
      nombre: nombre,
      // Referencia de la fotografía que utilizará la ficha.
      foto: foto,
    );
  }
  // Prepara la tarjeta del protagonista con la foto local que devuelve la API.
  Widget _seccionActor() {
    return _fichaPersona(
      // Texto que identifica si la ficha corresponde al director o al protagonista.
      etiqueta: 'ACTOR PROTAGONISTA',
      // Nombre de la persona que aparecerá en la ficha.
      nombre: (widget.publicacion['actor'] ?? '').toString(),
      // Referencia de la fotografía que utilizará la ficha.
      foto: (widget.publicacion['foto_actor'] ?? '').toString().trim(),
    );
  }
  // Acomoda las fichas del director y del actor según el espacio disponible.
  Widget _personas() {
    // Comprueba si la publicación tiene un actor para mostrar su ficha.
    final tieneActor =
        (widget.publicacion['actor'] ?? '').toString().trim().isNotEmpty;
    return LayoutBuilder(
      // Construye el contenido del diálogo o de la sección según el estado actual.
      builder: (context, constraints) {
        if (!tieneActor) {
          return _seccionDirector();
        }
        // Tiene en cuenta el tamaño de texto elegido en el teléfono al decidir la distribución.
        final escala =
            MediaQuery.textScalerOf(context).scale(16) / 16;
        // Coloca las fichas una junto a otra solo cuando hay suficiente ancho; en el teléfono se muestran una debajo de otra.
        if (constraints.maxWidth >= 700 * escala) {
          return Row(
            // stretch estira los elementos horizontalmente dentro de la columna.
            crossAxisAlignment: CrossAxisAlignment.start,
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              Expanded(child: _seccionDirector()),
              const SizedBox(width: 16),
              Expanded(child: _seccionActor()),
            ],
          );
        }
        return Column(
          // stretch estira los elementos horizontalmente dentro de la columna.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // Lista de widgets que se colocarán dentro del componente.
          children: [
            _seccionDirector(),
            const SizedBox(height: 16),
            _seccionActor(),
          ],
        );
      },
    );
  }
  // Construye las etiquetas y permite que pasen a otra línea cuando sea necesario.
  Widget _etiquetas(List<String> etiquetas) {
    return Wrap(
      // Separación horizontal entre los botones del Wrap.
      spacing: 8,
      // Separación entre filas cuando los botones no caben en una sola línea.
      runSpacing: 8,
      // Lista de widgets que se colocarán dentro del componente.
      children: etiquetas.map((etiqueta) {
        return Container(
          // Establece el espacio interior alrededor del contenido.
          padding: SpookyLectorEstilos.margenEtiqueta,
          // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
          decoration: SpookyLectorEstilos.etiqueta,
          // Widget que se coloca dentro de este contenedor.
          child: Text(
            etiqueta,
            // Estilo del texto o del botón.
            style: SpookyLectorEstilos.etiquetaTexto,
          ),
        );
      }).toList(),
    );
  }
  // Construye el resumen de votos, las cinco estrellas y los mensajes de esta sección.
  Widget _seccionCalificacion() {
    // Desactiva las estrellas mientras se consulta, se guarda o hay un error pendiente de actualizar.
    final deshabilitado = _cargandoCalificacion ||
        _guardandoCalificacion ||
        _errorCalificacion != null;
    return Container(
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyDetalleEstilos.margenPanel,
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyDetalleEstilos.panel,
      // Widget que se coloca dentro de este contenedor.
      child: Column(
        // stretch estira los elementos horizontalmente dentro de la columna.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Lista de widgets que se colocarán dentro del componente.
        children: [
          const Text(
            'CALIFICACIÓN',
            // Estilo del texto o del botón.
            style: SpookyDetalleEstilos.encabezado,
          ),
          SpookyDetalleEstilos.separador,
          if (_cargandoCalificacion)
            const Center(
              // Widget que se coloca dentro de este contenedor.
              child: CircularProgressIndicator(),
            )
          else if (_errorCalificacion != null) ...[
            Text(
              _errorCalificacion!,
              // Estilo del texto o del botón.
              style: SpookyDetalleEstilos.contenido,
            ),
            Align(
              alignment: Alignment.centerLeft,
              // Widget que se coloca dentro de este contenedor.
              child: TextButton(
                // Define la acción del botón y puede desactivarla mientras se procesa una operación.
                onPressed: _guardandoCalificacion
                    ? null
                    : () {
                        // Solicita el promedio, la cantidad de votos y la calificación de la cuenta actual.
                        _cargarCalificacion();
                      },
                // Widget que se coloca dentro de este contenedor.
                child: const Text('Actualizar calificación'),
              ),
            ),
          ] else ...[
            Text(
              _totalVotos == 0
                  ? 'Todavía no hay calificaciones.'
                  : '${_promedio.toStringAsFixed(1)} / 5 · '
                      '$_totalVotos '
                      '${_totalVotos == 1 ? 'voto' : 'votos'}',
              // Estilo del texto o del botón.
              style: SpookyDetalleEstilos.contenido,
            ),
            SpookyDetalleEstilos.espacioCorto,
            const Text(
              'Toca una estrella para calificar.',
              // Estilo del texto o del botón.
              style: SpookyDetalleEstilos.contenido,
            ),
          ],
          SpookyDetalleEstilos.espacioCorto,
          Wrap(
            // Separación horizontal entre los botones del Wrap.
            spacing: 2,
            // Separación entre filas cuando los botones no caben en una sola línea.
            runSpacing: 4,
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              // Construye un botón por cada valor posible de la calificación, de una a cinco estrellas.
              for (int estrella = 1; estrella <= 5; estrella++)
                IconButton(
                  // Descripción de ayuda y accesibilidad del botón.
                  tooltip: 'Calificar con $estrella '
                      '${estrella == 1 ? 'estrella' : 'estrellas'}',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  // Define la acción del botón y puede desactivarla mientras se procesa una operación.
                  onPressed: deshabilitado
                      ? null
                      : () {
                          // Envía el valor del botón de estrella que se pulsó.
                          _guardarCalificacion(estrella);
                        },
                  // Icono que acompaña la acción.
                  icon: Icon(
                    // Rellena las estrellas según el voto propio, no según el promedio de toda la comunidad.
                    estrella <= (_miVoto ?? 0)
                        ? Icons.star
                        : Icons.star_border,
                    // Color tomado del tema o del esquema de colores.
                    color: estrella <= (_miVoto ?? 0)
                        ? Colors.amber
                        : SpookyTema.textoSecundario,
                    // Tamaño del icono en unidades lógicas.
                    size: 32,
                  ),
                ),
            ],
          ),
          if (_guardandoCalificacion) ...[
            SpookyDetalleEstilos.espacioCorto,
            const LinearProgressIndicator(),
          ],
          if (!_cargandoCalificacion &&
              _errorCalificacion == null &&
              _miVoto != null) ...[
            SpookyDetalleEstilos.espacioCorto,
            Text(
              'Tu calificación: $_miVoto / 5',
              // Estilo del texto o del botón.
              style: SpookyDetalleEstilos.contenido,
            ),
            SpookyDetalleEstilos.espacioCorto,
            const Text(
              'Puedes cambiarla tocando otra estrella.',
              // Estilo del texto o del botón.
              style: SpookyDetalleEstilos.contenido,
            ),
          ],
        ],
      ),
    );
  }
  // Presenta la portada real con su sombra e indicador de carga.
  Widget _portada() {
    // Si no hay una portada válida, no solicita una imagen de prueba.
    final url = _urlPortada;
    if (url.isEmpty) return const SizedBox.shrink();
    return Center(
      // Widget que se coloca dentro de este contenedor.
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          // Limita el ancho de la portada al valor definido en el tema de Cruppis.
          maxWidth: SpookyDetalleEstilos.anchoPortada,
        ),
        // Widget que se coloca dentro de este contenedor.
        child: DecoratedBox(
          // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
          decoration: SpookyDetalleEstilos.sombraPortada,
          // Widget que se coloca dentro de este contenedor.
          child: ClipRRect(
            // Redondea las esquinas de la imagen o del botón.
            borderRadius: BorderRadius.circular(
              SpookyDetalleEstilos.radioPortada,
            ),
            // Widget que se coloca dentro de este contenedor.
            child: Image.network(
              url,
              // Ancho solicitado en unidades lógicas de Flutter.
              width: double.infinity,
              // Ajusta la imagen al espacio indicado: contain la muestra completa y cover llena el marco recortando lo necesario.
              fit: BoxFit.contain,
              // Muestra un indicador mientras se descarga la portada.
              loadingBuilder: (context, child, progreso) {
                // Cuando termina la descarga, muestra la imagen en lugar del indicador.
                if (progreso == null) return child;
                return const SizedBox(
                  // Altura solicitada en unidades lógicas de Flutter.
                  height: 220,
                  // Widget que se coloca dentro de este contenedor.
                  child: Center(
                    // Widget que se coloca dentro de este contenedor.
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              // Muestra un icono si falla la imagen; no intenta cargar fotografías de prueba.
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  // Altura solicitada en unidades lógicas de Flutter.
                  height: 180,
                  // Widget que se coloca dentro de este contenedor.
                  child: Center(
                    // Widget que se coloca dentro de este contenedor.
                    child: Icon(
                      Icons.broken_image_outlined,
                      // Tamaño del icono en unidades lógicas.
                      size: 56,
                      // Color tomado del tema o del esquema de colores.
                      color: SpookyTema.textoSecundario,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
  // Reúne la portada, el tipo, el título, las etiquetas, la sinopsis y las personas de la reseña.
  Widget _fichaPublicacion() {
    // Utiliza los datos recibidos al abrir esta pantalla.
    final publicacion = widget.publicacion;
    final titulo = (publicacion['titulo'] ?? 'Sin título').toString();
    // Prepara las etiquetas antes de construir sus elementos visuales.
    final etiquetas = _obtenerEtiquetas();
    return Container(
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyDetalleEstilos.margenPanel,
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyDetalleEstilos.panel,
      // Widget que se coloca dentro de este contenedor.
      child: Column(
        // stretch estira los elementos horizontalmente dentro de la columna.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Lista de widgets que se colocarán dentro del componente.
        children: [
          _portada(),
          SpookyDetalleEstilos.espacio,
          Text(
            (publicacion['tipo'] ?? '').toString().toUpperCase(),
            // Estilo del texto o del botón.
            style: SpookyDetalleEstilos.tipo,
          ),
          SpookyDetalleEstilos.espacioCorto,
          Text(
            titulo,
            // Estilo del texto o del botón.
            style: SpookyDetalleEstilos.titulo,
          ),
          if (etiquetas.isNotEmpty) ...[
            SpookyDetalleEstilos.espacio,
            _etiquetas(etiquetas),
          ],
          SpookyDetalleEstilos.espacio,
          Text(
            '${publicacion['sinopsis'] ?? 'Sin sinopsis'}',
            // Estilo del texto o del botón.
            style: SpookyDetalleEstilos.contenido,
          ),
          SpookyDetalleEstilos.espacio,
          _personas(),
        ],
      ),
    );
  }
  // Muestra el autor, la fecha y el contenido de un comentario; ofrece eliminarlo si pertenece a la cuenta actual.
  Widget _comentario(Map<String, dynamic> comentario) {
    final nombre = (comentario['usuario'] ?? '').toString().trim();
    // Da formato a la fecha que ya tiene el comentario.
    final fecha = _fechaComentario(comentario['fecha']);
    // Compara al autor del comentario con la cuenta que inició sesión.
    final esPropio = comentario['id_usuario'].toString() ==
        // Usa texto en ambos identificadores para compararlos aunque uno haya llegado como número.
        widget.usuario['id_usuario'].toString();
    return Padding(
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyDetalleEstilos.margenComentario,
      // Widget que se coloca dentro de este contenedor.
      child: Column(
        // stretch estira los elementos horizontalmente dentro de la columna.
        crossAxisAlignment: CrossAxisAlignment.start,
        // Lista de widgets que se colocarán dentro del componente.
        children: [
          Wrap(
            // Separación horizontal entre los botones del Wrap.
            spacing: 12,
            // Separación entre filas cuando los botones no caben en una sola línea.
            runSpacing: 6,
            // stretch estira los elementos horizontalmente dentro de la columna.
            crossAxisAlignment: WrapCrossAlignment.center,
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              Text(
                nombre.isEmpty ? 'Usuario' : nombre,
                // Estilo del texto o del botón.
                style: SpookyDetalleEstilos.autorComentario,
              ),
              if (fecha.isNotEmpty)
                Text(
                  fecha,
                  // Estilo del texto o del botón.
                  style: SpookyDetalleEstilos.fecha,
                ),
            ],
          ),
          SpookyDetalleEstilos.espacioCorto,
          Text(
            '${comentario['contenido'] ?? ''}',
            // Estilo del texto o del botón.
            style: SpookyDetalleEstilos.contenido,
          ),
          // Incluye el botón de eliminación únicamente en los comentarios propios.
          if (esPropio)
            Align(
              alignment: Alignment.centerRight,
              // Widget que se coloca dentro de este contenedor.
              child: TextButton(
                // Define la acción del botón y puede desactivarla mientras se procesa una operación.
                onPressed: _procesandoComentario
                    ? null
                    : () => _eliminarComentario(comentario),
                // Widget que se coloca dentro de este contenedor.
                child: const Text('Eliminar'),
              ),
            ),
        ],
      ),
    );
  }
  // Presenta la carga, los errores o la lista de comentarios según el resultado de la consulta.
  Widget _seccionComentarios() {
    return Container(
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyDetalleEstilos.margenPanel,
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyDetalleEstilos.panel,
      // Widget que se coloca dentro de este contenedor.
      child: FutureBuilder<List<Map<String, dynamic>>>(
        // Observa la consulta de comentarios para mostrar su avance y resultado.
        future: _comentarios,
        // Construye el contenido del diálogo o de la sección según el estado actual.
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              // Establece el espacio interior alrededor del contenido.
              padding: SpookyDetalleEstilos.margenPanel,
              // Widget que se coloca dentro de este contenedor.
              child: Center(
                // Widget que se coloca dentro de este contenedor.
                child: CircularProgressIndicator(),
              ),
            );
          }
          // Muestra el mensaje de error y una opción para volver a consultar.
          if (snapshot.hasError) {
            return Column(
              // start alinea el contenido al inicio horizontal de la columna.
              crossAxisAlignment: CrossAxisAlignment.start,
              // Lista de widgets que se colocarán dentro del componente.
              children: [
                const Text(
                  'COMENTARIOS',
                  // Estilo del texto o del botón.
                  style: SpookyDetalleEstilos.encabezado,
                ),
                SpookyDetalleEstilos.espacio,
                const Text(
                  'No se pudieron cargar los comentarios.',
                  // Estilo del texto o del botón.
                  style: SpookyDetalleEstilos.contenido,
                ),
                TextButton(
                  // Define la acción del botón y puede desactivarla mientras se procesa una operación.
                  onPressed: _recargarComentarios,
                  // Widget que se coloca dentro de este contenedor.
                  child: const Text('Reintentar'),
                ),
              ],
            );
          }
          // Utiliza la lista recibida o una lista vacía cuando no hay resultados.
          final comentarios = snapshot.data ?? [];
          return Column(
            // stretch estira los elementos horizontalmente dentro de la columna.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              Text(
                'COMENTARIOS RECIENTES (${comentarios.length})',
                // Estilo del texto o del botón.
                style: SpookyDetalleEstilos.encabezado,
              ),
              SpookyDetalleEstilos.separador,
              if (comentarios.isEmpty)
                const Text(
                  'Todavía no hay comentarios en esta reseña.',
                  // Estilo del texto o del botón.
                  style: SpookyDetalleEstilos.contenido,
                )
              else
                // Agrega el contenido y el separador de cada comentario recibido.
                for (final comentario in comentarios) ...[
                  _comentario(comentario),
                  SpookyDetalleEstilos.separadorComentarios,
                ],
            ],
          );
        },
      ),
    );
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Organiza las secciones del detalle dentro de una pantalla que se puede desplazar y actualizar.
  Widget build(BuildContext context) {
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
            // Define la acción del botón y puede desactivarla mientras se procesa una operación.
            onPressed: _actualizarDetalle,
            // Descripción de ayuda y accesibilidad del botón.
            tooltip: 'Actualizar comentarios y calificación',
            // Icono que acompaña la acción.
            icon: const Icon(Icons.refresh),
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
        child: SizedBox.expand(
          // Widget que se coloca dentro de este contenedor.
          child: SafeArea(
            // Widget que se coloca dentro de este contenedor.
            child: RefreshIndicator(
              // Al deslizar hacia abajo, consulta otra vez los comentarios y las calificaciones.
              onRefresh: _actualizarDetalle,
              // Widget que se coloca dentro de este contenedor.
              child: SingleChildScrollView(
                // Permite deslizar para actualizar incluso si el contenido es corto.
                physics: const AlwaysScrollableScrollPhysics(),
                // Configura cómo se oculta el teclado al desplazar el formulario.
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                // Establece el espacio interior alrededor del contenido.
                padding: SpookyDetalleEstilos.margenPantalla,
                // Widget que se coloca dentro de este contenedor.
                child: Column(
                  // stretch estira los elementos horizontalmente dentro de la columna.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  // Lista de widgets que se colocarán dentro del componente.
                  children: [
                    _fichaPublicacion(),
                    SpookyDetalleEstilos.espacio,
                    _seccionCalificacion(),
                    SpookyDetalleEstilos.espacio,
                    _formularioOpinion(),
                    SpookyDetalleEstilos.espacio,
                    _seccionComentarios(),
                    SpookyDetalleEstilos.espacio,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
