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
  // const permite crear el widget como constante cuando sus datos también lo permiten.
  const AdminPanelPage({
    // key ayuda a Flutter a identificar este widget dentro de la interfaz.
    super.key,
    // required obliga a proporcionar este dato al abrir el panel.
    required this.usuario,
    required this.token,
  });
  // Recibe los datos del administrador que inició sesión.
  // Map agrupa campos por nombre; dynamic permite distintos tipos de valores.
  // final impide reasignar esta propiedad después de construir el widget.
  final Map<String, dynamic> usuario;
  // Las otras pantallas necesitan este token
  // para realizar las consultas protegidas de la API.
  // El token es la credencial que la app envía para que el backend compruebe la sesión.
  final String token;
  @override
  // createState crea el objeto que guarda los cambios de esta pantalla.
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}
// State almacena el estado del panel; el prefijo _ hace privado el nombre dentro de este archivo.
class _AdminPanelPageState extends State<AdminPanelPage> {
  // Permite saber si ya comenzó el cierre de sesión
  // y evita que se sigan utilizando los botones.
  bool _cerrandoSesion = false;
  // Abre la pantalla del módulo seleccionado.
  // Widget representa una pieza de la interfaz; aquí es la pantalla que se va a abrir.
  void _abrir(Widget pantalla) {
    if (_cerrandoSesion) return;
    // El panel queda detrás de la nueva pantalla,
    // por lo que se puede regresar al terminar.
    // Navigator administra las pantallas abiertas; context indica dónde está este widget.
    // push agrega una pantalla y <void> indica que no se espera un resultado con datos.
    Navigator.of(context).push<void>(
      // MaterialPageRoute crea la navegación con la presentación de Material.
      MaterialPageRoute<void>(
        // builder devuelve la pantalla que se mostrará en esa ruta.
        builder: (context) => pantalla,
      ),
    );
  }
  void _cerrarSesion() {
    // Evita repetir el cierre si se pulsa varias veces el botón.
    if (_cerrandoSesion) return;
    // Actualiza los botones y permite salir del panel.
    // setState actualiza el indicador y pide a Flutter reconstruir la interfaz.
    setState(() {
      _cerrandoSesion = true;
    });
    // Espera a que la pantalla aplique el cambio anterior
    // antes de intentar regresar.
    // Un frame es una actualización de la pantalla; el callback se ejecuta después.
    // _ indica que no necesitamos utilizar el dato que recibe esta función.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Comprueba que la pantalla siga abierta.
      // mounted confirma que este estado todavía pertenece a una pantalla activa.
      if (!mounted) return;
      // Cierra esta ruta y vuelve a la pantalla que abrió el panel.
      // La eliminación del token y el regreso al login deben realizarse allí;
      // este pop por sí solo no borra la sesión.
      Navigator.of(context).pop();
    });
  }
  // Construye las tarjetas del panel con la misma distribución.
  // Cada módulo recibe su título, descripción, botón y acción.
  Widget _modulo({
    required String titulo,
    required String descripcion,
    required String boton,
    // VoidCallback es una función sin parámetros que no devuelve un valor.
    required VoidCallback onPressed,
  }) {
    // Container permite reunir fondo, márgenes interiores y contenido.
    return Container(
      // decoration aplica el fondo, el borde y las sombras de la tarjeta.
      decoration: SpookyPanelEstilos.tarjeta,
      // padding deja espacio entre el borde y los elementos interiores.
      padding: SpookyPanelEstilos.margenTarjeta,
      // Column coloca los elementos uno debajo de otro.
      child: Column(
        // stretch solicita que los elementos ocupen el ancho disponible.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // children reúne los elementos que se mostrarán dentro de la columna.
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
              // condición ? opción : otraOpción elige la acción; null desactiva el botón.
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
  // build describe cómo se ve la pantalla con el estado actual.
  Widget build(BuildContext context) {
    // PopScope controla si se permite volver a la pantalla anterior.
    return PopScope(
      // Evita salir con el botón de regresar del teléfono.
      // La salida se habilita al presionar Cerrar sesión.
      canPop: _cerrandoSesion,
      // Scaffold organiza la barra superior y el contenido principal.
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
              // tooltip describe el icono y también ayuda a identificar su función.
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
          // PreferredSize comunica a la barra superior cuánto espacio ocupa la línea.
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
          // SizedBox.expand ocupa el espacio disponible dentro de las restricciones del padre.
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
                        // Text.rich permite combinar fragmentos con distintos estilos.
                        Text.rich(
                          TextSpan(
                            style: SpookyPanelEstilos.descripcion,
                            children: [
                              const TextSpan(text: 'Bienvenido, '),
                              TextSpan(
                                // Muestra el nombre recibido al iniciar sesión.
                                // Si falta, no lo sustituye por un nombre inventado.
                                text:
                                    '${widget.usuario['nombre'] ?? ''}.',
                                style: SpookyPanelEstilos.nombreUsuario,
                              ),
                              const TextSpan(
                                text: ' Desde aquí puedes gestionar '
                                    'el catálogo, las cuentas y los comentarios de Cruppis.',
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
                        'Registro, consulta, edición y eliminación de directores '
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
