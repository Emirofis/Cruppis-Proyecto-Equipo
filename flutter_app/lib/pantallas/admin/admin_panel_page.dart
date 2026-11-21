// Importa los elementos que se usan para construir la pantalla.
import 'package:flutter/material.dart';

// Reúne los colores y estilos que comparte la aplicación.
import '../../estilos/spooky_tema.dart';

// Pantallas que se pueden abrir desde el panel.
import 'actores_page.dart';
import 'directores_page.dart';
import 'moderacion_page.dart';
import 'resenas_page.dart';
import 'usuarios_page.dart';

// Pantalla principal del administrador.
// Su estado cambia cuando comienza el cierre de sesión.
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({
    super.key,
    required this.usuario,
    required this.token,
  });

  // Recibe los datos del administrador que inició sesión.
  final Map<String, dynamic> usuario;

  // Las otras pantallas necesitan este token
  // para realizar las consultas protegidas de la API.
  final String token;

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  // Permite saber si ya comenzó el cierre de sesión
  // y evita que se sigan utilizando los botones.
  bool _cerrandoSesion = false;

  // Abre la pantalla del módulo seleccionado.
  void _abrir(Widget pantalla) {
    if (_cerrandoSesion) return;

    // El panel queda detrás de la nueva pantalla,
    // por lo que se puede regresar al terminar.
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => pantalla,
      ),
    );
  }

  void _cerrarSesion() {
    // Evita repetir el cierre si se pulsa varias veces el botón.
    if (_cerrandoSesion) return;

    // Actualiza los botones y permite salir del panel.
    setState(() {
      _cerrandoSesion = true;
    });

    // Espera a que la pantalla aplique el cambio anterior
    // antes de intentar regresar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Comprueba que la pantalla siga abierta.
      if (!mounted) return;

      // Regresa a main.dart, donde se controla
      // la limpieza de la sesión y el regreso al login.
      Navigator.of(context).pop();
    });
  }

  // Construye las tarjetas del panel con la misma distribución.
  // Cada módulo recibe su título, descripción, botón y acción.
  Widget _modulo({
    required String titulo,
    required String descripcion,
    required String boton,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: SpookyPanelEstilos.tarjeta,
      padding: SpookyPanelEstilos.margenTarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado del módulo.
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: SpookyPanelEstilos.tituloModulo,
          ),

          SpookyPanelEstilos.separacion,

          // Explica qué se puede administrar desde este módulo.
          Text(
            descripcion,
            textAlign: TextAlign.center,
            style: SpookyPanelEstilos.descripcion,
          ),

          SpookyPanelEstilos.separacion,

          // Añade el resplandor que acompaña a los botones del panel.
          DecoratedBox(
            decoration: SpookyPanelEstilos.resplandorBoton,
            child: FilledButton(
              // Desactiva el botón si se está cerrando la sesión.
              onPressed: _cerrandoSesion ? null : onPressed,
              style: SpookyPanelEstilos.boton,
              child: Text(
                boton,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Evita salir con el botón de regresar del teléfono.
      // La salida se habilita al presionar Cerrar sesión.
      canPop: _cerrandoSesion,
      child: Scaffold(
        appBar: AppBar(
          // El panel no muestra una flecha para volver.
          automaticallyImplyLeading: false,

          title: const Text(
            'Cruppis',
            style: SpookyPanelEstilos.logo,
          ),

          actions: [
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: _cerrandoSesion ? null : _cerrarSesion,

              // Mantiene un espacio suficiente para pulsar el icono.
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              icon: const Icon(Icons.logout),
            ),

            const SizedBox(width: SpookyTema.espacio),
          ],

          // Coloca la línea morada debajo del encabezado.
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(
              SpookyPanelEstilos.altoBorde,
            ),
            child: Container(
              height: SpookyPanelEstilos.altoBorde,
              decoration: SpookyPanelEstilos.bordeEncabezado,
            ),
          ),
        ),

        body: DecoratedBox(
          // Aplica el fondo que se utiliza en el panel.
          decoration: SpookyPanelEstilos.fondo,
          child: SizedBox.expand(
            // Permite recorrer todos los módulos aunque
            // no quepan completos en la pantalla del teléfono.
            child: SingleChildScrollView(
              padding: SpookyPanelEstilos.margen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tarjeta de bienvenida del administrador.
                  Container(
                    decoration: SpookyPanelEstilos.tarjeta,
                    padding: SpookyPanelEstilos.margenTarjeta,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PANEL DE CONTROL\nADMINISTRATIVO',
                          style: SpookyPanelEstilos.tituloPrincipal,
                        ),

                        SpookyPanelEstilos.separacionCorta,

                        // Combina el saludo y el nombre del usuario
                        // para destacar únicamente su nombre.
                        Text.rich(
                          TextSpan(
                            style: SpookyPanelEstilos.descripcion,
                            children: [
                              const TextSpan(text: 'Bienvenido, '),

                              TextSpan(
                                // Si no se recibe un nombre,
                                // utiliza Administrador como respaldo.
                                text:
                                    '${widget.usuario['nombre'] ?? 'Administrador'}.',
                                style: SpookyPanelEstilos.nombreUsuario,
                              ),

                              const TextSpan(
                                text: ' Desde aquí puedes gestionar '
                                    'el catálogo, usuarios y moderar el sitio.',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SpookyPanelEstilos.separacion,

                  // Acceso a la gestión de directores.
                  _modulo(
                    titulo: 'DIRECTORES DE CINE',
                    descripcion:
                        'Consulta, registro y actualización de directores '
                        'con nombre y fotografía.',
                    boton: 'GESTIONAR DIRECTORES',
                    onPressed: () {
                      // Comparte el token con la pantalla que se abre.
                      _abrir(
                        DirectoresPage(token: widget.token),
                      );
                    },
                  ),

                  SpookyPanelEstilos.separacion,

                  // Acceso a la gestión de actores.
                  _modulo(
                    titulo: 'ACTORES PROTAGONISTAS',
                    descripcion:
                        'Registro, consulta, edición y eliminación de '
                        'actores con nombre y fotografía.',
                    boton: 'GESTIONAR ACTORES',
                    onPressed: () {
                      _abrir(
                        ActoresPage(token: widget.token),
                      );
                    },
                  ),

                  SpookyPanelEstilos.separacion,

                  // Acceso al registro y mantenimiento de las reseñas.
                  _modulo(
                    titulo: 'RESEÑAS Y PUBLICACIONES',
                    descripcion:
                        'Registro, modificación y eliminación de reseñas '
                        'vinculadas a directores.',
                    boton: 'GESTIONAR RESEÑAS',
                    onPressed: () {
                      _abrir(
                        ResenasPage(token: widget.token),
                      );
                    },
                  ),

                  SpookyPanelEstilos.separacion,

                  // Acceso a la revisión de comentarios de los lectores.
                  _modulo(
                    titulo: 'MODERACIÓN DE COMENTARIOS',
                    descripcion:
                        'Revisión y eliminación de comentarios '
                        'inapropiados de la comunidad.',
                    boton: 'MODERAR COMENTARIOS',
                    onPressed: () {
                      _abrir(
                        ModeracionPage(token: widget.token),
                      );
                    },
                  ),

                  SpookyPanelEstilos.separacion,

                  // Acceso a la administración de cuentas de lectores.
                  // La API comprueba qué cuentas se pueden eliminar.
                  _modulo(
                    titulo: 'CONTROL DE USUARIOS',
                    descripcion:
                        'Consulta y eliminación de cuentas de lectores. '
                        'La cuenta del administrador está protegida.',
                    boton: 'GESTIONAR USUARIOS',
                    onPressed: () {
                      _abrir(
                        UsuariosPage(token: widget.token),
                      );
                    },
                  ),

                  // Deja espacio debajo de la última tarjeta.
                  SpookyPanelEstilos.separacion,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}