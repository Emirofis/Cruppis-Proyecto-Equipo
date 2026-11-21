// CRUPPIS — Consulta y gestión de directores.
// Esta pantalla muestra los registros y permite abrir su formulario o solicitar una eliminación.
// El formulario se encuentra en formulario_director_page.dart.
// La API comprueba los permisos y realiza los cambios en MySQL.

// Permite leer las respuestas JSON de la API y conservar correctamente los acentos.
import 'dart:convert';
// Incluye los componentes que se utilizan para construir la pantalla.
import 'package:flutter/material.dart';
// Permite consultar la API y enviar la solicitud de eliminación.
import 'package:http/http.dart' as http;
// Importa el formulario que se abre para registrar o editar un director.
import 'formulario_director_page.dart';
// Define la pantalla de directores. Su contenido cambia al consultar, editar o eliminar registros.
class DirectoresPage extends StatefulWidget {
  // Recibe el token de la cuenta que abrió esta pantalla.
  const DirectoresPage({
    // Permite que Flutter identifique esta pantalla dentro de la aplicación.
    super.key,
    // El token es obligatorio para realizar las consultas administrativas.
    required this.token,
  });
  // Conserva el token recibido para enviarlo a la API.
  final String token;
  @override
  // Crea el estado que controla los datos y las acciones de esta pantalla.
  State<DirectoresPage> createState() => _DirectoresPageState();
}
// Reúne las consultas, los mensajes y la presentación de la lista de directores.
class _DirectoresPageState extends State<DirectoresPage> {
  // Dirección de la API en la computadora. Debe actualizarse si cambia su IPv4.
  static const String _servidor = 'http://192.168.1.65:8000';
  // Guarda la consulta pendiente y su futura lista de resultados. Se prepara en initState.
  late Future<List<Map<String, dynamic>>> _directores;
  // Evita iniciar otras acciones mientras se está eliminando un director.
  bool _eliminando = false;
  // Identifica la tarjeta que debe mostrar el aviso de eliminación; null significa que no hay ninguna.
  int? _idEliminando;
  @override
  // Prepara la pantalla la primera vez que se abre.
  void initState() {
    // Realiza primero la preparación que necesita Flutter.
    super.initState();
    // Inicia una consulta y la asigna a la lista que observa la pantalla.
    _directores = _consultarDirectores();
  }
  // Solicita los directores a la API sin detener la interacción con la aplicación.
  Future<List<Map<String, dynamic>>> _consultarDirectores() async {
    // Espera la respuesta de la petición HTTP.
    final respuesta = await http
        // Utiliza GET para consultar información sin modificar los registros.
        .get(
          // Prepara la dirección de la consulta administrativa de directores.
          Uri.parse('$_servidor/api/admin/directores'),
          // Incluye los datos de autorización que acompañan la solicitud.
          headers: {
            // Envía el token de sesión para que la API compruebe la cuenta y sus permisos.
            'Authorization': 'Bearer ${widget.token}',
          },
        )
        // Limita la espera a 20 segundos para evitar que la operación quede esperando indefinidamente.
        .timeout(const Duration(seconds: 20));
    // Detecta que la API no aceptó la sesión, por ejemplo porque venció el token.
    if (respuesta.statusCode == 401) {
      // Comunica el fallo para que la pantalla pueda mostrar su explicación.
      throw Exception(
        'Tu sesión venció. Cierra sesión e inicia nuevamente.',
      );
    }
    // Detecta que la cuenta no tiene permiso para realizar esta operación.
    if (respuesta.statusCode == 403) {
      // Comunica el fallo para que la pantalla pueda mostrar su explicación.
      throw Exception(
        'Tu cuenta no tiene permisos de administrador.',
      );
    }
    // Si no se recibió la confirmación esperada, muestra un error en lugar de utilizar los datos.
    if (respuesta.statusCode != 200) {
      // Comunica el fallo para que la pantalla pueda mostrar su explicación.
      throw Exception(
        'No se pudieron consultar los directores '
        '(${respuesta.statusCode}).',
      );
    }
    // Convierte la respuesta a datos de Dart y utiliza UTF-8 para conservar acentos y otros caracteres.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la API realmente haya devuelto una lista.
    if (datos is! List) {
      // Informa que la respuesta no tiene la estructura que necesita esta pantalla.
      throw const FormatException('La respuesta no es una lista.');
    }
    // Prepara los datos de cada director para devolverlos como una lista de mapas.
    return datos
        // Convierte cada registro a un mapa con nombres de campos y sus valores.
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        // Reúne todos los registros convertidos en una lista.
        .toList();
  }
  // Vuelve a consultar los directores para mostrar los cambios más recientes.
  void _recargar() {
    // Actualiza los datos del estado y pide a Flutter que refleje el cambio en pantalla.
    setState(() {
      // Inicia una consulta y la asigna a la lista que observa la pantalla.
      _directores = _consultarDirectores();
    });
  }
  // Centraliza los avisos para no repetir su construcción en cada operación.
  void _mostrarMensaje(String mensaje) {
    // Comprueba que la pantalla siga abierta antes de utilizarla después de una espera.
    if (!mounted) return;
    // Muestra el mensaje temporal en la parte inferior de la pantalla.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
  // Busca un mensaje útil en la respuesta de la API cuando falla una eliminación.
  String _mensajeError(http.Response respuesta) {
    // Detecta que la API no aceptó la sesión, por ejemplo porque venció el token.
    if (respuesta.statusCode == 401) {
      return 'Tu sesión venció. Cierra sesión e inicia nuevamente.';
    }
    // Detecta que la cuenta no tiene permiso para realizar esta operación.
    if (respuesta.statusCode == 403) {
      return 'Tu cuenta no tiene permisos de administrador.';
    }
    // Intenta completar la operación y deja preparado el manejo de posibles errores.
    try {
      // Convierte la respuesta a datos de Dart y utiliza UTF-8 para conservar acentos y otros caracteres.
      final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
      // Comprueba que la API haya incluido un mensaje de texto en el campo detail.
      if (datos is Map && datos['detail'] is String) {
        // Recupera el mensaje enviado por la API.
        final mensaje = datos['detail'] as String;
        // Distingue el aviso genérico de una ruta que no se encontró en el servidor.
        if (mensaje == 'Not Found') {
          return 'No se encontró la ruta de eliminación en el backend.';
        }
        // Devuelve el mensaje específico que proporcionó la API.
        return mensaje;
      }
    // Si la respuesta no se pudo leer, utiliza el mensaje general que aparece después.
    } catch (_) {
    }
    return 'No se pudo eliminar el director '
        '(${respuesta.statusCode}).';
  }
  // Abre el formulario y espera su resultado para actualizar la lista al regresar.
  Future<void> _abrirFormulario({
    // Si recibe un director, abre la edición; si no recibe ninguno, abre un registro nuevo.
    Map<String, dynamic>? director,
  }) async {
    // Evita iniciar otra acción mientras está en curso una eliminación.
    if (_eliminando) return;
    // Abre el formulario y espera saber si confirmó un guardado.
    final guardado = await Navigator.of(context).push<bool>(
      // Prepara la pantalla que devolverá el resultado del formulario.
      MaterialPageRoute<bool>(
        // Construye el formulario de directores con los datos que necesita.
        builder: (context) => FormularioDirectorPage(
          // Pasa el token actual al formulario para que pueda consultar y guardar en la API.
          token: widget.token,
          // Comparte los datos del director que se editará, o null si será un registro nuevo.
          director: director,
        ),
      ),
    );
    // Comprueba que la pantalla siga abierta antes de utilizarla después de una espera.
    if (!mounted) return;
    // Actualiza la lista consultando de nuevo la API.
    _recargar();
    // Muestra la confirmación solamente cuando el formulario informó que guardó los datos.
    if (guardado == true) {
      // Muestra el aviso correspondiente sin cerrar la pantalla.
      _mostrarMensaje('Director guardado correctamente.');
    }
  }
  // Confirma la decisión de la persona antes de solicitar que se elimine el director.
  Future<void> _eliminarDirector(
    Map<String, dynamic> director,
  ) async {
    // Evita iniciar otra acción mientras está en curso una eliminación.
    if (_eliminando) return;
    // Intenta obtener el identificador como número; devuelve null si el dato no es válido.
    final id = int.tryParse('${director['id_director']}');
    // No permite enviar una eliminación con un identificador vacío o incorrecto.
    if (id == null || id <= 0) {
      // Muestra el aviso correspondiente sin cerrar la pantalla.
      _mostrarMensaje('El director seleccionado no es válido.');
      // Termina esta operación para no continuar con datos o condiciones incorrectas.
      return;
    }
    // Obtiene el nombre para mostrarlo en la confirmación; usa un texto de respaldo si falta.
    final nombre = (director['nombre'] ?? 'este director').toString();
    // Abre la pregunta de confirmación y espera la respuesta.
    final confirmar = await showDialog<bool>(
      // Utiliza la pantalla actual como referencia para mostrar el aviso.
      context: context,
      // Construye el diálogo o el contenido según la información disponible.
      builder: (context) => AlertDialog(
        // Define el título de la barra o del aviso.
        title: const Text('Eliminar director'),
        // Muestra la pregunta o explicación del mensaje.
        content: Text(
          '¿Deseas eliminar a $nombre?\n\n'
          'Sus reseñas se conservarán y quedarán sin director asignado.',
        ),
        // Coloca los botones disponibles para responder al aviso.
        actions: [
          TextButton(
            // Define la acción del botón; null lo desactiva durante la eliminación.
            onPressed: () {
              // Cierra el aviso e indica que se canceló la eliminación.
              Navigator.of(context).pop(false);
            },
            // Define el contenido que se coloca dentro de este componente.
            child: const Text('Cancelar'),
          ),
          FilledButton(
            // Define la acción del botón; null lo desactiva durante la eliminación.
            onPressed: () {
              // Cierra el aviso e indica que se confirmó la eliminación.
              Navigator.of(context).pop(true);
            },
            // Define el contenido que se coloca dentro de este componente.
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    // Continúa únicamente si la pantalla sigue abierta, se confirmó la decisión y no hay otra eliminación.
    if (!mounted || confirmar != true || _eliminando) {
      // Termina esta operación para no continuar con datos o condiciones incorrectas.
      return;
    }
    // Actualiza los datos del estado y pide a Flutter que refleje el cambio en pantalla.
    setState(() {
      // Bloquea temporalmente las acciones para evitar solicitudes repetidas.
      _eliminando = true;
      // Marca qué tarjeta debe mostrar el indicador de progreso.
      _idEliminando = id;
    });
    // Intenta completar la operación y deja preparado el manejo de posibles errores.
    try {
      // Espera la respuesta de la petición HTTP.
      final respuesta = await http
          // Envía a la API la solicitud de eliminación.
          .delete(
            // Incluye el identificador del director seleccionado en la dirección.
            Uri.parse('$_servidor/api/admin/directores/$id'),
            // Incluye los datos de autorización que acompañan la solicitud.
            headers: {
              // Envía el token de sesión para que la API compruebe la cuenta y sus permisos.
              'Authorization': 'Bearer ${widget.token}',
            },
          )
          // Limita la espera a 20 segundos para evitar que la operación quede esperando indefinidamente.
          .timeout(const Duration(seconds: 20));
      // Comprueba que la pantalla siga abierta antes de utilizarla después de una espera.
      if (!mounted) return;
      // Si no se recibió la confirmación esperada, muestra un error en lugar de utilizar los datos.
      if (respuesta.statusCode != 200) {
        // Muestra la explicación del error que devolvió la API.
        _mostrarMensaje(_mensajeError(respuesta));
        // Actualiza la lista si el servidor indica que no encontró el recurso solicitado.
        if (respuesta.statusCode == 404) {
          // Actualiza la lista consultando de nuevo la API.
          _recargar();
        }
        // Termina esta operación para no continuar con datos o condiciones incorrectas.
        return;
      }
      // Actualiza la lista consultando de nuevo la API.
      _recargar();
      // Muestra el aviso correspondiente sin cerrar la pantalla.
      _mostrarMensaje('Director eliminado correctamente.');
    // Si la respuesta no se pudo leer, utiliza el mensaje general que aparece después.
    } catch (_) {
      // Muestra el aviso correspondiente sin cerrar la pantalla.
      _mostrarMensaje(
        'No se pudo confirmar la eliminación. '
        'Actualiza la lista para comprobarlo.',
      );
    // Libera los indicadores al terminar, tanto si se pudo eliminar como si ocurrió un error.
    } finally {
      // Comprueba que la pantalla siga disponible antes de cambiar su estado.
      if (mounted) {
        // Actualiza los datos del estado y pide a Flutter que refleje el cambio en pantalla.
        setState(() {
          // Permite volver a utilizar los botones.
          _eliminando = false;
          // Retira la marca de la tarjeta que se estaba eliminando.
          _idEliminando = null;
        });
      }
    }
  }
  // Construye la dirección de la fotografía usando el nombre que devuelve la API.
  String _urlFoto(Map<String, dynamic> director) {
    // Lee el nombre de la imagen y elimina espacios que puedan sobrar.
    final foto = (director['foto'] ?? '').toString().trim();
    // Parte de la dirección del servidor y agrega la ruta de la fotografía.
    return Uri.parse(_servidor).replace(
      // Construye la ruta por partes para que Uri se encargue de los caracteres especiales.
      pathSegments: [
        'portadas',
        // Utiliza la imagen de respaldo si no se recibió un nombre de fotografía.
        foto.isEmpty ? 'default_director.jpg' : foto,
      ],
    ).toString();
  }
  // Construye la tarjeta con la fotografía, el nombre y los botones del director.
  Widget _tarjetaDirector(Map<String, dynamic> director) {
    // Obtiene los colores del tema de Cruppis para aplicarlos a los botones.
    final esquema = Theme.of(context).colorScheme;
    // Comprueba si esta tarjeta corresponde al director que se está eliminando.
    final eliminandoEste =
        // Convierte el identificador a texto para comparar ambos valores del mismo modo.
        _idEliminando?.toString() ==
        // Lo compara con el identificador del director que aparece en esta tarjeta.
        director['id_director'].toString();
    return Card(
      // Define el contenido que se coloca dentro de este componente.
      child: Padding(
        // Deja espacio interior para que el contenido no quede pegado a los bordes.
        padding: const EdgeInsets.all(16),
        // Define el contenido que se coloca dentro de este componente.
        child: Column(
          // Extiende el contenido al ancho disponible dentro de la columna.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // Organiza los elementos que se mostrarán dentro de este grupo.
          children: [
            Row(
              // Organiza los elementos que se mostrarán dentro de este grupo.
              children: [
                ClipRRect(
                  // Redondea las esquinas del componente.
                  borderRadius: BorderRadius.circular(12),
                  // Define el contenido que se coloca dentro de este componente.
                  child: Image.network(
                    _urlFoto(director),
                    // Define el ancho solicitado para este elemento.
                    width: 80,
                    // Define la altura solicitada para este elemento.
                    height: 80,
                    // Llena el espacio de la imagen manteniendo su proporción; puede recortar los bordes.
                    fit: BoxFit.cover,
                    // Muestra un icono de respaldo si la fotografía no se puede cargar.
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(
                        // Define el ancho solicitado para este elemento.
                        width: 80,
                        // Define la altura solicitada para este elemento.
                        height: 80,
                        // Define el contenido que se coloca dentro de este componente.
                        child: Icon(
                          Icons.person_outline,
                          // Define el tamaño del icono.
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  // Define el contenido que se coloca dentro de este componente.
                  child: Text(
                    // Muestra el nombre del director o un texto de respaldo si no está disponible.
                    '${director['nombre'] ?? 'Sin nombre'}',
                    // Aplica los colores, tamaños o forma que corresponden a este elemento.
                    style: const TextStyle(
                      // Define el tamaño del texto.
                      fontSize: 18,
                      // Destaca el texto en negritas.
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              // Deja espacio horizontal entre los botones.
              spacing: 12,
              // Separa los botones cuando necesitan acomodarse en otra línea.
              runSpacing: 8,
              // Organiza los elementos que se mostrarán dentro de este grupo.
              children: [
                OutlinedButton.icon(
                  // Define la acción del botón; null lo desactiva durante la eliminación.
                  onPressed: _eliminando
                      ? null
                      : () {
                          // Abre la edición con los datos del director de esta tarjeta.
                          _abrirFormulario(director: director);
                        },
                  // Aplica los colores, tamaños o forma que corresponden a este elemento.
                  style: OutlinedButton.styleFrom(
                    // Aplica el color del texto y del icono del botón.
                    foregroundColor: esquema.secondary,
                    // Solicita un tamaño mínimo que facilite pulsar el botón.
                    minimumSize: const Size(48, 48),
                    // Deja espacio interior para que el contenido no quede pegado a los bordes.
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    // Define el color del borde del botón.
                    side: BorderSide(color: esquema.primary),
                    // Aplica la forma con esquinas redondeadas.
                    shape: RoundedRectangleBorder(
                      // Redondea las esquinas del componente.
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // Define el icono que representa la acción.
                  icon: const Icon(
                    Icons.edit_outlined,
                    // Define el tamaño del icono.
                    size: 18,
                  ),
                  // Muestra el texto del botón.
                  label: const Text('Editar'),
                ),
                OutlinedButton.icon(
                  // Define la acción del botón; null lo desactiva durante la eliminación.
                  onPressed: _eliminando
                      ? null
                      : () {
                          // Inicia la confirmación de eliminación de este director.
                          _eliminarDirector(director);
                        },
                  // Aplica los colores, tamaños o forma que corresponden a este elemento.
                  style: OutlinedButton.styleFrom(
                    // Aplica el color del texto y del icono del botón.
                    foregroundColor: esquema.error,
                    // Solicita un tamaño mínimo que facilite pulsar el botón.
                    minimumSize: const Size(48, 48),
                    // Deja espacio interior para que el contenido no quede pegado a los bordes.
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    // Define el color del borde del botón.
                    side: BorderSide(color: esquema.primary),
                    // Aplica la forma con esquinas redondeadas.
                    shape: RoundedRectangleBorder(
                      // Redondea las esquinas del componente.
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // Muestra progreso en la tarjeta que se está eliminando y un icono normal en las demás.
                  icon: eliminandoEste
                      ? SizedBox(
                          // Define el ancho solicitado para este elemento.
                          width: 18,
                          // Define la altura solicitada para este elemento.
                          height: 18,
                          // Define el contenido que se coloca dentro de este componente.
                          child: CircularProgressIndicator(
                            // Ajusta el grosor del indicador de progreso.
                            strokeWidth: 2,
                            // Aplica el color indicado a este elemento.
                            color: esquema.error,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline,
                          // Define el tamaño del icono.
                          size: 18,
                        ),
                  // Muestra el texto del botón.
                  label: Text(
                    // Cambia el texto del botón mientras la API responde.
                    eliminandoEste ? 'Eliminando...' : 'Eliminar',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  @override
  // Construye la pantalla a partir del estado actual de la consulta.
  Widget build(BuildContext context) {
    return Scaffold(
      // Coloca el título y el botón de actualización en la parte superior.
      appBar: AppBar(
        // Define el título de la barra o del aviso.
        title: const Text('Directores de cine'),
        // Coloca los botones disponibles para responder al aviso.
        actions: [
          IconButton(
            // Define la acción del botón; null lo desactiva durante la eliminación.
            onPressed: _eliminando ? null : _recargar,
            // Explica la acción del icono y ayuda a identificarlo.
            tooltip: 'Actualizar directores',
            // Solicita un área mínima para que sea más fácil pulsar el botón.
            constraints: const BoxConstraints(
              // Establece el ancho mínimo del área del botón.
              minWidth: 48,
              // Establece la altura mínima del área del botón.
              minHeight: 48,
            ),
            // Define el icono que representa la acción.
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // Coloca el acceso para registrar un director nuevo.
      floatingActionButton: FloatingActionButton.extended(
        // Define la acción del botón; null lo desactiva durante la eliminación.
        onPressed: _eliminando
            ? null
            : () {
                // Abre un formulario vacío para registrar un director nuevo.
                _abrirFormulario();
              },
        // Define el icono que representa la acción.
        icon: const Icon(Icons.add),
        // Muestra el texto del botón.
        label: const Text('Nuevo director'),
      ),
      // Muestra el contenido principal según avance o termine la consulta.
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Observa la consulta guardada para mostrar su resultado.
        future: _directores,
        // Construye el diálogo o el contenido según la información disponible.
        builder: (context, snapshot) {
          // Mientras llega la respuesta, muestra el indicador de carga.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              // Define el contenido que se coloca dentro de este componente.
              child: CircularProgressIndicator(),
            );
          }
          // Si la consulta falló, muestra el error y un botón para reintentar.
          if (snapshot.hasError) {
            return Center(
              // Define el contenido que se coloca dentro de este componente.
              child: SingleChildScrollView(
                // Deja espacio interior para que el contenido no quede pegado a los bordes.
                padding: const EdgeInsets.all(24),
                // Define el contenido que se coloca dentro de este componente.
                child: Column(
                  // Hace que el grupo ocupe solo la altura que necesita.
                  mainAxisSize: MainAxisSize.min,
                  // Organiza los elementos que se mostrarán dentro de este grupo.
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      // Define el tamaño del icono.
                      size: 48,
                      // Aplica el color indicado a este elemento.
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      // Presenta la explicación del fallo de la consulta.
                      '${snapshot.error}',
                      // Centra el texto dentro de su espacio.
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      // Define la acción del botón; null lo desactiva durante la eliminación.
                      onPressed: _recargar,
                      // Aplica los colores, tamaños o forma que corresponden a este elemento.
                      style: FilledButton.styleFrom(
                        // Solicita un tamaño mínimo que facilite pulsar el botón.
                        minimumSize: const Size(48, 48),
                      ),
                      // Define el contenido que se coloca dentro de este componente.
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }
          // Utiliza los directores recibidos o una lista vacía si no hay resultados.
          final directores = snapshot.data ?? [];
          // Muestra un aviso y explica cómo agregar el primer director.
          if (directores.isEmpty) {
            return const Center(
              // Define el contenido que se coloca dentro de este componente.
              child: Padding(
                // Deja espacio interior para que el contenido no quede pegado a los bordes.
                padding: EdgeInsets.all(24),
                // Define el contenido que se coloca dentro de este componente.
                child: Text(
                  'Todavía no hay directores registrados.\n'
                  'Pulsa “Nuevo director” para agregar uno.',
                  // Centra el texto dentro de su espacio.
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // Construye la lista con una separación entre las tarjetas.
          return ListView.separated(
            // Deja espacio interior para que el contenido no quede pegado a los bordes.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            // Indica cuántas tarjetas necesita la lista.
            itemCount: directores.length,
            // Coloca una separación entre un director y el siguiente.
            separatorBuilder: (context, index) {
              return const SizedBox(height: 12);
            },
            // Construye cada tarjeta a medida que la lista la necesita.
            itemBuilder: (context, index) {
              // Utiliza los datos de esta posición para construir la tarjeta correspondiente.
              return _tarjetaDirector(directores[index]);
            },
          );
        },
      ),
    );
  }
}
