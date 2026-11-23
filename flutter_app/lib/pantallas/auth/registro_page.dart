// CRUPPIS — Registro de cuentas de lectores.
// Revisa los campos, envía la solicitud y devuelve el correo al login cuando se crea la cuenta.
// La API también valida los datos, comprueba el correo duplicado y asigna el rol Lector.
// StatefulWidget permite actualizar la pantalla; State conserva sus datos actuales.
// Future representa un resultado pendiente; async y await permiten esperar sin bloquear la interfaz.
// final impide reasignar la variable; const permite crear valores constantes.
// GlobalKey permite acceder al Form para ejecutar los validadores de sus campos.
// setState solicita actualizar la interfaz; mounted comprueba si la pantalla sigue activa.
// JSON es el formato utilizado para enviar y recibir datos; UTF-8 conserva acentos y otros caracteres.
// try intenta una operación, catch atiende el error y finally retira el estado de carga.
// null indica ausencia de valor; ?? utiliza la alternativa cuando falta el primero.
// condición ? opción : otraOpción elige entre dos valores; onPressed: null desactiva un botón.
// ! afirma que un valor no es nulo; en currentState se utiliza porque el Form ya está construido.
// bcrypt es el método que usa el backend para guardar el hash de la contraseña.
// Un byte es una unidad de almacenamiento: un carácter puede ocupar varios bytes en UTF-8.
// Permite enviar las credenciales como JSON y leer la respuesta de la API.
import 'dart:convert';
// Incluye los componentes de la pantalla, los formularios y la navegación.
import 'package:flutter/material.dart';
// Permite enviar la solicitud de registro a la API.
import 'package:http/http.dart' as http;
// Pantalla donde una persona crea su cuenta de lector.
class RegistroPage extends StatefulWidget {
  // Permite abrir el registro sin necesitar una sesión iniciada.
  const RegistroPage({super.key});
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Crea el estado que controla los campos, los errores y el registro.
  State<RegistroPage> createState() => _RegistroPageState();
}
// Reúne las validaciones y el envío de los datos de la cuenta.
class _RegistroPageState extends State<RegistroPage> {
  // Permite revisar todos los campos antes de enviar la solicitud.
  final _formulario = GlobalKey<FormState>();
  // Conserva el nombre escrito en el formulario.
  final _nombre = TextEditingController();
  // Conserva el correo que se enviará a la API y se devolverá al login.
  final _correo = TextEditingController();
  // Conserva la contraseña tal como se escribió.
  final _password = TextEditingController();
  // Permite comparar la confirmación con la contraseña original.
  final _confirmacion = TextEditingController();
  // Comienza con la contraseña oculta y permite cambiar su visibilidad.
  bool _ocultarPassword = true;
  // Controla por separado la visibilidad de la confirmación.
  bool _ocultarConfirmacion = true;
  // Indica que se está enviando el registro y evita pulsaciones repetidas.
  bool _cargando = false;
  // Guarda el aviso que se muestra si no se pudo completar el registro.
  String? _error;
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Libera los controladores cuando se deja de utilizar esta pantalla.
  void dispose() {
    // Libera los recursos del campo del nombre.
    _nombre.dispose();
    // Libera los recursos del campo del correo.
    _correo.dispose();
    // Libera los recursos del campo de contraseña.
    _password.dispose();
    // Libera los recursos del campo de confirmación.
    _confirmacion.dispose();
    // Completa la limpieza que necesita Flutter.
    super.dispose();
  }
  // Revisa los campos y solicita la creación de la cuenta a la API.
  Future<void> _registrar() async {
    // No envía otra solicitud si ya hay una en curso o si los campos tienen errores. Aquí el formulario ya está construido.
    if (_cargando || !_formulario.currentState!.validate()) {
      // Termina este intento sin enviar otra solicitud.
      return;
    }
    // Cierra el teclado antes de continuar con la acción.
    FocusScope.of(context).unfocus();
    // Actualiza los valores y refleja el cambio en la pantalla.
    setState(() {
      // Bloquea las acciones mientras se espera la respuesta del registro.
      _cargando = true;
      // Retira el mensaje de error anterior.
      _error = null;
    });
    // Solo se vuelve true cuando la API confirma que creó la cuenta.
    bool creado = false;
    // Intenta completar esta operación y atiende sus posibles errores.
    try {
      // Espera la respuesta de la API sin bloquear toda la aplicación.
      final respuesta = await http
          // Envía las credenciales mediante una solicitud POST.
          .post(
            // Dirección del registro en la API. Debe actualizarse si cambia la IPv4 de la computadora.
            Uri.parse('http://10.13.40.223:8000/api/registro'),
            // Encabezados que acompañan la petición HTTP.
            headers: {
              // Indica al servidor que el cuerpo de la solicitud contiene JSON.
              'Content-Type': 'application/json; charset=UTF-8',
            },
            // Envía los campos como JSON. No se envía un rol: el servidor asigna Lector.
            body: jsonEncode({
              // Envía el nombre sin espacios sobrantes al principio ni al final.
              'nombre': _nombre.text.trim(),
              // Envía el correo sin espacios sobrantes en los extremos.
              'correo': _correo.text.trim(),
              // Envía la contraseña tal como se escribió; no elimina espacios porque pueden formar parte de ella.
              'password': _password.text,
              // Envía la confirmación para que la API también compruebe que ambas contraseñas coinciden.
              'confirm_password': _confirmacion.text,
            }),
          )
          // Limita la espera a 30 segundos; si vence, el servidor podría haber creado la cuenta.
          .timeout(const Duration(seconds: 30));
      // Reconoce la respuesta que confirma que se creó una cuenta nueva.
      if (respuesta.statusCode == 201) {
        // Marca que se puede regresar al login.
        creado = true;
      // Si la API no confirmó la creación, busca una explicación para mostrarla.
      } else {
        // Prepara un aviso general por si la API no devuelve una explicación más concreta.
        String mensaje = 'No se pudo registrar la cuenta.';
        // Intenta completar esta operación y atiende sus posibles errores.
        try {
          // Convierte la respuesta JSON en datos que Dart puede revisar.
          final datos = jsonDecode(
            // Lee el texto conservando los acentos y otros caracteres.
            utf8.decode(respuesta.bodyBytes),
          );
          // Comprueba que la respuesta tenga un mensaje detail de tipo texto antes de leerlo.
          if (datos is Map && datos['detail'] is String) {
            // Lee la explicación que devuelve la API, como el aviso de un correo ya registrado.
            mensaje = datos['detail'] as String;
          }
        // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
        } catch (_) {
        }
        // Comprueba que la pantalla de registro siga activa antes de cambiar sus datos.
        if (mounted) {
          // Actualiza los valores y refleja el cambio en la pantalla.
          setState(() {
            // Muestra la explicación del problema dentro del formulario.
            _error = mensaje;
          });
        }
      }
    // Atiende problemas de conexión o respuestas que no se pudieron interpretar.
    } catch (_) {
      // Comprueba que la pantalla de registro siga activa antes de cambiar sus datos.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Advierte que no se pudo confirmar el resultado para evitar registrar otra vez una cuenta que quizá ya se creó.
          _error = 'No se pudo confirmar el registro. '
              'Prueba iniciar sesión antes de volver a registrarte.';
        });
      }
    // Finaliza el estado de carga tanto si se creó la cuenta como si ocurrió un error.
    } finally {
      // Comprueba que la pantalla de registro siga activa antes de cambiar sus datos.
      if (mounted) {
        // Actualiza los valores y refleja el cambio en la pantalla.
        setState(() {
          // Retira el indicador de carga y vuelve a habilitar las acciones.
          _cargando = false;
        });
      }
    }
    // Regresa al login solo si la pantalla sigue abierta y se confirmó el registro.
    if (mounted && creado) {
      // Devuelve el correo para que el login lo coloque automáticamente en su campo.
      Navigator.of(context).pop<String>(_correo.text.trim());
    }
  }
  // Revisa la contraseña antes de enviarla; devuelve un mensaje si encuentra un problema.
  String? _validarPassword(String? valor) {
    // Utiliza un texto vacío cuando el campo todavía no tiene un valor.
    final password = valor ?? '';
    // Exige que se escriba una contraseña.
    if (password.isEmpty) {
      return 'Escribe tu contraseña.';
    }
    // Comprueba el límite de 72 bytes que utiliza el backend con bcrypt. No equivale siempre a 72 caracteres, porque algunos ocupan varios bytes.
    if (utf8.encode(password).length > 72) {
      return 'La contraseña admite un máximo de 72 bytes.';
    }
    // Rechaza el carácter nulo, igual que la validación que utiliza el backend.
    if (password.contains('\u0000')) {
      return 'La contraseña contiene un carácter no permitido.';
    }
    // Indica que este campo pasó la validación.
    return null;
  }
  // Indica que se está implementando un método definido por la clase de Flutter.
  @override
  // Construye el formulario con sus campos, avisos y botones.
  Widget build(BuildContext context) {
    return Scaffold(
      // Configura la barra superior de esta pantalla.
      appBar: AppBar(
        // Texto de la barra superior o del cuadro de confirmación.
        title: const Text('Crear cuenta de lector'),
      ),
      // Contenido principal de la pantalla.
      body: Center(
        // Widget que se coloca dentro de este contenedor.
        child: SingleChildScrollView(
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
                // min evita que la columna ocupe más altura de la necesaria.
                mainAxisSize: MainAxisSize.min,
                // stretch estira los elementos horizontalmente dentro de la columna.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                // Lista de widgets que se colocarán dentro del componente.
                children: [
                  const Icon(
                    Icons.person_add_outlined,
                    // Tamaño del icono en unidades lógicas.
                    size: 72,
                    // Color tomado del tema o del esquema de colores.
                    color: Colors.deepOrangeAccent,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    // Conecta este campo con el texto que se revisará y enviará al registrar la cuenta.
                    controller: _nombre,
                    // Evita cambiar el campo mientras se envía el registro.
                    enabled: !_cargando,
                    // Limita la longitud del campo según lo que admite la cuenta.
                    maxLength: 100,
                    // Sugiere comenzar cada palabra del nombre con mayúscula; no cambia por sí solo el texto escrito.
                    textCapitalization: TextCapitalization.words,
                    // Muestra la acción para pasar al siguiente campo del formulario.
                    textInputAction: TextInputAction.next,
                    // Configura la etiqueta y el borde del campo utilizando el tema de la aplicación.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el dato solicitado en este campo.
                      labelText: 'Nombre completo',
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Revisa el campo y muestra una explicación si el valor no es válido.
                    validator: (valor) {
                      return (valor ?? '').trim().isEmpty
                          ? 'Escribe tu nombre.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    // Conecta este campo con el texto que se revisará y enviará al registrar la cuenta.
                    controller: _correo,
                    // Evita cambiar el campo mientras se envía el registro.
                    enabled: !_cargando,
                    // Limita la longitud del campo según lo que admite la cuenta.
                    maxLength: 254,
                    keyboardType: TextInputType.emailAddress,
                    // Muestra la acción para pasar al siguiente campo del formulario.
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    // Configura la etiqueta y el borde del campo utilizando el tema de la aplicación.
                    decoration: const InputDecoration(
                      // Etiqueta que identifica el dato solicitado en este campo.
                      labelText: 'Correo electrónico',
                      // Define el borde del campo.
                      border: OutlineInputBorder(),
                    ),
                    // Revisa el campo y muestra una explicación si el valor no es válido.
                    validator: (valor) {
                      // Quita espacios exteriores antes de comprobar el formato del correo.
                      final correo = (valor ?? '').trim();
                      // RegExp describe el formato que debe cumplir el correo.
                      // r conserva las barras del patrón; ^ y $ señalan el inicio y el final.
                      // [^@\s]+ exige texto sin arrobas ni espacios en esa parte.
                      // \. representa un punto literal entre el dominio y su terminación.
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      // Si el correo no coincide con ese formato, muestra el mensaje de validación.
                      ).hasMatch(correo)) {
                        return 'Escribe un correo válido.';
                      }
                      // Indica que este campo pasó la validación.
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    // Conecta este campo con el texto que se revisará y enviará al registrar la cuenta.
                    controller: _password,
                    // Evita cambiar el campo mientras se envía el registro.
                    enabled: !_cargando,
                    // Controla si este campo muestra los caracteres o los mantiene ocultos.
                    obscureText: _ocultarPassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    // Muestra la acción para pasar al siguiente campo del formulario.
                    textInputAction: TextInputAction.next,
                    // Revisa el campo y muestra una explicación si el valor no es válido.
                    validator: _validarPassword,
                    // Configura la etiqueta y el borde del campo utilizando el tema de la aplicación.
                    decoration: InputDecoration(
                      // Etiqueta que identifica el dato solicitado en este campo.
                      labelText: 'Contraseña',
                      // Aclara el límite de tamaño permitido para la contraseña.
                      helperText: 'Máximo 72 bytes.',
                      // Define el borde del campo.
                      border: const OutlineInputBorder(),
                      // Coloca el botón de visibilidad al final del campo de contraseña.
                      suffixIcon: IconButton(
                        // Describe si el botón mostrará u ocultará el contenido del campo.
                        tooltip: _ocultarPassword
                            ? 'Mostrar contraseña'
                            : 'Ocultar contraseña',
                        // Asigna la acción del botón y la desactiva cuando se está registrando la cuenta.
                        onPressed: _cargando
                            ? null
                            : () {
                                // Actualiza los valores y refleja el cambio en la pantalla.
                                setState(() {
                                  // Alterna entre mostrar y ocultar la contraseña.
                                  _ocultarPassword = !_ocultarPassword;
                                });
                              },
                        // Icono que acompaña la acción.
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    // Conecta este campo con el texto que se revisará y enviará al registrar la cuenta.
                    controller: _confirmacion,
                    // Evita cambiar el campo mientras se envía el registro.
                    enabled: !_cargando,
                    // Controla si este campo muestra los caracteres o los mantiene ocultos.
                    obscureText: _ocultarConfirmacion,
                    autocorrect: false,
                    enableSuggestions: false,
                    // Muestra la acción de finalizar en el teclado.
                    textInputAction: TextInputAction.done,
                    // Permite intentar el registro desde la acción de finalizar del teclado.
                    onFieldSubmitted: (_) {
                      // Intenta crear la cuenta al pulsar la acción de finalizar del teclado.
                      _registrar();
                    },
                    // Configura la etiqueta y el borde del campo utilizando el tema de la aplicación.
                    decoration: InputDecoration(
                      // Etiqueta que identifica el dato solicitado en este campo.
                      labelText: 'Confirmar contraseña',
                      // Define el borde del campo.
                      border: const OutlineInputBorder(),
                      // Coloca el botón de visibilidad al final del campo de contraseña.
                      suffixIcon: IconButton(
                        // Describe si el botón mostrará u ocultará el contenido del campo.
                        tooltip: _ocultarConfirmacion
                            ? 'Mostrar confirmación'
                            : 'Ocultar confirmación',
                        // Asigna la acción del botón y la desactiva cuando se está registrando la cuenta.
                        onPressed: _cargando
                            ? null
                            : () {
                                // Actualiza los valores y refleja el cambio en la pantalla.
                                setState(() {
                                  // Cambia la visibilidad de la confirmación sin modificar la contraseña.
                                  _ocultarConfirmacion =
                                      // Invierte el valor actual de la visibilidad.
                                      !_ocultarConfirmacion;
                                });
                              },
                        // Icono que acompaña la acción.
                        icon: Icon(
                          _ocultarConfirmacion
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    // Revisa el campo y muestra una explicación si el valor no es válido.
                    validator: (valor) {
                      // No permite enviar el campo de contraseña vacío.
                      if (valor == null || valor.isEmpty) {
                        return 'Confirma tu contraseña.';
                      }
                      // Comprueba que la confirmación coincida exactamente con la contraseña escrita.
                      if (valor != _password.text) {
                        return 'Las contraseñas no coinciden.';
                      }
                      // Indica que este campo pasó la validación.
                      return null;
                    },
                  ),
                  // Agrega el mensaje al formulario únicamente cuando existe un error.
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
                    // Asigna la acción del botón y la desactiva cuando se está registrando la cuenta.
                    onPressed: _cargando ? null : _registrar,
                    // Estilo del texto o del botón.
                    style: FilledButton.styleFrom(
                      // Tamaño mínimo solicitado para facilitar la pulsación.
                      minimumSize: const Size(48, 48),
                    ),
                    // Widget que se coloca dentro de este contenedor.
                    child: _cargando
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
                        : const Text('Registrarse'),
                  ),
                  TextButton(
                    // Asigna la acción del botón y la desactiva cuando se está registrando la cuenta.
                    onPressed: _cargando
                        ? null
                        : () {
                            // Vuelve al login sin crear una cuenta desde esta acción.
                            Navigator.of(context).pop();
                          },
                    // Estilo del texto o del botón.
                    style: TextButton.styleFrom(
                      // Tamaño mínimo solicitado para facilitar la pulsación.
                      minimumSize: const Size(48, 48),
                    ),
                    // Widget que se coloca dentro de este contenedor.
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
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
}
