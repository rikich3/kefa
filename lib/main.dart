import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Importar Hive Flutter
import 'package:kefa/back/repositories/workers_repository_impl.dart';
import 'package:provider/provider.dart'; // Importar Provider
import 'package:path_provider/path_provider.dart'; // Importar path_provider para getApplicationDocumentsDirectory
//import 'package:firebase_core/firebase_core.dart'; // Si ya configuraste Firebase
import 'firebase_options.dart'; // Se generará
// Importar los modelos y proveedores que necesitarás
import 'back/dataModels/ingredientes.dart';
import 'back/data_sources/hive/hive_ingredientes_data_source.dart';
import 'back/repositories/ingredientes_repository_impl.dart';
import 'front/state/ingredientes_provider.dart';
import 'back/data_sources/hive/hive_instrumentos_data_source.dart';
import 'back/dataModels/instrumentos.dart';
import 'back/repositories/ingredientes_repository_impl.dart';
import 'front/state/instrumentos_provider.dart';
import 'back/dataModels/worker.dart';
import 'back/data_sources/hive/hive_worker_data_source.dart';
import 'back/repositories/instrumentos_repository.impl.dart';
import 'front/state/workers_provider.dart';

import 'home_page.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  //final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.initFlutter();
  Hive.registerAdapter(IngredientesAdapter());
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
    final HiveIngredientesDataSource hiveIngredientesDataSource = HiveIngredientesDataSource();
    final IngredientesRepositoryImpl ingredientesRepository = IngredientesRepositoryImpl(hiveDataSource: hiveIngredientesDataSource);
    final HiveInstrumentosDataSource hiveInstrumentosDataSource = HiveInstrumentosDataSource();
    final InstrumentosRepositoryImpl instrumentosRepository = InstrumentosRepositoryImpl(hiveDataSource: hiveInstrumentosDataSource);
    final HiveWorkerDataSource hiveWorkersDataSource = HiveWorkerDataSource();
    final WorkersRepositoryImpl workerRepository = WorkersRepositoryImpl(hiveDataSource: hiveWorkersDataSource);

    return 
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) =>
          IngredientesProvider(ingredientRepository: ingredientesRepository)),
        ChangeNotifierProvider(create: (_) =>
          InstrumentosProvider(instrumentosRepository: instrumentosRepository)),
        ChangeNotifierProvider(create: (_) =>
          WorkersProvider(workerRepository: workerRepository))
        ],
      child: MaterialApp(
        title: 'kefa, cocina virtual',
        // Habilitar Material Design 3
        theme: ThemeData(
          useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6699CC), // A desaturated blue
            ),
          // Aplicar la tipografía personalizada
          textTheme: myTextTheme,
          // Puedes ajustar otros aspectos del tema aquí si es necesario
        ),
        // Opcional: Configurar un tema oscuro si lo deseas
        darkTheme: ThemeData(
           useMaterial3: true,
           colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6699CC), brightness: Brightness.dark),
           textTheme: myTextTheme, // Usar la misma tipografía, se adapta a colores oscuros
        ),
        // Opcional: Decidir cómo se aplica el tema (sistema, claro, oscuro)
        themeMode: ThemeMode.system, // Seguir la configuración del sistema operativo
      
        home: const HomePage(), // Establecer la pantalla principal
        debugShowCheckedModeBanner: false, // Ocultar el banner de debug
      ),
    );
  }
}