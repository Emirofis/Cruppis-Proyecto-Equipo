// CRUPPIS — Formulario de directores.
// StatefulWidget permite actualizar la pantalla; State conserva los datos y sus indicadores.
// Future representa un resultado pendiente; async y await permiten esperar sin bloquear la interfaz.
// final impide reasignar una variable; late indica que se preparará antes de usarla.
// El signo ? permite null, que significa ausencia de valor; ?? elige otro valor si falta el primero.
// setState pide reconstruir la interfaz; mounted comprueba si la pantalla sigue activa.
// try intenta una operación; catch atiende errores y finally libera recursos al terminar.
// JSON es el formato de respuesta de la API; UTF-8 permite leer acentos y otros caracteres.
// Un token identifica la sesión; la API comprueba si puede guardar cambios.

// Permite leer los datos JSON que devuelve la API.
import 'dart:convert';
// Permite acceder a la fotografía seleccionada en el teléfono.
import 'dart:io';
import 'package:flutter/material.dart';
// Se utiliza para enviar el formulario a la API.
import 'package:http/http.dart' as http;
// Permite seleccionar una fotografía desde la galería.
import 'package:image_picker/image_picker.dart';
// Este formulario se utiliza tanto para registrar
// como para editar los datos de un director.
class FormularioDirectorPage extends StatefulWidget {
  // El constructor recibe la sesión y, si se va a editar, los datos del director.
  const FormularioDirectorPage({
    // key ayuda a Flutter a identificar este widget.
    super.key,
    // required obliga a proporcionar el token al abrir el formulario.
    required this.token,
    this.director,
  });
  // Recibe el token de la sesión para autorizar el guardado.
  final String token;
  // Si recibe un director, muestra sus datos para editarlos.
  // Si es null, el formulario comienza como un registro nuevo.
  final Map<String, dynamic>? director;
  @override
  // Crea el objeto que controla los cambios del formulario.
  State<FormularioDirectorPage> createState() =>
      _FormularioDirectorPageState();
}
class _FormularioDirectorPageState
    extends State<FormularioDirectorPage> {
  // Dirección de la API que está ejecutándose en la computadora.
  // Debe cambiarse si la computadora recibe otra dirección IPv4.
  static const String _servidor = 'http://10.13.40.223:8000';
  // Permite revisar los campos antes de enviar el formulario.
  // GlobalKey permite acceder al estado de Form para ejecutar sus validadores.
  final _formulario = GlobalKey<FormState>();
  // Abre la galería para seleccionar una imagen.
  final _selector = ImagePicker();
  // Controla el texto del nombre.
  // Se prepara en initState para cargar el nombre actual al editar.
  late final TextEditingController _nombre;
  // Conserva la fotografía nueva que se haya seleccionado.
  XFile? _foto;
  // Estos indicadores evitan repetir acciones mientras
  // se guarda el formulario o se selecciona una fotografía.
  bool _guardando = false;
  bool _seleccionando = false;
  // Guarda el mensaje que aparecerá si ocurre un problema.
  String? _error;
  // Determina si se está editando un director existente.
  // get calcula este valor al consultarlo; widget contiene los datos recibidos por la pantalla.
  bool get _editando => widget.director != null;
  // Comprueba si el director ya tiene una fotografía propia.
  // Rechaza el marcador antiguo default_director.jpg; no lo usa como imagen.
  // Solo permite conservar una referencia de foto del backend actual.
  bool get _tieneFotoActual {
    final foto =
        (widget.director?['foto'] ?? '').toString().trim();
    return foto != 'default_director.jpg' && _urlFotoActual().isNotEmpty;
  }
  @override
  void initState() {
    // Ejecuta primero la preparación que requiere Flutter.
    super.initState();
    // Al editar, coloca el nombre actual en el campo.
    // En un registro nuevo, deja el campo vacío.
    _nombre = TextEditingController(
      text: (widget.director?['nombre'] ?? '').toString(),
    );
  }
  @override
  void dispose() {
    // Libera el controlador cuando se cierra el formulario.
    _nombre.dispose();
    super.dispose();
  }
  // Abre la galería y revisa la fotografía seleccionada.
  Future<void> _seleccionarFoto() async {
    // Evita abrir la galería varias veces o durante el guardado.
    if (_seleccionando || _guardando) {
      return;
    }
    // Cierra el teclado antes de mostrar la galería.
    FocusScope.of(context).unfocus();
    setState(() {
      // Bloquea nuevas selecciones y borra el aviso anterior.
      _seleccionando = true;
      _error = null;
    });
    try {
      // Solicita una imagen con dimensiones moderadas
      // para evitar cargar una fotografía demasiado grande.
      final seleccion = await _selector.pickImage(
        // Utiliza la galería; estas medidas y calidad ayudan a reducir el archivo enviado.
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      // Si se cierra la galería sin elegir una imagen,
      // conserva la fotografía que ya se tenía.
      if (seleccion == null) {
        return;
      }
      // Revisa que el archivo elegido no supere los 5 MB.
      // length devuelve el tamaño en bytes; 1024 × 1024 bytes equivalen a un MiB.
      if (await seleccion.length() > 5 * 1024 * 1024) {
        throw Exception(
          'La fotografía debe pesar como máximo 5 MB.',
        );
      }
      // Después de esperar, comprueba que el formulario siga abierto.
      if (!mounted) {
        return;
      }
      // Guarda la selección y actualiza la vista previa.
      setState(() {
        _foto = seleccion;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo seleccionar la fotografía. '
              'Usa una imagen JPG, PNG o WEBP de hasta 5 MB.';
        });
      }
    } finally {
      // Libera el botón aunque se haya cancelado la selección
      // o haya ocurrido un error.
      if (mounted) {
        setState(() {
          _seleccionando = false;
        });
      }
    }
  }
  // Revisa los datos y envía el nombre y la fotografía a la API.
  Future<void> _guardar() async {
    // No continúa si hay otra operación en curso
    // o si algún campo del formulario no es válido.
    if (_guardando ||
        _seleccionando ||
        // ?. llama a validate solo si el estado existe; si falta, no se envía el formulario.
        !(_formulario.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    // Exige una fotografía al registrar.
    // Al editar permite conservar la fotografía actual.
    if (_foto == null && !_tieneFotoActual) {
      setState(() {
        _error = 'Selecciona una fotografía para el director.';
      });
      return;
    }
    // Desactiva los botones y limpia cualquier error anterior.
    setState(() {
      _guardando = true;
      _error = null;
    });
    // Este cliente se utiliza para enviar la solicitud
    // y se cierra al terminar.
    final cliente = http.Client();
    // Solo cambia a true cuando la API confirma el guardado.
    bool guardado = false;
    try {
      // Al editar, la dirección incluye el identificador del director.
      // Al registrar, utiliza la dirección general de directores.
      final ruta = _editando
          ? '$_servidor/api/admin/directores/'
              // ! indica que aquí se espera un director no nulo porque estamos editando.
              '${widget.director!['id_director']}'
          : '$_servidor/api/admin/directores';
      // MultipartRequest permite enviar texto y archivos juntos.
      // PUT actualiza un registro y POST crea uno nuevo.
      final solicitud = http.MultipartRequest(
        _editando ? 'PUT' : 'POST',
        Uri.parse(ruta),
      );
      // La API utiliza el token para comprobar los permisos.
      solicitud.headers['Authorization'] =
          'Bearer ${widget.token}';
      // Envía el nombre sin espacios al principio ni al final.
      solicitud.fields['nombre'] = _nombre.text.trim();
      final foto = _foto;
      // Solo adjunta una imagen cuando se eligió una nueva.
      // Si no se adjunta, el backend conserva la fotografía actual.
      if (foto != null) {
        solicitud.files.add(
          await http.MultipartFile.fromPath(
            // Debe coincidir con el nombre del campo de la API.
            'foto',
            // Ruta del archivo temporal seleccionado en el dispositivo.
            foto.path,
            // Adjunta el nombre del archivo junto con su contenido.
            filename: foto.name,
          ),
        );
      }
      // Espera el envío y la lectura completa de la respuesta.
      // El límite de espera se aplica a ambas partes.
      final respuesta = await (() async {
        // Envía la solicitud y recibe un flujo: una respuesta que llega por partes.
        final envio = await cliente.send(solicitud);
        // Reúne las partes en una respuesta que permite consultar estado y contenido.
        return http.Response.fromStream(envio);
      // timeout limita la espera; no garantiza que el servidor haya cancelado el guardado.
      })().timeout(const Duration(seconds: 30));
      // La API responde 200 al actualizar y 201 al registrar.
      if (respuesta.statusCode == 200 ||
          respuesta.statusCode == 201) {
        guardado = true;
      } else {
        String mensaje = 'No se pudo guardar el director.';
        if (respuesta.statusCode == 401) {
          mensaje = 'La sesión venció. Inicia sesión nuevamente.';
        } else if (respuesta.statusCode == 403) {
          mensaje = 'Tu cuenta no tiene permisos de administrador.';
        } else {
          // Intenta recuperar la explicación que envió la API.
          try {
            final datos = jsonDecode(
              utf8.decode(respuesta.bodyBytes),
            );
            if (datos is Map && datos['detail'] is String) {
              mensaje = datos['detail'] as String;
            }
          } catch (_) {
            // Si la respuesta no contiene JSON válido,
            // conserva el mensaje general.
          }
        }
        if (mounted) {
          setState(() {
            _error = mensaje;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          // Una falla de conexión no permite saber con certeza
          // si el servidor alcanzó a guardar el registro.
          _error = 'No se pudo confirmar el guardado. '
              'Vuelve a la lista y actualízala antes de intentar otra vez.';
        });
      }
    } finally {
      // Libera los recursos del cliente HTTP.
      cliente.close();
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
    // Regresa a la lista y avisa que debe mostrar los cambios.
    if (mounted && guardado) {
      // pop cierra esta pantalla y devuelve true al listado para confirmar el cambio.
      Navigator.of(context).pop(true);
    }
  }
  // Valida la referencia guardada y rechaza las imágenes de sitios externos.
  String _urlFotoActual() {
    // ?? utiliza texto vacío cuando no hay una foto; no crea una imagen de prueba.
    final foto = (widget.director?['foto'] ?? '').toString().trim();
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


  // Decide qué imagen mostrar dentro del formulario.
  Widget _vistaFoto() {
    final foto = _foto;
    // Da prioridad a la fotografía que se acaba de seleccionar.
    if (foto != null) {
      return Image.file(
        // Image.file muestra la selección local antes de subirla al backend.
        File(foto.path),
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Muestra un icono si el archivo no se puede abrir.
          return const Icon(
            Icons.broken_image_outlined,
            size: 80,
          );
        },
      );
    }
    // Obtiene la dirección local validada para la fotografía guardada.
    final url = _urlFotoActual();

    // Solo consulta imágenes de /portadas/ en el backend configurado.
    if (url.isNotEmpty) {
      return Image.network(
        url,
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person_outline, size: 80);
        },
      );
    }
    // Mantiene un espacio para la foto cuando todavía no hay ninguna.
    return const SizedBox(
      width: 160,
      height: 160,
      child: Icon(Icons.person_outline, size: 80),
    );
  }
  @override
  // build describe la interfaz usando los valores actuales del formulario.
  Widget build(BuildContext context) {
    // Scaffold organiza la barra superior y el contenido de la pantalla.
    return Scaffold(
      appBar: AppBar(
        title: Text(
          // El título cambia según la operación que se está realizando.
          _editando ? 'Editar director' : 'Registrar director',
        ),
      ),
      // Permite recorrer el formulario si el teclado
      // o el tamaño del teléfono reducen el espacio disponible.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          // Vincula este Form con la clave que ejecuta validate antes de guardar.
          key: _formulario,
          child: Column(
            // Column coloca los elementos en vertical; stretch solicita todo el ancho disponible.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Centra la fotografía y redondea sus esquinas.
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _vistaFoto(),
                ),
              ),
              const SizedBox(height: 20),
              // Abre la galería cuando no hay otra operación en curso.
              OutlinedButton.icon(
                onPressed: _guardando || _seleccionando
                    ? null
                    : _seleccionarFoto,
                style: OutlinedButton.styleFrom(
                  // Tamaño mínimo solicitado en unidades lógicas para facilitar la pulsación.
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(
                  _seleccionando
                      ? 'Abriendo galería…'
                      : 'Seleccionar fotografía',
                ),
              ),
              const SizedBox(height: 24),
              // Campo para registrar o modificar el nombre.
              TextFormField(
                // El controlador permite leer y preparar el nombre del campo.
                controller: _nombre,
                // Evita cambiar el nombre mientras se está enviando.
                enabled: !_guardando,
                // Limita el nombre a 100 caracteres en este campo.
                maxLength: 100,
                // Sugiere al teclado comenzar cada palabra en mayúscula.
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre del director',
                  border: OutlineInputBorder(),
                ),
                // No permite un nombre vacío o compuesto solo por espacios.
                validator: (valor) {
                  if ((valor ?? '').trim().isEmpty) {
                    return 'Escribe el nombre del director.';
                  }
                  // null indica que el campo pasó esta validación.
                  return null;
                },
              ),
              // Agrega el mensaje únicamente cuando existe un error.
              // ... incorpora estos widgets a la lista solo si existe un error.
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  // ! utiliza el mensaje como no nulo tras comprobarlo en la condición.
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Envía el formulario después de revisar sus datos.
              FilledButton(
                onPressed: _guardando || _seleccionando
                    ? null
                    : _guardar,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                ),
                // Mientras guarda, sustituye el texto por un indicador.
                child: _guardando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _editando
                            ? 'Actualizar director'
                            : 'Guardar director',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
