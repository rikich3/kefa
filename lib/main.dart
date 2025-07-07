import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

// Importar modelos y adapters
import 'back/dataModels/ingredientes.dart';
import 'back/dataModels/instrumentos.dart';
import 'back/dataModels/worker.dart';
import 'back/dataModels/receta.dart';
import 'back/dataModels/paso.dart';
// TODO: Importar estos cuando estén listos para usar
// import 'back/dataModels/horario_item.dart';
// import 'back/dataModels/cocinero_scheduling.dart';
// import 'back/dataModels/utensilio_scheduling.dart';
// import 'back/dataModels/paso_scheduling.dart';

// Importar data sources
import 'back/data_sources/hive/hive_ingredientes_data_source.dart';
import 'back/data_sources/hive/hive_instrumentos_data_source.dart';
import 'back/data_sources/hive/hive_worker_data_source.dart';
import 'back/data_sources/hive/hive_receta_data_source.dart';
import 'back/data_sources/hive/hive_paso_data_source.dart';
import 'back/data_sources/hive/hive_persistence_manager.dart';

// Importar repositories
import 'back/repositories/ingredientes_repository_impl.dart';
import 'back/repositories/instrumentos_repository.impl.dart';
import 'back/repositories/workers_repository_impl.dart';
import 'back/repositories/receta_repository_impl.dart';
import 'back/repositories/paso_repository_impl.dart';

// Importar providers
import 'front/state/ingredientes_provider.dart';
import 'front/state/instrumentos_provider.dart';
import 'front/state/workers_provider.dart';
import 'front/state/receta_provider.dart';
import 'front/state/paso_provider.dart';

import 'home_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Hive
  await Hive.initFlutter();
  
  // Registrar todos los adapters de Hive
  Hive.registerAdapter(IngredientesAdapter());
  Hive.registerAdapter(WorkerAdapter());
  Hive.registerAdapter(InstrumentoAdapter());
  Hive.registerAdapter(RecetaAdapter());
  Hive.registerAdapter(PasoAdapter());
  Hive.registerAdapter(IngredienteRequeridoAdapter());
  // TODO: Activar estos adapters cuando estén listos para usar
  // Hive.registerAdapter(HorarioItemAdapter());
  // Hive.registerAdapter(CocineroSchedulingAdapter());
  // Hive.registerAdapter(UtensilioSchedulingAdapter());
  // Hive.registerAdapter(PasoSchedulingAdapter());
  
  // Test de persistencia
  print('🔬 Ejecutando test de persistencia...');
  final persistenceTest = await HivePersistenceManager.testPersistence();
  if (!persistenceTest) {
    print('⚠️ ADVERTENCIA: La persistencia puede no funcionar correctamente');
  }
  
  // Diagnóstico inicial
  await HivePersistenceManager.printDiagnostics();
  
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
      labelLarge: TextStyle(fontFamily: 'sans-serif', fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 1.25),
      labelMedium: TextStyle(fontFamily: 'sans-serif', fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 1.5),
      labelSmall: TextStyle(fontFamily: 'sans-serif', fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 1.5),
    );
    final HiveIngredientesDataSource hiveIngredientesDataSource = HiveIngredientesDataSource();
    final IngredientesRepositoryImpl ingredientesRepository = IngredientesRepositoryImpl(hiveDataSource: hiveIngredientesDataSource);
    final HiveInstrumentosDataSource hiveInstrumentosDataSource = HiveInstrumentosDataSource();
    final InstrumentosRepositoryImpl instrumentosRepository = InstrumentosRepositoryImpl(hiveDataSource: hiveInstrumentosDataSource);
    final HiveWorkerDataSource hiveWorkersDataSource = HiveWorkerDataSource();
    final WorkersRepositoryImpl workerRepository = WorkersRepositoryImpl(hiveDataSource: hiveWorkersDataSource);
    final HiveRecetaDataSource hiveRecetaDataSource = HiveRecetaDataSource();
    final RecetaRepositoryImpl recetaRepository = RecetaRepositoryImpl(hiveDataSource: hiveRecetaDataSource);
    final HivePasoDataSource hivePasoDataSource = HivePasoDataSource();
    final PasoRepositoryImpl pasoRepository = PasoRepositoryImpl(hiveDataSource: hivePasoDataSource);

    // Imprimir información de inicio
    print('🚀 Iniciando aplicación Kefa');
    print('📦 Hive inicializado');
    print('🔧 Adapters registrados');
    print('📋 Providers configurados');

    return 
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          print('🔄 Creando IngredientesProvider');
          return IngredientesProvider(ingredientRepository: ingredientesRepository);
        }),
        ChangeNotifierProvider(create: (_) {
          print('🔄 Creando InstrumentosProvider');
          return InstrumentosProvider(instrumentosRepository: instrumentosRepository);
        }),
        ChangeNotifierProvider(create: (_) {
          print('🔄 Creando WorkersProvider');
          return WorkersProvider(workerRepository: workerRepository);
        }),
        ChangeNotifierProvider(create: (_) {
          print('🔄 Creando RecetaProvider');
          return RecetaProvider(
            recetaRepository: recetaRepository,
            pasoRepository: pasoRepository,
          );
        }),
        ChangeNotifierProvider(create: (_) {
          print('🔄 Creando PasoProvider');
          return PasoProvider(pasoRepository: pasoRepository);
        }),
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