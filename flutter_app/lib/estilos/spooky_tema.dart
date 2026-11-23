// CRUPPIS — Tema visual de la aplicación móvil.
// Este archivo define apariencia; no consulta la API, no guarda datos y no controla sesiones.
// Se mantienen los nombres Spooky... porque las pantallas existentes los referencian.
// Cambiarlos requiere actualizar todas esas referencias en el proyecto.
// static permite acceder con Clase.propiedad sin crear un objeto.
// const define valores constantes; final permite inicializarlos una vez durante la ejecución.
// Las medidas son unidades lógicas de Flutter, no píxeles físicos del teléfono.
// En Color(0xAARRGGBB), AA es opacidad y RR/GG/BB son rojo, verde y azul.
// Las líneas con ), ], }; o } cierran el bloque iniciado anteriormente.


import 'package:flutter/material.dart';
// Centraliza la paleta y el tema oscuro general de Cruppis.
class SpookyTema {
  // El constructor con _ impide crear objetos de esta clase desde otros archivos; aquí solo agrupamos estilos.
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
  // Conserva el nombre rojo para las pantallas que lo utilizan; el color aplicado es morado.
  static const rojo = morado;
  // Conserva el nombre rojoOscuro para las pantallas que lo utilizan; aplica morado oscuro.
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
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 24,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Asigna el color a este elemento.
    color: texto,
  );
  // Estilo del título dentro de una tarjeta.
  static const tituloTarjeta = TextStyle(
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 17,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Asigna el color a este elemento.
    color: texto,
  );
  // Estilo general de los textos descriptivos.
  static const textoDescripcion = TextStyle(
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.5,
    // Asigna el color a este elemento.
    color: textoSecundario,
  );
  // Borde neón para las tarjetas del catálogo.
  // Decoración de tarjeta con contorno y dos sombras moradas.
  static final tarjetaNeon = BoxDecoration(
    // Asigna el color a este elemento.
    color: superficie,
    // Redondea las esquinas; un radio mayor produce una curva más amplia.
    borderRadius: BorderRadius.circular(16),
    // Configura el contorno de este elemento.
    border: Border.all(
      // Asigna el color a este elemento.
      color: const Color(0xFF9D62FF),
      // Establece el grosor del borde.
      width: 1.2,
    ),
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: const [
      BoxShadow(
        // Asigna el color a este elemento.
        color: Color(0x557C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 14,
        // Expande la sombra antes de difuminarla.
        spreadRadius: 1,
      ),
      BoxShadow(
        // Asigna el color a este elemento.
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
    // Utiliza Material 3, el conjunto de componentes y reglas visuales de Flutter.
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
      // Evita que el efecto de elevación añada un tinte al color elegido.
      surfaceTintColor: Colors.transparent,
      // Determina si el título de la barra superior se centra.
      centerTitle: false,
      // La elevación da apariencia de profundidad; cero elimina su sombra.
      elevation: 0,
      // Elevación de la barra cuando el contenido se desplaza debajo de ella.
      scrolledUnderElevation: 0,
      // Estilo del título de la barra superior.
      titleTextStyle: TextStyle(
        // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
        fontSize: 21,
        // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
        fontWeight: FontWeight.bold,
        // Asigna el color a este elemento.
        color: texto,
        // Separación adicional entre las letras.
        letterSpacing: 0.5,
      ),
    ),
    // Configura la apariencia predeterminada de los widgets Card.
    cardTheme: CardThemeData(
      // Asigna el color a este elemento.
      color: superficie,
      // Evita que el efecto de elevación añada un tinte al color elegido.
      surfaceTintColor: Colors.transparent,
      // La elevación da apariencia de profundidad; cero elimina su sombra.
      elevation: 0,
      // Define la forma del componente y, cuando corresponde, su contorno.
      shape: RoundedRectangleBorder(
        // Redondea las esquinas; un radio mayor produce una curva más amplia.
        borderRadius: BorderRadius.circular(radio),
        // Define el color y grosor del borde.
        side: const BorderSide(color: borde),
      ),
    ),
    // Estilo común de los campos de formulario.
    inputDecorationTheme: InputDecorationTheme(
      // Activa el relleno del campo de texto.
      filled: true,
      // Asigna el color del fondo del campo o de la casilla.
      fillColor: campo,
      // Estilo de la etiqueta del campo.
      labelStyle: const TextStyle(color: textoSecundario),
      // Estilo de la etiqueta cuando flota encima del campo.
      floatingLabelStyle: const TextStyle(color: lila),
      // Estilo de la indicación que aparece cuando el campo está vacío.
      hintStyle: const TextStyle(color: textoSecundario),
      // Estilo del texto de ayuda del campo.
      helperStyle: const TextStyle(color: textoSecundario),
      // Espacio interior entre el borde del campo y su contenido.
      contentPadding: const EdgeInsets.all(16),
      // Configura el contorno de este elemento.
      border: OutlineInputBorder(
        // Redondea las esquinas; un radio mayor produce una curva más amplia.
        borderRadius: BorderRadius.circular(radio),
        borderSide: const BorderSide(color: borde),
      ),
      // Borde del campo habilitado cuando no tiene el foco.
      enabledBorder: OutlineInputBorder(
        // Redondea las esquinas; un radio mayor produce una curva más amplia.
        borderRadius: BorderRadius.circular(radio),
        borderSide: const BorderSide(color: borde),
      ),
      // Borde del campo que está seleccionado para escribir.
      focusedBorder: OutlineInputBorder(
        // Redondea las esquinas; un radio mayor produce una curva más amplia.
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
        // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
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
          // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
          fontSize: 16,
          // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
          fontWeight: FontWeight.bold,
        ),
        // Define la forma del componente y, cuando corresponde, su contorno.
        shape: RoundedRectangleBorder(
          // Redondea las esquinas; un radio mayor produce una curva más amplia.
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
        // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
        minimumSize: const Size(areaTactil, areaTactil),
        // Define el color y grosor del borde.
        side: const BorderSide(color: morado),
        // Define la forma del componente y, cuando corresponde, su contorno.
        shape: RoundedRectangleBorder(
          // Redondea las esquinas; un radio mayor produce una curva más amplia.
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
        // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
        minimumSize: const Size(areaTactil, areaTactil),
      ),
    ),
    // Estilo común de los botones que muestran un icono.
    iconButtonTheme: IconButtonThemeData(
      // Construye la configuración visual del botón.
      style: IconButton.styleFrom(
        // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
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
      // Asigna el color del fondo del campo o de la casilla.
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
      // Asigna el color a este elemento.
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
      // Asigna el color a este elemento.
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
        // Asigna el color a este elemento.
        color: texto,
        // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
        fontSize: 14,
      ),
      // Color de la acción del mensaje temporal.
      actionTextColor: lila,
      // floating muestra el aviso separado de los bordes de la pantalla.
      behavior: SnackBarBehavior.floating,
    ),
    // Estilo de la barra inferior NavigationBar.
    navigationBarTheme: const NavigationBarThemeData(
      // Color de fondo del componente.
      backgroundColor: fondo,
      // Evita que el efecto de elevación añada un tinte al color elegido.
      surfaceTintColor: Colors.transparent,
      // Color que destaca el destino seleccionado en la barra inferior.
      indicatorColor: moradoOscuro,
    ),
  );
}
// Agrupa los estilos reutilizados por el panel administrativo.
class SpookyPanelEstilos {
  // El constructor con _ impide crear objetos de esta clase desde otros archivos; aquí solo agrupamos estilos.
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
    // Asigna el color a este elemento.
    color: SpookyTema.superficie,
    // Redondea las esquinas; un radio mayor produce una curva más amplia.
    borderRadius: BorderRadius.circular(18),
    // Configura el contorno de este elemento.
    border: Border.all(color: SpookyTema.borde),
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: const [
      BoxShadow(
        // Asigna el color a este elemento.
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
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 25,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.w900,
    // Separación adicional entre las letras.
    letterSpacing: 2,
    // Agrega sombras al texto.
    shadows: [
      Shadow(
        // Asigna el color a este elemento.
        color: Color(0x667C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 12,
      ),
    ],
  );
  // Estilo del título principal del panel.
  static const tituloPrincipal = TextStyle(
    // Solicita la fuente serif, con remates en las letras; su aspecto depende de las fuentes configuradas.
    fontFamily: 'serif',
    // Asigna el color a este elemento.
    color: SpookyTema.lila,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 25,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.6,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.3,
  );
  // Estilo de los títulos de los módulos administrativos.
  static const tituloModulo = TextStyle(
    // Solicita la fuente serif, con remates en las letras; su aspecto depende de las fuentes configuradas.
    fontFamily: 'serif',
    // Asigna el color a este elemento.
    color: SpookyTema.lila,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 22,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.4,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.3,
  );
  // Estilo de los textos descriptivos.
  static const descripcion = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.textoSecundario,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.6,
  );
  // Estilo para destacar el nombre de la cuenta.
  static const nombreUsuario = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
  );
  // Decoración que añade un resplandor alrededor del botón.
  static const resplandorBoton = BoxDecoration(
    // Redondea las esquinas; un radio mayor produce una curva más amplia.
    borderRadius: BorderRadius.all(Radius.circular(14)),
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: [
      BoxShadow(
        // Asigna el color a este elemento.
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
    // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
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
      // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
      fontSize: 15,
      // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
      fontWeight: FontWeight.bold,
    ),
    // Define la forma del componente y, cuando corresponde, su contorno.
    shape: RoundedRectangleBorder(
      // Redondea las esquinas; un radio mayor produce una curva más amplia.
      borderRadius: BorderRadius.circular(14),
    ),
  );
  // Estilo del botón para salir; la lógica de cierre de sesión está en la pantalla.
  static final botonSalir = TextButton.styleFrom(
    // Color de fondo del componente.
    backgroundColor: SpookyTema.moradoOscuro,
    // Color de su texto e iconos.
    foregroundColor: SpookyTema.texto,
    // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
    minimumSize: const Size(48, 48),
    // Espacio interior alrededor del contenido.
    padding: const EdgeInsets.symmetric(horizontal: 16),
    // Define la forma del componente y, cuando corresponde, su contorno.
    shape: RoundedRectangleBorder(
      // Redondea las esquinas; un radio mayor produce una curva más amplia.
      borderRadius: BorderRadius.circular(14),
      // Define el color y grosor del borde.
      side: const BorderSide(color: SpookyTema.borde),
    ),
  );
  // Decoración de la línea del encabezado.
  static const bordeEncabezado = BoxDecoration(
    // Asigna el color a este elemento.
    color: SpookyTema.morado,
    // Agrega las sombras que producen profundidad o resplandor.
    boxShadow: [
      BoxShadow(
        // Asigna el color a este elemento.
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
  // El constructor con _ impide crear objetos de esta clase desde otros archivos; aquí solo agrupamos estilos.
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
  // Estilo del título del banner principal. El nombre no guarda ni consulta una marca en la base de datos.
  static const tituloDestacada = TextStyle(
    // Solicita la fuente serif, con remates en las letras; su aspecto depende de las fuentes configuradas.
    fontFamily: 'serif',
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 32,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.2,
  );
  // Estilo del encabezado de sección.
  static const tituloSeccion = TextStyle(
    // Solicita la fuente serif, con remates en las letras; su aspecto depende de las fuentes configuradas.
    fontFamily: 'serif',
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 22,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.5,
  );
  // Estilo del título dentro de una tarjeta.
  static const tituloTarjeta = TextStyle(
    // Solicita la fuente serif, con remates en las letras; su aspecto depende de las fuentes configuradas.
    fontFamily: 'serif',
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 19,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.3,
  );
  // Estilo de los textos descriptivos.
  static const descripcion = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.textoSecundario,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.5,
  );
  // Estilo del texto de una etiqueta.
  static const etiquetaTexto = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.lila,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 12,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.4,
  );
  // Decoración del fondo y borde de una etiqueta.
  static final etiqueta = BoxDecoration(
    // Asigna el color a este elemento.
    color: SpookyTema.moradoOscuro,
    // Redondea las esquinas; un radio mayor produce una curva más amplia.
    borderRadius: BorderRadius.circular(12),
    // Configura el contorno de este elemento.
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
    // Configura el contorno de este elemento.
    border: Border(
      // Configura el borde del lado izquierdo.
      left: BorderSide(
        // Asigna el color a este elemento.
        color: SpookyTema.morado,
        // Establece el grosor del borde.
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
    // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
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
      // Redondea las esquinas; un radio mayor produce una curva más amplia.
      borderRadius: BorderRadius.circular(14),
    ),
    // Estilo del texto del botón.
    textStyle: const TextStyle(
      // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
      fontSize: 15,
      // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
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
      // Asigna el color a este elemento.
      color: SpookyTema.lila,
    ),
    // Activa el relleno del campo de texto.
    filled: true,
    // Asigna el color del fondo del campo o de la casilla.
    fillColor: SpookyTema.campo,
    // Configura el contorno de este elemento.
    border: OutlineInputBorder(
      // Redondea las esquinas; un radio mayor produce una curva más amplia.
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SpookyTema.borde),
    ),
    // Borde del campo habilitado cuando no tiene el foco.
    enabledBorder: OutlineInputBorder(
      // Redondea las esquinas; un radio mayor produce una curva más amplia.
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: SpookyTema.borde),
    ),
    // Borde del campo que está seleccionado para escribir.
    focusedBorder: OutlineInputBorder(
      // Redondea las esquinas; un radio mayor produce una curva más amplia.
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        // Asigna el color a este elemento.
        color: SpookyTema.lila,
        // Establece el grosor del borde.
        width: 2,
      ),
    ),
  );
  // Tema de la barra inferior, cuando la pantalla lo utiliza.
  static const barraNavegacion = NavigationBarThemeData(
    // Color de fondo del componente.
    backgroundColor: SpookyTema.fondo,
    // Evita que el efecto de elevación añada un tinte al color elegido.
    surfaceTintColor: Colors.transparent,
    // Color que destaca el destino seleccionado en la barra inferior.
    indicatorColor: SpookyTema.moradoOscuro,
  );
}
// Agrupa estilos de la pantalla de detalle de una reseña.
class SpookyDetalleEstilos {
  // El constructor con _ impide crear objetos de esta clase desde otros archivos; aquí solo agrupamos estilos.
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
    // Asigna el color a este elemento.
    color: SpookyTema.superficie,
    // Redondea las esquinas; un radio mayor produce una curva más amplia.
    borderRadius: BorderRadius.circular(18),
    // Configura el contorno de este elemento.
    border: Border.all(color: SpookyTema.borde),
  );
  // Decoración de la ficha de información del director.
  static final fichaDirector = BoxDecoration(
    // Asigna el color a este elemento.
    color: SpookyTema.campo,
    // Redondea las esquinas; un radio mayor produce una curva más amplia.
    borderRadius: BorderRadius.circular(16),
    // Configura el contorno de este elemento.
    border: Border.all(color: SpookyTema.borde),
  );
  // Contorno circular de la fotografía.
  static final marcoFoto = BoxDecoration(
    // Define la forma del componente y, cuando corresponde, su contorno.
    shape: BoxShape.circle,
    // Configura el contorno de este elemento.
    border: Border.all(
      // Asigna el color a este elemento.
      color: SpookyTema.morado,
      // Establece el grosor del borde.
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
        // Asigna el color a este elemento.
        color: Color(0x337C3AED),
        // Controla cuánto se difumina la sombra o el resplandor.
        blurRadius: 20,
        // Expande la sombra antes de difuminarla.
        spreadRadius: 1,
      ),
    ],
    // Redondea las esquinas; un radio mayor produce una curva más amplia.
    borderRadius: BorderRadius.all(Radius.circular(14)),
  );
  // Estilo del indicador Película o Serie.
  static const tipo = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.lila,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 14,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 1,
  );
  // Estilo del título de la publicación.
  static const titulo = TextStyle(
    // Solicita la fuente serif, con remates en las letras; su aspecto depende de las fuentes configuradas.
    fontFamily: 'serif',
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 30,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.25,
  );
  // Estilo de los encabezados del detalle.
  static const encabezado = TextStyle(
    // Solicita la fuente serif, con remates en las letras; su aspecto depende de las fuentes configuradas.
    fontFamily: 'serif',
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 22,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
    // Separación adicional entre las letras.
    letterSpacing: 0.4,
  );
  // Estilo del texto de la reseña.
  static const contenido = TextStyle(
    // Asigna el color a este elemento.
    color: Color(0xFFE4DFF0),
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 16,
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1.7,
  );
  // Estilo de la etiqueta que identifica al director.
  static const etiquetaDirector = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.textoSecundario,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 12,
    // Separación adicional entre las letras.
    letterSpacing: 0.7,
  );
  // Estilo del nombre del director.
  static const nombreDirector = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.texto,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 18,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
  );
  // Estilo del nombre del autor de un comentario.
  static const autorComentario = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.lila,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 17,
    // Define el grosor de las letras: bold es negrita y w900 es un grosor mayor.
    fontWeight: FontWeight.bold,
  );
  // Estilo de la fecha del comentario; no agrega fechas a las publicaciones.
  static const fecha = TextStyle(
    // Asigna el color a este elemento.
    color: SpookyTema.textoSecundario,
    // Define el tamaño de la letra; el ajuste de texto del dispositivo puede ampliarlo.
    fontSize: 13,
  );
  // Separador visual de secciones.
  static const separador = Divider(
    // Define la altura ocupada por el separador, en unidades lógicas.
    height: 28,
    // Asigna el color a este elemento.
    color: SpookyTema.borde,
  );
  // Línea que separa los comentarios.
  static const separadorComentarios = Divider(
    // Ajusta la separación entre líneas con respecto al tamaño de la letra.
    height: 1,
    // Asigna el color a este elemento.
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
      // Solicita este tamaño mínimo para facilitar que se pueda tocar el botón.
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
        // Asigna el color a este elemento.
        color: seleccionado ? SpookyTema.lila : SpookyTema.borde,
        // Establece el grosor del borde.
        width: seleccionado ? 2 : 1,
      ),
      // Define la forma del componente y, cuando corresponde, su contorno.
      shape: RoundedRectangleBorder(
        // Redondea las esquinas; un radio mayor produce una curva más amplia.
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
