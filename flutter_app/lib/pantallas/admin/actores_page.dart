// CRUPPIS — Administración de actores.
// Incluye el listado administrativo de actores y su formulario de registro o edición.
// Solo el backend decide si el token pertenece a un administrador autorizado.
// GET consulta, POST registra, PUT modifica y DELETE elimina.
// async/await permite esperar operaciones sin bloquear la interfaz.
// Future representa un resultado que llegará después; mounted indica si el widget sigue activo.
// El prefijo _ hace privado un nombre dentro de la biblioteca Dart de este archivo.
// StatefulWidget es una pantalla cuyo contenido cambia; State almacena esos cambios.
// setState avisa a Flutter de que debe volver a dibujar la interfaz con los nuevos datos.
// JSON es el formato de texto que utiliza la API para enviar datos; UTF-8 conserva acentos.
// MultipartRequest envía el nombre y la fotografía juntos en una petición.
// Form y GlobalKey permiten comprobar los campos antes de enviarlos.
// null representa ausencia de valor; un botón con onPressed: null queda desactivado.
// Los cierres ), ], }; y } terminan las instrucciones y bloques anteriores.
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
// Importa los estilos compartidos de Cruppis; se conserva el nombre del archivo por compatibilidad.
import '../../estilos/spooky_tema.dart';
// Dirección actual del backend. Si cambia la IPv4 de la computadora, hay que actualizarla antes de generar otro APK.
const String _servidorActores = 'http://10.13.40.223:8000';
// Construye la dirección de una foto guardada en backend/uploads.
// No acepta imágenes alojadas en páginas externas.
String _urlFotoActor(Object? valor) {
  // ?? utiliza texto vacío cuando no hay una foto; no crea una imagen de prueba.
  final foto = (valor ?? '').toString().trim();
  if (foto.isEmpty) return '';

  // Uri separa una dirección en protocolo, servidor, puerto y ruta.
  final base = Uri.parse(_servidorActores);
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

// Obtiene un mensaje legible a partir de una respuesta de error de la API.
String _errorActores(http.Response respuesta) {
  // Reconoce que el servidor no autorizó la sesión; por ejemplo, porque el token venció.
  if (respuesta.statusCode == 401) {
    // Devuelve instrucciones para que la persona vuelva a autenticarse.
    return 'Tu sesión venció. Cierra sesión e inicia nuevamente.';
  }
  // Intenta completar la operación; los errores se atienden en catch.
  try {
    // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la respuesta tenga un mensaje detail de tipo texto antes de leerlo.
    if (datos is Map && datos['detail'] is String) {
      // Devuelve el mensaje enviado por FastAPI.
      return datos['detail'] as String;
    }
  // catch atiende el error. El símbolo _ indica que no se necesita leer la excepción.
  } catch (_) {
    // Utiliza el mensaje general.
  }
  // Si no hay un mensaje específico, prepara un mensaje general con el estado HTTP.
  return 'No se pudo completar la operación '
      '(${respuesta.statusCode}).';
}
// Define la pantalla de actores. Es StatefulWidget porque su contenido y sus indicadores cambian.
class ActoresPage extends StatefulWidget {
  // Constructor público de la pantalla: recibe el token de la sesión actual.
  const ActoresPage({
    // Permite que Flutter identifique este widget dentro del árbol de la interfaz.
    super.key,
    // Obliga a proporcionar el token al abrir la pantalla.
    required this.token,
  });
  // Conserva el token recibido; final impide reasignar esta propiedad del widget.
  final String token;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Crea el objeto que almacena y modifica el estado de esta pantalla.
  State<ActoresPage> createState() => _ActoresPageState();
}
// Contiene la consulta, la eliminación, la navegación y la interfaz de la lista de actores.
class _ActoresPageState extends State<ActoresPage> {
  // Guarda una consulta pendiente cuyo resultado es una lista de actores. Se inicializa en initState.
  late Future<List<Map<String, dynamic>>> _actores;
  // Indica si hay una eliminación en curso y evita acciones simultáneas desde los botones.
  bool _eliminando = false;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Se ejecuta una vez cuando se crea el estado del widget.
  void initState() {
    // Ejecuta primero la inicialización que necesita la clase de Flutter.
    super.initState();
    // Inicia una consulta de actores y guarda su Future para que FutureBuilder observe el resultado.
    _actores = _obtenerActores();
  }
  // Consulta los actores sin bloquear la interfaz y devuelve una lista de mapas.
  Future<List<Map<String, dynamic>>> _obtenerActores() async {
    // Inicia una petición HTTP y espera su respuesta de forma asíncrona.
    final respuesta = await http
        // Solicita datos al servidor utilizando el método GET.
        .get(
          // Construye la dirección del endpoint administrativo de actores.
          Uri.parse('$_servidorActores/api/admin/actores'),
          // Encabezados que acompañan la petición HTTP.
          headers: {
            // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
            'Authorization': 'Bearer ${widget.token}',
          },
        )
        // Limita a 20 segundos la espera de esta operación; un timeout no demuestra si el servidor terminó una modificación.
        .timeout(const Duration(seconds: 20));
    // Solo considera correcta la consulta cuando la API responde HTTP 200.
    if (respuesta.statusCode != 200) {
      // Propaga el mensaje de error para que la interfaz pueda mostrarlo.
      throw Exception(_errorActores(respuesta));
    }
    // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la respuesta sea una lista antes de convertir los actores.
    if (datos is! List) {
      // Indica que la respuesta no tiene el formato esperado por esta pantalla.
      throw const FormatException('Respuesta inválida.');
    }
    // Devuelve la lista después de convertir cada elemento en un mapa de claves String.
    return datos
        // Convierte cada actor a un mapa para consultar campos como id_actor, nombre y foto.
        .map((actor) => Map<String, dynamic>.from(actor as Map))
        // Reúne los actores convertidos en una lista que puede mostrar la pantalla.
        .toList();
  }
  // Solicita nuevamente la lista de actores.
  void _recargar() {
    // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
    setState(() {
      // Inicia una consulta de actores y guarda su Future para que FutureBuilder observe el resultado.
      _actores = _obtenerActores();
    });
  }
  // Actualiza los actores al deslizar la lista hacia abajo.
  Future<void> _actualizarDeslizando() async {
    // Crea una sola consulta que compartirán el indicador de actualización y FutureBuilder.
    final consulta = _obtenerActores();
    // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
    setState(() {
      // Asigna la nueva consulta para que FutureBuilder observe su resultado.
      _actores = consulta;
    });
    // Intenta completar la operación; los errores se atienden en catch.
    try {
      // Mantiene el indicador de actualización hasta que la consulta termina.
      await consulta;
    // catch atiende el error. El símbolo _ indica que no se necesita leer la excepción.
    } catch (_) {
      // El FutureBuilder muestra el error y permite reintentar.
    }
  }
  // Abre el formulario y espera saber si se guardó un actor.
  Future<void> _abrirFormulario({
    // Parámetro opcional: si tiene un actor se edita; si es null se registra uno nuevo.
    Map<String, dynamic>? actor,
  }) async {
    // Evita comenzar otra acción desde esta función mientras se elimina un actor.
    if (_eliminando) return;
    // Abre otra pantalla y espera un resultado booleano al cerrarla.
    final guardado = await Navigator.of(context).push<bool>(
      // Crea una ruta que puede devolver true o false a la pantalla anterior.
      MaterialPageRoute<bool>(
        // Construye el formulario de registro o edición que se mostrará en la ruta.
        builder: (context) => _FormularioActorPage(
          // Pasa la sesión actual a la pantalla del formulario.
          token: widget.token,
          // Pasa el actor seleccionado o null para crear uno nuevo.
          actor: actor,
        ),
      ),
    );
    // Continúa solo si la pantalla sigue abierta y el formulario confirmó el guardado.
    if (!mounted || guardado != true) return;
    // Vuelve a consultar la API para mostrar la información actualizada.
    _recargar();
    // Muestra un aviso temporal en la pantalla actual.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        // Contenido principal del mensaje o del diálogo.
        content: Text('Actor guardado correctamente.'),
      ),
    );
  }
  // Solicita confirmación y envía la eliminación del actor seleccionado a la API.
  Future<void> _eliminarActor(Map<String, dynamic> actor) async {
    // Evita comenzar otra acción desde esta función mientras se elimina un actor.
    if (_eliminando) return;
    // Abre un diálogo y espera la decisión de la persona.
    final confirmar = await showDialog<bool>(
      // Indica el contexto de la pantalla donde se abrirá el diálogo.
      context: context,
      // Construye el contenido del diálogo o de la sección según el estado actual.
      builder: (context) => AlertDialog(
        // Texto de la barra superior o del cuadro de confirmación.
        title: const Text('Eliminar actor'),
        // Contenido principal del mensaje o del diálogo.
        content: Text(
          '¿Deseas eliminar a ${actor['nombre']}?\n\n'
          'Las reseñas se conservarán y quedarán sin este actor.',
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
    // No elimina si la pantalla ya se cerró, se canceló el diálogo o ya hay una eliminación activa.
    if (!mounted || confirmar != true || _eliminando) {
      // Termina esta función sin continuar con las instrucciones siguientes.
      return;
    }
    // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
    setState(() {
      // Activa el estado de eliminación para bloquear botones y mostrar el progreso.
      _eliminando = true;
    });
    // Intenta completar la operación; los errores se atienden en catch.
    try {
      // Obtiene el identificador del actor que se eliminará.
      final id = actor['id_actor'];
      // Inicia una petición HTTP y espera su respuesta de forma asíncrona.
      final respuesta = await http
          // Envía una solicitud DELETE a la API para eliminar el registro.
          .delete(
            // Construye la dirección específica del actor seleccionado.
            Uri.parse('$_servidorActores/api/admin/actores/$id'),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Envía el token en el encabezado de autorización. La API es quien valida los permisos.
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          // Limita a 20 segundos la espera de esta operación; un timeout no demuestra si el servidor terminó una modificación.
          .timeout(const Duration(seconds: 20));
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Acepta la eliminación confirmada o que el actor ya no exista.
      if (respuesta.statusCode != 200 &&
          // Si el estado tampoco es 404, se muestra el error enviado por la API.
          respuesta.statusCode != 404) {
        // Muestra un aviso temporal en la pantalla actual.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorActores(respuesta))),
        );
        // Termina esta función sin continuar con las instrucciones siguientes.
        return;
      }
      // Vuelve a consultar la API para mostrar la información actualizada.
      _recargar();
      // Muestra un aviso temporal en la pantalla actual.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Contenido principal del mensaje o del diálogo.
          content: Text(
            // Elige el mensaje según si el actor ya había sido eliminado o se eliminó ahora.
            respuesta.statusCode == 404
                ? 'El actor ya no existe.'
                : 'Actor eliminado correctamente.',
          ),
        ),
      );
    // catch atiende el error. El símbolo _ indica que no se necesita leer la excepción.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Muestra un aviso temporal en la pantalla actual.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // Contenido principal del mensaje o del diálogo.
          content: Text(
            'No se pudo confirmar la eliminación. '
            'Actualiza la lista para comprobarlo.',
          ),
        ),
      );
    // Este bloque se ejecuta tanto si la operación tuvo éxito como si falló.
    } finally {
      // Comprueba que el estado siga asociado a una pantalla antes de llamar a setState.
      if (mounted) {
        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
        setState(() {
          // Libera el estado de eliminación para volver a permitir las acciones.
          _eliminando = false;
        });
      }
    }
  }
  // Construye una tarjeta con la fotografía, el nombre y las acciones del actor.
  Widget _tarjetaActor(Map<String, dynamic> actor) {
    // Obtiene los colores del tema que utiliza la aplicación.
    final esquema = Theme.of(context).colorScheme;
    // Prepara la dirección de la fotografía del actor.
    final foto = _urlFotoActor(actor['foto']);
    // Devuelve el widget que representa esta parte de la pantalla.
    return Container(
      // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
      decoration: SpookyPanelEstilos.tarjeta,
      // Establece el espacio interior alrededor del contenido.
      padding: const EdgeInsets.all(16),
      // Widget que se coloca dentro de este contenedor.
      child: Column(
        // stretch estira los elementos horizontalmente dentro de la columna.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // Lista de widgets que se colocarán dentro del componente.
        children: [
          Row(
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              ClipRRect(
                // Redondea las esquinas de la imagen o del botón.
                borderRadius: BorderRadius.circular(12),
                // Widget que se coloca dentro de este contenedor.
                child: Image.network(
                  foto,
                  // Ancho solicitado en unidades lógicas de Flutter.
                  width: 80,
                  // Altura solicitada en unidades lógicas de Flutter.
                  height: 80,
                  // cover llena el espacio disponible y recorta los bordes de la imagen si es necesario.
                  fit: BoxFit.cover,
                  // Construye una alternativa visual cuando la imagen no se puede cargar.
                  errorBuilder: (context, error, stackTrace) {
                    // Devuelve el widget que representa esta parte de la pantalla.
                    return const SizedBox(
                      // Ancho solicitado en unidades lógicas de Flutter.
                      width: 80,
                      // Altura solicitada en unidades lógicas de Flutter.
                      height: 80,
                      // Widget que se coloca dentro de este contenedor.
                      child: Icon(
                        Icons.person_outline,
                        // Tamaño del icono en unidades lógicas.
                        size: 40,
                        // Color tomado del tema o del esquema de colores.
                        color: SpookyTema.textoSecundario,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                // Widget que se coloca dentro de este contenedor.
                child: Text(
                  '${actor['nombre'] ?? 'Sin nombre'}',
                  // Estilo del texto o del botón.
                  style: const TextStyle(
                    // Tamaño de letra en unidades lógicas, sujeto a la escala de texto del sistema.
                    fontSize: 18,
                    // Grosor de la letra; bold utiliza negrita.
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            // Separación horizontal entre los botones del Wrap.
            spacing: 12,
            // Separación entre filas cuando los botones no caben en una sola línea.
            runSpacing: 8,
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              OutlinedButton.icon(
                // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                onPressed: _eliminando
                    ? null
                    : () {
                        // Abre el formulario; con actor edita y sin actor registra.
                        _abrirFormulario(actor: actor);
                      },
                // Estilo del texto o del botón.
                style: OutlinedButton.styleFrom(
                  // Color del texto y del icono del botón.
                  foregroundColor: esquema.secondary,
                  // Tamaño mínimo solicitado para facilitar la pulsación.
                  minimumSize: const Size(48, 48),
                  // Establece el espacio interior alrededor del contenido.
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // Contorno del botón.
                  side: BorderSide(color: esquema.primary),
                  // Forma y redondeado del botón.
                  shape: RoundedRectangleBorder(
                    // Redondea las esquinas de la imagen o del botón.
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                // Icono que acompaña la acción.
                icon: const Icon(
                  Icons.edit_outlined,
                  // Tamaño del icono en unidades lógicas.
                  size: 18,
                ),
                // Texto visible del botón.
                label: const Text('Editar'),
              ),
              OutlinedButton.icon(
                // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                onPressed: _eliminando
                    ? null
                    : () {
                        // Inicia la confirmación y eliminación del actor de esta tarjeta.
                        _eliminarActor(actor);
                      },
                // Estilo del texto o del botón.
                style: OutlinedButton.styleFrom(
                  // Color del texto y del icono del botón.
                  foregroundColor: esquema.error,
                  // Tamaño mínimo solicitado para facilitar la pulsación.
                  minimumSize: const Size(48, 48),
                  // Establece el espacio interior alrededor del contenido.
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  // Contorno del botón.
                  side: BorderSide(color: esquema.primary),
                  // Forma y redondeado del botón.
                  shape: RoundedRectangleBorder(
                    // Redondea las esquinas de la imagen o del botón.
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                // Icono que acompaña la acción.
                icon: const Icon(
                  Icons.delete_outline,
                  // Tamaño del icono en unidades lógicas.
                  size: 18,
                ),
                // Texto visible del botón.
                label: const Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Construye la interfaz a partir de los datos y los indicadores actuales.
  Widget build(BuildContext context) {
    // Devuelve el widget que representa esta parte de la pantalla.
    return Scaffold(
      // Configura la barra superior de esta pantalla.
      appBar: AppBar(
        // Texto de la barra superior o del cuadro de confirmación.
        title: const Text('ACTORES'),
        // Lista de botones de la barra superior o del diálogo.
        actions: [
          IconButton(
            // Descripción de ayuda y accesibilidad del botón.
            tooltip: 'Actualizar actores',
            // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
            onPressed: _eliminando ? null : _recargar,
            // Icono que acompaña la acción.
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // Botón flotante que abre el registro de un actor.
      floatingActionButton: FloatingActionButton.extended(
        // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
        onPressed: _eliminando
            ? null
            : () {
                // Abre el formulario; con actor edita y sin actor registra.
                _abrirFormulario();
              },
        // Icono que acompaña la acción.
        icon: const Icon(Icons.add),
        // Texto visible del botón.
        label: const Text('Nuevo actor'),
      ),
      // Contenido principal de la pantalla.
      body: DecoratedBox(
        // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
        decoration: SpookyPanelEstilos.fondo,
        // Widget que se coloca dentro de este contenedor.
        child: SizedBox.expand(
          // Widget que se coloca dentro de este contenedor.
          child: Column(
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              // Incluye el indicador lineal únicamente durante una eliminación.
              if (_eliminando) const LinearProgressIndicator(),
              Expanded(
                // Widget que se coloca dentro de este contenedor.
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  // Consulta asíncrona que FutureBuilder debe observar.
                  future: _actores,
                  // Construye el contenido del diálogo o de la sección según el estado actual.
                  builder: (context, snapshot) {
                    // Comprueba si la consulta todavía está esperando su resultado.
                    if (snapshot.connectionState ==
                        // Mientras la consulta espera, la interfaz mostrará un indicador de carga.
                        ConnectionState.waiting) {
                      // Devuelve el widget que representa esta parte de la pantalla.
                      return const Center(
                        // Widget que se coloca dentro de este contenedor.
                        child: CircularProgressIndicator(),
                      );
                    }
                    // Muestra el mensaje de error y una opción para volver a consultar.
                    if (snapshot.hasError) {
                      // Devuelve el widget que representa esta parte de la pantalla.
                      return Center(
                        // Widget que se coloca dentro de este contenedor.
                        child: Padding(
                          // Establece el espacio interior alrededor del contenido.
                          padding: SpookyPanelEstilos.margen,
                          // Widget que se coloca dentro de este contenedor.
                          child: Column(
                            // min evita que la columna ocupe más altura de la necesaria.
                            mainAxisSize: MainAxisSize.min,
                            // Lista de widgets que se colocarán dentro del componente.
                            children: [
                              Text(
                                snapshot.error
                                    .toString()
                                    .replaceFirst('Exception: ', ''),
                                // Alineación del texto dentro del espacio disponible.
                                textAlign: TextAlign.center,
                              ),
                              SpookyPanelEstilos.separacion,
                              FilledButton(
                                // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                                onPressed: _recargar,
                                // Widget que se coloca dentro de este contenedor.
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // Utiliza la lista recibida o una lista vacía si todavía no hay datos.
                    final actores = snapshot.data ?? [];
                    // Devuelve el widget que representa esta parte de la pantalla.
                    return RefreshIndicator(
                      // Función que se ejecuta al deslizar hacia abajo para actualizar.
                      onRefresh: _actualizarDeslizando,
                      // Widget que se coloca dentro de este contenedor.
                      child: ListView.separated(
                        // Permite deslizar incluso si la lista es corta o solo muestra el mensaje de vacío.
                        physics: const AlwaysScrollableScrollPhysics(),
                        // Establece el espacio interior alrededor del contenido.
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          100,
                        ),
                        // Número de elementos; utiliza uno para poder mostrar el aviso cuando la lista está vacía.
                        itemCount: actores.isEmpty ? 1 : actores.length,
                        // Construye el espacio entre una tarjeta y la siguiente.
                        separatorBuilder: (context, index) =>
                            SpookyPanelEstilos.separacion,
                        // Construye cada elemento de la lista cuando Flutter lo necesita.
                        itemBuilder: (context, index) {
                          // Si no existen actores, muestra el aviso de lista vacía.
                          if (actores.isEmpty) {
                            // Devuelve el widget que representa esta parte de la pantalla.
                            return const Padding(
                              // Establece el espacio interior alrededor del contenido.
                              padding: EdgeInsets.all(24),
                              // Widget que se coloca dentro de este contenedor.
                              child: Text(
                                'No hay actores registrados.',
                                // Alineación del texto dentro del espacio disponible.
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          // Construye la tarjeta del actor que corresponde a esta posición de la lista.
                          return _tarjetaActor(actores[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// Define el formulario privado de este archivo; se reutiliza para registrar y editar actores.
class _FormularioActorPage extends StatefulWidget {
  // Recibe la sesión actual y, opcionalmente, los datos del actor que se editará.
  const _FormularioActorPage({
    // Obliga a proporcionar el token al abrir la pantalla.
    required this.token,
    this.actor,
  });
  // Conserva el token recibido; final impide reasignar esta propiedad del widget.
  final String token;
  // Conserva los datos del actor o null cuando se trata de un registro nuevo.
  final Map<String, dynamic>? actor;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Crea el estado encargado de los campos, la fotografía y el envío del formulario.
  State<_FormularioActorPage> createState() =>
      _FormularioActorPageState();
}
// Contiene las validaciones y el comportamiento del formulario de actores.
class _FormularioActorPageState extends State<_FormularioActorPage> {
  // Permite acceder al estado del Form y ejecutar sus validadores.
  final _formulario = GlobalKey<FormState>();
  // Controla el texto escrito en el campo del nombre.
  final _nombre = TextEditingController();
  // Crea el selector de imágenes que abre la galería.
  final _selector = ImagePicker();
  // Guarda el archivo elegido; null significa que no se ha seleccionado uno nuevo.
  XFile? _fotoSeleccionada;
  // Indica que se está enviando el formulario.
  bool _guardando = false;
  // Indica que se está abriendo o procesando la selección de una fotografía.
  bool _seleccionando = false;
  // Guarda el mensaje que se mostrará debajo de los campos; null significa que no hay error.
  String? _error;
  // Getter que determina el modo del formulario: editar cuando existe un actor recibido.
  bool get _editando => widget.actor != null;
  // Getter que comprueba si el actor recibido ya tiene una referencia de fotografía.
  bool get _tieneFotoActual =>
      _urlFotoActor(widget.actor?['foto']).isNotEmpty;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Se ejecuta una vez cuando se crea el estado del widget.
  void initState() {
    // Ejecuta primero la inicialización que necesita la clase de Flutter.
    super.initState();
    // Precarga el nombre actual al editar; al registrar deja el campo vacío.
    _nombre.text = (widget.actor?['nombre'] ?? '').toString();
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Libera recursos cuando el formulario deja de utilizarse.
  void dispose() {
    // Libera el controlador del campo de texto.
    _nombre.dispose();
    // Completa la liberación del estado de Flutter.
    super.dispose();
  }
  // Abre la galería, revisa el tamaño y guarda el archivo seleccionado para su vista previa.
  Future<void> _seleccionarFoto() async {
    // Evita iniciar otra operación mientras se guarda o se selecciona una imagen.
    if (_guardando || _seleccionando) return;
    // Quita el foco del campo activo para cerrar el teclado.
    FocusScope.of(context).unfocus();
    // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
    setState(() {
      // Activa el indicador de selección para evitar pulsaciones repetidas.
      _seleccionando = true;
      // Limpia el mensaje de error anterior.
      _error = null;
    });
    // Intenta completar la operación; los errores se atienden en catch.
    try {
      // Espera que la persona seleccione una imagen o cancele la galería.
      final seleccion = await _selector.pickImage(
        // Selecciona imágenes de la galería, no de la cámara.
        source: ImageSource.gallery,
        // Solicita una anchura máxima de 1600 para la imagen seleccionada.
        maxWidth: 1600,
        // Solicita una altura máxima de 1600 para la imagen seleccionada.
        maxHeight: 1600,
        // Solicita calidad 85 para los formatos y plataformas que admiten este ajuste.
        imageQuality: 85,
      );
      // Termina sin cambiar la fotografía si se canceló la selección.
      if (seleccion == null) return;
      // Comprueba que el archivo seleccionado no supere 5 MB.
      if (await seleccion.length() > 5 * 1024 * 1024) {
        // Activa el manejo de errores cuando el archivo excede el límite.
        throw Exception('La fotografía supera los 5 MB.');
      }
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
      setState(() {
        // Conserva el archivo elegido para mostrarlo y enviarlo después.
        _fotoSeleccionada = seleccion;
      });
    // catch atiende el error. El símbolo _ indica que no se necesita leer la excepción.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
      setState(() {
        _error = 'No se pudo seleccionar la fotografía. '
            'Usa una imagen JPG, PNG o WEBP de hasta 5 MB.';
      });
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
  // Elige qué mostrar: la fotografía nueva, la actual del servidor o un icono de respaldo.
  Widget _vistaFoto() {
    // Copia la referencia a una variable local para comprobar si es nula.
    final seleccion = _fotoSeleccionada;
    // Si hay una fotografía nueva, utiliza ese archivo para la vista previa.
    if (seleccion != null) {
      // Muestra una imagen almacenada localmente en el teléfono.
      return Image.file(
        // Crea la referencia al archivo local mediante la ruta que devolvió image_picker.
        File(seleccion.path),
        // Ancho solicitado en unidades lógicas de Flutter.
        width: 160,
        // Altura solicitada en unidades lógicas de Flutter.
        height: 160,
        // cover llena el espacio disponible y recorta los bordes de la imagen si es necesario.
        fit: BoxFit.cover,
        // Construye una alternativa visual cuando la imagen no se puede cargar.
        errorBuilder: (context, error, stackTrace) {
          // Devuelve el widget que representa esta parte de la pantalla.
          return const SizedBox(
            // Ancho solicitado en unidades lógicas de Flutter.
            width: 160,
            // Altura solicitada en unidades lógicas de Flutter.
            height: 160,
            // Widget que se coloca dentro de este contenedor.
            child: Icon(Icons.broken_image_outlined, size: 80),
          );
        },
      );
    }
    // Si no se eligió una imagen nueva, intenta mostrar la fotografía que ya tiene el actor.
    if (_tieneFotoActual) {
      // Descarga y muestra la fotografía existente desde el servidor.
      return Image.network(
        // Convierte la referencia de la fotografía actual en una dirección utilizable.
        _urlFotoActor(widget.actor?['foto']),
        // Ancho solicitado en unidades lógicas de Flutter.
        width: 160,
        // Altura solicitada en unidades lógicas de Flutter.
        height: 160,
        // cover llena el espacio disponible y recorta los bordes de la imagen si es necesario.
        fit: BoxFit.cover,
        // Construye una alternativa visual cuando la imagen no se puede cargar.
        errorBuilder: (context, error, stackTrace) {
          // Devuelve el widget que representa esta parte de la pantalla.
          return const SizedBox(
            // Ancho solicitado en unidades lógicas de Flutter.
            width: 160,
            // Altura solicitada en unidades lógicas de Flutter.
            height: 160,
            // Widget que se coloca dentro de este contenedor.
            child: Icon(Icons.person_outline, size: 80),
          );
        },
      );
    }
    // Devuelve el widget que representa esta parte de la pantalla.
    return const SizedBox(
      // Ancho solicitado en unidades lógicas de Flutter.
      width: 160,
      // Altura solicitada en unidades lógicas de Flutter.
      height: 160,
      // Widget que se coloca dentro de este contenedor.
      child: Icon(
        Icons.person_outline,
        // Tamaño del icono en unidades lógicas.
        size: 80,
        // Color tomado del tema o del esquema de colores.
        color: SpookyTema.textoSecundario,
      ),
    );
  }
  // Valida el formulario, prepara nombre y fotografía y solicita registrar o actualizar al actor.
  Future<void> _guardar() async {
    // Evita iniciar otra operación mientras se guarda o se selecciona una imagen.
    if (_guardando || _seleccionando) return;
    // Quita el foco del campo activo para cerrar el teclado.
    FocusScope.of(context).unfocus();
    // Ejecuta los validadores del Form; detiene el envío si fallan o si no existe el estado del formulario.
    if (!(_formulario.currentState?.validate() ?? false)) {
      // Termina esta función sin continuar con las instrucciones siguientes.
      return;
    }
    // Exige una fotografía; al editar permite conservar la que ya existe.
    if (_fotoSeleccionada == null && !_tieneFotoActual) {
      // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
      setState(() {
        _error = 'Selecciona una fotografía para el actor.';
      });
      // Termina esta función sin continuar con las instrucciones siguientes.
      return;
    }
    // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
    setState(() {
      // Bloquea las acciones durante el envío y permite mostrar un indicador de progreso.
      _guardando = true;
      // Limpia el mensaje de error anterior.
      _error = null;
    });
    // Crea un cliente HTTP para enviar la solicitud multipart y cerrarlo al finalizar.
    final cliente = http.Client();
    // Recuerda si el servidor confirmó el guardado antes de cerrar el formulario.
    var guardado = false;
    // Intenta completar la operación; los errores se atienden en catch.
    try {
      // Obtiene el identificador existente; será null en un registro nuevo.
      final id = widget.actor?['id_actor'];
      // Construye la dirección del endpoint según si se está registrando o editando.
      final uri = Uri.parse(
        _editando
            ? '$_servidorActores/api/admin/actores/$id'
            : '$_servidorActores/api/admin/actores',
      );
      // Prepara una solicitud multipart para enviar campos de texto y un archivo en la misma petición.
      final solicitud = http.MultipartRequest(
        // Utiliza PUT para editar y POST para crear un actor.
        _editando ? 'PUT' : 'POST',
        uri,
      );
      // Agrega el token de sesión para que el backend compruebe la autorización.
      solicitud.headers['Authorization'] = 'Bearer ${widget.token}';
      // Añade el nombre sin espacios al principio ni al final.
      solicitud.fields['nombre'] = _nombre.text.trim();
      // Obtiene la fotografía nueva, si se seleccionó una.
      final foto = _fotoSeleccionada;
      // Solo adjunta un archivo cuando hay una fotografía nueva; así se conserva la actual al editar.
      if (foto != null) {
        // Añade el archivo a las partes de la solicitud multipart.
        solicitud.files.add(
          // Lee el archivo indicado por su ruta y prepara el adjunto para enviarlo.
          await http.MultipartFile.fromPath(
            // Nombre del campo que el endpoint de FastAPI espera para la fotografía.
            'foto',
            // Ruta local del archivo seleccionado.
            foto.path,
            // Envía el nombre del archivo junto con la fotografía.
            filename: foto.name,
          ),
        );
      }
      // Ejecuta una función asíncrona inmediata para limitar conjuntamente la espera del envío y la lectura de la respuesta.
      final respuesta = await (() async {
        // Envía la solicitud y recibe una respuesta que llega como flujo de datos.
        final envio = await cliente.send(solicitud);
        // Lee el flujo completo y lo transforma en una respuesta HTTP que se puede consultar.
        return http.Response.fromStream(envio);
      // Limita a 30 segundos la espera del conjunto; si vence, el servidor podría haber alcanzado a guardar.
      })().timeout(const Duration(seconds: 30));
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Espera HTTP 200 al editar o HTTP 201 al crear; cualquier otro estado se trata como error.
      if (respuesta.statusCode != (_editando ? 200 : 201)) {
        // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
        setState(() {
          // Obtiene el mensaje de error para mostrarlo en el formulario.
          _error = _errorActores(respuesta);
        });
      // Ejecuta esta alternativa cuando no se cumple la condición anterior.
      } else {
        // Marca que la API confirmó el guardado.
        guardado = true;
      }
    // catch atiende el error. El símbolo _ indica que no se necesita leer la excepción.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza el estado y avisa a Flutter que debe reconstruir esta parte de la interfaz.
      setState(() {
        _error = 'No se pudo confirmar el guardado. '
            'Revisa la lista antes de volver a registrar el actor.';
      });
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
      // Regresa a la lista y devuelve true para que se actualice el catálogo de actores.
      Navigator.of(context).pop(true);
    }
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Construye la interfaz a partir de los datos y los indicadores actuales.
  Widget build(BuildContext context) {
    // Reúne los dos indicadores para desactivar controles durante una operación.
    final ocupado = _guardando || _seleccionando;
    // Devuelve el widget que representa esta parte de la pantalla.
    return PopScope(
      // Impide regresar desde el formulario mientras se está guardando o seleccionando una fotografía.
      canPop: !ocupado,
      // Widget que se coloca dentro de este contenedor.
      child: Scaffold(
        // Configura la barra superior de esta pantalla.
        appBar: AppBar(
          // Texto de la barra superior o del cuadro de confirmación.
          title: Text(
            _editando ? 'Editar actor' : 'Registrar actor',
          ),
        ),
        // Contenido principal de la pantalla.
        body: SingleChildScrollView(
          // Configura cómo se oculta el teclado al desplazar el formulario.
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
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
                Center(
                  // Widget que se coloca dentro de este contenedor.
                  child: ClipRRect(
                    // Redondea las esquinas de la imagen o del botón.
                    borderRadius: BorderRadius.circular(16),
                    // Widget que se coloca dentro de este contenedor.
                    child: _vistaFoto(),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  // Acción al pulsar el botón; null lo desactiva mientras la pantalla está ocupada.
                  onPressed: ocupado ? null : _seleccionarFoto,
                  // Estilo del texto o del botón.
                  style: OutlinedButton.styleFrom(
                    // Tamaño mínimo solicitado para facilitar la pulsación.
                    minimumSize: const Size(48, 48),
                  ),
                  // Icono que acompaña la acción.
                  icon: const Icon(Icons.photo_library_outlined),
                  // Texto visible del botón.
                  label: Text(
                    _seleccionando
                        ? 'Abriendo galería…'
                        : 'Seleccionar fotografía',
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  // Vincula este campo con el controlador del nombre.
                  controller: _nombre,
                  // Desactiva el campo mientras hay una operación en curso.
                  enabled: !ocupado,
                  // Limita el nombre del actor a 150 caracteres en el campo.
                  maxLength: 150,
                  // Sugiere al teclado iniciar cada palabra con mayúscula; no transforma obligatoriamente el texto.
                  textCapitalization: TextCapitalization.words,
                  // Muestra la acción de finalizar en el teclado.
                  textInputAction: TextInputAction.done,
                  // Quita el foco al tocar fuera del campo.
                  onTapOutside: (_) {
                    // Quita el foco del campo activo para cerrar el teclado.
                    FocusScope.of(context).unfocus();
                  },
                  // Intenta guardar cuando se pulsa la acción de finalizar del teclado.
                  onFieldSubmitted: (_) {
                    // Ejecuta las validaciones y solicita guardar el formulario.
                    _guardar();
                  },
                  // Configura la etiqueta y el borde del campo; utiliza el tema compartido.
                  decoration: const InputDecoration(
                    // Etiqueta que identifica el campo del nombre.
                    labelText: 'Nombre del actor',
                    // Define el borde del campo.
                    border: OutlineInputBorder(),
                  ),
                  // Revisa el texto y devuelve un mensaje si el nombre no es válido.
                  validator: (valor) {
                    // Rechaza un nombre vacío o compuesto únicamente por espacios.
                    if ((valor ?? '').trim().isEmpty) {
                      // Devuelve el error de validación que aparecerá junto al campo.
                      return 'Escribe el nombre del actor.';
                    }
                    // Indica que no hay un valor específico; en el validador del formulario significa que el dato es válido.
                    return null;
                  },
                ),
                // Agrega los widgets de error a la lista únicamente cuando existe un mensaje.
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
                              ? 'Actualizar actor'
                              : 'Guardar actor',
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
