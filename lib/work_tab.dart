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
import 'back/algorithms/scheduling_dinamico_algorithm_optimizado.dart';
import 'back/dataModels/loteo_optimizer.dart';
import 'screens/cocineros_grid_screen.dart';
import 'back/dataModels/receta.dart';
import 'algoritmo/algoritmo_cocina_optimizado.dart';

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
  SchedulingDinamicoAlgorithmOptimizado? _algoritmoOptimizado;

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

    // Limpiar tareas previas antes de generar nuevo plan
    final tareasProvider = Provider.of<TareaAsignadaProvider>(context, listen: false);
    await tareasProvider.limpiarTareas();

    try {
      print('🚀 INICIANDO ALGORITMO DE SCHEDULING');
      print('=' * 50);
      
      _logsProceso.add('🚀 Iniciando algoritmo de scheduling...');
      _logsProceso.add('📋 Recetas seleccionadas: ${_recetasSeleccionadas.toString()}');
      _logsProceso.add('👨‍🍳 Cocineros: ${_recetasSeleccionadas.length}');
      _logsProceso.add('🔧 Utensilios: ${_recetasSeleccionadas.length}');
      _logsProceso.add('📝 Pasos totales: ${_recetasSeleccionadas.length}');

      // Obtener datos de providers
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);
      final recetaProvider = Provider.of<RecetaProvider>(context, listen: false);

      // Obtener receta seleccionada (asumimos una receta para el ejemplo)
      final recetaSeleccionadaId = _recetasSeleccionadas.keys.isNotEmpty ? _recetasSeleccionadas.keys.first : null;
      final recetaEntries = recetaProvider.recetaEntries;
      MapEntry<dynamic, Receta>? recetaEntrySeleccionada;
      if (recetaSeleccionadaId != null) {
        try {
          recetaEntrySeleccionada = recetaEntries.firstWhere((r) => r.value.nombre == recetaSeleccionadaId);
        } catch (_) {
          recetaEntrySeleccionada = null;
        }
      }
      final recetaSeleccionada = recetaEntrySeleccionada?.value;
      final pasos = pasoProvider.pasoEntries.map((e) => e.value).toList();
      final workers = workersProvider.workers;
      final instrumentos = instrumentosProvider.instrumentos;
      final cantidadFinal = recetaSeleccionada != null ? recetaSeleccionada.cantidadPorciones.toDouble() : 1.0;

      // Loteo óptimo de pasos
      List<LoteoPasoResult> pasosLoteados = [];
      if (recetaSeleccionada != null) {
        pasosLoteados = LoteoOptimizer.optimizarLoteo(
          receta: recetaSeleccionada,
          pasos: pasos,
          utensilios: instrumentos,
          cantidadFinal: cantidadFinal,
        );
        print('🟢 Pasos loteados:');
        for (final loteo in pasosLoteados) {
          print('Paso: \'${loteo.paso.nombrePaso}\', Lote: \'${loteo.lote}/${loteo.totalLotes}\', Cantidad: \'${loteo.cantidad}\', Utensilio: \'${loteo.utensilio?.nombre ?? '-'}\'');
        }
      }
      // --- LIMPIEZA FINAL DE CONVERSIÓN Y USO DE VARIABLES ---
      final pasosScheduling = pasosLoteados.map((loteo) => PasoScheduling(
        id: loteo.paso.id + '_lote${loteo.lote}',
        nombre: loteo.paso.nombrePaso + (loteo.totalLotes > 1 ? ' (Lote ${loteo.lote}/${loteo.totalLotes})' : ''),
        tipoCocinero: loteo.paso.tipoCocinero ?? 'cocinero',
        tipoUtensilio: loteo.utensilio?.nombre ?? loteo.paso.tipoUtensilio ?? 'A',
        duracion: (loteo.paso.tiempoCoccionSegundos + loteo.paso.tiempoPreparacionSegundos),
        dependencias: (loteo.paso.dependencias ?? []),
      )).toList();

      final cocineros = _convertirWorkersACocineros(workers);
      final utensiliosScheduling = _convertirInstrumentosAUtensilios(instrumentos);

      _logsProceso.add('👨‍🍳 Cocineros: \'${cocineros.length}\'');
      _logsProceso.add('🔧 Utensilios: \'${utensiliosScheduling.length}\'');
      _logsProceso.add('📝 Pasos totales: \'${pasosScheduling.length}\'');
      
      // Inicializar algoritmo optimizado
      _algoritmoOptimizado = SchedulingDinamicoAlgorithmOptimizado(
        pasos: pasosScheduling,
        cocineros: cocineros,
        utensilios: utensiliosScheduling,
      );

      _logsProceso.add('⚙️ Algoritmo optimizado inicializado');

      // Ejecutar algoritmo optimizado
      await Future.delayed(const Duration(milliseconds: 500));
      final logsEjecucion = _algoritmoOptimizado!.ejecutarCompleto();
      
      _logsProceso.addAll(logsEjecucion);
      _logsProceso.add('✅ Algoritmo optimizado ejecutado exitosamente');
      
      // Generar resultado visual SOLO con el algoritmo NUEVO
      // Elimina la llamada incorrecta con 'tareas' fuera de scope
      // (No llamar a _generarPlanVisualOptimizadoNuevo(tareas) aquí)
      
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

  // Ejecutar el algoritmo optimizado que alcanza el makespan óptimo
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

    // Limpiar tareas previas antes de generar nuevo plan
    final tareasProvider = Provider.of<TareaAsignadaProvider>(context, listen: false);
    await tareasProvider.limpiarTareas();

    try {
      print('🚀 INICIANDO NUEVO ALGORITMO DE SCHEDULING OPTIMIZADO');
      print('=' * 50);
      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
      print('Cantidad de recetas a procesar: \\${_recetasSeleccionadas.length}');
      print('Recetas seleccionadas: \\${_recetasSeleccionadas.toString()}');
      print('Lista de cocineros:');
      for (final worker in workersProvider.workers) {
        print(' - \\${worker.nombre}');
      }

      // Obtener datos de providers
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);
      final recetaProvider = Provider.of<RecetaProvider>(context, listen: false);

      // Obtener receta seleccionada y cantidad
      final recetaSeleccionadaId = _recetasSeleccionadas.keys.isNotEmpty ? _recetasSeleccionadas.keys.first : null;
      final cantidadPlatos = recetaSeleccionadaId != null ? _recetasSeleccionadas[recetaSeleccionadaId] ?? 1 : 1;
      final recetaEntries = recetaProvider.recetaEntries;
      MapEntry<dynamic, Receta>? recetaEntrySeleccionada;
      if (recetaSeleccionadaId != null) {
        try {
          recetaEntrySeleccionada = recetaEntries.firstWhere((r) => r.value.nombre == recetaSeleccionadaId);
        } catch (_) {
          recetaEntrySeleccionada = null;
        }
      }
      final recetaSeleccionada = recetaEntrySeleccionada?.value;
      if (recetaSeleccionada == null) {
        _logsProceso.add('❌ No se encontró la receta seleccionada.');
        setState(() { _ejecutandoAlgoritmo = false; });
        return;
      }
      // Filtrar pasos de la receta seleccionada
      final pasos = pasoProvider.pasoEntries.map((e) => e.value).where((p) => p.recetaId == recetaSeleccionada.nombre).toList();
      final workers = workersProvider.workers;
      final instrumentos = instrumentosProvider.instrumentos;

      // Ejecutar algoritmo optimizado
      final algoritmo = AlgoritmoCocinaOptimizado(
        pasos: pasos,
        cocineros: workers,
        utensilios: instrumentos,
        cantidadPlatos: cantidadPlatos,
      );
      final List<TareaCocinaOptimizada> tareas = algoritmo.generarAgenda();
      print('Agendas generadas por cocinero:');
      final tareasPorCocinero = <String, List<TareaCocinaOptimizada>>{};
      for (final tarea in tareas) {
        tareasPorCocinero.putIfAbsent(tarea.cocineroId, () => []).add(tarea);
      }
      tareasPorCocinero.forEach((cocinero, tareas) {
        print('👨‍🍳 $cocinero:');
        for (final tarea in tareas) {
          print('   - \\${tarea.nombreTarea} | \\${tarea.tiempoInicioSegundos}s - \\${tarea.tiempoInicioSegundos + tarea.duracionSegundos}s | \\${tarea.utensiliosRequeridos.join(", ")}');
        }
      });

      _logsProceso.add('✅ Planificación generada con \\${tareas.length} tareas.');
      _resultadoPlan = _generarPlanVisualOptimizadoNuevo(tareas);
      print('✅ NUEVO ALGORITMO OPTIMIZADO COMPLETADO');
      print('=' * 50);

      // Guardar tareas en la base de datos
      final tareasProvider = Provider.of<TareaAsignadaProvider>(context, listen: false);
      final tareasAsignadas = tareas.map((t) => TareaAsignada(
        id: (t as TareaCocinaOptimizada).id,
        cocineroId: t.cocineroId,
        nombreTarea: t.nombreTarea,
        descripcion: t.descripcion,
        utensiliosRequeridos: t.utensiliosRequeridos,
        tiempoInicioSegundos: t.tiempoInicioSegundos,
        duracionSegundos: t.duracionSegundos,
        orden: t.orden,
        fechaAsignacion: t.fechaAsignacion,
      )).toList();
      await tareasProvider.guardarTareas(tareasAsignadas);
      _logsProceso.add('💾 Agenda guardada en la base de datos.');
    } catch (e) {
      print('❌ Error en nuevo algoritmo optimizado: $e');
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

  String _generarPlanVisualOptimizadoNuevo(List<TareaCocinaOptimizada> tareas) {
    if (tareas.isEmpty) return 'No hay plan generado aún';
    final buffer = StringBuffer();
    buffer.writeln('Plan de ejecución optimizado:');
    buffer.writeln('=' * 50);
    tareas.sort((a, b) => a.tiempoInicioSegundos.compareTo(b.tiempoInicioSegundos));
    for (final tarea in tareas) {
      final tiempoFin = tarea.tiempoInicioSegundos + tarea.duracionSegundos;
      buffer.writeln(
        '${tarea.nombreTarea}\n'
        '  🕒 ${tarea.tiempoInicioSegundos}s - ${tiempoFin}s (${tarea.duracionSegundos}s)\n'
        '  👨‍🍳 ${tarea.cocineroId}\n'
        '  🔧 ${tarea.utensiliosRequeridos.join(", ")}\n'
      );
    }
    return buffer.toString();
  }

  // Método para asignar tareas a los cocineros en la base de datos
  void _asignarTareasACocineros() async {
    if (_algoritmoOptimizado?.estadoActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero debe generar un plan optimizado')),
      );
      return;
    }

    try {
      print('📋 Iniciando asignación de tareas a cocineros...');
      
      final estado = _algoritmoOptimizado!.estadoActual!;
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

  List<Widget> _generarPlanPorCocinero(List<TareaAsignada> tareas, TextTheme textTheme) {
    if (tareas.isEmpty) {
      return [Text('No hay tareas asignadas.', style: textTheme.bodyMedium)];
    }
    final tareasPorCocinero = <String, List<TareaAsignada>>{};
    for (final tarea in tareas) {
      tareasPorCocinero.putIfAbsent(tarea.cocineroId, () => []).add(tarea);
    }
    final widgets = <Widget>[];
    tareasPorCocinero.forEach((cocinero, tareas) {
      widgets.add(Text('👨‍🍳 $cocinero', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)));
      tareas.sort((a, b) => a.tiempoInicioSegundos.compareTo(b.tiempoInicioSegundos));
      for (final tarea in tareas) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            '${tarea.nombreTarea} | 🕒 ${tarea.tiempoInicioFormateado} - ${tarea.tiempoFinSegundos}s | 🔧 ${tarea.utensiliosRequeridos.join(", ")}',
            style: textTheme.bodyMedium,
          ),
        ));
      }
      widgets.add(const SizedBox(height: 16));
    });
    return widgets;
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
                                _recetasSeleccionadas[receta.nombre] = cantidad - 1;
                                if (_recetasSeleccionadas[receta.nombre]! <= 0) {
                                  _recetasSeleccionadas.remove(receta.nombre);
                                }
                              });
                            } : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Container(
                            width: 32,
                            alignment: Alignment.center,
                            child: Text(cantidad.toString(), style: textTheme.titleMedium),
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
                          'Algoritmo de Scheduling Optimizado',
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.auto_awesome, color: Colors.purple),
                          title: Text('Genera el plan óptimo de cocina para minimizar el tiempo total.'),
                          subtitle: Text('Considera lotes, dependencias, recursos y agenda de cocineros.'),
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
                      children: _logsProceso.map((log) => Text(log)).toList(),
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
                      children: _generarPlanPorCocinero(tareasProvider.todasLasTareasAsignadas, textTheme),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
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
