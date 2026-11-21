// CRUPPIS — Pantalla de inicio de sesión.
// Comprueba las credenciales con la API y entrega la respuesta al controlador de sesión.
// La asignación de roles y los permisos se revisan en el servidor.

// Permite enviar las credenciales como JSON y leer la respuesta de la API.
import 'dart:convert';
// Incluye los componentes de la pantalla, los formularios y la navegación.
import 'package:flutter/material.dart';
// Permite enviar la solicitud de inicio de sesión a la API.
import 'package:http/http.dart' as http;
// Utiliza los estilos compartidos de Cruppis. El nombre del archivo se conserva para no romper las referencias.
import '../../estilos/spooky_tema.dart';
// Importa la pantalla donde se crean las cuentas de lectores.
import 'registro_page.dart';
// Pantalla de acceso. Su contenido cambia mientras consulta la API o muestra un error.
class LoginPage extends StatefulWidget {
  // Permite recibir la función que continuará con el proceso cuando se confirme la sesión.
  const LoginPage({
    super.key,
    this.onSesion,
  });
  // Función opcional que recibe la sesión confirmada. Puede esperar otras tareas, como guardar el token y abrir la pantalla correspondiente.
  final Future<void> Function(Map<String, dynamic> sesion)? onSesion;
  @override
  // Crea el estado que administra los campos y las acciones de esta pantalla.
  State<LoginPage> createState() => _LoginPageState();
}
// Contiene la validación del formulario, el acceso a la API y la presentación del login.
class _LoginPageState extends State<LoginPage> {
  // Permite revisar los campos y restablecer el formulario.
  final _formulario = GlobalKey<FormState>();
  // Controla el correo escrito y permite completarlo después del registro.
  final _correo = TextEditingController();
  // Controla la contraseña escrita y permite borrarla cuando ya no se necesita.
  final _password = TextEditingController();
  // Oculta la contraseña al abrir la pantalla.
  bool _ocultarPassword = true;
  // Evita repetir el envío mientras se comprueban las credenciales.
  bool _cargando = false;
  // Guarda el mensaje de error que se mostrará dentro del formulario.
  String? _error;
  @override
  // Libera los recursos de los campos cuando esta pantalla deja de utilizarse.
  void dispose() {
    // Libera el controlador del correo.
    _correo.dispose();
    // Libera el controlador de la contraseña.
    _password.dispose();
    // Completa la limpieza que necesita Flutter.
    super.dispose();
  }
  // Abre el registro y espera el correo de la cuenta creada para colocarlo en el login.
  Future<void> _abrirRegistro() async {
    // No abre otra pantalla mientras se está comprobando una sesión.
    if (_cargando) return;
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Abre otra pantalla y espera que devuelva el correo registrado como texto.
    final correo = await Navigator.of(context).push<String>(
      // Prepara la ruta que puede devolver el correo al terminar.
      MaterialPageRoute<String>(
        // Construye la pantalla de registro de lectores.
        builder: (context) => const RegistroPage(),
      ),
    );
    // Continúa solo si el login sigue abierto y el registro devolvió un correo.
    if (!mounted || correo == null) return;
    // Restablece los campos y sus mensajes de validación antes de preparar el formulario otra vez.
    _formulario.currentState?.reset();
    // Completa el campo con el correo de la cuenta recién creada.
    _correo.text = correo;
    // Borra la contraseña para evitar conservarla en el formulario.
    _password.clear();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Retira el mensaje de error anterior.
      _error = null;
      // Vuelve a ocultar la contraseña.
      _ocultarPassword = true;
    });
    // Muestra un aviso temporal para indicar el resultado del registro.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        // Contenido principal del mensaje o del diálogo.
        content: Text('Cuenta creada. Ahora inicia sesión.'),
      ),
    );
  }
  // Revisa los campos, consulta la API y entrega la sesión confirmada al resto de la aplicación.
  Future<void> _iniciarSesion() async {
    // Evita enviar una nueva solicitud mientras ya se está comprobando otra.
    if (_cargando ||
        // No continúa si falta el formulario o si alguno de sus campos no pasa la validación.
        !(_formulario.currentState?.validate() ?? false)) {
      // Termina este intento sin continuar con el acceso.
      return;
    }
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Desactiva las acciones y muestra que se está comprobando el acceso.
      _cargando = true;
      // Retira el mensaje de error anterior.
      _error = null;
    });
    // Reserva un lugar para la respuesta válida; queda sin valor cuando el acceso falla.
    Map<String, dynamic>? sesion;
    // Intenta realizar la consulta y deja preparado el manejo de los errores.
    try {
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Envía las credenciales mediante una solicitud POST.
          .post(
            // Dirección del login de la API. Debe actualizarse si cambia la IPv4 de la computadora.
            Uri.parse('http://192.168.1.65:8000/api/login'),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Indica al servidor que el cuerpo de la solicitud contiene JSON.
              'Content-Type': 'application/json; charset=UTF-8',
            },
            // Convierte el correo y la contraseña al formato que espera la API.
            body: jsonEncode({
              // Envía el correo sin espacios sobrantes en los extremos.
              'correo': _correo.text.trim(),
              // Envía la contraseña tal como se escribió; no elimina espacios porque pueden formar parte de ella.
              'password': _password.text,
            }),
          )
          // Limita la espera de la respuesta a 20 segundos.
          .timeout(const Duration(seconds: 20));
      // Reconoce que la API rechazó las credenciales o el acceso de la cuenta.
      if (respuesta.statusCode == 401) {
        // Interrumpe el acceso con un mensaje que se podrá mostrar en el formulario.
        throw const _ErrorLogin(
          'Correo o contraseña incorrectos, o cuenta sin acceso.',
        );
      }
      // Informa que el servidor no confirmó el inicio de sesión.
      if (respuesta.statusCode != 200) {
        // Interrumpe el acceso con un mensaje que se podrá mostrar en el formulario.
        throw const _ErrorLogin(
          'El servidor no pudo iniciar la sesión. Intenta nuevamente.',
        );
      }
      // Convierte la respuesta JSON en datos que Dart puede revisar.
      final datos = jsonDecode(
        // Lee el texto conservando los acentos y otros caracteres.
        utf8.decode(respuesta.bodyBytes),
      );
      // Comprueba que la respuesta tenga campos con nombre, como access_token y usuario.
      if (datos is! Map<String, dynamic>) {
        // Rechaza la respuesta porque no tiene los datos esperados para una sesión.
        throw const FormatException(
          'Respuesta de sesión inválida.',
        );
      }
      // Recupera el token que la app utilizará para identificarse en las consultas protegidas.
      final token = datos['access_token'];
      // Recupera los datos de la cuenta que la API autenticó.
      final usuario = datos['usuario'];
      // Revisa que el token sea texto antes de utilizarlo.
      if (token is! String ||
          // También rechaza un token vacío o formado solo por espacios.
          token.trim().isEmpty ||
          // Exige que la respuesta incluya los datos del usuario con la estructura esperada.
          usuario is! Map) {
        // Rechaza la respuesta porque no tiene los datos esperados para una sesión.
        throw const FormatException(
          'Respuesta de sesión inválida.',
        );
      }
      // Conserva la sesión solo después de comprobar los datos básicos de la respuesta.
      sesion = datos;
    // Atiende los errores de acceso que tienen un mensaje preparado para la persona.
    } on _ErrorLogin catch (error) {
      // Comprueba que el login siga abierto antes de actualizar su contenido.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Muestra la explicación del problema de acceso.
          _error = error.mensaje;
        });
      }
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Comprueba que el login siga abierto antes de actualizar su contenido.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Prepara un aviso general cuando no se pudo completar la comunicación o leer la respuesta.
          _error = 'No se pudo conectar correctamente con la API. '
              'Comprueba que esté encendida e intenta nuevamente.';
        });
      }
    // Termina el estado de carga tanto si se aceptó el acceso como si ocurrió un error.
    } finally {
      // Comprueba que el login siga abierto antes de actualizar su contenido.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Retira el indicador de carga y vuelve a habilitar las acciones.
          _cargando = false;
        });
      }
    }
    // No continúa si la pantalla ya se cerró o si no hay una sesión confirmada.
    if (!mounted || sesion == null) return;
    // Restablece los campos y sus mensajes de validación antes de preparar el formulario otra vez.
    _formulario.currentState?.reset();
    // Borra el correo después del acceso para no conservar las credenciales al regresar.
    _correo.clear();
    // Borra la contraseña para evitar conservarla en el formulario.
    _password.clear();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Vuelve a ocultar la contraseña.
      _ocultarPassword = true;
      // Retira el mensaje de error anterior.
      _error = null;
    });
    // Obtiene la función que recibió el login para continuar con el manejo de la sesión.
    final onSesion = widget.onSesion;
    // Si se recibió esa función, le entrega los datos de acceso.
    if (onSesion != null) {
      // Espera las tareas del controlador de sesión, como guardar el token y abrir la pantalla del rol.
      await onSesion(sesion);
    // Utiliza esta alternativa si no se proporcionó una función para recibir la sesión.
    } else {
      // Si no se recibió una función, regresa a la pantalla anterior y le devuelve la sesión.
      Navigator.of(context).pop<Map<String, dynamic>>(sesion);
    }
  }
  // Construye el logo y el nombre que identifican a Cruppis en el login.
  Widget _identidadCruppis() {
    // Devuelve los elementos que forman esta parte de la pantalla.
    return Column(
      // Lista de widgets que se colocarán dentro del componente.
      children: [
        Container(
          // Ancho solicitado en unidades lógicas de Flutter.
          width: 112,
          // Altura solicitada en unidades lógicas de Flutter.
          height: 112,
          // Aplica la decoración correspondiente al fondo, al logo o al botón.
          decoration: BoxDecoration(
            // Da una forma circular al fondo del logo.
            shape: BoxShape.circle,
            // Aplica un cambio de color al fondo del logo.
            gradient: const RadialGradient(
              // Colores que forman el fondo del logo.
              colors: [
                Color(0xFF392051),
                SpookyTema.superficie,
              ],
            ),
            // Dibuja el contorno del logo.
            border: Border.all(
              // Color tomado del tema o del esquema de colores.
              color: SpookyTema.lila,
              // Ancho solicitado en unidades lógicas de Flutter.
              width: 1.5,
            ),
            // Añade el resplandor que rodea al logo.
            boxShadow: const [
              BoxShadow(
                // Color tomado del tema o del esquema de colores.
                color: Color(0x667C3AED),
                // Define qué tan difusa aparece la sombra.
                blurRadius: 24,
                // Amplía la sombra alrededor de la figura.
                spreadRadius: 2,
              ),
            ],
          ),
          // Centra el contenido dentro del círculo.
          alignment: Alignment.center,
          // Widget que se coloca dentro de este contenedor.
          child: ClipOval(
            // Widget que se coloca dentro de este contenedor.
            child: Image.asset(
              // Carga el logo incluido en los archivos de la aplicación; debe estar declarado en pubspec.yaml.
              'assets/imagenes/logo_cruppis.png',
              // Ancho solicitado en unidades lógicas de Flutter.
              width: 106,
              // Altura solicitada en unidades lógicas de Flutter.
              height: 106,
              // cover llena el espacio disponible y recorta los bordes de la imagen si es necesario.
              fit: BoxFit.contain,
              // Describe el logo para las herramientas de accesibilidad.
              semanticLabel: 'Logo de Cruppis',
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Cruppis',
          // Alineación del texto dentro del espacio disponible.
          textAlign: TextAlign.center,
          // Estilo del texto o del botón.
          style: TextStyle(
            // Solicita la familia de letra indicada para el nombre.
            fontFamily: 'serif',
            // Define el tamaño del texto.
            fontSize: 36,
            // Destaca el texto en negritas.
            fontWeight: FontWeight.bold,
            // Separa ligeramente las letras del nombre.
            letterSpacing: 2,
            // Color tomado del tema o del esquema de colores.
            color: SpookyTema.texto,
            // Añade el resplandor del texto de Cruppis.
            shadows: [
              Shadow(
                // Color tomado del tema o del esquema de colores.
                color: Color(0x887C3AED),
                // Define qué tan difusa aparece la sombra.
                blurRadius: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
  @override
  // Construye la pantalla utilizando el estado actual de los campos y de la consulta.
  Widget build(BuildContext context) {
    // Devuelve los elementos que forman esta parte de la pantalla.
    return Scaffold(
      // Configura la barra superior de esta pantalla.
      appBar: AppBar(
        // Evita que la barra agregue una flecha de regreso automáticamente.
        automaticallyImplyLeading: false,
        // Texto de la barra superior o del cuadro de confirmación.
        title: const Text('Iniciar sesión'),
      ),
      // Contenido principal de la pantalla.
      body: DecoratedBox(
        // Aplica la decoración correspondiente al fondo, al logo o al botón.
        decoration: SpookyLectorEstilos.fondo,
        // Widget que se coloca dentro de este contenedor.
        child: SizedBox.expand(
          // Widget que se coloca dentro de este contenedor.
          child: SafeArea(
            // Widget que se coloca dentro de este contenedor.
            child: Center(
              // Widget que se coloca dentro de este contenedor.
              child: SingleChildScrollView(
                // Configura cómo se oculta el teclado al desplazar el formulario.
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                // Establece el espacio interior alrededor del contenido.
                padding: const EdgeInsets.all(24),
                // Widget que se coloca dentro de este contenedor.
                child: ConstrainedBox(
                  // Evita que el formulario quede demasiado ancho en pantallas grandes.
                  constraints: const BoxConstraints(maxWidth: 420),
                  // Widget que se coloca dentro de este contenedor.
                  child: Form(
                    // Vincula el Form con la clave utilizada para ejecutar sus validadores.
                    key: _formulario,
                    // Widget que se coloca dentro de este contenedor.
                    child: Column(
                      // Ajusta la columna a la altura que necesita su contenido.
                      mainAxisSize: MainAxisSize.min,
                      // Extiende los campos y botones al ancho del formulario.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      // Lista de widgets que se colocarán dentro del componente.
                      children: [
                        _identidadCruppis(),
                        const SizedBox(height: 32),
                       const Text(
                          'Bienvenido a Cruppis',
                          // Alineación del texto dentro del espacio disponible.
                          textAlign: TextAlign.center,
                          // Estilo del texto o del botón.
                          style: TextStyle(
                            // Define el tamaño del texto.
                            fontSize: 20,
                            // Destaca el texto en negritas.
                            fontWeight: FontWeight.bold,
                            // Color tomado del tema o del esquema de colores.
                            color: SpookyTema.texto,
                          ),
                        ),
                        const SizedBox(height: 8),
                       const Text(
                          'Ingresa con tu cuenta para continuar',
                          // Alineación del texto dentro del espacio disponible.
                          textAlign: TextAlign.center,
                          // Estilo del texto o del botón.
                          style: SpookyLectorEstilos.descripcion,
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          // Conecta el campo con el controlador que guarda su texto.
                          controller: _correo,
                          // Impide modificar el campo mientras se envían las credenciales.
                          enabled: !_cargando,
                          // Sugiere un teclado apropiado para escribir un correo.
                          keyboardType: TextInputType.emailAddress,
                          // Define si el teclado ofrece pasar al siguiente campo o finalizar.
                          textInputAction: TextInputAction.next,
                          // Evita que el teclado cambie automáticamente lo que se escribió.
                          autocorrect: false,
                          // Evita las sugerencias del teclado al escribir las credenciales.
                          enableSuggestions: false,
                          // Quita el foco al tocar fuera del campo.
                          onTapOutside: (_) {
                            // Cierra el teclado antes de continuar con la acción.
                            FocusScope.of(context).unfocus();
                          },
                          // Aplica la decoración correspondiente al fondo, al logo o al botón.
                          decoration: const InputDecoration(
                            // Etiqueta que identifica el campo del nombre.
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              // Color tomado del tema o del esquema de colores.
                              color: SpookyTema.lila,
                            ),
                          ),
                          // Revisa el texto y devuelve un mensaje si el nombre no es válido.
                          validator: (valor) {
                            // Prepara el correo para comprobar que no esté vacío y que incluya una arroba.
                            final correo = (valor ?? '').trim();
                            // Hace una revisión básica del correo; las credenciales se comprueban realmente en la API.
                            if (correo.isEmpty || !correo.contains('@')) {
                              return 'Escribe tu correo electrónico.';
                            }
                            // Indica que este campo pasó la validación.
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          // Conecta el campo con el controlador que guarda su texto.
                          controller: _password,
                          // Impide modificar el campo mientras se envían las credenciales.
                          enabled: !_cargando,
                          // Muestra u oculta los caracteres de la contraseña según el estado actual.
                          obscureText: _ocultarPassword,
                          // Evita que el teclado cambie automáticamente lo que se escribió.
                          autocorrect: false,
                          // Evita las sugerencias del teclado al escribir las credenciales.
                          enableSuggestions: false,
                          // Define si el teclado ofrece pasar al siguiente campo o finalizar.
                          textInputAction: TextInputAction.done,
                          // Quita el foco al tocar fuera del campo.
                          onTapOutside: (_) {
                            // Cierra el teclado antes de continuar con la acción.
                            FocusScope.of(context).unfocus();
                          },
                          // Permite intentar el acceso desde la acción de finalizar del teclado.
                          onFieldSubmitted: (_) {
                            // Intenta entrar cuando se pulsa la acción del teclado.
                            _iniciarSesion();
                          },
                          // Aplica la decoración correspondiente al fondo, al logo o al botón.
                          decoration: InputDecoration(
                            // Etiqueta que identifica el campo del nombre.
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                              // Color tomado del tema o del esquema de colores.
                              color: SpookyTema.lila,
                            ),
                            // Coloca el botón para mostrar u ocultar la contraseña al final del campo.
                            suffixIcon: IconButton(
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                              // Describe la acción que realizará el botón.
                              tooltip: _ocultarPassword
                                  ? 'Mostrar contraseña'
                                  : 'Ocultar contraseña',
                              // Asigna la acción del botón; null lo desactiva mientras se consulta la API.
                              onPressed: _cargando
                                  ? null
                                  : () {
                                      // Actualiza los valores y refleja el cambio en la pantalla.
                                      setState(() {
                                        // Cambia entre mostrar y ocultar la contraseña.
                                        _ocultarPassword =
                                            // Invierte el valor actual: true pasa a false y false pasa a true.
                                            !_ocultarPassword;
                                      });
                                    },
                              // Icono que acompaña la acción.
                              icon: Icon(
                                _ocultarPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                // Color tomado del tema o del esquema de colores.
                                color: SpookyTema.lila,
                              ),
                            ),
                          ),
                          // Revisa el texto y devuelve un mensaje si el nombre no es válido.
                          validator: (valor) {
                            // No permite enviar el campo de contraseña vacío.
                            if (valor == null || valor.isEmpty) {
                              return 'Escribe tu contraseña.';
                            }
                            // Indica que este campo pasó la validación.
                            return null;
                          },
                        ),
                        // Agrega el mensaje al formulario únicamente cuando existe un error.
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            // Estilo del texto o del botón.
                            style: TextStyle(
                              // Color tomado del tema o del esquema de colores.
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                       const SizedBox(height: 24),
                        DecoratedBox(
                          // Aplica la decoración correspondiente al fondo, al logo o al botón.
                          decoration: SpookyPanelEstilos.resplandorBoton,
                          // Widget que se coloca dentro de este contenedor.
                          child: FilledButton(
                            // Asigna la acción del botón; null lo desactiva mientras se consulta la API.
                            onPressed: _cargando ? null : _iniciarSesion,
                            // Estilo del texto o del botón.
                            style: FilledButton.styleFrom(
                              // Tamaño mínimo solicitado para facilitar la pulsación.
                              minimumSize: const Size(48, 48),
                            ),
                            // Widget que se coloca dentro de este contenedor.
                            child: _cargando
                                ? const SizedBox(
                                    // Ancho solicitado en unidades lógicas de Flutter.
                                    width: 20,
                                    // Altura solicitada en unidades lógicas de Flutter.
                                    height: 20,
                                    // Widget que se coloca dentro de este contenedor.
                                    child: CircularProgressIndicator(
                                      // Grosor de la línea del indicador circular.
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Entrar'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          // Asigna la acción del botón; null lo desactiva mientras se consulta la API.
                          onPressed: _cargando ? null : _abrirRegistro,
                          // Estilo del texto o del botón.
                          style: TextButton.styleFrom(
                            // Tamaño mínimo solicitado para facilitar la pulsación.
                            minimumSize: const Size(48, 48),
                          ),
                          // Widget que se coloca dentro de este contenedor.
                          child: const Text(
                            '¿No tienes cuenta? Regístrate como lector',
                            // Alineación del texto dentro del espacio disponible.
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// Agrupa los errores de acceso con un mensaje propio para distinguirlos de otros fallos.
class _ErrorLogin implements Exception {
  // Recibe la explicación que se mostrará cuando se capture este error.
  const _ErrorLogin(this.mensaje);
  // Conserva el mensaje del error sin modificarlo.
  final String mensaje;
}
