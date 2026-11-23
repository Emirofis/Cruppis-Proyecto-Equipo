// CRUPPIS — Moderación de comentarios.
// GET consulta los registros y DELETE solicita eliminar el comentario elegido.
// La API verifica el token y los permisos antes de permitir una eliminación.
// StatefulWidget permite cambios en la pantalla; State conserva sus datos e indicadores.
// Future representa un resultado pendiente; async y await esperan sin bloquear la interfaz.
// List reúne registros; Map guarda campos por nombre y dynamic permite distintos tipos de valores.
// final impide reasignar una variable; late permite prepararla antes de utilizarla.
// null representa ausencia de valor; ?? usa la alternativa indicada si el dato es nulo.
// Los mensajes de lista vacía o datos no disponibles describen un estado real, no son datos de prueba.

// Permite interpretar las respuestas JSON que devuelve la API.
import 'dart:convert';
import 'package:flutter/material.dart';
// Permite consultar los comentarios y solicitar su eliminación.
import 'package:http/http.dart' as http;
// Pantalla donde el administrador revisa los comentarios
// y puede eliminar aquellos que considere inapropiados.
class ModeracionPage extends StatefulWidget {
  // El constructor recibe la sesión de quien abre esta pantalla.
  const ModeracionPage({
    // key ayuda a Flutter a identificar este widget dentro de la interfaz.
    super.key,
    // required exige proporcionar el token al abrir el módulo.
    required this.token,
  });
  // Recibe el token de la cuenta que inició sesión.
  // La API lo utiliza para comprobar los permisos administrativos.
  final String token;
  @override
  // createState crea el objeto encargado de los cambios de esta pantalla.
  State<ModeracionPage> createState() => _ModeracionPageState();
}
// El prefijo _ mantiene este nombre privado dentro de la biblioteca de este archivo.
class _ModeracionPageState extends State<ModeracionPage> {
  // Dirección del backend que se ejecuta en la computadora.
  // Debe actualizarse si cambia la dirección IPv4.
  static const String _servidor = 'http://10.13.40.223:8000';
  // Guarda la consulta que traerá la lista de comentarios.
  late Future<List<Map<String, dynamic>>> _comentarios;
  // Evita iniciar otra eliminación mientras la API responde.
  bool _eliminando = false;
  @override
  // initState se ejecuta una vez cuando se prepara el estado de la pantalla.
  void initState() {
    // Ejecuta primero la preparación de la clase de Flutter.
    super.initState();
    // Consulta los comentarios al abrir la pantalla.
    _comentarios = _consultarComentarios();
  }
  // Solicita a la API los comentarios disponibles para moderar.
  Future<List<Map<String, dynamic>>> _consultarComentarios() async {
    // http.get envía la consulta y await espera su respuesta.
    final respuesta = await http.get(
      // Uri.parse interpreta la dirección de la consulta administrativa.
      Uri.parse('$_servidor/api/admin/comentarios'),
      headers: {
        // Envía el token para que la API compruebe la sesión.
        // Bearer es el tipo de credencial; el token identifica la sesión ante el backend.
        'Authorization': 'Bearer ${widget.token}',
      },
    // timeout limita la espera de la respuesta a 20 segundos.
    ).timeout(const Duration(seconds: 20));
    // Informa cuando la sesión ya no es válida.
    if (respuesta.statusCode == 401) {
      throw Exception(
        'La sesión venció. Cierra sesión e inicia nuevamente.',
      );
    }
    // Impide continuar si la cuenta no tiene los permisos necesarios.
    if (respuesta.statusCode == 403) {
      throw Exception(
        'Tu cuenta no tiene permisos de administrador.',
      );
    }
    // No intenta utilizar como lista una respuesta que indique un error.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar los comentarios '
        '(${respuesta.statusCode}).',
      );
    }
    // Convierte la respuesta a datos de Dart.
    // UTF-8 permite conservar acentos, emojis y otros caracteres.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la respuesta tenga la estructura esperada.
    // is! significa que el valor no pertenece al tipo indicado.
    if (datos is! List) {
      throw const FormatException('Respuesta inválida.');
    }
    // Organiza cada comentario como un mapa de campos y valores.
    return datos
        // map convierte cada registro y toList reúne los resultados.
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        .toList();
  }
  // Inicia una nueva consulta para mostrar la información actualizada.
  void _recargar() {
    // setState cambia los datos y pide a Flutter actualizar la interfaz.
    setState(() {
      _comentarios = _consultarComentarios();
    });
  }
  // Pide confirmación antes de eliminar el comentario seleccionado.
  Future<void> _eliminarComentario(
    Map<String, dynamic> comentario,
  ) async {
    // No comienza otra eliminación si ya hay una en curso.
    if (_eliminando) return;
    // Espera la respuesta del administrador antes de enviar la solicitud.
    // bool permite recibir true al confirmar o false al cancelar.
    final confirmar = await showDialog<bool>(
      // context identifica la parte de la interfaz donde se presenta el diálogo.
      context: context,
      // builder construye el cuadro con su título, contenido y botones.
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        // Permite desplazar el contenido si el comentario es largo.
        content: SingleChildScrollView(
          child: Text(
            '¿Eliminar el comentario de '
            '${comentario['usuario']} en '
            '“${comentario['publicacion']}”?\n\n'
            '${comentario['contenido']}\n\n'
            'Esta acción no se puede deshacer.',
          ),
        ),
        actions: [
          TextButton(
            // Cierra el aviso sin autorizar la eliminación.
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            // Confirma que se desea eliminar el comentario.
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    // Continúa solo si la pantalla sigue abierta y se confirmó la acción.
    // mounted comprueba que la pantalla siga activa; || significa «o».
    if (!mounted || confirmar != true) return;
    // Desactiva los botones y muestra el indicador de progreso.
    setState(() {
      _eliminando = true;
    });
    // Guarda el mensaje que se mostrará al terminar.
    String mensaje;
    // try intenta completar la solicitud; catch atiende el error si no se consigue.
    try {
      // Envía el identificador del comentario que se quiere eliminar.
      final respuesta = await http.delete(
        Uri.parse(
          '$_servidor/api/admin/comentarios/'
          '${comentario['id_comentario']}',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      // Vencer este plazo no demuestra que el servidor haya cancelado la eliminación.
      ).timeout(const Duration(seconds: 20));
      // Prepara una explicación según la respuesta de la API.
      if (respuesta.statusCode == 200) {
        mensaje = 'Comentario eliminado correctamente.';
      } else if (respuesta.statusCode == 404) {
        mensaje = 'El comentario ya no existe.';
      } else if (respuesta.statusCode == 401) {
        mensaje = 'La sesión venció. Inicia sesión nuevamente.';
      } else if (respuesta.statusCode == 403) {
        mensaje = 'Tu cuenta no tiene permisos de administrador.';
      } else {
        mensaje = 'No se pudo eliminar el comentario '
            '(${respuesta.statusCode}).';
      }
    // _ indica que no necesitamos leer el objeto de la excepción.
    } catch (_) {
      // Si se pierde la conexión, no se puede asegurar
      // si el servidor alcanzó a completar la eliminación.
      mensaje = 'No se pudo confirmar la eliminación. '
          'Revisa la lista antes de intentar nuevamente.';
    }
    // Evita actualizar una pantalla que ya se cerró.
    if (!mounted) return;
    setState(() {
      _eliminando = false;
    });
    // Consulta nuevamente para comprobar qué comentarios siguen registrados.
    _recargar();
    // Muestra el resultado de la operación.
    // SnackBar es un aviso temporal; ScaffoldMessenger lo muestra en la pantalla.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
  // Construye la tarjeta con el autor, la reseña y el comentario.
  Widget _tarjetaComentario(Map<String, dynamic> comentario) {
    // Card crea la tarjeta; Padding deja espacio alrededor de su contenido.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        // Column acomoda sus elementos uno debajo de otro.
        child: Column(
          // start alinea los elementos al inicio horizontal de la columna.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destaca el nombre de quien escribió el comentario.
            Text(
              // Si falta el nombre, se identifica de forma general; no se crea una cuenta.
              '${comentario['usuario'] ?? 'Usuario'}',
              style: const TextStyle(
                // Conserva el color que ya utiliza este módulo para resaltar al autor.
                color: Colors.deepOrangeAccent,
                // Tamaño del texto en unidades lógicas de Flutter.
                fontSize: 18,
                // bold aplica negrita al nombre.
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Indica a qué reseña pertenece el comentario.
            Text(
              'Reseña: ${comentario['publicacion'] ?? 'Sin información'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Separa los datos del autor del contenido.
            const Divider(height: 24),
            Text(
              '${comentario['contenido'] ?? ''}',
              style: const TextStyle(
                fontSize: 16,
                // Ajusta la altura de cada línea respecto al tamaño de la letra.
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              // Bloquea las eliminaciones mientras se procesa una solicitud.
              // condición ? opción : otraOpción elige la acción; null desactiva el botón.
              onPressed: _eliminando
                  ? null
                  : () {
                      _eliminarComentario(comentario);
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                // Solicita un área mínima que facilite tocar el botón.
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar comentario'),
            ),
          ],
        ),
      ),
    );
  }
  @override
  // build describe cómo se presenta la pantalla con el estado actual.
  Widget build(BuildContext context) {
    // Scaffold organiza la barra superior y el contenido principal.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderación de comentarios'),
        actions: [
          // Permite consultar nuevamente los comentarios.
          IconButton(
            tooltip: 'Actualizar comentarios',
            onPressed: _eliminando ? null : _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Aparece únicamente mientras se elimina un comentario.
          if (_eliminando) const LinearProgressIndicator(),
          // La lista utiliza el espacio restante de la pantalla.
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // FutureBuilder observa la consulta; snapshot reúne su estado y resultado.
              future: _comentarios,
              builder: (context, snapshot) {
                // Muestra la carga mientras espera los datos.
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                // Si la consulta falla, muestra el motivo
                // y permite volver a intentarlo.
                if (snapshot.hasError) {
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _recargar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Utiliza una lista vacía si no se recibieron comentarios.
                final comentarios = snapshot.data ?? [];
                if (comentarios.isEmpty) {
                  return const Center(
                    child: Text('No hay comentarios para moderar.'),
                  );
                }
                // Construye las tarjetas con una separación entre ellas.
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  // length indica cuántas tarjetas necesita la lista.
                  itemCount: comentarios.length,
                  // Construye el espacio que separa una tarjeta de la siguiente.
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  // Construye cada tarjeta cuando la lista necesita mostrarla.
                  itemBuilder: (context, index) {
                    return _tarjetaComentario(comentarios[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
