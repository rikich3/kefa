import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Importar google_fonts
import 'home_page.dart'; // Importar la pantalla principal
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Elegimos una fuente serif de Google Fonts para títulos/subtítulos
    // Y usamos la fuente por defecto de Material Design (generalmente Roboto/system sans-serif)
    // para el resto del texto.
    final TextTheme myTextTheme = TextTheme(
      displayLarge: TextStyle(fontFamily: 'serif', fontSize: 96, fontWeight: FontWeight.w300, letterSpacing: -1.5),
      displayMedium: TextStyle(fontFamily: 'serif', fontSize: 60, fontWeight: FontWeight.w300, letterSpacing: -0.5),
      displaySmall: TextStyle(fontFamily: 'serif', fontSize: 48, fontWeight: FontWeight.w400),
      headlineLarge: TextStyle(fontFamily: 'serif', fontSize: 40, fontWeight: FontWeight.w400),
      headlineMedium: TextStyle(fontFamily: 'serif', fontSize: 34, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      headlineSmall: TextStyle(fontFamily: 'serif', fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0.15),
      titleMedium: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.15),
      titleSmall: TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
      bodyLarge: TextStyle(fontFamily: 'sans-serif', fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
      bodyMedium: TextStyle(fontFamily: 'sans-serif', fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
      bodySmall: TextStyle(fontFamily: 'sans-serif', fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),
      labelLarge: TextStyle(fontFamily: 'sans-serif', fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 1.25),
      labelMedium: TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 1.5),
      labelSmall: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
    );

    return MaterialApp(
      title: 'kefa, cocina virtual',
      // Habilitar Material Design 3
      theme: ThemeData(
        useMaterial3: true,
        // Generar paleta de colores M3 basada en un color semilla (morado)
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        // Aplicar la tipografía personalizada
        textTheme: myTextTheme,
        // Puedes ajustar otros aspectos del tema aquí si es necesario
      ),
      // Opcional: Configurar un tema oscuro si lo deseas
      darkTheme: ThemeData(
         useMaterial3: true,
         colorScheme: ColorScheme.fromSeed(seedColor: Colors.white, brightness: Brightness.dark),
         textTheme: myTextTheme, // Usar la misma tipografía, se adapta a colores oscuros
      ),
      // Opcional: Decidir cómo se aplica el tema (sistema, claro, oscuro)
      themeMode: ThemeMode.system, // Seguir la configuración del sistema operativo

      home: const HomePage(), // Establecer la pantalla principal
      debugShowCheckedModeBanner: false, // Ocultar el banner de debug
    );
  }
}