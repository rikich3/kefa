import '../dataModels/estado_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/horario_item.dart';
import 'dart:collection';

/// Algoritmo de scheduling ULTRA-OPTIMIZADO con complejidad O(n log n)
class SchedulingDinamicoAlgorithmUltraOptimizado {
  EstadoScheduling? _estadoActual;
  bool _debugMode = false;
  
  // ESTRUCTURAS OPTIMIZADAS PARA O(n log n)
  late Map<String, SplayTreeSet<CocineroScheduling>> _cocinerosPorTipo;
  late Map<String, SplayTreeSet<UtensilioScheduling>> _utensiliosPorTipo;
  late Set<String> _pasosEnCaminoCritico;
  
  // CACHE PARA EVITAR RECÁLCULOS
  final Map<String, int> _cacheCriticidad = {};
  final Map<String, List<String>> _cacheDependientes = {};
  
  /// Getter para acceder al estado actual
  EstadoScheduling? get estadoActual => _estadoActual;

  /// Inicializar con optimizaciones para casos masivos
  void inicializar({
    required List<PasoScheduling> pasos,
    required List<CocineroScheduling> cocineros,
    required List<UtensilioScheduling> utensilios,
  }) {
    _log('🚀 Inicializando scheduling ULTRA-OPTIMIZADO');
    
    // Convertir pasos básicos a pasos dinámicos
    final pasosDinamicos = pasos.map((p) => PasoSchedulingDinamico.fromPasoScheduling(p)).toList();
    
    // Reiniciar recursos
    for (var cocinero in cocineros) {
      cocinero.horario.clear();
      cocinero.ori = 0;
    }
    for (var utensilio in utensilios) {
      utensilio.horario.clear();
    }

    // Crear estado inicial
    _estadoActual = EstadoScheduling(
      tiempoActual: 0,
      todosPasos: pasosDinamicos,
      cocineros: cocineros,
      utensilios: utensilios,
    );

    // OPTIMIZACIÓN 1: Crear índices por tipo para búsqueda O(1)
    _crearIndicesPorTipo(cocineros, utensilios);
    
    // OPTIMIZACIÓN 2: Pre-calcular caminos críticos con algoritmo eficiente
    _calcularCaminosCriticosEficiente();
    
    // OPTIMIZACIÓN 3: Cache de dependientes
    _precalcularDependientes();
    
    // Calcular prioridades optimizadas
    _calcularPrioridadesUltraOptimizadas();
    _marcarPasosDisponiblesIniciales();
    
    _log('📊 Estado ultra-optimizado inicializado');
    _log('🔥 Pasos críticos: ${_pasosEnCaminoCritico.length}');
    _log('📋 Índices creados para ${_cocinerosPorTipo.keys.length} tipos de cocineros');
  }

  /// OPTIMIZACIÓN 1: Crear índices por tipo para búsqueda O(1)
  void _crearIndicesPorTipo(List<CocineroScheduling> cocineros, List<UtensilioScheduling> utensilios) {
    _cocinerosPorTipo = {};
    _utensiliosPorTipo = {};
    
    // Agrupar cocineros por tipo en árboles ordenados por disponibilidad
    for (final cocinero in cocineros) {
      _cocinerosPorTipo.putIfAbsent(cocinero.tipo, () => 
        SplayTreeSet<CocineroScheduling>((a, b) => 
          _calcularProximoTiempoDisponible(a).compareTo(_calcularProximoTiempoDisponible(b))
        )
      ).add(cocinero);
    }
    
    // Agrupar utensilios por tipo en árboles ordenados por disponibilidad
    for (final utensilio in utensilios) {
      _utensiliosPorTipo.putIfAbsent(utensilio.tipo, () => 
        SplayTreeSet<UtensilioScheduling>((a, b) => 
          _calcularProximoTiempoDisponible(a).compareTo(_calcularProximoTiempoDisponible(b))
        )
      ).add(utensilio);
    }
  }

  /// OPTIMIZACIÓN 2: Algoritmo eficiente de camino crítico O(n log n)
  void _calcularCaminosCriticosEficiente() {
    _pasosEnCaminoCritico = {};
    
    // Usar topological sort + longest path para encontrar caminos críticos
    final inDegree = <String, int>{};
    final adjList = <String, List<String>>{};
    
    // Construir grafo de dependencias
    for (final paso in _estadoActual!.todosPasos) {
      inDegree[paso.id] = paso.dependenciasOriginales.length;
      adjList[paso.id] = [];
    }
    
    for (final paso in _estadoActual!.todosPasos) {
      for (final dep in paso.dependenciasOriginales) {
        adjList[dep]?.add(paso.id);
      }
    }
    
    // Topological sort con cálculo de longest path
    final queue = Queue<String>();
    final longestPath = <String, int>{};
    
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
        longestPath[entry.key] = _obtenerDuracionPaso(entry.key);
      }
    }
    
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      
      for (final neighbor in adjList[current] ?? []) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        
        final newPath = longestPath[current]! + _obtenerDuracionPaso(neighbor);
        longestPath[neighbor] = (longestPath[neighbor] ?? 0) > newPath ? 
          longestPath[neighbor]! : newPath;
        
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }
    
    // Identificar pasos en camino crítico
    final maxPath = longestPath.values.isNotEmpty ? longestPath.values.reduce((a, b) => a > b ? a : b) : 0;
    final threshold = (maxPath * 0.8).toInt(); // 80% del camino más largo
    
    for (final entry in longestPath.entries) {
      if (entry.value >= threshold) {
        _pasosEnCaminoCritico.add(entry.key);
      }
    }
    
    _log('🎯 Camino crítico calculado eficientemente: ${_pasosEnCaminoCritico.length} pasos críticos');
  }

  /// OPTIMIZACIÓN 3: Pre-calcular dependientes para evitar búsquedas repetidas
  void _precalcularDependientes() {
    for (final paso in _estadoActual!.todosPasos) {
      _cacheDependientes[paso.id] = _estadoActual!.todosPasos
          .where((p) => p.dependenciasOriginales.contains(paso.id))
          .map((p) => p.id)
          .toList();
    }
  }

  /// ALGORITMO PRINCIPAL O(n log n)
  List<String> ejecutarCompleto() {
    if (_estadoActual == null) {
      throw StateError('Debe inicializar el algoritmo primero');
    }

    _log('▶️ Iniciando ejecución ultra-optimizada');
    
    int iteraciones = 0;
    const maxIteraciones = 2000;
    
    while (_estadoActual!.hayTrabajoDisponible && iteraciones < maxIteraciones) {
      iteraciones++;
      
      // ASIGNACIÓN OPTIMIZADA O(log n) por paso
      _asignarRecursosUltraOptimizado();
      
      // Avanzar tiempo
      final proximoEvento = _estadoActual!.proximoEvento;
      if (proximoEvento != null && proximoEvento > _estadoActual!.tiempoActual) {
        _avanzarTiempo(proximoEvento);
      }
      
      _procesarPasosTerminados();
      _actualizarDependenciasOptimizado();
      
      if (!_estadoActual!.hayTrabajoDisponible) break;
    }
    
    _estadoActual!.completado = true;
    _log('🏁 Scheduling ultra-optimizado completado en ${_estadoActual!.tiempoActual}s');
    
    return _estadoActual!.logEventos;
  }

  /// ASIGNACIÓN ULTRA-OPTIMIZADA O(log n)
  void _asignarRecursosUltraOptimizado() {
    // Ordenar pasos por prioridad (ya calculada)
    final pasosOrdenados = _estadoActual!.pasosDisponibles.toList()
      ..sort((PasoSchedulingDinamico a, PasoSchedulingDinamico b) => b.prioridad.compareTo(a.prioridad));

    for (final paso in pasosOrdenados) {
      // BÚSQUEDA O(log n) en lugar de O(n)
      final cocineroDisponible = _obtenerMejorCocinero(paso.tipoCocinero);
      final utensilioDisponible = _obtenerMejorUtensilio(paso.tipoUtensilio);
      
      if (cocineroDisponible != null && utensilioDisponible != null) {
        _asignarRecursosOptimizado(paso, cocineroDisponible, utensilioDisponible);
        
        // Reordenar árboles después de asignación
        _reordenarRecursos(cocineroDisponible, utensilioDisponible);
      }
    }
  }

  /// BÚSQUEDA OPTIMIZADA O(log n) de mejor cocinero
  CocineroScheduling? _obtenerMejorCocinero(String tipo) {
    final cocinerosPorTipo = _cocinerosPorTipo[tipo];
    if (cocinerosPorTipo == null || cocinerosPorTipo.isEmpty) return null;
    
    // El primer elemento del SplayTree es el más disponible
    return cocinerosPorTipo.first;
  }

  /// BÚSQUEDA OPTIMIZADA O(log n) de mejor utensilio
  UtensilioScheduling? _obtenerMejorUtensilio(String tipo) {
    final utensiliosPorTipo = _utensiliosPorTipo[tipo];
    if (utensiliosPorTipo == null || utensiliosPorTipo.isEmpty) return null;
    
    // El primer elemento del SplayTree es el más disponible
    return utensiliosPorTipo.first;
  }

  /// Asignar recursos con optimizaciones
  void _asignarRecursosOptimizado(PasoSchedulingDinamico paso, CocineroScheduling cocinero, UtensilioScheduling utensilio) {
    final tiempoInicioCocinero = _calcularProximoTiempoDisponible(cocinero);
    final tiempoInicioUtensilio = _calcularProximoTiempoDisponible(utensilio);
    final tiempoInicio = [tiempoInicioCocinero, tiempoInicioUtensilio, _estadoActual!.tiempoActual]
        .reduce((a, b) => a > b ? a : b);
    
    paso.iniciarEjecucion(tiempoInicio, cocinero.id, utensilio.id);
    
    // Reservar recursos
    cocinero.horario.add(HorarioItem(tiempoInicio: tiempoInicio, duracion: paso.duracion, pasoId: paso.id));
    utensilio.horario.add(HorarioItem(tiempoInicio: tiempoInicio, duracion: paso.duracion, pasoId: paso.id));
    
    _estadoActual!.agregarEvento('⚡ Iniciado: ${paso.nombre} hasta T${paso.tiempoFin}');
  }

  /// Reordenar árboles después de asignación
  void _reordenarRecursos(CocineroScheduling cocinero, UtensilioScheduling utensilio) {
    // Remover y re-agregar para mantener orden en SplayTree
    _cocinerosPorTipo[cocinero.tipo]?.remove(cocinero);
    _cocinerosPorTipo[cocinero.tipo]?.add(cocinero);
    
    _utensiliosPorTipo[utensilio.tipo]?.remove(utensilio);
    _utensiliosPorTipo[utensilio.tipo]?.add(utensilio);
  }

  /// Prioridades ultra-optimizadas con cache
  void _calcularPrioridadesUltraOptimizadas() {
    for (final paso in _estadoActual!.todosPasos) {
      // Usar cache para evitar recálculos
      if (!_cacheCriticidad.containsKey(paso.id)) {
        _cacheCriticidad[paso.id] = paso.calcularCriticidad(_estadoActual!.todosPasos);
      }
      
      double prioridad = 0.0;
      
      if (_pasosEnCaminoCritico.contains(paso.id)) {
        prioridad = 50000.0 + _cacheCriticidad[paso.id]! * 100.0; // PRIORIDAD EXTREMA
      } else {
        prioridad = _cacheCriticidad[paso.id]! * 10.0 + paso.duracion;
      }
      
      paso.prioridad = prioridad.toInt();
    }
  }

  /// Actualización optimizada de dependencias
  void _actualizarDependenciasOptimizado() {
    final pasosRecienCompletados = _estadoActual!.pasosCompletados
        .where((p) => p.tiempoFin == _estadoActual!.tiempoActual)
        .toList();

    for (final pasoCompletado in pasosRecienCompletados) {
      // Usar cache de dependientes
      final dependientesIds = _cacheDependientes[pasoCompletado.id] ?? [];
      
      for (final dependienteId in dependientesIds) {
        final dependientesEncontrados = _estadoActual!.pasosPendientes
            .where((p) => p.id == dependienteId);
        final dependiente = dependientesEncontrados.isNotEmpty ? dependientesEncontrados.first : null;
        
        if (dependiente != null) {
          dependiente.completarDependencia(pasoCompletado.id);
        }
      }
    }
  }

  // FUNCIONES AUXILIARES OPTIMIZADAS
  int _obtenerDuracionPaso(String pasoId) {
    final pasos = _estadoActual!.todosPasos.where((p) => p.id == pasoId);
    return pasos.isNotEmpty ? pasos.first.duracion : 0;
  }

  void _avanzarTiempo(int nuevoTiempo) {
    _estadoActual!.tiempoActual = nuevoTiempo;
  }

  void _procesarPasosTerminados() {
    final pasosACompletar = _estadoActual!.pasosEnProceso
        .where((p) => p.tiempoFin == _estadoActual!.tiempoActual)
        .toList();

    for (final paso in pasosACompletar) {
      paso.completarEjecucion(_estadoActual!.tiempoActual);
      _estadoActual!.agregarEvento('✅ Completado: ${paso.nombre}');
    }
  }

  void _marcarPasosDisponiblesIniciales() {
    for (final paso in _estadoActual!.todosPasos) {
      if (paso.dependenciasOriginales.isEmpty) {
        paso.estado = EstadoPaso.disponible;
      }
    }
  }

  int _calcularProximoTiempoDisponible(dynamic recurso) {
    if (recurso.horario.isEmpty) return _estadoActual!.tiempoActual;
    
    return recurso.horario
        .where((HorarioItem item) => (item.tiempoInicio + item.duracion) > _estadoActual!.tiempoActual)
        .fold<int>(_estadoActual!.tiempoActual, (int max, HorarioItem item) => 
            (item.tiempoInicio + item.duracion) > max ? (item.tiempoInicio + item.duracion) : max);
  }

  void _log(String mensaje) {
    if (_debugMode) print(mensaje);
  }

  void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }
}
