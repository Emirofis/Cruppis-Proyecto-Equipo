// CRUPPIS — Tema visual de la aplicación móvil.
// Este archivo define apariencia; no consulta la API, no guarda datos y no controla sesiones.
// Se mantienen los nombres Spooky... porque las pantallas existentes los referencian.
// Cambiarlos requiere actualizar todas esas referencias en el proyecto.
// static permite acceder con Clase.propiedad sin crear un objeto.
// const define valores constantes; final permite inicializarlos una vez durante la ejecución.
// Las medidas son unidades lógicas de Flutter, no píxeles físicos del teléfono.
// En Color(0xAARRGGBB), AA es opacidad y RR/GG/BB son rojo, verde y azul.
// Las líneas con ), ], }; o } cierran el bloque iniciado anteriormente.

// Importa los componentes Material, colores, textos, temas y decoraciones de Flutter.
import 'package:flutter/material.dart';
// Centraliza la paleta y el tema oscuro general de Cruppis.
class SpookyTema {
  // Constructor privado: evita crear instancias de esta clase que solo agrupa estilos estáticos.
  SpookyTema._();
  // Fondo principal o decoración de fondo de esta sección.
  static const fondo = Color(0xFF090810);
  // Color para las tarjetas y paneles.
  static const superficie = Color(0xFF121020);
  // Color de fondo de los campos de texto.
  static const campo = Color(0xFF19152A);
  // Color principal de la identidad de Cruppis.
  static const morado = Color(0xFF7C3AED);
  // Variante oscura para fondos e indicadores.
  static const moradoOscuro = Color(0xFF30174D);
  // Color claro para acentos, iconos y etiquetas.
  static const lila = Color(0xFFC4B5FD);
  // Alias de compatibilidad: conserva las referencias antiguas, pero su valor real es morado.
  static const rojo = morado;
  // Alias de compatibilidad: conserva las referencias antiguas, pero su valor real es morado oscuro.
  static const rojoOscuro = moradoOscuro;
  // Color claro del texto principal.
  static const texto = Color(0xFFF5F3FF);
  // Color de los textos de apoyo.
  static const textoSecundario = Color(0xFFB5AEC8);
  // Color común de los bordes.
  static const borde = Color(0xFF35284C);
  // Radio reutilizable para redondear esquinas.
  static const double radio = 16;
  // Separación reutilizable entre elementos.
  static const double espacio = 16;
  // Tamaño mínimo solicitado a los botones del tema: 48 unidades lógicas.
  static const double areaTactil = 48;
  // Margen uniforme de las pantallas que utilizan este valor.
  static const margenPantalla = EdgeInsets.all(20);
  // Estilo del encabezado de sección.
  static const tituloSeccion = TextStyle(
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 24,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Color del texto, borde o efecto que se está configurando.
    color: texto,
  );
  // Estilo del título dentro de una tarjeta.
  static const tituloTarjeta = TextStyle(
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 17,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Color del texto, borde o efecto que se está configurando.
    color: texto,
  );
  // Estilo general de los textos descriptivos.
  static const textoDescripcion = TextStyle(
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.5,
    // Color del texto, borde o efecto que se está configurando.
    color: textoSecundario,
  );
  // Borde neón para las tarjetas del catálogo.
  // Decoración de tarjeta con contorno y dos sombras moradas.
  static final tarjetaNeon = BoxDecoration(
    // Color del texto, borde o efecto que se está configurando.
    color: superficie,
    // Redondea las esquinas del elemento con el radio indicado.
    borderRadius: BorderRadius.circular(16),
    // Define el contorno de la decoración o el borde del campo de texto.
    border: Border.all(
      // Color del texto, borde o efecto que se está configurando.
      color: const Color(0xFF9D62FF),
      // Grosor del borde o ancho del elemento, según el objeto que lo contiene.
      width: 1.2,
    ),
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: const [
      BoxShadow(
        // Color del texto, borde o efecto que se está configurando.
        color: Color(0x557C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 14,
        // Expande la sombra antes de difuminarla.
        spreadRadius: 1,
      ),
      BoxShadow(
        // Color del texto, borde o efecto que se está configurando.
        color: Color(0x227C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 24,
        // Expande la sombra antes de difuminarla.
        spreadRadius: 2,
      ),
    ],
  );
  // Tema que se asigna a MaterialApp para aplicar estos valores a la aplicación.
  static final ThemeData oscuro = ThemeData(
    // Activa los componentes y criterios visuales de Material Design 3.
    useMaterial3: true,
    // Indica que el tema general es oscuro.
    brightness: Brightness.dark,
    // Color predeterminado del fondo de las pantallas Scaffold.
    scaffoldBackgroundColor: fondo,
    // Establece el color principal para los componentes que consultan esta propiedad.
    primaryColor: morado,
    // Agrupa los colores que Material asigna a las distintas partes de sus componentes.
    colorScheme: const ColorScheme.dark(
      // Color principal de los componentes.
      primary: morado,
      // Color del contenido colocado sobre el color principal.
      onPrimary: Colors.white,
      // Color del contenedor asociado al color principal.
      primaryContainer: moradoOscuro,
      // Color del contenido dentro del contenedor principal.
      onPrimaryContainer: texto,
      // Color secundario del tema.
      secondary: lila,
      // Color del contenido colocado sobre el color secundario.
      onSecondary: fondo,
      // Fondo de los contenedores secundarios.
      secondaryContainer: moradoOscuro,
      // Color del contenido de los contenedores secundarios.
      onSecondaryContainer: texto,
      // Color de las superficies, como paneles y tarjetas.
      surface: superficie,
      // Color del contenido sobre las superficies.
      onSurface: texto,
      // Color de los contornos.
      outline: borde,
      // Color utilizado para indicar errores.
      error: Color(0xFFFFA3B5),
      // Color del contenido sobre el color de error.
      onError: Color(0xFF390015),
    ),
    // Configura la apariencia predeterminada de la barra superior.
    appBarTheme: const AppBarTheme(
      // Color de fondo del componente.
      backgroundColor: fondo,
      // Color de su texto e iconos.
      foregroundColor: texto,
      // Controla el tinte de elevación; transparente evita que cambie el color elegido.
      surfaceTintColor: Colors.transparent,
      // Determina si el título de la barra superior se centra.
      centerTitle: false,
      // Profundidad visual; cero elimina la sombra por elevación.
      elevation: 0,
      // Elevación de la barra cuando el contenido se desplaza debajo de ella.
      scrolledUnderElevation: 0,
      // Estilo del título de la barra superior.
      titleTextStyle: TextStyle(
        // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
        fontSize: 21,
        // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
        fontWeight: FontWeight.bold,
        // Color del texto, borde o efecto que se está configurando.
        color: texto,
        // Separación adicional entre las letras.
        letterSpacing: 0.5,
      ),
    ),
    // Configura la apariencia predeterminada de los widgets Card.
    cardTheme: CardThemeData(
      // Color del texto, borde o efecto que se está configurando.
      color: superficie,
      // Controla el tinte de elevación; transparente evita que cambie el color elegido.
      surfaceTintColor: Colors.transparent,
      // Profundidad visual; cero elimina la sombra por elevación.
      elevation: 0,
      // Define la forma del componente y, cuando corresponde, su contorno.
      shape: RoundedRectangleBorder(
        // Redondea las esquinas del elemento con el radio indicado.
        borderRadius: BorderRadius.circular(radio),
        // Define el color y grosor del borde.
        side: const BorderSide(color: borde),
      ),
    ),
    // Estilo común de los campos de formulario.
    inputDecorationTheme: InputDecorationTheme(
      // Activa el relleno del campo de texto.
      filled: true,
      // Define el relleno; en CheckboxTheme puede variar según el estado.
      fillColor: campo,
      // Estilo de la etiqueta del campo.
      labelStyle: const TextStyle(color: textoSecundario),
      // Estilo de la etiqueta cuando flota encima del campo.
      floatingLabelStyle: const TextStyle(color: lila),
      // Estilo del texto de ejemplo del campo.
      hintStyle: const TextStyle(color: textoSecundario),
      // Estilo del texto de ayuda del campo.
      helperStyle: const TextStyle(color: textoSecundario),
      // Espacio interior entre el borde del campo y su contenido.
      contentPadding: const EdgeInsets.all(16),
      // Define el contorno de la decoración o el borde del campo de texto.
      border: OutlineInputBorder(
        // Redondea las esquinas del elemento con el radio indicado.
        borderRadius: BorderRadius.circular(radio),
        borderSide: const BorderSide(color: borde),
      ),
      // Borde del campo habilitado cuando no tiene el foco.
      enabledBorder: OutlineInputBorder(
        // Redondea las esquinas del elemento con el radio indicado.
        borderRadius: BorderRadius.circular(radio),
        borderSide: const BorderSide(color: borde),
      ),
      // Borde del campo que está seleccionado para escribir.
      focusedBorder: OutlineInputBorder(
        // Redondea las esquinas del elemento con el radio indicado.
        borderRadius: BorderRadius.circular(radio),
        borderSide: const BorderSide(color: lila, width: 2),
      ),
    ),
    // Estilo común de los botones FilledButton.
    filledButtonTheme: FilledButtonThemeData(
      // Construye la configuración visual del botón.
      style: FilledButton.styleFrom(
        // Color de fondo del componente.
        backgroundColor: morado,
        // Color de su texto e iconos.
        foregroundColor: Colors.white,
        // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
        minimumSize: const Size(areaTactil, areaTactil),
        // Espacio interior alrededor del contenido.
        padding: const EdgeInsets.symmetric(
          // Espacio aplicado a izquierda y derecha.
          horizontal: 24,
          // Espacio aplicado arriba y abajo.
          vertical: 14,
        ),
        // Estilo del texto del botón.
        textStyle: const TextStyle(
          // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
          fontSize: 16,
          // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
          fontWeight: FontWeight.bold,
        ),
        // Define la forma del componente y, cuando corresponde, su contorno.
        shape: RoundedRectangleBorder(
          // Redondea las esquinas del elemento con el radio indicado.
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    // Estilo común de los botones con contorno.
    outlinedButtonTheme: OutlinedButtonThemeData(
      // Construye la configuración visual del botón.
      style: OutlinedButton.styleFrom(
        // Color de su texto e iconos.
        foregroundColor: lila,
        // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
        minimumSize: const Size(areaTactil, areaTactil),
        // Define el color y grosor del borde.
        side: const BorderSide(color: morado),
        // Define la forma del componente y, cuando corresponde, su contorno.
        shape: RoundedRectangleBorder(
          // Redondea las esquinas del elemento con el radio indicado.
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    // Estilo común de los botones de texto.
    textButtonTheme: TextButtonThemeData(
      // Construye la configuración visual del botón.
      style: TextButton.styleFrom(
        // Color de su texto e iconos.
        foregroundColor: lila,
        // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
        minimumSize: const Size(areaTactil, areaTactil),
      ),
    ),
    // Estilo común de los botones que muestran un icono.
    iconButtonTheme: IconButtonThemeData(
      // Construye la configuración visual del botón.
      style: IconButton.styleFrom(
        // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
        minimumSize: const Size(areaTactil, areaTactil),
      ),
    ),
    // Estilo del botón flotante de acción.
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      // Color de fondo del componente.
      backgroundColor: morado,
      // Color de su texto e iconos.
      foregroundColor: Colors.white,
    ),
    // Configura las casillas de selección.
    checkboxTheme: CheckboxThemeData(
      // Define el relleno; en CheckboxTheme puede variar según el estado.
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        // Recibe los estados actuales de la casilla y elige el color que corresponda.
        (estados) {
          // Comprueba si la casilla está deshabilitada.
          if (estados.contains(WidgetState.disabled)) {
            // Deja que Flutter utilice el color predeterminado para este estado.
            return null;
          }
          // Comprueba si la casilla está seleccionada para utilizar el color morado.
          return estados.contains(WidgetState.selected)
              // Si está seleccionada, utiliza morado.
              ? morado
              // Si no lo está, deja que Flutter resuelva su color predeterminado.
              : null;
        },
      ),
      // Color de la marca que indica una casilla seleccionada.
      checkColor: const WidgetStatePropertyAll(Colors.white),
    ),
    // Colores de los indicadores de carga.
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      // Color del texto, borde o efecto que se está configurando.
      color: lila,
      // Color de la pista del indicador lineal.
      linearTrackColor: moradoOscuro,
      // Color de la pista del indicador circular.
      circularTrackColor: moradoOscuro,
    ),
    // Configura el cursor y la selección del texto editable.
    textSelectionTheme: const TextSelectionThemeData(
      // Color de la línea que indica dónde se escribe.
      cursorColor: lila,
      // Color del fondo del texto seleccionado.
      selectionColor: Color(0x667C3AED),
      // Color de los controles para ampliar o reducir la selección.
      selectionHandleColor: lila,
    ),
    // Estilo común de los separadores.
    dividerTheme: const DividerThemeData(
      // Color del texto, borde o efecto que se está configurando.
      color: borde,
      // Grosor de la línea del separador.
      thickness: 1,
    ),
    // Apariencia de los mensajes temporales SnackBar.
    snackBarTheme: const SnackBarThemeData(
      // Color de fondo del componente.
      backgroundColor: Color(0xFF29203C),
      // Estilo del texto del mensaje temporal.
      contentTextStyle: TextStyle(
        // Color del texto, borde o efecto que se está configurando.
        color: texto,
        // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
        fontSize: 14,
      ),
      // Color de la acción del mensaje temporal.
      actionTextColor: lila,
      // floating hace que el mensaje aparezca separado de los bordes de la pantalla.
      behavior: SnackBarBehavior.floating,
    ),
    // Estilo de la barra inferior NavigationBar.
    navigationBarTheme: const NavigationBarThemeData(
      // Color de fondo del componente.
      backgroundColor: fondo,
      // Controla el tinte de elevación; transparente evita que cambie el color elegido.
      surfaceTintColor: Colors.transparent,
      // Color que destaca el destino seleccionado en la barra inferior.
      indicatorColor: moradoOscuro,
    ),
  );
}
// Agrupa los estilos reutilizados por el panel administrativo.
class SpookyPanelEstilos {
  // Constructor privado: evita crear instancias de esta clase que solo agrupa estilos estáticos.
  SpookyPanelEstilos._();
  // Espacio vertical reutilizable de 24 unidades lógicas.
  static const separacion = SizedBox(height: 24);
  // Espacio vertical reutilizable de 16 unidades lógicas.
  static const separacionCorta = SizedBox(height: 16);
  // Margen general de esta sección.
  static const margen = EdgeInsets.all(20);
  // Espacio interior de las tarjetas que utilicen esta constante.
  static const margenTarjeta = EdgeInsets.all(24);
  // Fondo principal o decoración de fondo de esta sección.
  static const fondo = BoxDecoration(
    // Crea una transición entre varios colores.
    gradient: LinearGradient(
      // Punto donde empieza el degradado.
      begin: Alignment.topCenter,
      // Punto donde termina el degradado.
      end: Alignment.bottomCenter,
      // Lista de colores del degradado, en su orden de aparición.
      colors: [
        Color(0xFF1C102D),
        SpookyTema.fondo,
        SpookyTema.fondo,
      ],
      // Ubicación de cada color en el recorrido, usando valores entre 0 y 1.
      stops: [0, 0.35, 1],
    ),
  );
  // Decoración reutilizable de las tarjetas de esta sección.
  static final tarjeta = BoxDecoration(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.superficie,
    // Redondea las esquinas del elemento con el radio indicado.
    borderRadius: BorderRadius.circular(18),
    // Define el contorno de la decoración o el borde del campo de texto.
    border: Border.all(color: SpookyTema.borde),
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: const [
      BoxShadow(
        // Color del texto, borde o efecto que se está configurando.
        color: Color(0x22000000),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 18,
        // Desplaza la sombra horizontal y verticalmente.
        offset: Offset(0, 8),
      ),
    ],
  );
  // Estilo de texto del nombre de la aplicación; no carga una imagen.
  static const logo = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 25,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.w900,
    // Separación adicional entre las letras.
    letterSpacing: 2,
    // Agrega sombras al texto.
    shadows: [
      Shadow(
        // Color del texto, borde o efecto que se está configurando.
        color: Color(0x667C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 12,
      ),
    ],
  );
  // Estilo del título principal del panel.
  static const tituloPrincipal = TextStyle(
    // Solicita la familia serif; su apariencia depende de las fuentes disponibles y de su configuración en la app.
    fontFamily: 'serif',
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.lila,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 25,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.6,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.3,
  );
  // Estilo de los títulos de los módulos administrativos.
  static const tituloModulo = TextStyle(
    // Solicita la familia serif; su apariencia depende de las fuentes disponibles y de su configuración en la app.
    fontFamily: 'serif',
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.lila,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 22,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.4,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.3,
  );
  // Estilo de los textos descriptivos.
  static const descripcion = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.textoSecundario,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.6,
  );
  // Estilo para destacar el nombre de la cuenta.
  static const nombreUsuario = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
  );
  // Decoración que añade un resplandor alrededor del botón.
  static const resplandorBoton = BoxDecoration(
    // Redondea las esquinas del elemento con el radio indicado.
    borderRadius: BorderRadius.all(Radius.circular(14)),
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: [
      BoxShadow(
        // Color del texto, borde o efecto que se está configurando.
        color: Color(0x447C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 16,
        // Desplaza la sombra horizontal y verticalmente.
        offset: Offset(0, 4),
      ),
    ],
  );
  // Estilo reutilizable para los botones de esta sección.
  static final boton = FilledButton.styleFrom(
    // Color de fondo del componente.
    backgroundColor: SpookyTema.morado,
    // Color de su texto e iconos.
    foregroundColor: Colors.white,
    // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
    minimumSize: const Size(double.infinity, 52),
    // Espacio interior alrededor del contenido.
    padding: const EdgeInsets.symmetric(
      // Espacio aplicado a izquierda y derecha.
      horizontal: 16,
      // Espacio aplicado arriba y abajo.
      vertical: 14,
    ),
    // Estilo del texto del botón.
    textStyle: const TextStyle(
      // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
      fontSize: 15,
      // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
      fontWeight: FontWeight.bold,
    ),
    // Define la forma del componente y, cuando corresponde, su contorno.
    shape: RoundedRectangleBorder(
      // Redondea las esquinas del elemento con el radio indicado.
      borderRadius: BorderRadius.circular(14),
    ),
  );
  // Estilo del botón para salir; la lógica de cierre de sesión está en la pantalla.
  static final botonSalir = TextButton.styleFrom(
    // Color de fondo del componente.
    backgroundColor: SpookyTema.moradoOscuro,
    // Color de su texto e iconos.
    foregroundColor: SpookyTema.texto,
    // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
    minimumSize: const Size(48, 48),
    // Espacio interior alrededor del contenido.
    padding: const EdgeInsets.symmetric(horizontal: 16),
    // Define la forma del componente y, cuando corresponde, su contorno.
    shape: RoundedRectangleBorder(
      // Redondea las esquinas del elemento con el radio indicado.
      borderRadius: BorderRadius.circular(14),
      // Define el color y grosor del borde.
      side: const BorderSide(color: SpookyTema.borde),
    ),
  );
  // Decoración de la línea del encabezado.
  static const bordeEncabezado = BoxDecoration(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.morado,
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: [
      BoxShadow(
        // Color del texto, borde o efecto que se está configurando.
        color: Color(0x557C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 12,
      ),
    ],
  );
  // Altura de la línea del encabezado.
  static const double altoBorde = 1;
}
// Agrupa estilos de Inicio, catálogo, buscador y navegación del lector.
class SpookyLectorEstilos {
  // Constructor privado: evita crear instancias de esta clase que solo agrupa estilos estáticos.
  SpookyLectorEstilos._();
  // Margen general de esta sección.
  static const margen = EdgeInsets.all(20);
  // Separación reutilizable entre elementos.
  static const espacio = SizedBox(height: 20);
  // Fondo principal o decoración de fondo de esta sección.
  static const fondo = BoxDecoration(
    // Crea una transición entre varios colores.
    gradient: LinearGradient(
      // Punto donde empieza el degradado.
      begin: Alignment.topCenter,
      // Punto donde termina el degradado.
      end: Alignment.bottomCenter,
      // Lista de colores del degradado, en su orden de aparición.
      colors: [
        Color(0xFF171023),
        SpookyTema.fondo,
        SpookyTema.fondo,
      ],
      // Ubicación de cada color en el recorrido, usando valores entre 0 y 1.
      stops: [0, 0.4, 1],
    ),
  );
  // Oscurece progresivamente la portada para facilitar la lectura del texto colocado encima.
  static const degradadoPortada = BoxDecoration(
    // Crea una transición entre varios colores.
    gradient: LinearGradient(
      // Punto donde empieza el degradado.
      begin: Alignment.topCenter,
      // Punto donde termina el degradado.
      end: Alignment.bottomCenter,
      // Lista de colores del degradado, en su orden de aparición.
      colors: [
        Color(0x11090810),
        Color(0xCC100B1B),
        SpookyTema.fondo,
      ],
      // Ubicación de cada color en el recorrido, usando valores entre 0 y 1.
      stops: [0, 0.5, 1],
    ),
  );
  // Decoración reutilizable de las tarjetas de esta sección.
  static final tarjeta = SpookyTema.tarjetaNeon;
  // Estilo del título de la reseña destacada.
  static const tituloDestacada = TextStyle(
    // Solicita la familia serif; su apariencia depende de las fuentes disponibles y de su configuración en la app.
    fontFamily: 'serif',
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 32,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.2,
  );
  // Estilo del encabezado de sección.
  static const tituloSeccion = TextStyle(
    // Solicita la familia serif; su apariencia depende de las fuentes disponibles y de su configuración en la app.
    fontFamily: 'serif',
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 22,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.5,
  );
  // Estilo del título dentro de una tarjeta.
  static const tituloTarjeta = TextStyle(
    // Solicita la familia serif; su apariencia depende de las fuentes disponibles y de su configuración en la app.
    fontFamily: 'serif',
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 19,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.3,
  );
  // Estilo de los textos descriptivos.
  static const descripcion = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.textoSecundario,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.5,
  );
  // Estilo del texto de una etiqueta.
  static const etiquetaTexto = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.lila,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 12,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.4,
  );
  // Decoración del fondo y borde de una etiqueta.
  static final etiqueta = BoxDecoration(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.moradoOscuro,
    // Redondea las esquinas del elemento con el radio indicado.
    borderRadius: BorderRadius.circular(12),
    // Define el contorno de la decoración o el borde del campo de texto.
    border: Border.all(color: SpookyTema.borde),
  );
  // Espacio interior de las etiquetas.
  static const margenEtiqueta = EdgeInsets.symmetric(
    // Espacio aplicado a izquierda y derecha.
    horizontal: 10,
    // Espacio aplicado arriba y abajo.
    vertical: 6,
  );
  // Línea de acento situada a la izquierda del título.
  static const bordeTitulo = BoxDecoration(
    // Define el contorno de la decoración o el borde del campo de texto.
    border: Border(
      // Configura el borde del lado izquierdo.
      left: BorderSide(
        // Color del texto, borde o efecto que se está configurando.
        color: SpookyTema.morado,
        // Grosor del borde o ancho del elemento, según el objeto que lo contiene.
        width: 4,
      ),
    ),
  );
  // Separación entre la línea de acento y el título.
  static const margenTitulo = EdgeInsets.only(left: 12);
  // Estilo reutilizable para los botones de esta sección.
  static final boton = FilledButton.styleFrom(
    // Color de fondo del componente.
    backgroundColor: SpookyTema.morado,
    // Color de su texto e iconos.
    foregroundColor: Colors.white,
    // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
    minimumSize: const Size(48, 52),
    // Espacio interior alrededor del contenido.
    padding: const EdgeInsets.symmetric(
      // Espacio aplicado a izquierda y derecha.
      horizontal: 20,
      // Espacio aplicado arriba y abajo.
      vertical: 14,
    ),
    // Define la forma del componente y, cuando corresponde, su contorno.
    shape: RoundedRectangleBorder(
      // Redondea las esquinas del elemento con el radio indicado.
      borderRadius: BorderRadius.circular(14),
    ),
    // Estilo del texto del botón.
    textStyle: const TextStyle(
      // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
      fontSize: 15,
      // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
      fontWeight: FontWeight.bold,
    ),
  );
  // Decoración del campo de búsqueda; el filtrado se implementa en la pantalla.
  static final buscador = InputDecoration(
    // Texto de orientación; no ejecuta la búsqueda ni define qué campos se consultan.
    hintText: 'Buscar por título o director…',
    // Icono que aparece al inicio del campo de búsqueda.
    prefixIcon: const Icon(
      Icons.search,
      // Color del texto, borde o efecto que se está configurando.
      color: SpookyTema.lila,
    ),
    // Activa el relleno del campo de texto.
    filled: true,
    // Define el relleno; en CheckboxTheme puede variar según el estado.
    fillColor: SpookyTema.campo,
    // Define el contorno de la decoración o el borde del campo de texto.
    border: OutlineInputBorder(
      // Redondea las esquinas del elemento con el radio indicado.
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SpookyTema.borde),
    ),
    // Borde del campo habilitado cuando no tiene el foco.
    enabledBorder: OutlineInputBorder(
      // Redondea las esquinas del elemento con el radio indicado.
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SpookyTema.borde),
    ),
    // Borde del campo que está seleccionado para escribir.
    focusedBorder: OutlineInputBorder(
      // Redondea las esquinas del elemento con el radio indicado.
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        // Color del texto, borde o efecto que se está configurando.
        color: SpookyTema.lila,
        // Grosor del borde o ancho del elemento, según el objeto que lo contiene.
        width: 2,
      ),
    ),
  );
  // Tema de la barra inferior, cuando la pantalla lo utiliza.
  static const barraNavegacion = NavigationBarThemeData(
    // Color de fondo del componente.
    backgroundColor: SpookyTema.fondo,
    // Controla el tinte de elevación; transparente evita que cambie el color elegido.
    surfaceTintColor: Colors.transparent,
    // Color que destaca el destino seleccionado en la barra inferior.
    indicatorColor: SpookyTema.moradoOscuro,
  );
}
// Agrupa estilos de la pantalla de detalle de una reseña.
class SpookyDetalleEstilos {
  // Constructor privado: evita crear instancias de esta clase que solo agrupa estilos estáticos.
  SpookyDetalleEstilos._();
  // Margen uniforme de las pantallas que utilizan este valor.
  static const margenPantalla = EdgeInsets.all(20);
  // Espacio interior del panel de detalle.
  static const margenPanel = EdgeInsets.all(20);
  // Separación vertical alrededor de los comentarios.
  static const margenComentario = EdgeInsets.symmetric(vertical: 18);
  // Separación reutilizable entre elementos.
  static const espacio = SizedBox(height: 20);
  // Separación vertical corta.
  static const espacioCorto = SizedBox(height: 10);
  // Separación horizontal entre elementos.
  static const espacioHorizontal = SizedBox(width: 16);
  // Radio de las esquinas de la portada.
  static const double radioPortada = 14;
  // Tamaño solicitado a la fotografía de la ficha.
  static const double tamanoFoto = 72;
  // Ancho de referencia de la portada; las restricciones del widget determinan su tamaño final.
  static const double anchoPortada = 360;
  // Decoración del panel de detalle.
  static final panel = BoxDecoration(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.superficie,
    // Redondea las esquinas del elemento con el radio indicado.
    borderRadius: BorderRadius.circular(18),
    // Define el contorno de la decoración o el borde del campo de texto.
    border: Border.all(color: SpookyTema.borde),
  );
  // Decoración de la ficha de información del director.
  static final fichaDirector = BoxDecoration(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.campo,
    // Redondea las esquinas del elemento con el radio indicado.
    borderRadius: BorderRadius.circular(16),
    // Define el contorno de la decoración o el borde del campo de texto.
    border: Border.all(color: SpookyTema.borde),
  );
  // Contorno circular de la fotografía.
  static final marcoFoto = BoxDecoration(
    // Define la forma del componente y, cuando corresponde, su contorno.
    shape: BoxShape.circle,
    // Define el contorno de la decoración o el borde del campo de texto.
    border: Border.all(
      // Color del texto, borde o efecto que se está configurando.
      color: SpookyTema.morado,
      // Grosor del borde o ancho del elemento, según el objeto que lo contiene.
      width: 2,
    ),
  );
  // Color de fondo de la fotografía.
  static const fondoFoto = Color(0xFF292039);
  // Resplandor que acompaña a la portada.
  static const sombraPortada = BoxDecoration(
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: [
      BoxShadow(
        // Color del texto, borde o efecto que se está configurando.
        color: Color(0x337C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 20,
        // Expande la sombra antes de difuminarla.
        spreadRadius: 1,
      ),
    ],
    // Redondea las esquinas del elemento con el radio indicado.
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  // Estilo del indicador Película o Serie.
  static const tipo = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.lila,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 14,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 1,
  );
  // Estilo del título de la publicación.
  static const titulo = TextStyle(
    // Solicita la familia serif; su apariencia depende de las fuentes disponibles y de su configuración en la app.
    fontFamily: 'serif',
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 30,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.25,
  );
  // Estilo de los encabezados del detalle.
  static const encabezado = TextStyle(
    // Solicita la familia serif; su apariencia depende de las fuentes disponibles y de su configuración en la app.
    fontFamily: 'serif',
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 22,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.4,
  );
  // Estilo del texto de la reseña.
  static const contenido = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: Color(0xFFE4DFF0),
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1.7,
  );
  // Estilo de la etiqueta que identifica al director.
  static const etiquetaDirector = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.textoSecundario,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 12,
    // Separación adicional entre las letras.
    letterSpacing: 0.7,
  );
  // Estilo del nombre del director.
  static const nombreDirector = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.texto,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 18,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
  );
  // Estilo del nombre del autor de un comentario.
  static const autorComentario = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.lila,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 17,
    // Grosor de la letra: bold es negrita y w900 es un grosor más intenso.
    fontWeight: FontWeight.bold,
  );
  // Estilo de la fecha del comentario; no agrega fechas a las publicaciones.
  static const fecha = TextStyle(
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.textoSecundario,
    // Tamaño de la letra en unidades lógicas; la escala de texto del dispositivo puede ampliarlo.
    fontSize: 13,
  );
  // Separador visual de secciones.
  static const separador = Divider(
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 28,
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.borde,
  );
  // Línea que separa los comentarios.
  static const separadorComentarios = Divider(
    // En TextStyle es el multiplicador de altura de línea; en SizedBox o Divider es una altura en unidades lógicas.
    height: 1,
    // Color del texto, borde o efecto que se está configurando.
    color: SpookyTema.borde,
  );
}
// Define el tamaño de los emojis y los botones para elegir una reacción.
class SpookyComentarioEstilos {
  // Estilo del emoji de una reacción.
  static const TextStyle emoji = TextStyle(fontSize: 24);
  // Devuelve el estilo del botón de reacción según si está seleccionado o no.
  static ButtonStyle reaccion(bool seleccionado) {
    // Construye y devuelve el estilo del botón de reacción.
    return OutlinedButton.styleFrom(
      // Tamaño mínimo solicitado para el botón; no fija su tamaño máximo.
      minimumSize: const Size(56, 48),
      // Espacio interior alrededor del contenido.
      padding: const EdgeInsets.symmetric(
        // Espacio aplicado a izquierda y derecha.
        horizontal: 14,
        // Espacio aplicado arriba y abajo.
        vertical: 10,
      ),
      // Color de fondo del componente.
      backgroundColor: seleccionado
          // Si la reacción está seleccionada, aplica un fondo morado oscuro.
          ? SpookyTema.moradoOscuro
          // Si no está seleccionada, utiliza el fondo normal de superficie.
          : SpookyTema.superficie,
      // Define el color y grosor del borde.
      side: BorderSide(
        // Color del texto, borde o efecto que se está configurando.
        color: seleccionado ? SpookyTema.lila : SpookyTema.borde,
        // Grosor del borde o ancho del elemento, según el objeto que lo contiene.
        width: seleccionado ? 2 : 1,
      ),
      // Define la forma del componente y, cuando corresponde, su contorno.
      shape: RoundedRectangleBorder(
        // Redondea las esquinas del elemento con el radio indicado.
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
