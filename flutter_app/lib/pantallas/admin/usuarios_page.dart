// Permite interpretar las respuestas JSON de la API.
import 'dart:convert';

import 'package:flutter/material.dart';

// Permite consultar las cuentas y solicitar su eliminación.
import 'package:http/http.dart' as http;

// Pantalla donde el administrador consulta los usuarios
// y puede solicitar la eliminación de cuentas de lectores.
class UsuariosPage extends StatefulWidget {
  const UsuariosPage({
    super.key,
    required this.token,
  });

  // Recibe el token de la sesión para las consultas administrativas.
  final String token;

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  // Dirección de la API que se ejecuta en la computadora.
  // Debe actualizarse si cambia su dirección IPv4.
  static const String _servidor = 'http://192.168.1.65:8000';

  // Guarda la consulta que traerá los usuarios registrados.
  late Future<List<Map<String, dynamic>>> _usuarios;

  // Evita realizar varias eliminaciones al mismo tiempo.
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();

    // Consulta los usuarios cuando se abre esta pantalla.
    _usuarios = _consultarUsuarios();
  }

  // Solicita las cuentas que la API permite consultar al administrador.
  Future<List<Map<String, dynamic>>> _consultarUsuarios() async {
    final respuesta = await http.get(
      Uri.parse('$_servidor/api/admin/usuarios'),
      headers: {
        // La API comprueba el token y los permisos de la cuenta.
        'Authorization': 'Bearer ${widget.token}',
      },
    ).timeout(const Duration(seconds: 20));

    // Informa cuando la sesión ya no es válida.
    if (respuesta.statusCode == 401) {
      throw Exception(
        'La sesión venció. Inicia sesión nuevamente.',
      );
    }

    // Informa cuando la cuenta no tiene permiso para consultar usuarios.
    if (respuesta.statusCode == 403) {
      throw Exception(
        'Tu cuenta no tiene permisos de administrador.',
      );
    }

    // No utiliza como datos una respuesta que indique un error.
    if (respuesta.statusCode != 200) {
      throw Exception(
        'No se pudieron consultar los usuarios '
        '(${respuesta.statusCode}).',
      );
    }

    // Lee la respuesta conservando acentos y otros caracteres.
    final datos = jsonDecode(utf8.decode(respuesta.bodyBytes));

    // Comprueba que la API haya devuelto una lista.
    if (datos is! List) {
      throw const FormatException('Respuesta inválida.');
    }

    // Convierte cada cuenta en un mapa con sus campos y valores.
    return datos
        .map((elemento) => Map<String, dynamic>.from(elemento as Map))
        .toList();
  }

  // Vuelve a consultar las cuentas para mostrar los cambios recientes.
  void _recargar() {
    setState(() {
      _usuarios = _consultarUsuarios();
    });
  }

  // Revisa la cuenta seleccionada y pide confirmación antes de eliminarla.
  Future<void> _eliminarUsuario(Map<String, dynamic> usuario) async {
    // No permite eliminar al administrador original ni cuentas
    // con un rol diferente de Lector.
    // La API también comprueba estas restricciones.
    if (_eliminando ||
        usuario['id_usuario'].toString() == '1' ||
        usuario['rol'] != 'Lector') {
      return;
    }

    // Muestra el nombre y el correo para confirmar
    // que se eligió la cuenta correcta.
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lector'),
        content: Text(
          '¿Eliminar la cuenta de ${usuario['nombre']}?\n\n'
          '${usuario['correo']}\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            // Cierra el aviso sin autorizar la eliminación.
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            // Confirma que se desea eliminar la cuenta.
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    // Continúa solo si se confirmó y la pantalla sigue abierta.
    if (!mounted || confirmar != true) return;

    // Desactiva los botones mientras la API procesa la solicitud.
    setState(() {
      _eliminando = true;
    });

    // Guarda la explicación que se mostrará al terminar.
    String mensaje;

    try {
      // Envía el identificador de la cuenta seleccionada.
      final respuesta = await http.delete(
        Uri.parse(
          '$_servidor/api/admin/usuarios/${usuario['id_usuario']}',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      ).timeout(const Duration(seconds: 20));

      if (respuesta.statusCode == 200) {
        mensaje = 'Usuario eliminado correctamente.';
      } else if (respuesta.statusCode == 401) {
        mensaje = 'La sesión venció. Inicia sesión nuevamente.';
      } else {
        mensaje = 'No se pudo eliminar el usuario '
            '(${respuesta.statusCode}).';

        // Recupera la explicación de la API, por ejemplo,
        // cuando no permite eliminar una cuenta con comentarios.
        try {
          final datos = jsonDecode(
            utf8.decode(respuesta.bodyBytes),
          );

          if (datos is Map && datos['detail'] is String) {
            mensaje = datos['detail'] as String;
          }
        } catch (_) {
          // Si la respuesta no se puede interpretar,
          // conserva el mensaje general.
        }
      }
    } catch (_) {
      // Una falla de conexión no permite asegurar
      // si el servidor alcanzó a eliminar la cuenta.
      mensaje = 'No se pudo confirmar la eliminación. '
          'Revisa la lista antes de intentar nuevamente.';
    }

    // Evita actualizar una pantalla que ya se cerró.
    if (!mounted) return;

    setState(() {
      _eliminando = false;
    });

    // Actualiza las cuentas para comprobar el resultado.
    _recargar();

    // Utiliza un diálogo para que los mensajes largos
    // puedan leerse sin desaparecer automáticamente.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gestión de usuarios'),
        content: SingleChildScrollView(
          child: Text(mensaje),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  // Construye una tarjeta con los datos y las acciones de cada cuenta.
  Widget _tarjetaUsuario(Map<String, dynamic> usuario) {
    // Identifica la cuenta del administrador original.
    final protegido = usuario['id_usuario'].toString() == '1';

    // Solo las cuentas de lectores muestran el botón de eliminación.
    final esLector = usuario['rol'] == 'Lector';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Muestra el nombre de la cuenta.
            Text(
              '${usuario['nombre'] ?? 'Sin nombre'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 8),

            Text('${usuario['correo'] ?? ''}'),

            const SizedBox(height: 8),

            // Permite reconocer el rol de la cuenta.
            Text(
              'Rol: ${usuario['rol']}',
              style: const TextStyle(
                color: Colors.deepOrangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // La cuenta protegida muestra un aviso en lugar de un botón.
            if (protegido)
              const Row(
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Administrador único · Cuenta protegida',
                    ),
                  ),
                ],
              )
            else if (esLector)
              OutlinedButton.icon(
                // Desactiva la acción mientras hay una eliminación en curso.
                onPressed: _eliminando
                    ? null
                    : () {
                        _eliminarUsuario(usuario);
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  minimumSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.person_remove_outlined),
                label: const Text('Eliminar lector'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de usuarios'),
        actions: [
          // Permite consultar nuevamente las cuentas.
          IconButton(
            tooltip: 'Actualizar usuarios',
            onPressed: _eliminando ? null : _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Column(
        children: [
          // Aparece mientras se procesa una eliminación.
          if (_eliminando) const LinearProgressIndicator(),

          // La lista ocupa el espacio restante de la pantalla.
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _usuarios,
              builder: (context, snapshot) {
                // Muestra un indicador mientras llegan los datos.
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

                // Utiliza una lista vacía si no se recibieron cuentas.
                final usuarios = snapshot.data ?? [];

                if (usuarios.isEmpty) {
                  return const Center(
                    child: Text('No hay usuarios registrados.'),
                  );
                }

                // Construye una tarjeta por cuenta
                // y deja una separación entre ellas.
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: usuarios.length,
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemBuilder: (context, index) {
                    return _tarjetaUsuario(usuarios[index]);
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