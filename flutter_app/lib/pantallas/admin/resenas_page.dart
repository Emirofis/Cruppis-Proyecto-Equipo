// CRUPPIS — Administración de reseñas.
// StatefulWidget permite que cambie el contenido; State conserva los datos de la pantalla.
// final impide reasignar una propiedad; const define un valor constante.
// El signo ? permite null, que significa ausencia de valor.
// JSON es el formato de respuesta de la API y UTF-8 conserva acentos y otros caracteres.
// Este archivo consulta, abre el formulario y elimina reseñas; no decide cuál ocupa el banner.

// Permite interpretar las respuestas JSON que envía la API.
import 'dart:convert';
// Incluye widgets, formularios, navegación y estilos de Material.
import 'package:flutter/material.dart';
// Permite consultar las reseñas y solicitar su eliminación.
import 'package:http/http.dart' as http;
// Formulario que se utiliza para publicar o editar una reseña.
import 'formulario_resena_page.dart';
// Muestra las reseñas que puede gestionar el administrador.
class ResenasPage extends StatefulWidget {
  // El constructor recibe los datos necesarios para abrir la pantalla.
  const ResenasPage({
    // key ayuda a Flutter a identificar este widget dentro de la interfaz.
    super.key,
    // required obliga a proporcionar el token al abrir este módulo.
    required this.token,
  });
  // Recibe el token de la sesión para realizar
  // las consultas protegidas de la API.
  final String token;
  @override
  // createState crea el objeto que conservará los datos y cambios de la pantalla.
  State<ResenasPage> createState() => _ResenasPageState();
}
class _ResenasPageState extends State<ResenasPage> {
  // Dirección del backend que se ejecuta en la computadora.
  // Debe actualizarse si cambia su dirección IPv4.
  static const _servidor = 'http://10.13.40.223:8000';
  // Guarda la consulta que traerá las reseñas.
  // late indica que se asignará antes de usarla; Future representa un resultado pendiente.
  // List reúne las reseñas y Map permite consultar sus campos por nombre.
  late Future<List<Map<String, dynamic>>> _resenas;
  // Evita realizar otras acciones mientras se elimina una reseña.
  bool _eliminando = false;
  @override
  // initState prepara el estado una sola vez al crear la pantalla.
  void initState() {
    // Ejecuta primero la preparación de la clase de Flutter.
    super.initState();
    // Consulta las reseñas cuando se abre la pantalla.
    _resenas = _consultar();
  }
  // Solicita a la API las reseñas del catálogo administrativo.
  Future<List<Map<String, dynamic>>> _consultar() async {
    // async y await permiten esperar la respuesta sin bloquear la interfaz.
    // GET consulta datos; Uri.parse interpreta la dirección del backend.
    final respuesta = await http.get(
      Uri.parse('$_servidor/api/admin/resenas'),
      headers: {
        // La API revisa este token antes de permitir la consulta.
        // Bearer es el tipo de credencial; la API valida el token y los permisos.
        'Authorization': 'Bearer ${widget.token}',
      },
    // timeout limita a 20 segundos la espera de la consulta.
    ).timeout(const Duration(seconds: 20));
    // Informa cuando la sesión ya no es válida.
    if (respuesta.statusCode == 401) {
      throw Exception(
        'La sesión venció. Inicia sesión nuevamente.',
      );
    }
    // Si la consulta falla, no intenta utilizar la respuesta como datos.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar las reseñas '
        '(${respuesta.statusCode}).',
      );
    }
    // Lee el JSON conservando los acentos y otros caracteres.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));
    // Comprueba que la API haya devuelto una lista.
    // is! comprueba que el valor no sea del tipo indicado.
    if (datos is! List) {
      throw const FormatException('Respuesta inválida.');
    }
    // Organiza cada reseña como un mapa de campos y valores.
    return datos
        // map convierte cada registro y toList reúne todos los resultados.
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        .toList();
  }
  // Vuelve a consultar las reseñas para mostrar los cambios recientes.
  void _recargar() {
    // setState pide a Flutter reconstruir la interfaz con los datos actualizados.
    setState(() {
      _resenas = _consultar();
    });
  }
  // Abre el formulario para publicar o editar.
  // Si no recibe una reseña, el formulario comienza vacío.
  Future<void> _abrirFormulario({
    Map<String, dynamic>? resena,
  }) async {
    // Espera el resultado que devuelve el formulario al cerrarse.
    // Navigator abre otra pantalla. <bool> indica que puede devolver true o false.
    final guardado = await Navigator.of(context).push<bool>(
      // MaterialPageRoute prepara la navegación hacia el formulario.
      MaterialPageRoute<bool>(
        // builder construye la pantalla y le pasa la sesión y la reseña seleccionada.
        builder: (context) => FormularioResenaPage(
          token: widget.token,
          resena: resena,
        ),
      ),
    );
    // Evita utilizar la pantalla si se cerró durante la espera.
    // mounted confirma que el estado todavía pertenece a una pantalla activa.
    if (!mounted) return;
    // Actualiza la lista incluso si se regresó sin confirmar.
    _recargar();
    // El formulario devuelve true cuando la API confirma el guardado.
    if (guardado == true) {
      // SnackBar es un aviso temporal que aparece en la pantalla actual.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reseña guardada correctamente.'),
        ),
      );
    }
  }
  // Solicita confirmación antes de eliminar una reseña.
  Future<void> _eliminar(Map<String, dynamic> resena) async {
    // No comienza otra eliminación mientras espera la respuesta anterior.
    if (_eliminando) return;
    // showDialog muestra la pregunta y espera la decisión del administrador.
    final confirmar = await showDialog<bool>(
      // context identifica la pantalla donde se abrirá el cuadro de confirmación.
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar reseña'),
        // Explica qué registro se eliminará y advierte
        // que también se perderán sus comentarios.
        content: Text(
          '¿Eliminar “${resena['titulo']}”? '
          'También se eliminarán sus comentarios. '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            // Cierra el aviso sin eliminar la reseña.
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            // Confirma la eliminación.
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    // Continúa únicamente si se confirmó y la pantalla sigue abierta.
    // || significa «o»; se cancela si la pantalla se cerró o no se confirmó.
    if (!mounted || confirmar != true) return;
    // Desactiva los botones mientras la API procesa la solicitud.
    setState(() {
      _eliminando = true;
    });
    // Guarda el mensaje que se mostrará al terminar.
    String mensaje;
    // try intenta ejecutar la solicitud; catch atiende una falla de conexión o de lectura.
    try {
      // Envía el identificador de la reseña que se quiere eliminar.
      final respuesta = await http.delete(
        Uri.parse(
          '$_servidor/api/admin/resenas/${resena['id_publicacion']}',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      // El plazo limita la espera, pero no demuestra que el servidor haya cancelado el borrado.
      ).timeout(const Duration(seconds: 20));
      if (respuesta.statusCode == 200) {
        mensaje = 'Reseña eliminada correctamente.';
      } else if (respuesta.statusCode == 401) {
        mensaje = 'La sesión venció. Inicia sesión nuevamente.';
      } else {
        mensaje = 'No se pudo eliminar (${respuesta.statusCode}).';
      }
    // _ indica que no se necesita leer el objeto de la excepción.
    } catch (_) {
      // Si falla la conexión, el servidor podría haber terminado
      // la eliminación aunque no se haya recibido su respuesta.
      mensaje = 'No se pudo confirmar la eliminación. '
          'Revisa la lista antes de intentar nuevamente.';
    }
    if (!mounted) return;
    // Permite utilizar nuevamente los botones.
    setState(() {
      _eliminando = false;
    });
    // Consulta la lista para comprobar qué reseñas siguen registradas.
    _recargar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
  @override
  // build describe la interfaz utilizando el estado actual.
  Widget build(BuildContext context) {
    // Scaffold organiza la barra superior, el contenido y el botón flotante.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseñas y publicaciones'),
        actions: [
          // Permite actualizar la lista de forma manual.
          IconButton(
            tooltip: 'Actualizar reseñas',
            // condición ? opción : otraOpción elige la acción; null desactiva el botón.
            onPressed: _eliminando ? null : _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // Abre el formulario sin datos para crear una reseña.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _eliminando
            ? null
            : () {
                _abrirFormulario();
              },
        icon: const Icon(Icons.add),
        label: const Text('Nueva reseña'),
      ),
      body: Column(
        children: [
          // Muestra el progreso mientras se elimina una reseña.
          if (_eliminando) const LinearProgressIndicator(),
          // Deja a la lista ocupar el espacio restante de la pantalla.
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              // FutureBuilder observa la consulta; snapshot contiene su estado, datos o error.
              future: _resenas,
              builder: (context, snapshot) {
                // Mientras espera los datos, muestra un indicador de carga.
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                          TextButton(
                            onPressed: _recargar,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // ?? utiliza una lista vacía si no hay datos; no agrega reseñas de ejemplo.
                final resenas = snapshot.data ?? [];
                // Informa cuando todavía no hay publicaciones.
                if (resenas.isEmpty) {
                  return const Center(
                    child: Text('Todavía no hay reseñas registradas.'),
                  );
                }
                // Construye una tarjeta por cada reseña recibida.
                return ListView.separated(
                  // El espacio inferior evita que el botón flotante
                  // tape las acciones de la última tarjeta.
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  // length indica cuántas tarjetas debe construir la lista.
                  itemCount: resenas.length,
                  // Crea el espacio entre una tarjeta y la siguiente.
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  // Construye cada tarjeta cuando la lista necesita mostrarla.
                  itemBuilder: (context, index) {
                    // Obtiene los datos de la reseña de esta posición.
                    final resena = resenas[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        // Column coloca los elementos en vertical; start los alinea al inicio.
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Muestra el título con el estilo de la aplicación.
                            Text(
                              '${resena['titulo']}',
                              // Toma el estilo de título definido en el tema de la aplicación.
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            // Indica si corresponde a una película o serie.
                            Text('${resena['tipo']}'),
                            const SizedBox(height: 8),
                            Text('Director: ${resena['director']}'),
                            const SizedBox(height: 16),
                            // Acomoda los botones en otra línea
                            // si no hay suficiente espacio horizontal.
                            Wrap(
                              // spacing separa los botones horizontalmente; runSpacing separa las filas.
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: _eliminando
                                      ? null
                                      : () {
                                          // Abre el formulario con los datos
                                          // de la reseña seleccionada.
                                          _abrirFormulario(resena: resena);
                                        },
                                  style: OutlinedButton.styleFrom(
                                    // Solicita un área mínima para facilitar tocar el botón.
                                    minimumSize: const Size(48, 48),
                                  ),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Editar'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _eliminando
                                      ? null
                                      : () {
                                          _eliminar(resena);
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                    minimumSize: const Size(48, 48),
                                  ),
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
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
