// Fixed version of work_tab.dart with firstOrNull replacements
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'front/state/receta_provider.dart';
import 'front/state/paso_provider.dart';
import 'front/state/workers_provider.dart';
import 'front/state/instrumentos_provider.dart';
import 'back/dataModels/paso.dart';
import 'back/dataModels/worker.dart';
import 'back/dataModels/instrumentos.dart';
import 'back/dataModels/cocinero_scheduling.dart';
import 'back/dataModels/utensilio_scheduling.dart';
import 'back/dataModels/paso_scheduling.dart';
import 'back/algorithms/kitchen_scheduling_algorithm.dart';
import 'back/algorithms/scheduling_dinamico_algorithm.dart';
import 'back/algorithms/scheduling_dinamico_algorithm_optimizado.dart';

class WorkTab extends StatefulWidget {
  const WorkTab({super.key});

  @override
  State<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends State<WorkTab> {
  final Map<String, int> _recetasSeleccionadas = {};
  bool _ejecutandoAlgoritmo = false;
  bool _usarAlgoritmoOptimizado = true; // Nueva opción
  bool _usarAlgoritmoDinamico = false; // Algoritmo dinámico con dependencias
  String? _resultadoPlan;
  List<String> _logsProceso = [];
  final SchedulingDinamicoAlgorithm _algoritmoDinamico = SchedulingDinamicoAlgorithm();
  final SchedulingDinamicoAlgorithmOptimizado _algoritmoOptimizado = SchedulingDinamicoAlgorithmOptimizado();

  @override
  void initState() {
    super.initState();
    // Cargar datos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() async {
    final recetaProvider = Provider.of<RecetaProvider>(context, listen: false);
    final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
    final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
    final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

    await Future.wait([
      recetaProvider.loadRecetas(),
      pasoProvider.loadPasos(),
      workersProvider.loadWorkers(),
      instrumentosProvider.loadInstrumentos(),
    ]);

    setState(() {});
  }

  List<CocineroScheduling> _convertirWorkersACocineros(List<Worker> workers) {
    final cocineros = <CocineroScheduling>[];
    
    for (final worker in workers) {
      cocineros.add(CocineroScheduling(
        id: worker.nombre,
        nombre: worker.nombre,
        tipo: 'cocinero', // Los workers son cocineros reales
        ori: 0,
      ));
    }

    // Agregar ollas (asumiendo 2 ollas disponibles)
    cocineros.add(CocineroScheduling(
      id: 'olla1',
      nombre: 'Olla 1',
      tipo: 'olla',
      ori: 0,
    ));
    cocineros.add(CocineroScheduling(
      id: 'olla2',
      nombre: 'Olla 2',
      tipo: 'olla',
      ori: 30, // B2 empieza en 30s como en el ejemplo
    ));

    return cocineros;
  }

  List<UtensilioScheduling> _convertirInstrumentosAUtensilios(List<Instrumento> instrumentos) {
    final utensilios = <UtensilioScheduling>[];
    
    for (final instrumento in instrumentos) {
      // Crear una instancia por cada cantidad disponible
      for (int i = 1; i <= instrumento.cantidad; i++) {
        utensilios.add(UtensilioScheduling(
          id: '${instrumento.nombre}_$i',
          nombre: '${instrumento.nombre} $i',
          tipo: instrumento.nombre,
          ori: 0,
        ));
      }
    }

    return utensilios;
  }

  List<PasoScheduling> _convertirPasosAScheduling(
      Map<String, int> recetas, 
      List<MapEntry<dynamic, Paso>> pasosList,
      List<MapEntry<dynamic, Receta>> recetasList) {
    final pasos = <PasoScheduling>[];
    
    print('🔍 CONVERSION DE PASOS - DEBUG:');
    print('   Recetas y cantidades: $recetas');
    print('   Total pasos disponibles: ${pasosList.length}');
    
    // Para cada receta seleccionada
    for (final entry in recetas.entries) {
      final nombreReceta = entry.key;
      final cantidad = entry.value;
      
      // Buscar la receta por nombre
      final recetaEntry = recetasList
          .where((r) => r.value.nombre == nombreReceta)
          .toList();
      
      if (recetaEntry.isEmpty) {
        print('⚠️ Receta no encontrada: $nombreReceta');
        continue;
      }
      
      final receta = recetaEntry.first.value;
      print('   Procesando receta: "$nombreReceta" x$cantidad');
      
      // Obtener pasos para esta receta
      final pasosDeReceta = pasosList
          .where((p) => receta.pasosIds.contains(p.value.id.toString()))
          .toList();
      
      pasosDeReceta.sort((a, b) => a.value.orden.compareTo(b.value.orden));
      
      print('   Pasos encontrados para "$nombreReceta": ${pasosDeReceta.length}');
      
      // Para cada cantidad de esta receta
      for (int i = 1; i <= cantidad; i++) {
        // Crear el mapeo de IDs originales a IDs únicos para esta instancia de receta
        Map<String, String> idMapping = {};
        
        // Primera pasada: crear los pasos
        for (final pasoEntry in pasosDeReceta) {
          final paso = pasoEntry.value;
          
          print('     - Paso: "${paso.nombrePaso}" (ID: ${paso.id}, Orden: ${paso.orden})');
          print('       Tipo cocinero: ${paso.tipoCocinero}, Tipo utensilio: ${paso.tipoUtensilio}');
          print('       Duracion: ${paso.tiempoPreparacionSegundos}s');
          print('       Dependencias: ${paso.tareasAnterioresDirectas}');
          
          // Crear ID único para este paso en esta instancia de receta
          final idUnico = '${paso.nombrePaso}_plato$i';
          idMapping[paso.id.toString()] = idUnico;
          
          // Guardar las dependencias para la segunda pasada
          print('     🔗 Convirtiendo dependencias: ${paso.tareasAnterioresDirectas}');
          final dependenciasConvertidas = <String>[];
          
          for (final depId in paso.tareasAnterioresDirectas) {
            if (idMapping.containsKey(depId)) {
              print('       ✅ Dependencia convertida: $depId -> ${idMapping[depId]}');
              dependenciasConvertidas.add(idMapping[depId]!);
            } else {
              print('       ⚠️ Dependencia no encontrada en idMapping: $depId');
            }
          }
          
          print('     🔗 Dependencias finales: $dependenciasConvertidas');
          
          // Crear el paso de scheduling
          final pasoScheduling = PasoScheduling(
            id: idUnico,
            nombre: '${paso.nombrePaso} (Plato $i)',
            tipoCocinero: paso.tipoCocinero ?? 'cocinero', // Default a cocinero si es null
            tipoUtensilio: paso.tipoUtensilio ?? 'Bowl',   // Default a Bowl si es null
            duracion: paso.tiempoPreparacionSegundos,
            dependencias: dependenciasConvertidas,
          );
          
          pasos.add(pasoScheduling);
          print('     Agregado: ${pasoScheduling.id}');
        }
      }
    }
    
    print('🔍 PASOS FINALES PARA SCHEDULING: ${pasos.length}');
    for (final paso in pasos) {
      print('   - ${paso.nombre} (${paso.tipoCocinero}, ${paso.tipoUtensilio}, ${paso.duracion}s) - deps: ${paso.dependencias}');
    }
    
    return pasos;
  }

  void _ejecutarAlgoritmoStandard() async {
    if (_recetasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos una receta')),
      );
      return;
    }

    setState(() {
      _ejecutandoAlgoritmo = true;
      _resultadoPlan = null;
      _logsProceso = [];
    });

    try {
      print('🚀 INICIANDO ALGORITMO DE SCHEDULING ESTÁNDAR');
      print('==================================================');
      
      _logsProceso.add('🚀 Iniciando algoritmo de scheduling');
      
      // Obtener los datos necesarios
      final recetaProvider = Provider.of<RecetaProvider>(context, listen: false);
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);
      
      final recetas = await recetaProvider.getAllRecetasWithKeys();
      final pasos = await pasoProvider.getAllPasosWithKeys();
      final workers = await workersProvider.getAllWorkersWithKeys();
      final instrumentos = await instrumentosProvider.getAllInstrumentosWithKeys();

      _logsProceso.add('📊 Datos obtenidos: ${recetas.length} recetas, ${pasos.length} pasos');
      
      // Convertir los datos al formato del algoritmo
      final cocineros = _convertirWorkersACocineros(workers.map((e) => e.value).toList());
      final utensilios = _convertirInstrumentosAUtensilios(instrumentos.map((e) => e.value).toList());
      final pasosScheduling = _convertirPasosAScheduling(_recetasSeleccionadas, pasos, recetas);
      
      print('👨‍🍳 Cocineros disponibles:');
      for (final cocinero in cocineros) {
        print('   - ${cocinero.toString()}');
      }

      print('🔧 Utensilios disponibles:');
      for (final utensilio in utensilios) {
        print('   - ${utensilio.toString()}');
      }

      print('📝 Pasos a ejecutar:');
      for (final paso in pasosScheduling) {
        print('   - ${paso.toString()}');
      }

      _logsProceso.add('👨‍🍳 Cocineros: ${cocineros.length}');
      _logsProceso.add('🔧 Utensilios: ${utensilios.length}');
      _logsProceso.add('📝 Pasos totales: ${pasosScheduling.length}');

      // Crear y ejecutar algoritmo
      final algoritmo = KitchenSchedulingAlgorithm();
      
      algoritmo.inicializarRecursos(
        listaCocineros: cocineros,
        listaUtensilios: utensilios,
        listaPasos: pasosScheduling,
      );

      _logsProceso.add('⚙️ Recursos inicializados');

      // Ejecutar algoritmo (usando el primer paso como raíz por simplicidad)
      if (pasosScheduling.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simular procesamiento
        // Ejecutar algoritmo según configuración
        if (_usarAlgoritmoOptimizado) {
          algoritmo.ejecutarAlgoritmoOptimizado(pasosScheduling.first.id, _recetasSeleccionadas.values.reduce((a, b) => a + b));
        } else {
          algoritmo.ejecutarAlgoritmo(pasosScheduling.first.id, _recetasSeleccionadas.values.reduce((a, b) => a + b));
        }
        
        _logsProceso.add('✅ Algoritmo ejecutado exitosamente');
        
        // Generar resultado visual
        _resultadoPlan = _generarPlanVisual(algoritmo);
        
        print('✅ ALGORITMO COMPLETADO');
        print('=' * 50);
      }

    } catch (e) {
      print('❌ Error en algoritmo: $e');
      _logsProceso.add('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ejecutar algoritmo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _ejecutandoAlgoritmo = false;
        });
      }
    }
  }

  void _ejecutarAlgoritmoDinamico() async {
    if (_recetasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos una receta')),
      );
      return;
    }

    setState(() {
      _ejecutandoAlgoritmo = true;
      _resultadoPlan = null;
      _logsProceso = [];
    });

    try {
      print('🚀 INICIANDO ALGORITMO DINÁMICO DE SCHEDULING');
      print('==================================================');
      
      _logsProceso.add('🚀 Iniciando algoritmo dinámico de scheduling');
      
      // Obtener los datos necesarios
      final recetaProvider = Provider.of<RecetaProvider>(context, listen: false);
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);
      
      final recetas = await recetaProvider.getAllRecetasWithKeys();
      final pasos = await pasoProvider.getAllPasosWithKeys();
      final workers = await workersProvider.getAllWorkersWithKeys();
      final instrumentos = await instrumentosProvider.getAllInstrumentosWithKeys();

      _logsProceso.add('📊 Datos obtenidos: ${recetas.length} recetas, ${pasos.length} pasos');
      
      // Convertir los datos al formato del algoritmo
      final cocineros = _convertirWorkersACocineros(workers.map((e) => e.value).toList());
      final utensilios = _convertirInstrumentosAUtensilios(instrumentos.map((e) => e.value).toList());
      final pasosConvertidos = _convertirPasosAScheduling(_recetasSeleccionadas, pasos, recetas);
      
      _logsProceso.add('👨‍🍳 Cocineros: ${cocineros.length}');
      _logsProceso.add('🔧 Utensilios: ${utensilios.length}');
      _logsProceso.add('📝 Pasos totales: ${pasosConvertidos.length}');

      // Elegir algoritmo basado en configuración
      if (_usarAlgoritmoDinamico && _usarAlgoritmoOptimizado) {
        _logsProceso.add('🚀 Usando algoritmo OPTIMIZADO MEJORADO con detección de camino crítico y validación completa');
        
        // Inicializar algoritmo optimizado
        _algoritmoOptimizado.inicializar(
          pasos: pasosConvertidos,
          cocineros: cocineros,
          utensilios: utensilios,
        );

        _logsProceso.add('⚙️ Algoritmo optimizado inicializado');

        // Ejecutar algoritmo optimizado
        await Future.delayed(const Duration(milliseconds: 500));
        final logsEjecucion = _algoritmoOptimizado.ejecutarCompleto();
        
        _logsProceso.addAll(logsEjecucion);
        _logsProceso.add('✅ Algoritmo optimizado ejecutado exitosamente');
        
        // Generar resultado visual
        _resultadoPlan = _generarPlanVisualOptimizado(_algoritmoOptimizado);
        
        print('✅ ALGORITMO OPTIMIZADO COMPLETADO');
        // No intentamos ejecutar el algoritmo estándar después del optimizado
        // ya que causaría un error de firstOrNull
        
      } else if (_usarAlgoritmoDinamico) {
        _logsProceso.add('⚙️ Usando algoritmo dinámico ESTÁNDAR');
        
        try {
          // Inicializar algoritmo dinámico
          _algoritmoDinamico.inicializar(
            pasos: pasosConvertidos,
            cocineros: cocineros,
            utensilios: utensilios,
          );

          _logsProceso.add('⚙️ Algoritmo dinámico inicializado');

          // Ejecutar algoritmo dinámico
          await Future.delayed(const Duration(milliseconds: 500));
          final logsEjecucion = _algoritmoDinamico.ejecutarCompleto();
          
          _logsProceso.addAll(logsEjecucion);
          _logsProceso.add('✅ Algoritmo dinámico ejecutado exitosamente');
          
          // Generar resultado visual
          _resultadoPlan = _generarPlanVisualDinamico(_algoritmoDinamico);
          
          print('✅ ALGORITMO DINÁMICO COMPLETADO');
        } catch (e) {
          print('❌ Error en algoritmo dinámico: $e');
          _logsProceso.add('❌ Error en algoritmo dinámico: $e');
          rethrow;
        }
      } else {
        // Ejecutar algoritmo estándar
        _ejecutarAlgoritmoStandard();
      }

    } catch (e) {
      print('❌ Error en algoritmo dinámico: $e');
      _logsProceso.add('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ejecutar algoritmo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _ejecutandoAlgoritmo = false;
        });
      }
    }
  }

  String _generarPlanVisual(KitchenSchedulingAlgorithm algoritmo) {
    final buffer = StringBuffer();
    
    buffer.writeln('🚀 PLAN DE COCINA GENERADO');
    buffer.writeln('=' * 40);
    buffer.writeln();
    
    buffer.writeln('👨‍🍳 COCINEROS Y OLLAS:');
    for (final cocinero in algoritmo.cocineros) {
      buffer.writeln('${cocinero.nombre} (${cocinero.tipo}):');
      if (cocinero.horario.isEmpty) {
        buffer.writeln('  Sin tareas asignadas');
      } else {
        for (final item in cocinero.horario) {
          final paso = algoritmo.pasos[item.pasoId];
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln('  Tiempo total ocupado: ${cocinero.ori}s');
      buffer.writeln();
    }
    
    buffer.writeln('🔧 UTENSILIOS:');
    for (final utensilio in algoritmo.utensilios) {
      buffer.writeln('${utensilio.nombre} (${utensilio.tipo}):');
      if (utensilio.horario.isEmpty) {
        buffer.writeln('  Sin uso asignado');
      } else {
        for (final item in utensilio.horario) {
          final pasosPorId = algoritmo.listaPasos.where((p) => p.id == item.pasoId);
          final paso = pasosPorId.isNotEmpty ? pasosPorId.first : null;
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln('  Tiempo total ocupado: ${utensilio.ori}s');
      buffer.writeln();
    }
    
    // Calcular tiempo total
    final tiemposCocineros = algoritmo.cocineros.map((c) => c.ori).toList();
    final tiempoTotal = tiemposCocineros.reduce((a, b) => a > b ? a : b);
    buffer.writeln('⏱️ TIEMPO TOTAL: ${tiempoTotal}s');

    return buffer.toString();
  }

  String _generarPlanVisualDinamico(dynamic algoritmo) {
    final buffer = StringBuffer();
    final estado = algoritmo.estadoActual!;
    
    buffer.writeln('🚀 PLAN DE COCINA DINÁMICO GENERADO');
    buffer.writeln('=' * 50);
    buffer.writeln('⏰ Tiempo total de ejecución: ${estado.tiempoActual} segundos');
    buffer.writeln('✅ Pasos completados: ${estado.pasosCompletados.length}/${estado.todosPasos.length}');
    buffer.writeln();
    
    buffer.writeln('👨‍🍳 COCINEROS Y OLLAS:');
    for (final cocinero in estado.cocineros) {
      buffer.writeln('${cocinero.nombre} (${cocinero.tipo}):');
      if (cocinero.horario.isEmpty) {
        buffer.writeln('  Sin tareas asignadas');
      } else {
        for (final item in cocinero.horario) {
          final pasosPorId = estado.todosPasos.where((p) => p.id == item.pasoId);
          final paso = pasosPorId.isNotEmpty ? pasosPorId.first : null;
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('🔧 UTENSILIOS:');
    for (final utensilio in estado.utensilios) {
      buffer.writeln('${utensilio.nombre} (${utensilio.tipo}):');
      if (utensilio.horario.isEmpty) {
        buffer.writeln('  Sin uso asignado');
      } else {
        for (final item in utensilio.horario) {
          final pasosList = estado.todosPasos.where((p) => p.id == item.pasoId).toList();
          final paso = pasosList.isNotEmpty ? pasosList.first : null;
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('📈 CRONOLOGÍA DE PASOS:');
    final pasosOrdenados = estado.pasosCompletados.toList()
      ..sort((a, b) => (a.tiempoInicio ?? 0).compareTo(b.tiempoInicio ?? 0));
    
    for (final paso in pasosOrdenados) {
      buffer.writeln('T${paso.tiempoInicio}-T${paso.tiempoFin}: ${paso.nombre} (${paso.cocineroAsignado}+${paso.utensilioAsignado})');
    }

    return buffer.toString();
  }

  String _generarPlanVisualOptimizado(dynamic algoritmo) {
    final buffer = StringBuffer();
    final estado = algoritmo.estadoActual!;
    
    buffer.writeln('🚀 PLAN DE COCINA OPTIMIZADO MEJORADO GENERADO');
    buffer.writeln('=' * 50);
    buffer.writeln('⏰ Tiempo total de ejecución: ${estado.tiempoActual} segundos');
    buffer.writeln('✅ Pasos completados: ${estado.pasosCompletados.length}/${estado.todosPasos.length}');
    buffer.writeln('🔥 Algoritmo: OPTIMIZADO MEJORADO con detección de camino crítico');
    buffer.writeln();
    
    buffer.writeln('👨‍🍳 COCINEROS Y OLLAS:');
    for (final cocinero in estado.cocineros) {
      buffer.writeln('${cocinero.nombre} (${cocinero.tipo}):');
      if (cocinero.horario.isEmpty) {
        buffer.writeln('  Sin tareas asignadas');
      } else {
        for (final item in cocinero.horario) {
          final pasosList = estado.todosPasos.where((p) => p.id == item.pasoId).toList();
          final paso = pasosList.isNotEmpty ? pasosList.first : null;
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('🔧 UTENSILIOS:');
    for (final utensilio in estado.utensilios) {
      buffer.writeln('${utensilio.nombre} (${utensilio.tipo}):');
      if (utensilio.horario.isEmpty) {
        buffer.writeln('  Sin uso asignado');
      } else {
        for (final item in utensilio.horario) {
          final pasosList = estado.todosPasos.where((p) => p.id == item.pasoId).toList();
          final paso = pasosList.isNotEmpty ? pasosList.first : null;
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('📈 CRONOLOGÍA DE PASOS:');
    final pasosOrdenados = estado.pasosCompletados.toList()
      ..sort((a, b) => (a.tiempoInicio ?? 0).compareTo(b.tiempoInicio ?? 0));
    
    for (final paso in pasosOrdenados) {
      buffer.writeln('T${paso.tiempoInicio}-T${paso.tiempoFin}: ${paso.nombre} (${paso.cocineroAsignado}+${paso.utensilioAsignado})');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final recetaProvider = Provider.of<RecetaProvider>(context);
    final workersProvider = Provider.of<WorkersProvider>(context);
    final instrumentosProvider = Provider.of<InstrumentosProvider>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            title: const Text('Gestión de Trabajo'),
            floating: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: const Text(
                  'Programa tu cocina de manera eficiente',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          '👨‍🍳 Selecciona las recetas a preparar',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Recetas disponibles
                        const Text(
                          'Recetas disponibles:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        recetaProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recetaProvider.recetas.length,
                              itemBuilder: (context, index) {
                                final receta = recetaProvider.recetas[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    title: Text(receta.nombre),
                                    subtitle: Text('${receta.duracionEstimadaMinutos} minutos'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: _recetasSeleccionadas[receta.nombre] == null || 
                                                    _recetasSeleccionadas[receta.nombre]! <= 0 ? null : () {
                                            setState(() {
                                              if (_recetasSeleccionadas[receta.nombre]! > 0) {
                                                _recetasSeleccionadas[receta.nombre] = _recetasSeleccionadas[receta.nombre]! - 1;
                                                
                                                // Eliminar si llega a 0
                                                if (_recetasSeleccionadas[receta.nombre] == 0) {
                                                  _recetasSeleccionadas.remove(receta.nombre);
                                                }
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                          '${_recetasSeleccionadas[receta.nombre] ?? 0}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            setState(() {
                                              _recetasSeleccionadas[receta.nombre] = (_recetasSeleccionadas[receta.nombre] ?? 0) + 1;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        
                        const SizedBox(height: 16),
                        const Text(
                          'Recursos disponibles:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Mostrar cantidad de cocineros y utensilios
                        Row(
                          children: [
                            Expanded(
                              child: Card(
                                color: Colors.amber.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.people, size: 32, color: Colors.amber),
                                      const Text(
                                        'Cocineros',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${workersProvider.workers.length}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Card(
                                color: Colors.green.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.kitchen, size: 32, color: Colors.green),
                                      const Text(
                                        'Utensilios',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${instrumentosProvider.instrumentos.length}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Usar Algoritmo Dinámico'),
                          subtitle: Text(_usarAlgoritmoDinamico 
                            ? 'Gestión avanzada de dependencias en tiempo real'
                            : 'Algoritmo tradicional de scheduling'),
                          value: _usarAlgoritmoDinamico,
                          onChanged: (value) {
                            setState(() {
                              _usarAlgoritmoDinamico = value;
                            });
                          },
                        ),
                        if (_usarAlgoritmoDinamico) ...[
                          const SizedBox(height: 8),
                          SwitchListTile(
                            title: const Text('Usar Optimización MEJORADA de Camino Crítico'),
                            subtitle: Text(_usarAlgoritmoOptimizado 
                              ? '🔥 Detección automática + priorización avanzada + validación completa'
                              : 'Algoritmo dinámico estándar'),
                            value: _usarAlgoritmoOptimizado,
                            onChanged: (value) {
                              setState(() {
                                _usarAlgoritmoOptimizado = value;
                              });
                            },
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _recetasSeleccionadas.isEmpty || _ejecutandoAlgoritmo ? null : () {
                            // Ejecutar el algoritmo seleccionado
                            if (_usarAlgoritmoDinamico) {
                              _ejecutarAlgoritmoDinamico();
                            } else {
                              _ejecutarAlgoritmoStandard();
                            }
                          },
                          icon: _ejecutandoAlgoritmo
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(_ejecutandoAlgoritmo
                              ? 'Ejecutando...'
                              : _usarAlgoritmoDinamico
                                  ? _usarAlgoritmoOptimizado
                                      ? 'Ejecutar Algoritmo Optimizado Mejorado'
                                      : 'Ejecutar Algoritmo Dinámico'
                                  : 'Ejecutar Algoritmo Estándar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Mostrar resultados del algoritmo
              if (_logsProceso.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '📝 Proceso de Scheduling',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Logs del proceso
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            height: 200,
                            child: ListView.builder(
                              itemCount: _logsProceso.length,
                              itemBuilder: (context, index) {
                                return Text(_logsProceso[index]);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              
              // Mostrar plan de trabajo
              if (_resultadoPlan != null) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '📊 Plan de Trabajo',
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Resultado del algoritmo
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: SelectableText(_resultadoPlan!),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
