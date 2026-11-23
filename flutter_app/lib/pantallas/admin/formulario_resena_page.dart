// CRUPPIS — Formulario para publicar y editar reseñas.
// Carga directores y actores, revisa los campos y envía el formulario a la API.
// StatefulWidget permite actualizar el formulario; State guarda sus datos e indicadores.
// Future es un resultado pendiente; async y await permiten esperar sin bloquear la pantalla.
// Future.wait espera varias consultas y conserva el orden en que se escribieron.
// Map agrupa campos por nombre; List reúne registros y dynamic permite distintos tipos de valores.
// late indica que la variable se preparará antes de utilizarla; final impide reasignarla.
// null representa un valor ausente; ?? utiliza la alternativa indicada cuando falta el dato.
// setState pide actualizar la interfaz; mounted comprueba que la pantalla siga activa.
// GlobalKey permite acceder al Form para ejecutar sus validadores antes de guardar.
// JSON es el formato de respuesta de la API; UTF-8 conserva acentos y otros caracteres.
// MultipartRequest envía campos de texto y un archivo juntos; POST registra y PUT actualiza.
// split divide el texto; trim quita espacios exteriores y join une los valores.
// toSet reúne valores sin repetirlos; contains comprueba si un ID pertenece al conjunto.
// runes.length cuenta puntos de código Unicode; utf8.encode mide el texto en bytes.
// condición ? opción : otraOpción elige un valor; onPressed: null desactiva un botón.
// La portada es opcional: al editar se conserva la actual si no se elige otra.
// Una reseña nueva sin imagen queda sin portada; no se asigna una imagen de prueba.
// Permite convertir las respuestas JSON a datos de Dart y decodificar el texto UTF-8.
import 'dart:convert';
// Permite mostrar un archivo de imagen del teléfono. Este archivo está pensado para la app móvil, no para Flutter web.
import 'dart:io';
// Importa widgets, navegación, formularios, colores y otros componentes Material de Flutter.
import 'package:flutter/material.dart';
// Importa las peticiones HTTP con el prefijo http para distinguir sus clases y funciones.
import 'package:http/http.dart' as http;
// Permite seleccionar una fotografía desde la galería del teléfono.
import 'package:image_picker/image_picker.dart';
// Este formulario sirve para publicar una reseña nueva o modificar una que ya existe.
class FormularioResenaPage extends StatefulWidget {
  // Recibe el token de la sesión y, al editar, los datos de la reseña.
  const FormularioResenaPage({
    // Permite que Flutter identifique este widget dentro del árbol de la interfaz.
    super.key,
    // Obliga a proporcionar el token al abrir la pantalla.
    required this.token,
    this.resena,
  });
  // Conserva el token recibido; final impide reasignar esta propiedad del widget.
  final String token;
  // Conserva los datos de la reseña; null indica que se trata de una publicación nueva.
  final Map<String, dynamic>? resena;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Crea el estado que controla los campos, las selecciones y el guardado.
  State<FormularioResenaPage> createState() =>
      _FormularioResenaPageState();
}
// Reúne los datos del formulario y las acciones necesarias para consultar y guardar en la API.
class _FormularioResenaPageState extends State<FormularioResenaPage> {
  // Dirección de la API en la computadora. Hay que actualizarla si cambia su IPv4.
  static const _servidor = 'http://10.13.40.223:8000';
  // Permite acceder al estado del Form y ejecutar sus validadores.
  final _formulario = GlobalKey<FormState>();
  // Crea el selector de imágenes que abre la galería.
  final _selector = ImagePicker();
  // Controla el título y permite cargar el texto actual cuando se edita.
  late final TextEditingController _titulo;
  // Controla el contenido escrito en la sinopsis.
  late final TextEditingController _sinopsis;
  // Controla las etiquetas escritas y separadas con comas.
  late final TextEditingController _etiquetas;
  // Guarda una consulta conjunta: la primera lista contiene directores y la segunda contiene actores.
  late Future<List<List<Map<String, dynamic>>>> _datosFormulario;
  // Usa Película como tipo inicial hasta que se elija otro o se cargue una reseña.
  String _tipo = 'Película';
  // Guarda el identificador del director seleccionado; comienza sin valor si no hay uno asignado.
  int? _idDirector;
  // Guarda el identificador del actor protagonista seleccionado.
  int? _idActor;
  // Conserva la imagen nueva elegida para la portada, si se selecciona una.
  XFile? _portada;
  // Indica que se está enviando el formulario.
  bool _guardando = false;
  // Indica que se está abriendo o procesando la selección de una fotografía.
  bool _seleccionando = false;
  // Guarda el mensaje que se mostrará debajo de los campos; null significa que no hay error.
  String? _error;
  // Permite distinguir entre publicar una reseña nueva y editar una existente.
  bool get _editando => widget.resena != null;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Se ejecuta una vez cuando se crea el estado del widget.
  void initState() {
    // Ejecuta primero la inicialización que necesita la clase de Flutter.
    super.initState();
    // Prepara el campo del título con los datos actuales o lo deja vacío.
    _titulo = TextEditingController(
      text: (widget.resena?['titulo'] ?? '').toString(),
    );
    // Prepara el campo de la sinopsis con los datos de la reseña que se está editando.
    _sinopsis = TextEditingController(
      text: (widget.resena?['sinopsis'] ?? '').toString(),
    );
    // Recupera las etiquetas existentes para mostrarlas dentro del campo.
    final etiquetasGuardadas = widget.resena?['etiquetas'];
    // Prepara el campo de etiquetas tanto si la API las devuelve como lista como si llegan en un texto.
    _etiquetas = TextEditingController(
      text: etiquetasGuardadas is List
          // Si llegan como lista, conserva los textos y los une separándolos con comas.
          ? etiquetasGuardadas.whereType<String>().join(', ')
          : (etiquetasGuardadas ?? '').toString(),
    );
    // Carga Serie cuando ese es el tipo guardado; en los demás casos utiliza Película.
    _tipo = widget.resena?['tipo'] == 'Serie' ? 'Serie' : 'Película';
    // Intenta recuperar el identificador del director como número; si no existe, queda en null.
    _idDirector = int.tryParse(
      '${widget.resena?['id_director']}',
    );
    // Intenta recuperar el identificador del actor que ya estaba asignado.
    _idActor = int.tryParse(
      '${widget.resena?['id_actor']}',
    );
    // Inicia de nuevo la consulta de los datos que necesitan las listas de selección.
    _datosFormulario = _cargarDatosFormulario();
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Libera recursos cuando el formulario deja de utilizarse.
  void dispose() {
    // Libera el controlador del título al cerrar el formulario.
    _titulo.dispose();
    // Libera el controlador de la sinopsis.
    _sinopsis.dispose();
    // Libera el controlador de las etiquetas.
    _etiquetas.dispose();
    // Completa la liberación del estado de Flutter.
    super.dispose();
  }
  // Prepara las dos consultas necesarias para elegir un director y un actor.
  Future<List<List<Map<String, dynamic>>>> _cargarDatosFormulario() {
    // Inicia ambas consultas y espera sus resultados. Conserva el orden: directores primero y actores después.
    return Future.wait<List<Map<String, dynamic>>>([
      // Solicita los directores registrados.
      _consultarDirectores(),
      // Solicita los actores registrados.
      _consultarActores(),
    ]);
  }
  // Consulta los directores disponibles para relacionarlos con la reseña.
  Future<List<Map<String, dynamic>>> _consultarDirectores() async {
    // Inicia una petición HTTP y espera su respuesta de forma asíncrona.
    final respuesta = await http
        // Solicita datos al servidor utilizando el método GET.
        .get(
          // Prepara la dirección de la consulta administrativa de directores.
          Uri.parse('$_servidor/api/admin/directores'),
          // Encabezados que acompañan la petición HTTP.
          headers: {
            // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
            'Authorization': 'Bearer ${widget.token}',
          },
        )
        // Limita a 20 segundos la espera de esta operación; un timeout no demuestra si el servidor terminó una modificación.
        .timeout(const Duration(seconds: 20));
    // Si la consulta no terminó correctamente, informa del error en lugar de usar la respuesta como una lista.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar los directores. '
        'Si la sesión venció, inicia sesión nuevamente.',
      );
    }
    // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la respuesta sea una lista antes de convertir sus registros.
    if (datos is! List) {
      // Indica que la respuesta no tiene el formato esperado por esta pantalla.
      throw const FormatException('Respuesta inválida.');
    }
    // Prepara la lista de registros que utilizará el selector.
    return datos
        // Convierte cada registro en un mapa con los nombres de sus campos y sus valores.
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        // Reúne los resultados en una lista.
        .toList();
  }
  // Consulta los actores disponibles para elegir al protagonista.
  Future<List<Map<String, dynamic>>> _consultarActores() async {
    // Inicia una petición HTTP y espera su respuesta de forma asíncrona.
    final respuesta = await http
        // Solicita datos al servidor utilizando el método GET.
        .get(
          // Prepara la dirección de la consulta administrativa de actores.
          Uri.parse('$_servidor/api/admin/actores'),
          // Encabezados que acompañan la petición HTTP.
          headers: {
            // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
            'Authorization': 'Bearer ${widget.token}',
          },
        )
        // Limita a 20 segundos la espera de esta operación; un timeout no demuestra si el servidor terminó una modificación.
        .timeout(const Duration(seconds: 20));
    // Si la consulta no terminó correctamente, informa del error en lugar de usar la respuesta como una lista.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar los actores. '
        'Si la sesión venció, inicia sesión nuevamente.',
      );
    }
    // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la respuesta sea una lista antes de convertir sus registros.
    if (datos is! List) {
      // Indica que la respuesta no tiene el formato esperado por esta pantalla.
      throw const FormatException('Respuesta inválida.');
    }
    // Prepara la lista de registros que utilizará el selector.
    return datos
        // Convierte cada registro en un mapa con los nombres de sus campos y sus valores.
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        // Reúne los resultados en una lista.
        .toList();
  }
  // Abre la galería y revisa el tamaño de la portada antes de mostrarla.
  Future<void> _seleccionarPortada() async {
    // Evita iniciar otra operación mientras se guarda o se selecciona una imagen.
    if (_guardando || _seleccionando) return;
    // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
    setState(() {
      // Activa el indicador de selección para evitar pulsaciones repetidas.
      _seleccionando = true;
      // Limpia el mensaje de error anterior.
      _error = null;
    });
    // Intenta completar la operación y atiende los errores si algo falla.
    try {
      // Espera que se elija una imagen o se cancele la selección.
      final imagen = await _selector.pickImage(
        // Selecciona imágenes de la galería, no de la cámara.
        source: ImageSource.gallery,
        // Solicita una anchura máxima de 1600 para la imagen seleccionada.
        maxWidth: 1600,
        // Solicita una altura máxima de 1600 para la imagen seleccionada.
        maxHeight: 1600,
        // Solicita calidad 85 para los formatos y plataformas que admiten este ajuste.
        imageQuality: 85,
      );
      // Si se cancela la galería, conserva la portada anterior.
      if (imagen == null) return;
      // Revisa que el archivo seleccionado no supere los 5 MB.
      if (await imagen.length() > 5 * 1024 * 1024) {
        // Interrumpe la selección para mostrar el aviso del tamaño permitido.
        throw Exception('Imagen demasiado grande.');
      }
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
      setState(() {
        // Conserva la imagen seleccionada y permite actualizar su vista previa.
        _portada = imagen;
      });
    // Si ocurre un problema, prepara un mensaje para explicar qué pasó.
    } catch (_) {
      // Comprueba que el estado siga asociado a una pantalla antes de llamar a setState.
      if (mounted) {
        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
        setState(() {
          _error = 'Selecciona una imagen JPG, PNG o WEBP de hasta 5 MB.';
        });
      }
    // Este bloque se ejecuta tanto si la operación tuvo éxito como si falló.
    } finally {
      // Comprueba que el estado siga asociado a una pantalla antes de llamar a setState.
      if (mounted) {
        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
        setState(() {
          // Libera el estado de selección al terminar, incluso si hubo un error.
          _seleccionando = false;
        });
      }
    }
  }
  // Revisa el formulario y envía sus datos a la API para publicar o actualizar la reseña.
  Future<void> _guardar() async {
    // Evita repetir el envío o guardar mientras todavía se está eligiendo una imagen.
    if (_guardando ||
        _seleccionando ||
        // Ejecuta las validaciones de los campos; si alguna falla, no continúa con el envío.
        !(_formulario.currentState?.validate() ?? false)) {
      // Termina la operación sin continuar con el envío.
      return;
    }
    // Quita el foco del campo activo para cerrar el teclado.
    FocusScope.of(context).unfocus();
    // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
    setState(() {
      // Bloquea las acciones durante el envío y permite mostrar un indicador de progreso.
      _guardando = true;
      // Limpia el mensaje de error anterior.
      _error = null;
    });
    // Crea un cliente HTTP para enviar la solicitud multipart y cerrarlo al finalizar.
    final cliente = http.Client();
    // Permite cerrar el formulario únicamente cuando la API haya confirmado el guardado.
    bool guardado = false;
    // Intenta completar la operación y atiende los errores si algo falla.
    try {
      // Elige la dirección de la reseña existente al editar, o la dirección general al publicar.
      final ruta = _editando
          ? '$_servidor/api/admin/resenas/'
              '${widget.resena!['id_publicacion']}'
          : '$_servidor/api/admin/resenas';
      // Prepara una solicitud multipart para enviar campos de texto y un archivo en la misma petición.
      final solicitud = http.MultipartRequest(
        // Utiliza PUT para modificar una reseña y POST para publicar una nueva.
        _editando ? 'PUT' : 'POST',
        Uri.parse(ruta),
      );
      // Agrega el token de sesión para que el backend compruebe la autorización.
      solicitud.headers['Authorization'] = 'Bearer ${widget.token}';
      // Añade al formulario los datos de texto que espera la API.
      solicitud.fields.addAll({
        // Envía el título sin espacios sobrantes al principio o al final.
        'titulo': _titulo.text.trim(),
        // Envía el tipo seleccionado: Película o Serie.
        'tipo': _tipo,
        // Envía el identificador del director que pasó la validación del selector.
        'id_director': _idDirector.toString(),
        // Envía el identificador del actor seleccionado.
        'id_actor': _idActor.toString(),
        // Envía las etiquetas separadas por comas para que el backend las procese.
        'etiquetas': _etiquetas.text.trim(),
        // Envía la sinopsis sin espacios sobrantes en los extremos.
        'sinopsis': _sinopsis.text.trim(),
      });
      // Obtiene la referencia de la portada nueva, si se eligió una.
      final portada = _portada;
      // Adjunta una portada solo cuando se seleccionó una nueva; al editar, la API puede conservar la actual.
      if (portada != null) {
        // Añade el archivo a las partes de la solicitud multipart.
        solicitud.files.add(
          // Lee el archivo indicado por su ruta y prepara el adjunto para enviarlo.
          await http.MultipartFile.fromPath(
            // Nombre del campo de archivo que espera el backend para la portada.
            'portada',
            // Indica dónde está guardada la imagen seleccionada en el teléfono.
            portada.path,
            // Envía el nombre del archivo junto con la imagen.
            filename: portada.name,
          ),
        );
      }
      // Agrupa el envío y la lectura en una sola operación con límite de espera.
      final respuesta = await (() async {
        // Envía la solicitud y recibe una respuesta que llega como flujo de datos.
        final envio = await cliente.send(solicitud);
        // Lee el flujo completo y lo transforma en una respuesta HTTP que se puede consultar.
        return http.Response.fromStream(envio);
      // Limita a 30 segundos la espera del conjunto; si vence, el servidor podría haber alcanzado a guardar.
      })().timeout(const Duration(seconds: 30));
      // Reconoce la confirmación de actualización o de creación que devuelve la API.
      if (respuesta.statusCode == 200 || respuesta.statusCode == 201) {
        // Marca que la API confirmó el guardado.
        guardado = true;
      // Utiliza esta alternativa cuando no se cumple la condición anterior.
      } else {
        String mensaje = 'No se pudo guardar la reseña.';
        // Reconoce que el servidor no autorizó la sesión; por ejemplo, porque el token venció.
        if (respuesta.statusCode == 401) {
          mensaje = 'La sesión venció. Inicia sesión nuevamente.';
        } else if (respuesta.statusCode == 403) {
          mensaje = 'Tu cuenta no tiene permisos administrativos.';
        // Utiliza esta alternativa cuando no se cumple la condición anterior.
        } else {
          // Intenta completar la operación y atiende los errores si algo falla.
          try {
            final datos = jsonDecode(
              utf8.decode(respuesta.bodyBytes),
            );
            // Comprueba que la respuesta tenga un mensaje detail de tipo texto antes de leerlo.
            if (datos is Map && datos['detail'] is String) {
              mensaje = datos['detail'] as String;
            }
          // Si ocurre un problema, prepara un mensaje para explicar qué pasó.
          } catch (_) {
          }
        }
        // Comprueba que el estado siga asociado a una pantalla antes de llamar a setState.
        if (mounted) {
          // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
          setState(() {
            _error = mensaje;
          });
        }
      }
    // Si ocurre un problema, prepara un mensaje para explicar qué pasó.
    } catch (_) {
      // Comprueba que el estado siga asociado a una pantalla antes de llamar a setState.
      if (mounted) {
        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
        setState(() {
          _error = 'No se pudo confirmar el guardado. '
              'Regresa y actualiza la lista antes de intentar nuevamente.';
        });
      }
    // Este bloque se ejecuta tanto si la operación tuvo éxito como si falló.
    } finally {
      // Libera los recursos del cliente HTTP al terminar la operación.
      cliente.close();
      // Comprueba que el estado siga asociado a una pantalla antes de llamar a setState.
      if (mounted) {
        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
        setState(() {
          // Desactiva el estado de envío.
          _guardando = false;
        });
      }
    }
    // Cierra el formulario solo si sigue abierto y el guardado fue confirmado.
    if (mounted && guardado) {
      // Regresa a la lista de reseñas y devuelve true para que se consulte de nuevo.
      Navigator.of(context).pop(true);
    }
  }
  // Admite únicamente portadas del backend configurado, no enlaces de páginas externas.
  String _urlPortadaActual() {
    // ?? utiliza texto vacío cuando no hay una foto; no crea una imagen de prueba.
    final foto = (widget.resena?['portada'] ?? '').toString().trim();
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


  // Muestra la portada nueva, la que ya tiene la reseña o un icono de respaldo.
  Widget _vistaPortada() {
    // Comprueba primero si se ha elegido una portada nueva.
    final seleccion = _portada;
    // Si hay una fotografía nueva, utiliza ese archivo para la vista previa.
    if (seleccion != null) {
      // Muestra una imagen almacenada localmente en el teléfono.
      return Image.file(
        // Crea la referencia al archivo local mediante la ruta que devolvió image_picker.
        File(seleccion.path),
        // Altura solicitada en unidades lógicas de Flutter.
        height: 200,
        // Muestra la imagen completa dentro del espacio disponible, sin recortarla.
        fit: BoxFit.contain,
        // Construye una alternativa visual cuando la imagen no se puede cargar.
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image_outlined, size: 80);
        },
      );
    }
    // Recupera el nombre de la portada actual cuando no hay una nueva selección.
    // Valida la portada guardada y construye su dirección en el backend.
    final url = _urlPortadaActual();
    if (url.isNotEmpty) {
      return Image.network(
        url,
        // Altura solicitada en unidades lógicas de Flutter.
        height: 200,
        // Muestra la imagen completa dentro del espacio disponible, sin recortarla.
        fit: BoxFit.contain,
        // Construye una alternativa visual cuando la imagen no se puede cargar.
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.image_outlined, size: 80);
        },
      );
    }
    return const SizedBox(
      // Altura solicitada en unidades lógicas de Flutter.
      height: 140,
      // Widget que se coloca dentro de este contenedor.
      child: Icon(Icons.image_outlined, size: 80),
    );
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Construye la interfaz a partir de los datos y los indicadores actuales.
  Widget build(BuildContext context) {
    // Reúne los dos indicadores para desactivar controles durante una operación.
    final ocupado = _guardando || _seleccionando;
    return Scaffold(
      // Configura la barra superior de esta pantalla.
      appBar: AppBar(
        // Texto de la barra superior o del cuadro de confirmación.
        title: Text(_editando ? 'Editar reseña' : 'Nueva reseña'),
      ),
      // Contenido principal de la pantalla.
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        // Espera las consultas de actores y directores antes de mostrar los selectores.
        future: _datosFormulario,
        // Construye el contenido del diálogo o de la sección según el estado actual.
        builder: (context, snapshot) {
          // Muestra la carga mientras llegan las dos listas.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si falla alguna consulta, muestra el mensaje y permite intentarlo otra vez.
          if (snapshot.hasError) {
            return Center(
              // Widget que se coloca dentro de este contenedor.
              child: Padding(
                // Establece el espacio interior alrededor del contenido.
                padding: const EdgeInsets.all(24),
                // Widget que se coloca dentro de este contenedor.
                child: Column(
                  // min evita que la columna ocupe más altura de la necesaria.
                  mainAxisSize: MainAxisSize.min,
                  // Lista de widgets que se colocarán dentro del componente.
                  children: [
                    Text(
                      '${snapshot.error}',
                      // Alineación del texto dentro del espacio disponible.
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                      onPressed: () {
                        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
                        setState(() {
                          // Inicia de nuevo la consulta de los datos que necesitan las listas de selección.
                          _datosFormulario = _cargarDatosFormulario();
                        });
                      },
                      // Widget que se coloca dentro de este contenedor.
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Recupera las dos listas después de que la consulta terminó sin error.
          final datos = snapshot.data!;
          // La primera lista corresponde a los directores.
          final directores = datos[0];
          // La segunda lista corresponde a los actores.
          final actores = datos[1];
          // Impide continuar si falta registrar un director o un actor que se pueda seleccionar.
          if (directores.isEmpty || actores.isEmpty) {
            return Center(
              // Widget que se coloca dentro de este contenedor.
              child: Padding(
                // Establece el espacio interior alrededor del contenido.
                padding: const EdgeInsets.all(24),
                // Widget que se coloca dentro de este contenedor.
                child: Column(
                  // min evita que la columna ocupe más altura de la necesaria.
                  mainAxisSize: MainAxisSize.min,
                  // Lista de widgets que se colocarán dentro del componente.
                  children: [
                    Text(
                      directores.isEmpty
                          ? 'Primero registra un director desde el panel.'
                          : 'Primero registra un actor desde el panel.',
                      // Alineación del texto dentro del espacio disponible.
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                      onPressed: () {
                        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
                        setState(() {
                          // Inicia de nuevo la consulta de los datos que necesitan las listas de selección.
                          _datosFormulario = _cargarDatosFormulario();
                        });
                      },
                      // Widget que se coloca dentro de este contenedor.
                      child: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Prepara los identificadores disponibles para comprobar la selección del director.
          final idsDirectores = directores
              .map((director) => int.parse('${director['id_director']}'))
              // Agrupa los identificadores sin repetirlos para comprobar si uno sigue disponible.
              .toSet();
          // Prepara los identificadores disponibles para comprobar la selección del actor.
          final idsActores = actores
              .map((actor) => int.parse('${actor['id_actor']}'))
              // Agrupa los identificadores sin repetirlos para comprobar si uno sigue disponible.
              .toSet();
          // Utiliza el director guardado solo si todavía aparece en la lista de registros.
          final directorSeleccionado =
              idsDirectores.contains(_idDirector) ? _idDirector : null;
          // Utiliza el actor guardado solo si todavía aparece en la lista de registros.
          final actorSeleccionado =
              idsActores.contains(_idActor) ? _idActor : null;
          return SingleChildScrollView(
            // Establece el espacio interior alrededor del contenido.
            padding: const EdgeInsets.all(24),
            // Widget que se coloca dentro de este contenedor.
            child: Form(
              // Vincula el Form con la clave utilizada para ejecutar sus validadores.
              key: _formulario,
              // Widget que se coloca dentro de este contenedor.
              child: Column(
                // stretch estira los elementos horizontalmente dentro de la columna.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // Lista de widgets que se colocarán dentro del componente.
                children: [
                  _vistaPortada(),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                    onPressed: ocupado ? null : _seleccionarPortada,
                    // Estilo del texto o del botón.
                    style: OutlinedButton.styleFrom(
                      // Tamaño mínimo solicitado para facilitar la pulsación.
                      minimumSize: const Size(48, 48),
                    ),
                    // Icono que acompaña la acción.
                    icon: const Icon(Icons.photo_library_outlined),
                    // Texto visible del botón.
                    label: const Text('Seleccionar portada'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _editando
                        ? 'Si no eliges otra portada, se conserva la actual.'
                        : 'Si no eliges una imagen, la reseña quedará sin portada.',
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    // Conecta el campo con el controlador que guarda y recupera su texto.
                    controller: _titulo,
                    // Desactiva el campo mientras hay una operación en curso.
                    enabled: !ocupado,
                    // Limita el título a 255 caracteres desde el campo de texto.
                    maxLength: 255,
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Título',
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Revisa el contenido del campo y devuelve una explicación si no es válido.
                    validator: (valor) {
                      return (valor ?? '').trim().isEmpty
                          ? 'Escribe el título.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Muestra la lista para elegir si la publicación corresponde a una película o una serie.
                  DropdownButtonFormField<String>(
                    // Coloca la selección inicial que corresponde a los datos cargados.
                    initialValue: _tipo,
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Tipo',
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Opciones que se mostrarán en la lista de selección.
                    items: const [
                      DropdownMenuItem(
                        // Valor que se guarda al elegir esta opción.
                        value: 'Película',
                        // Widget que se coloca dentro de este contenedor.
                        child: Text('Película'),
                      ),
                      DropdownMenuItem(
                        // Valor que se guarda al elegir esta opción.
                        value: 'Serie',
                        // Widget que se coloca dentro de este contenedor.
                        child: Text('Serie'),
                      ),
                    ],
                    // Guarda la selección realizada; se desactiva mientras el formulario está ocupado.
                    onChanged: ocupado
                        ? null
                        : (valor) {
                            if (valor != null) {
                              // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
                              setState(() {
                                // Guarda el tipo elegido y actualiza el formulario.
                                _tipo = valor;
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 16),
                  // Muestra una lista que guarda el identificador del director o actor elegido.
                  DropdownButtonFormField<int>(
                    // Coloca la selección inicial que corresponde a los datos cargados.
                    initialValue: directorSeleccionado,
                    // Permite que la lista utilice el ancho disponible.
                    isExpanded: true,
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Director obligatorio',
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Crea una opción por cada director registrado.
                    items: directores.map((director) {
                      return DropdownMenuItem<int>(
                        // Valor que se guarda al elegir esta opción.
                        value: int.parse('${director['id_director']}'),
                        // Widget que se coloca dentro de este contenedor.
                        child: Text(
                          '${director['nombre']}',
                          // Acorta con puntos suspensivos los nombres que no caben.
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    // Guarda la selección realizada; se desactiva mientras el formulario está ocupado.
                    onChanged: ocupado
                        ? null
                        : (valor) {
                            // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
                            setState(() {
                              // Guarda el identificador del director elegido.
                              _idDirector = valor;
                            });
                          },
                    // Revisa el contenido del campo y devuelve una explicación si no es válido.
                    validator: (valor) {
                      return valor == null ||
                              !idsDirectores.contains(valor)
                          ? 'Selecciona un director registrado.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Muestra una lista que guarda el identificador del director o actor elegido.
                  DropdownButtonFormField<int>(
                    // Coloca la selección inicial que corresponde a los datos cargados.
                    initialValue: actorSeleccionado,
                    // Permite que la lista utilice el ancho disponible.
                    isExpanded: true,
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Actor protagonista obligatorio',
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Crea una opción por cada actor registrado.
                    items: actores.map((actor) {
                      return DropdownMenuItem<int>(
                        // Valor que se guarda al elegir esta opción.
                        value: int.parse('${actor['id_actor']}'),
                        // Widget que se coloca dentro de este contenedor.
                        child: Text(
                          '${actor['nombre']}',
                          // Acorta con puntos suspensivos los nombres que no caben.
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    // Guarda la selección realizada; se desactiva mientras el formulario está ocupado.
                    onChanged: ocupado
                        ? null
                        : (valor) {
                            // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
                            setState(() {
                              // Guarda el identificador del actor elegido.
                              _idActor = valor;
                            });
                          },
                    // Revisa el contenido del campo y devuelve una explicación si no es válido.
                    validator: (valor) {
                      return valor == null || !idsActores.contains(valor)
                          ? 'Selecciona un actor registrado.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    // Conecta el campo con el controlador que guarda y recupera su texto.
                    controller: _etiquetas,
                    // Desactiva el campo mientras hay una operación en curso.
                    enabled: !ocupado,
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Etiquetas',
                      hintText: 'Escribe las etiquetas separadas por comas',
                      // Explica cómo escribir las etiquetas y cuál es su límite.
                      helperText:
                          'Separa las etiquetas con comas. '
                          'Máximo 60 caracteres por etiqueta.',
                      // Permite que la explicación ocupe hasta tres líneas.
                      helperMaxLines: 3,
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Revisa el contenido del campo y devuelve una explicación si no es válido.
                    validator: (valor) {
                      // Prepara las etiquetas escritas para revisar que sean válidas.
                      final etiquetas = (valor ?? '')
                          // Separa el texto cada vez que encuentra una coma.
                          .split(',')
                          // Retira espacios sobrantes de cada etiqueta.
                          .map((etiqueta) => etiqueta.trim())
                          // Descarta las partes vacías que puedan quedar entre las comas.
                          .where((etiqueta) => etiqueta.isNotEmpty)
                          // Reúne los resultados en una lista.
                          .toList();
                      // Exige que se haya escrito al menos una etiqueta.
                      if (etiquetas.isEmpty) {
                        return 'Escribe al menos una etiqueta.';
                      }
                      // Revisa si alguna etiqueta supera la longitud permitida.
                      if (etiquetas.any(
                        // Cuenta los puntos de código Unicode para comparar con el límite de 60 que utiliza el backend.
                        (etiqueta) => etiqueta.runes.length > 60,
                      )) {
                        return 'Cada etiqueta admite hasta 60 caracteres.';
                      }
                      // Indica que no hay un valor específico; en el validador del formulario significa que el dato es válido.
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    // Conecta el campo con el controlador que guarda y recupera su texto.
                    controller: _sinopsis,
                    // Desactiva el campo mientras hay una operación en curso.
                    enabled: !ocupado,
                    // Deja espacio para escribir una sinopsis de varias líneas.
                    minLines: 5,
                    // Limita la altura visible del campo; no limita la cantidad total de texto.
                    maxLines: 10,
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Sinopsis',
                      // Alinea la etiqueta con la parte superior del campo de varias líneas.
                      alignLabelWithHint: true,
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Revisa el contenido del campo y devuelve una explicación si no es válido.
                    validator: (valor) {
                      // Prepara el contenido de la sinopsis para validarlo.
                      final texto = (valor ?? '').trim();
                      // No permite publicar una reseña sin sinopsis.
                      if (texto.isEmpty) {
                        return 'Escribe la sinopsis.';
                      }
                      // Comprueba el tamaño en bytes que admite el campo TEXT de MySQL; los acentos y emojis pueden ocupar varios bytes.
                      if (utf8.encode(texto).length > 65535) {
                        return 'La sinopsis es demasiado extensa.';
                      }
                      // Indica que no hay un valor específico; en el validador del formulario significa que el dato es válido.
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Agrega el mensaje al formulario solo cuando existe un error para mostrar.
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      // Utiliza el mensaje como no nulo porque la condición anterior ya comprobó que existe.
                      _error!,
                      // Estilo del texto o del botón.
                      style: TextStyle(
                        // Color tomado del tema o del esquema de colores.
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                    onPressed: ocupado ? null : _guardar,
                    // Estilo del texto o del botón.
                    style: FilledButton.styleFrom(
                      // Tamaño mínimo solicitado para facilitar la pulsación.
                      minimumSize: const Size(48, 48),
                    ),
                    // Widget que se coloca dentro de este contenedor.
                    child: _guardando
                        ? const SizedBox(
                            // Ancho solicitado en unidades lógicas de Flutter.
                            width: 22,
                            // Altura solicitada en unidades lógicas de Flutter.
                            height: 22,
                            // Widget que se coloca dentro de este contenedor.
                            child: CircularProgressIndicator(
                              // Grosor de la línea del indicador circular.
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _editando
                                ? 'Actualizar reseña'
                                : 'Publicar reseña',
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
