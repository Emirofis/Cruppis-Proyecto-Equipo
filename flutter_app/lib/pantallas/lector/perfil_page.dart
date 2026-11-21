// CRUPPIS — Consulta y edición del perfil.
// Permite cambiar nombre, correo y fotografía. La foto es opcional.
// Elegir o quitar una foto modifica la vista previa; el cambio se confirma al guardar.
// El rol se muestra como información y no se puede editar desde este formulario.

// Permite enviar las credenciales como JSON y leer la respuesta de la API.
import 'dart:convert';
// Permite mostrar un archivo de imagen del teléfono. Este archivo está pensado para la app móvil, no para Flutter web.
import 'dart:io';
// Incluye los componentes de la pantalla, los formularios y la navegación.
import 'package:flutter/material.dart';
// Permite enviar la solicitud de inicio de sesión a la API.
import 'package:http/http.dart' as http;
// Permite seleccionar una fotografía desde la galería del teléfono.
import 'package:image_picker/image_picker.dart';
// Utiliza los estilos compartidos de Cruppis. El nombre del archivo se conserva para no romper las referencias.
import '../../estilos/spooky_tema.dart';
// Pantalla donde la cuenta actual consulta y modifica su nombre, correo y fotografía.
class PerfilPage extends StatefulWidget {
  // Recibe los datos de la cuenta, el token y una función para comunicar las actualizaciones.
  const PerfilPage({
    // Permite que Flutter identifique este widget dentro del árbol de la interfaz.
    super.key,
    required this.usuario,
    // Obliga a proporcionar el token al abrir la pantalla.
    required this.token,
    required this.onActualizado,
  });
  // Proporciona los datos iniciales mientras se consulta el perfil actualizado en la API.
  final Map<String, dynamic> usuario;
  // Identifica la sesión al consultar o modificar el perfil en la API.
  final String token;
  // Función que recibe el perfil actualizado para reflejar los cambios en la pantalla que abrió esta sección.
  final ValueChanged<Map<String, dynamic>> onActualizado;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Crea el estado que controla los campos, la fotografía y las consultas.
  State<PerfilPage> createState() => _PerfilPageState();
}
// Reúne los datos y las acciones de la pantalla de perfil.
class _PerfilPageState extends State<PerfilPage> {
  // Dirección de la API. Debe actualizarse si cambia la IPv4 de la computadora.
  static const String _servidor = 'http://192.168.1.65:8000';
  // Permite revisar el nombre y el correo antes de guardar.
  final _formulario = GlobalKey<FormState>();
  // Controla el nombre que se muestra y se modifica en el formulario.
  final _nombre = TextEditingController();
  // Controla el correo que se muestra y se modifica en el formulario.
  final _correo = TextEditingController();
  // Crea el selector de imágenes que abre la galería.
  final _selector = ImagePicker();
  // Guarda el archivo elegido; null significa que no se ha seleccionado uno nuevo.
  XFile? _fotoSeleccionada;
  // Comienza mostrando la carga mientras se consulta el perfil.
  bool _cargando = true;
  // Indica que se está enviando una actualización a la API.
  bool _guardando = false;
  // Indica que se está eligiendo una imagen en la galería.
  bool _seleccionando = false;
  // Recuerda que se solicitó retirar la fotografía. El cambio se confirma al guardar.
  bool _quitarFoto = false;
  // Guarda el problema que impidió consultar el perfil.
  String? _errorCarga;
  // Guarda el problema que ocurrió al elegir la foto o guardar los cambios.
  String? _errorGuardar;
  // Conserva la referencia de la fotografía que tiene guardada la cuenta.
  String _fotoActual = '';
  // Conserva el rol para mostrarlo; esta pantalla no permite modificarlo.
  String _rol = '';
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Carga primero los datos recibidos y después consulta su versión actual en la API.
  void initState() {
    // Ejecuta primero la inicialización que necesita la clase de Flutter.
    super.initState();
    // Coloca el nombre recibido como valor inicial.
    _nombre.text = (widget.usuario['nombre'] ?? '').toString();
    // Coloca el correo recibido como valor inicial.
    _correo.text = (widget.usuario['correo'] ?? '').toString();
    // Recupera la fotografía inicial si existe.
    _fotoActual = (widget.usuario['foto'] ?? '').toString().trim();
    // Recupera el rol de la cuenta para mostrarlo debajo de la fotografía.
    _rol = (widget.usuario['rol'] ?? '').toString();
    // Consulta los datos actuales de la cuenta en la API.
    _cargarPerfil();
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Libera los recursos de los campos cuando esta pantalla deja de utilizarse.
  void dispose() {
    // Libera el controlador del campo de texto.
    _nombre.dispose();
    // Libera el controlador del correo.
    _correo.dispose();
    // Completa la limpieza que necesita Flutter.
    super.dispose();
  }
  // Recupera el mensaje enviado por la API o utiliza un aviso general.
  String _mensajeError(http.Response respuesta) {
    // Reconoce que la API rechazó las credenciales o el acceso de la cuenta.
    if (respuesta.statusCode == 401) {
      // Devuelve instrucciones para que la persona vuelva a autenticarse.
      return 'Tu sesión venció. Cierra sesión e inicia nuevamente.';
    }
    // Intenta completar la operación y atiende los problemas que puedan ocurrir.
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
  // Convierte una respuesta JSON a un mapa y comprueba que tenga la estructura esperada.
  Map<String, dynamic> _leerMapa(http.Response respuesta) {
    // Decodifica los bytes como UTF-8 para conservar acentos y convierte el JSON en datos de Dart.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Rechaza una respuesta que no tenga campos con nombre.
    if (datos is! Map) {
      // Indica que la respuesta no tiene el formato esperado por esta pantalla.
      throw const FormatException('Respuesta inválida.');
    }
    // Devuelve una copia del mapa con nombres de campos de tipo texto.
    return Map<String, dynamic>.from(datos);
  }
  // Coloca los datos confirmados por la API en el formulario y limpia los cambios pendientes de fotografía.
  void _aplicarPerfil(Map<String, dynamic> perfil) {
    // Actualiza el campo del nombre con el valor que devolvió el servidor.
    _nombre.text = (perfil['nombre'] ?? '').toString();
    // Actualiza el correo con el valor que devolvió el servidor.
    _correo.text = (perfil['correo'] ?? '').toString();
    // Guarda la referencia de la fotografía confirmada por la API.
    _fotoActual = (perfil['foto'] ?? '').toString().trim();
    // Actualiza el rol que se muestra, sin ofrecer cambiarlo.
    _rol = (perfil['rol'] ?? '').toString();
    // Descarta la selección local para utilizar la fotografía que quedó confirmada en el perfil.
    _fotoSeleccionada = null;
    // Limpia la solicitud de quitar la foto; también se hace al elegir una nueva imagen.
    _quitarFoto = false;
  }
  // Consulta el perfil de la cuenta identificada por el token, sin enviar un identificador de otro usuario.
  Future<void> _cargarPerfil() async {
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Muestra la carga mientras se consulta la información.
      _cargando = true;
      // Retira el error anterior para volver a intentar la consulta.
      _errorCarga = null;
    });
    // Intenta completar la operación y atiende los problemas que puedan ocurrir.
    try {
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Solicita datos al servidor utilizando el método GET.
          .get(
            // Dirección de la API que consulta o actualiza el perfil de la sesión actual.
            Uri.parse('$_servidor/api/perfil'),
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
      // Informa que el servidor no confirmó el inicio de sesión.
      if (respuesta.statusCode != 200) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Conserva la explicación que envió el servidor al rechazar la consulta.
          _errorCarga = _mensajeError(respuesta);
        });
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Lee los datos del perfil que devolvió la consulta.
      final perfil = _leerMapa(respuesta);
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Actualiza el formulario con los valores confirmados por la API.
        _aplicarPerfil(perfil);
      });
      // Comunica el perfil actualizado a la pantalla principal para reflejar allí el nombre y los demás datos.
      widget.onActualizado(perfil);
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        _errorCarga =
            'No se pudo cargar tu perfil. Comprueba la conexión.';
      });
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Comprueba que el perfil siga abierto antes de actualizar su contenido.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Termina el estado de carga, tanto si se consultó el perfil como si hubo un error.
          _cargando = false;
        });
      }
    }
  }
  // Acepta una dirección completa, una ruta de portadas o un nombre de archivo para mostrar la fotografía.
  String _urlFoto(String valor) {
    // Retira los espacios sobrantes de la referencia de imagen.
    final foto = valor.trim();
    // Si no hay fotografía, devuelve una dirección vacía; la tarjeta dispone de un icono de respaldo.
    if (foto.isEmpty) return '';
    // Intenta interpretar el texto como una URI; devuelve null si no se puede analizar.
    final uri = Uri.tryParse(foto);
    // Comprueba si se pudo interpretar la dirección y si utiliza HTTP o HTTPS.
    if (uri != null &&
        // Acepta direcciones completas tanto HTTP como HTTPS; esto no comprueba que la imagen exista.
        (uri.scheme == 'http' || uri.scheme == 'https')) {
      // Conserva la dirección completa que ya proporcionó el servidor.
      return foto;
    }
    // Reconoce las rutas de fotografías que ya incluyen el directorio portadas.
    if (foto.startsWith('/portadas/') ||
        // También acepta esa ruta aunque no tenga una barra inicial.
        foto.startsWith('portadas/')) {
      // Completa la ruta relativa con la dirección del servidor.
      return Uri.parse('$_servidor/').resolve(foto).toString();
    }
    // Construye una dirección dentro de /portadas cuando solo se recibió un nombre de archivo.
    return Uri.parse(_servidor).replace(
      // Añade los componentes de la ruta y deja que Uri codifique los caracteres que lo necesiten.
      pathSegments: ['portadas', foto],
    ).toString();
  }
  // Abre la galería, comprueba el tamaño y prepara una fotografía nueva sin guardarla todavía en el servidor.
  Future<void> _seleccionarFoto() async {
    // Evita iniciar otra operación mientras se guarda o se selecciona una imagen.
    if (_guardando || _seleccionando) return;
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Activa el indicador de selección para evitar pulsaciones repetidas.
      _seleccionando = true;
      // Limpia el aviso anterior antes de una nueva acción.
      _errorGuardar = null;
    });
    // Intenta completar la operación y atiende los problemas que puedan ocurrir.
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
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Conserva la imagen elegida para mostrarla y enviarla cuando se guarden los cambios.
        _fotoSeleccionada = seleccion;
        // Limpia la solicitud de quitar la foto; también se hace al elegir una nueva imagen.
        _quitarFoto = false;
      });
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        _errorGuardar = 'No se pudo seleccionar la fotografía. '
            'Usa una imagen JPG, PNG o WEBP de hasta 5 MB.';
      });
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Comprueba que el perfil siga abierto antes de actualizar su contenido.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Libera el estado de selección al terminar, incluso si hubo un error.
          _seleccionando = false;
        });
      }
    }
  }
  // Prepara la eliminación de la fotografía en el formulario; todavía no envía cambios a la API.
  void _eliminarFoto() {
    // Evita iniciar otra operación mientras se guarda o se selecciona una imagen.
    if (_guardando || _seleccionando) return;
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Descarta la selección local para utilizar la fotografía que quedó confirmada en el perfil.
      _fotoSeleccionada = null;
      // Oculta la fotografía en la vista previa y marca que debe retirarse al guardar.
      _quitarFoto = true;
      // Limpia el aviso anterior antes de una nueva acción.
      _errorGuardar = null;
    });
  }
  // Valida los campos y envía el nombre, el correo y el cambio de fotografía solicitado.
  Future<void> _guardarPerfil() async {
    // Evita enviar el formulario mientras se guarda o se selecciona una imagen.
    if (_guardando ||
        _seleccionando ||
        // No continúa si el formulario no está disponible o tiene campos inválidos.
        !(_formulario.currentState?.validate() ?? false)) {
      // Termina esta operación sin continuar con las instrucciones siguientes.
      return;
    }
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Desactiva las acciones mientras se espera la confirmación del guardado.
      _guardando = true;
      // Limpia el aviso anterior antes de una nueva acción.
      _errorGuardar = null;
    });
    // Crea un cliente HTTP para enviar la solicitud multipart y cerrarlo al finalizar.
    final cliente = http.Client();
    // Intenta completar la operación y atiende los problemas que puedan ocurrir.
    try {
      // Prepara una solicitud multipart para enviar campos de texto y un archivo en la misma petición.
      final solicitud = http.MultipartRequest(
        // Utiliza PUT porque se modifica una cuenta que ya existe.
        'PUT',
        // Dirección de la API que consulta o actualiza el perfil de la sesión actual.
        Uri.parse('$_servidor/api/perfil'),
      );
      // Agrega el token de sesión para que el backend compruebe la autorización.
      solicitud.headers['Authorization'] = 'Bearer ${widget.token}';
      // Agrega los campos de texto de la actualización; no incluye el rol.
      solicitud.fields.addAll({
        // Envía el nombre sin espacios sobrantes en los extremos.
        'nombre': _nombre.text.trim(),
        // Envía el correo sin espacios sobrantes en los extremos.
        'correo': _correo.text.trim(),
        // Indica al backend si se pidió retirar la foto actual.
        'quitar_foto': _quitarFoto ? 'true' : 'false',
      });
      // Obtiene la fotografía nueva, si se seleccionó una.
      final foto = _fotoSeleccionada;
      // Adjunta una fotografía únicamente cuando se eligió una nueva.
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
      // Informa que el servidor no confirmó el inicio de sesión.
      if (respuesta.statusCode != 200) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Muestra la explicación del servidor, por ejemplo cuando el correo pertenece a otra cuenta.
          _errorGuardar = _mensajeError(respuesta);
        });
        // Termina esta operación sin continuar con las instrucciones siguientes.
        return;
      }
      // Lee la respuesta de confirmación del guardado.
      final datos = _leerMapa(respuesta);
      // Recupera los datos actualizados que la API incluye dentro del campo usuario.
      final usuario = datos['usuario'];
      // Comprueba que la confirmación incluya los datos de la cuenta antes de utilizarlos.
      if (usuario is! Map) {
        // Indica que la respuesta no tiene el formato esperado por esta pantalla.
        throw const FormatException('Respuesta inválida.');
      }
      // Prepara el mapa con los datos confirmados del perfil.
      final perfil = Map<String, dynamic>.from(usuario);
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        // Actualiza el formulario con los valores confirmados por la API.
        _aplicarPerfil(perfil);
      });
      // Comunica el perfil actualizado a la pantalla principal para reflejar allí el nombre y los demás datos.
      widget.onActualizado(perfil);
      // Muestra un aviso temporal para confirmar la actualización del perfil.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          // Contenido principal del mensaje o del diálogo.
          content: Text('Perfil actualizado correctamente.'),
        ),
      );
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Evita actualizar la interfaz si el widget se cerró mientras se esperaba una operación.
      if (!mounted) return;
      // Actualiza los valores y refleja el cambio en la pantalla.
      setState(() {
        _errorGuardar = 'No se pudo confirmar el guardado. '
            'Vuelve a abrir tu perfil para comprobar los cambios.';
      });
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Libera los recursos del cliente HTTP al terminar la operación.
      cliente.close();
      // Comprueba que el perfil siga abierto antes de actualizar su contenido.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Desactiva el estado de envío.
          _guardando = false;
        });
      }
    }
  }
  // Decide si debe mostrar la fotografía nueva, la actual o el icono de respaldo.
  Widget _avatar() {
    // Prepara el icono que se utiliza cuando no hay foto o no se puede cargar.
    const icono = Icon(
      Icons.person_outline,
      // Tamaño del icono en unidades lógicas.
      size: 64,
      // Color tomado del tema o del esquema de colores.
      color: SpookyTema.textoSecundario,
    );
    // Copia la referencia a una variable local para comprobar si es nula.
    final seleccion = _fotoSeleccionada;
    // Comienza con el icono de respaldo y lo sustituye si hay una imagen disponible.
    Widget imagen = icono;
    // No intenta mostrar una fotografía cuando se ha solicitado retirarla.
    if (!_quitarFoto) {
      // Si hay una fotografía nueva, utiliza ese archivo para la vista previa.
      if (seleccion != null) {
        // Muestra como vista previa el archivo elegido en el teléfono.
        imagen = Image.file(
          // Crea la referencia al archivo local mediante la ruta que devolvió image_picker.
          File(seleccion.path),
          // Llena el marco de la fotografía manteniendo su proporción y recortando lo que sobra.
          fit: BoxFit.cover,
          // Construye una alternativa visual cuando la imagen no se puede cargar.
          errorBuilder: (context, error, stackTrace) {
            // Utiliza el icono de respaldo si la imagen falla al cargarse.
            return icono;
          },
        );
      // Si no hay una foto nueva, intenta mostrar la que está guardada en la cuenta.
      } else if (_fotoActual.isNotEmpty) {
        // Carga la fotografía actual desde su dirección en el servidor.
        imagen = Image.network(
          _urlFoto(_fotoActual),
          // Llena el marco de la fotografía manteniendo su proporción y recortando lo que sobra.
          fit: BoxFit.cover,
          // Construye una alternativa visual cuando la imagen no se puede cargar.
          errorBuilder: (context, error, stackTrace) {
            // Utiliza el icono de respaldo si la imagen falla al cargarse.
            return icono;
          },
        );
      }
    }
    return Center(
      // Widget que se coloca dentro de este contenedor.
      child: Container(
        // Establece el espacio interior alrededor del contenido.
        padding: const EdgeInsets.all(3),
        // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
        decoration: SpookyDetalleEstilos.marcoFoto,
        // Widget que se coloca dentro de este contenedor.
        child: ClipOval(
          // Widget que se coloca dentro de este contenedor.
          child: SizedBox(
            // Ancho solicitado en unidades lógicas de Flutter.
            width: 110,
            // Altura solicitada en unidades lógicas de Flutter.
            height: 110,
            // Widget que se coloca dentro de este contenedor.
            child: ColoredBox(
              // Color tomado del tema o del esquema de colores.
              color: SpookyDetalleEstilos.fondoFoto,
              // Widget que se coloca dentro de este contenedor.
              child: imagen,
            ),
          ),
        ),
      ),
    );
  }
  // Elige entre mostrar la carga, un error con opción de reintentar o el formulario del perfil.
  Widget _contenido() {
    // Mientras llega el perfil, muestra el indicador de carga.
    if (_cargando) {
      return const Center(
        // Widget que se coloca dentro de este contenedor.
        child: CircularProgressIndicator(),
      );
    }
    // Si no se pudo consultar, muestra la explicación y permite intentarlo otra vez.
    if (_errorCarga != null) {
      return Center(
        // Widget que se coloca dentro de este contenedor.
        child: Padding(
          // Establece el espacio interior alrededor del contenido.
          padding: SpookyDetalleEstilos.margenPanel,
          // Widget que se coloca dentro de este contenedor.
          child: Column(
            // min evita que la columna ocupe más altura de la necesaria.
            mainAxisSize: MainAxisSize.min,
            // Lista de widgets que se colocarán dentro del componente.
            children: [
              Text(
                _errorCarga!,
                // Alineación del texto dentro del espacio disponible.
                textAlign: TextAlign.center,
                // Estilo del texto o del botón.
                style: SpookyDetalleEstilos.contenido,
              ),
              SpookyDetalleEstilos.espacio,
              FilledButton(
                // Asigna la acción y desactiva el botón mientras hay una operación en curso.
                onPressed: _cargarPerfil,
                // Widget que se coloca dentro de este contenedor.
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    // Reúne los dos indicadores para desactivar controles durante una operación.
    final ocupado = _guardando || _seleccionando;
    // Muestra la opción de quitar foto solo cuando todavía hay una imagen disponible.
    final mostrarQuitarFoto = !_quitarFoto &&
        // Considera tanto una selección nueva como una fotografía guardada anteriormente.
        (_fotoSeleccionada != null || _fotoActual.isNotEmpty);
    return SingleChildScrollView(
      // Configura cómo se oculta el teclado al desplazar el formulario.
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      // Establece el espacio interior alrededor del contenido.
      padding: SpookyDetalleEstilos.margenPantalla,
      // Widget que se coloca dentro de este contenedor.
      child: Center(
        // Widget que se coloca dentro de este contenedor.
        child: ConstrainedBox(
          // Evita que el formulario quede demasiado ancho en pantallas grandes.
          constraints: const BoxConstraints(maxWidth: 600),
          // Widget que se coloca dentro de este contenedor.
          child: Container(
            // Establece el espacio interior alrededor del contenido.
            padding: SpookyDetalleEstilos.margenPanel,
            // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
            decoration: SpookyDetalleEstilos.panel,
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
                  const Text(
                    'MI PERFIL',
                    // Estilo del texto o del botón.
                    style: SpookyDetalleEstilos.encabezado,
                  ),
                  SpookyDetalleEstilos.separador,
                  _avatar(),
                  SpookyDetalleEstilos.espacioCorto,
                  Text(
                    _rol,
                    // Alineación del texto dentro del espacio disponible.
                    textAlign: TextAlign.center,
                    // Estilo del texto o del botón.
                    style: SpookyDetalleEstilos.etiquetaDirector,
                  ),
                  SpookyDetalleEstilos.espacio,
                  TextFormField(
                    // Conecta el campo con el nombre o correo que se está editando.
                    controller: _nombre,
                    // Bloquea el campo mientras se guarda o se selecciona una foto.
                    enabled: !ocupado,
                    // Limita el campo según el tamaño permitido para el nombre o el correo.
                    maxLength: 100,
                    // Sugiere al teclado iniciar cada palabra con mayúscula; no transforma obligatoriamente el texto.
                    textCapitalization: TextCapitalization.words,
                    // Muestra la acción de finalizar en el teclado.
                    textInputAction: TextInputAction.next,
                    // Quita el foco al tocar fuera del campo.
                    onTapOutside: (_) {
                      // Cierra el teclado antes de continuar con la acción.
                      FocusScope.of(context).unfocus();
                    },
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Nombre',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    // Revisa el valor antes de enviar los cambios a la API.
                    validator: (valor) {
                      // Rechaza un nombre vacío o compuesto únicamente por espacios.
                      if ((valor ?? '').trim().isEmpty) {
                        return 'Escribe tu nombre.';
                      }
                      // Indica que este campo pasó la validación.
                      return null;
                    },
                  ),
                  SpookyDetalleEstilos.espacioCorto,
                  TextFormField(
                    // Conecta el campo con el nombre o correo que se está editando.
                    controller: _correo,
                    // Bloquea el campo mientras se guarda o se selecciona una foto.
                    enabled: !ocupado,
                    // Limita el campo según el tamaño permitido para el nombre o el correo.
                    maxLength: 254,
                    keyboardType: TextInputType.emailAddress,
                    // Muestra la acción de finalizar en el teclado.
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    // Quita el foco al tocar fuera del campo.
                    onTapOutside: (_) {
                      // Cierra el teclado antes de continuar con la acción.
                      FocusScope.of(context).unfocus();
                    },
                    // Permite guardar desde la acción de finalizar del teclado.
                    onFieldSubmitted: (_) {
                      // Permite intentar guardar desde la acción de finalizar del teclado.
                      _guardarPerfil();
                    },
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el campo del nombre.
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    // Revisa el valor antes de enviar los cambios a la API.
                    validator: (valor) {
                      // Prepara el correo para comprobar que no esté vacío y que incluya una arroba.
                      final correo = (valor ?? '').trim();
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(correo)) {
                        return 'Escribe un correo válido.';
                      }
                      // Indica que este campo pasó la validación.
                      return null;
                    },
                  ),
                  SpookyDetalleEstilos.espacioCorto,
                  OutlinedButton.icon(
                    // Asigna la acción y desactiva el botón mientras hay una operación en curso.
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
                  // Incluye el botón de quitar fotografía únicamente cuando corresponde.
                  if (mostrarQuitarFoto)
                    TextButton.icon(
                      // Asigna la acción y desactiva el botón mientras hay una operación en curso.
                      onPressed: ocupado ? null : _eliminarFoto,
                      // Icono que acompaña la acción.
                      icon: const Icon(Icons.delete_outline),
                      // Texto visible del botón.
                      label: const Text('Quitar fotografía'),
                    ),
                  // Añade el mensaje al formulario si ocurrió un problema al seleccionar o guardar.
                  if (_errorGuardar != null) ...[
                    SpookyDetalleEstilos.espacioCorto,
                    Text(
                      _errorGuardar!,
                      // Estilo del texto o del botón.
                      style: TextStyle(
                        // Color tomado del tema o del esquema de colores.
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  SpookyDetalleEstilos.espacio,
                  DecoratedBox(
                    // Aplica el fondo, el borde y la sombra definidos en los estilos compartidos.
                    decoration: SpookyPanelEstilos.resplandorBoton,
                    // Widget que se coloca dentro de este contenedor.
                    child: FilledButton(
                      // Estilo del texto o del botón.
                      style: SpookyPanelEstilos.boton,
                      // Asigna la acción y desactiva el botón mientras hay una operación en curso.
                      onPressed: ocupado ? null : _guardarPerfil,
                      // Widget que se coloca dentro de este contenedor.
                      child: Text(
                        _guardando
                            ? 'Guardando...'
                            : 'Guardar cambios',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Construye el encabezado y el fondo del perfil con el contenido que corresponde al estado actual.
  Widget build(BuildContext context) {
    return PopScope(
      // Evita regresar mientras se envían cambios o se está seleccionando una fotografía.
      canPop: !_guardando && !_seleccionando,
      // Widget que se coloca dentro de este contenedor.
      child: Scaffold(
        // Configura la barra superior de esta pantalla.
        appBar: AppBar(
          // Texto de la barra superior o del cuadro de confirmación.
          title: const Text(
            'MI PERFIL',
            // Estilo del texto o del botón.
            style: SpookyPanelEstilos.logo,
          ),
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
              child: _contenido(),
            ),
          ),
        ),
      ),
    );
  }
}
