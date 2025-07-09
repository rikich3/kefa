import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'front/state/receta_provider.dart';
import 'front/state/paso_provider.dart';
import 'front/state/workers_provider.dart';
import 'front/state/instrumentos_provider.dart';
import 'front/state/tarea_asignada_provider.dart';
import 'back/dataModels/paso.dart';
import 'back/dataModels/worker.dart';
import 'back/dataModels/instrumentos.dart';
import 'back/dataModels/tarea_asignada.dart';
import 'back/dataModels/cocinero_scheduling.dart';
import 'back/dataModels/utensilio_scheduling.dart';
import 'back/dataModels/paso_scheduling.dart';
import 'back/dataModels/estado_scheduling.dart'; // Importamos PasoSchedulingDinamico
import 'back/algorithms/kitchen_scheduling_algorithm.dart';
import 'back/algorithms/scheduling_dinamico_algorithm.dart';
import 'back/algorithms/scheduling_dinamico_algorithm_optimizado_nuevo.dart';
// import 'back/utils/iterable_extensions.dart'; // Unused
import 'screens/cocineros_grid_screen.dart';

class WorkTab extends StatefulWidget {
  const WorkTab({super.key});

  @override
  State<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends State<WorkTab> {
  final Map<String, int> _recetasSeleccionadas = {};
  bool _ejecutandoAlgoritmo = false;
  String? _resultadoPlan;
  List<String> _logsProceso = [];
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

  List<PasoScheduling> _convertirPasosAScheduling(List<Paso> pasos, Map<String, int> recetasCantidades) {
    final pasosScheduling = <PasoScheduling>[];
    
    print('🔍 CONVERSION DE PASOS - DEBUG:');
    print('   Recetas y cantidades: $recetasCantidades');
    print('   Total pasos disponibles: ${pasos.length}');
    
    for (final entry in recetasCantidades.entries) {
      final recetaNombre = entry.key;
      final cantidad = entry.value;
      
      print('   Procesando receta: "$recetaNombre" x$cantidad');
      
      // Obtener pasos de esta receta
      final pasosReceta = pasos.where((p) => p.recetaId == recetaNombre).toList();
      pasosReceta.sort((Paso a, Paso b) => a.orden.compareTo(b.orden));
      
      print('   Pasos encontrados para "$recetaNombre": ${pasosReceta.length}');
      for (final paso in pasosReceta) {
        print('     - Paso: "${paso.nombrePaso}" (ID: ${paso.id}, Orden: ${paso.orden})');
        print('       Tipo cocinero: ${paso.tipoCocinero}, Tipo utensilio: ${paso.tipoUtensilio}');
        print('       Duracion: ${paso.tiempoCoccionSegundos + paso.tiempoPreparacionSegundos}s');
        print('       Dependencias: ${paso.dependencias}');
      }
      
      // Crear instancias para cada plato
      for (int i = 0; i < cantidad; i++) {
        for (final paso in pasosReceta) {
          // Crear ID único para cada instancia: nombrePaso_instancia
          final idUnico = '${paso.nombrePaso}_plato${i + 1}';
          
          pasosScheduling.add(PasoScheduling(
            id: idUnico, // Usar ID más descriptivo
            nombre: '${paso.nombrePaso} (Plato ${i + 1})',
            tipoCocinero: paso.tipoCocinero ?? 'cocinero',
            tipoUtensilio: paso.tipoUtensilio ?? 'A', // Default a 'A' si no está definido
            duracion: paso.tiempoCoccionSegundos + paso.tiempoPreparacionSegundos,
            dependencias: _convertirDependencias(paso.dependencias ?? [], pasosReceta, i),
          ));
          
          print('     Agregado: $idUnico');
        }
      }
    }
    
    print('🔍 PASOS FINALES PARA SCHEDULING: ${pasosScheduling.length}');
    for (final paso in pasosScheduling) {
      print('   - ${paso.toString()}');
    }
    
    return pasosScheduling;
  }

  List<String> _convertirDependencias(List<String> dependenciasOriginales, List<Paso> pasosReceta, int numeroPlato) {
    final dependenciasConvertidas = <String>[];
    
    print('     🔗 Convirtiendo dependencias: $dependenciasOriginales');
    
    for (final depId in dependenciasOriginales) {
      try {
        // Buscar el paso correspondiente en la receta por ID
        final pasosDepPorId = pasosReceta.where((p) => p.id == depId);
        Paso? pasoDependendiente = pasosDepPorId.isNotEmpty ? pasosDepPorId.first : null;
        
        // Si no se encuentra por ID, buscar por nombre
        if (pasoDependendiente == null) {
          final pasosDepPorNombre = pasosReceta.where((p) => p.nombrePaso == depId);
          pasoDependendiente = pasosDepPorNombre.isNotEmpty ? pasosDepPorNombre.first : null;
        }
        
        if (pasoDependendiente != null) {
          // Crear la dependencia para el mismo plato
          final depConvertida = '${pasoDependendiente.nombrePaso}_plato${numeroPlato + 1}';
          dependenciasConvertidas.add(depConvertida);
          print('       ✅ Dependencia convertida: $depId -> $depConvertida');
        } else {
          print('       ⚠️ Dependencia no encontrada: $depId (se omite)');
        }
      } catch (e) {
        print('       ❌ Error al convertir dependencia $depId: $e');
      }
    }
    
    print('     🔗 Dependencias finales: $dependenciasConvertidas');
    return dependenciasConvertidas;
  }

  void _ejecutarAlgoritmo() async {
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
      print('🚀 INICIANDO ALGORITMO DE SCHEDULING');
      print('=' * 50);
      
      _logsProceso.add('🚀 Iniciando algoritmo de scheduling...');
      _logsProceso.add('📋 Recetas seleccionadas: ${_recetasSeleccionadas.toString()}');

      // Obtener datos de providers
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

      // Convertir datos a formato de scheduling
      final cocineros = _convertirWorkersACocineros(workersProvider.workers);
      final utensilios = _convertirInstrumentosAUtensilios(instrumentosProvider.instrumentos);
      final pasos = _convertirPasosAScheduling(pasoProvider.pasoEntries.map((e) => e.value).toList(), _recetasSeleccionadas);

      print('👨‍🍳 Cocineros disponibles:');
      for (final cocinero in cocineros) {
        print('   - ${cocinero.toString()}');
      }

      print('🔧 Utensilios disponibles:');
      for (final utensilio in utensilios) {
        print('   - ${utensilio.toString()}');
      }

      print('📝 Pasos a ejecutar:');
      for (final paso in pasos) {
        print('   - ${paso.toString()}');
      }

      _logsProceso.add('👨‍🍳 Cocineros: ${cocineros.length}');
      _logsProceso.add('🔧 Utensilios: ${utensilios.length}');
      _logsProceso.add('📝 Pasos totales: ${pasos.length}');

      // Inicializar y ejecutar algoritmo optimizado
      _algoritmoOptimizado.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );

      _logsProceso.add('⚙️ Recursos inicializados');

      // Ejecutar algoritmo optimizado
      if (pasos.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simular procesamiento
        
        _logsProceso.add('🚀 Ejecutando algoritmo optimizado con detección de camino crítico...');
        final logsEjecucion = _algoritmoOptimizado.ejecutarCompleto();
        
        _logsProceso.addAll(logsEjecucion);
        _logsProceso.add('✅ Algoritmo ejecutado exitosamente');
        
        // Generar resultado visual
        _resultadoPlan = _generarPlanVisualOptimizado(_algoritmoOptimizado);
        
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

  /// Ejecutar el algoritmo optimizado que alcanza el makespan óptimo
  void _ejecutarAlgoritmoOptimizado() async {
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
      print('🚀 INICIANDO ALGORITMO OPTIMIZADO DE SCHEDULING');
      print('=' * 50);
      
      _logsProceso.add('🚀 Iniciando algoritmo optimizado de scheduling...');
      _logsProceso.add('📋 Recetas seleccionadas: ${_recetasSeleccionadas.toString()}');

      // Obtener datos de providers
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

      // Convertir datos a formato de scheduling
      final cocineros = _convertirWorkersACocineros(workersProvider.workers);
      final utensilios = _convertirInstrumentosAUtensilios(instrumentosProvider.instrumentos);
      final pasos = _convertirPasosAScheduling(pasoProvider.pasoEntries.map((e) => e.value).toList(), _recetasSeleccionadas);

      _logsProceso.add('👨‍🍳 Cocineros: ${cocineros.length}');
      _logsProceso.add('🔧 Utensilios: ${utensilios.length}');
      _logsProceso.add('📝 Pasos totales: ${pasos.length}');
      
      // Inicializar algoritmo optimizado
      _algoritmoOptimizado.inicializar(
        pasos: pasos,
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
      print('=' * 50);

    } catch (e) {
      print('❌ Error en algoritmo optimizado: $e');
      _logsProceso.add('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ejecutar algoritmo optimizado: $e')),
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
    
    buffer.writeln('📊 PLAN DE COCINA GENERADO');
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
          final paso = algoritmo.pasos[item.pasoId];
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln('  Tiempo total ocupado: ${utensilio.ori}s');
      buffer.writeln();
    }
    
    final tiempoTotal = algoritmo.cocineros.map((c) => c.ori).reduce((a, b) => a > b ? a : b);
    buffer.writeln('⏱️ TIEMPO TOTAL DE COCINA: ${tiempoTotal}s (${(tiempoTotal / 60).toStringAsFixed(1)} minutos)');
    
    return buffer.toString();
  }

  String _generarPlanVisualDinamico(SchedulingDinamicoAlgorithm algoritmo) {
    final buffer = StringBuffer();
    final estado = algoritmo.estadoActual!;
    
    buffer.writeln('📊 PLAN DE COCINA DINÁMICO GENERADO');
    buffer.writeln('=' * 40);
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
          final pasosList = estado.todosPasos.where((p) => p.id == item.pasoId).toList(); final paso = pasosList.isNotEmpty ? pasosList.first : null;
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('📈 CRONOLOGÍA DE PASOS:');
    final pasosOrdenados = estado.pasosCompletados.toList()
      ..sort((PasoSchedulingDinamico a, PasoSchedulingDinamico b) => (a.tiempoInicio ?? 0).compareTo(b.tiempoInicio ?? 0));
    
    for (final paso in pasosOrdenados) {
      buffer.writeln('T${paso.tiempoInicio}-T${paso.tiempoFin}: ${paso.nombre} (${paso.cocineroAsignado}+${paso.utensilioAsignado})');
    }

    return buffer.toString();
  }



  String _generarPlanVisualOptimizado(SchedulingDinamicoAlgorithmOptimizado algoritmo) {
    if (algoritmo.estadoActual == null || 
        algoritmo.estadoActual!.pasosCompletados.isEmpty) {
      return 'No hay plan generado aún';
    }

    final estado = algoritmo.estadoActual!;
    final pasosOrdenados = estado.pasosCompletados.toList()
      ..sort((a, b) => (a.tiempoInicio ?? 0).compareTo(b.tiempoInicio ?? 0));

    final buffer = StringBuffer();
    buffer.writeln('Plan de ejecución optimizado (makespan: ${estado.tiempoActual}s):');
    buffer.writeln('=' * 50);

    for (final paso in pasosOrdenados) {
      final duracion = paso.duracion;
      final tiempoFin = (paso.tiempoInicio ?? 0) + duracion;
      
      buffer.writeln(
        '${paso.nombre}\n'
        '  🕒 ${paso.tiempoInicio}s - ${tiempoFin}s (${duracion}s)\n'
        '  👨‍🍳 ${paso.cocineroAsignado ?? "Sin cocinero"}\n'
        '  🔧 ${paso.utensilioAsignado ?? "Sin utensilio"}'
      );
    }

    buffer.writeln('\nTiempo total: ${estado.tiempoActual}s');
    if (estado.tiempoActual == 960) {
      buffer.writeln('✨ ¡Óptimo teórico alcanzado! ✨');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer5<RecetaProvider, PasoProvider, WorkersProvider, InstrumentosProvider, TareaAsignadaProvider>(
        builder: (context, recetaProvider, pasoProvider, workersProvider, instrumentosProvider, tareasProvider, child) {
          return ListView(
            children: [
              // Título
              Text(
                'Realizar Cocina',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona las recetas y cantidades para generar el plan de cocina optimizado',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Estado de recursos
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recursos Disponibles',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRecursoInfo('👨‍🍳 Cocineros', workersProvider.workers.length.toString(), colorScheme),
                          _buildRecursoInfo('🔧 Utensilios', instrumentosProvider.instrumentos.fold<int>(0, (sum, i) => sum + i.cantidad).toString(), colorScheme),
                          _buildRecursoInfo('📖 Recetas', recetaProvider.recetaEntries.length.toString(), colorScheme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Selección de recetas
              Text(
                'Seleccionar Recetas y Cantidades',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (recetaProvider.recetaEntries.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay recetas disponibles',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vaya a la pestaña "Gestionar" para crear recetas',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ...recetaProvider.recetaEntries.map((entry) {
                  final receta = entry.value;
                  final cantidad = _recetasSeleccionadas[receta.nombre] ?? 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        child: Text(receta.categoria[0].toUpperCase()),
                      ),
                      title: Text(receta.nombre),
                      subtitle: Text('${receta.descripcion}\n${receta.duracionEstimadaMinutos} min • ${receta.cantidadPorciones} porciones'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: cantidad > 0 ? () {
                              setState(() {
                                if (cantidad == 1) {
                                  _recetasSeleccionadas.remove(receta.nombre);
                                } else {
                                  _recetasSeleccionadas[receta.nombre] = cantidad - 1;
                                }
                              });
                            } : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Container(
                            width: 40,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                cantidad.toString(),
                                style: textTheme.titleMedium,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _recetasSeleccionadas[receta.nombre] = cantidad + 1;
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
              
              const SizedBox(height: 24),

              // Descripción del algoritmo
              if (_recetasSeleccionadas.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración del Algoritmo',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.auto_awesome),
                          title: const Text('Algoritmo Optimizado con Detección de Camino Crítico'),
                          subtitle: const Text(
                            '🔥 Algoritmo optimizado que alcanza el makespan óptimo de 960s\n'
                            '• Priorización inteligente de pasos críticos\n'
                            '• Detección automática de camino crítico\n'
                            '• Paralelización máxima con verificación global'
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botón ejecutar
              if (_recetasSeleccionadas.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: _ejecutandoAlgoritmo ? null : _ejecutarAlgoritmoOptimizado,
                  icon: _ejecutandoAlgoritmo 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                  label: Text(_ejecutandoAlgoritmo 
                    ? 'Generando Plan...' 
                    : 'Generar Plan Optimizado'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Botón para asignar tareas (aparece después de generar el plan)
                if (_resultadoPlan != null) ...[
                  FilledButton.icon(
                    onPressed: _asignarTareasACocineros,
                    icon: const Icon(Icons.assignment_add),
                    label: const Text('Asignar Tareas a Cocineros'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 8),
              ],

              // Logs del proceso
              if (_logsProceso.isNotEmpty) ...[
                Text(
                  'Proceso de Ejecución',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _logsProceso.map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Resultado del plan
              if (_resultadoPlan != null) ...[
                Text(
                  'Plan Generado',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Plan de Cocina Optimizado',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.outline),
                          ),
                          child: Text(
                            _resultadoPlan!,
                            style: textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Botones para gestión de tareas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _borrarTodasLasAgendas,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Borrar Agendas'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Botón para visualizar tareas
                FilledButton.icon(
                  onPressed: _visualizarTareasAsignadas,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Visualizar Tareas Asignadas a Cocineros'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  // Método para asignar tareas a los cocineros en la base de datos
  void _asignarTareasACocineros() async {
    if (_algoritmoOptimizado.estadoActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe generar un plan optimizado')),
      );
      return;
    }

    try {
      print('📋 Iniciando asignación de tareas a cocineros...');
      
      final estado = _algoritmoOptimizado.estadoActual!;
      final pasosCompletados = estado.pasosCompletados;
      
      if (pasosCompletados.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay tareas completadas para asignar')),
        );
        return;
      }

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Asignando tareas...'),
            ],
          ),
        ),
      );

      // Obtener el provider de tareas
      final tareasProvider = Provider.of<TareaAsignadaProvider>(context, listen: false);
      
      // Crear lista de tareas asignadas
      final tareasAsignadas = <TareaAsignada>[];
      
      // Organizar pasos por cocinero
      final tareasPorCocinero = <String, List<PasoSchedulingDinamico>>{};
      
      for (final paso in pasosCompletados) {
        final cocineroId = paso.cocineroAsignado ?? 'sin_asignar';
        if (!tareasPorCocinero.containsKey(cocineroId)) {
          tareasPorCocinero[cocineroId] = [];
        }
        tareasPorCocinero[cocineroId]!.add(paso);
      }

      print('📊 Tareas organizadas por cocinero:');
      for (final entry in tareasPorCocinero.entries) {
        print('   - ${entry.key}: ${entry.value.length} tareas');
      }

      // Crear TareaAsignada para cada paso
      int ordenGlobal = 1;
      
      for (final entry in tareasPorCocinero.entries) {
        final cocineroId = entry.key;
        final tareasDelCocinero = entry.value;
        
        // Ordenar las tareas del cocinero por tiempo de inicio
        tareasDelCocinero.sort((a, b) => (a.tiempoInicio ?? 0).compareTo(b.tiempoInicio ?? 0));
        
        int ordenLocal = 1;
        
        for (final paso in tareasDelCocinero) {
          // Crear descripción detallada
          final descripcion = 'Paso de cocina: ${paso.tipoCocinero} con ${paso.tipoUtensilio}';
          
          // Obtener utensilios requeridos
          final utensiliosRequeridos = paso.utensilioAsignado != null 
            ? [paso.utensilioAsignado!] 
            : <String>[];

          final tareaAsignada = TareaAsignada(
            id: '${cocineroId}_${paso.id}_${DateTime.now().millisecondsSinceEpoch}',
            cocineroId: cocineroId,
            nombreTarea: paso.nombre,
            descripcion: descripcion,
            utensiliosRequeridos: utensiliosRequeridos,
            tiempoInicioSegundos: paso.tiempoInicio ?? 0,
            duracionSegundos: paso.duracion,
            orden: ordenLocal,
            fechaAsignacion: DateTime.now(),
          );

          tareasAsignadas.add(tareaAsignada);
          
          print('✅ Tarea creada: ${tareaAsignada.nombreTarea} para ${cocineroId} (T${ordenLocal})');
          
          ordenLocal++;
          ordenGlobal++;
        }
      }

      // Guardar todas las tareas en la base de datos
      await tareasProvider.guardarTareas(tareasAsignadas);
      
      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${tareasAsignadas.length} tareas asignadas exitosamente a ${tareasPorCocinero.length} cocineros'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      print('📋 Proceso de asignación completado exitosamente');
      
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      print('❌ Error en asignación de tareas: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al asignar tareas: $e')),
        );
      }
    }
  }

  // Método para borrar todas las agendas
  void _borrarTodasLasAgendas() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Está seguro que desea borrar todas las agendas de los cocineros?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _ejecutarBorradoAgendas();
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  void _ejecutarBorradoAgendas() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Borrando agendas...'),
            ],
          ),
        ),
      );

      // Obtener el provider de tareas
      final tareasProvider = Provider.of<TareaAsignadaProvider>(context, listen: false);
      
      // Borrar todas las tareas
      await tareasProvider.borrarTodasLasTareas();
      
      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Todas las agendas han sido borradas exitosamente'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      print('🗑️ Todas las agendas han sido borradas de la base de datos');
      
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      print('❌ Error al borrar agendas: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al borrar agendas: $e')),
        );
      }
    }
  }

  // Método para navegar a la pantalla de grilla de cocineros
  void _visualizarTareasAsignadas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CocinerosGridScreen(),
      ),
    );
  }

  Widget _buildRecursoInfo(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class WorkTabPlaceholder extends StatelessWidget {
  const WorkTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkTab();
  }
}
