import '../dataModels/estado_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/horario_item.dart';

/// Algoritmo de scheduling dinámico CORREGIDO con validación completa
class SchedulingDinamicoAlgorithmCorregido {
  EstadoScheduling? _estadoActual;
  bool _debugMode = true;
  
  // ESTRUCTURAS PARA OPTIMIZACIÓN
  Map<String, List<String>> _caminosCriticos = {};
  Map<String, double> _impactoEnMakespan = {};
  Set<String> _pasosEnCaminoCritico = {};

  /// Getter para acceder al estado actual
  EstadoScheduling? get estadoActual => _estadoActual;

  /// Inicializar el algoritmo con pasos, cocineros y utensilios
  void inicializar({
    required List<PasoScheduling> pasos,
    required List<CocineroScheduling> cocineros,
    required List<UtensilioScheduling> utensilios,
  }) {
    _log('🚀 Inicializando scheduling dinámico CORREGIDO');
    
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

    // Calcular optimizaciones
    _calcularCaminosCriticos();
    _identificarPasosEnCaminoCritico();
    _calcularImpactoEnMakespan();
    _calcularPrioridadesOptimizadas();
    _marcarPasosDisponiblesIniciales();
    
    _log('📊 Estado inicial optimizado: $_estadoActual');
    _log('🔥 Pasos en camino crítico detectados: ${_pasosEnCaminoCritico.length}');
    _log('📋 Pasos disponibles inicialmente: ${_estadoActual!.pasosDisponibles.length}');
  }

  /// Ejecutar el algoritmo completo con validaciones completas
  List<String> ejecutarCompleto() {
    if (_estadoActual == null) {
      throw StateError('Debe inicializar el algoritmo primero');
    }

    final totalPasos = _estadoActual!.todosPasos.length;
    final stopwatch = Stopwatch()..start();
    const timeoutMs = 30000; // 30 segundos máximo
    
    _log('▶️ Iniciando ejecución completa del scheduling CORREGIDO');
    
    int iteraciones = 0;
    int iteracionesSinProgreso = 0;
    const maxIteraciones = 5000;
    const maxSinProgreso = 20; // Más tolerante
    
    while (_estadoActual!.hayTrabajoDisponible && iteraciones < maxIteraciones) {
      iteraciones++;
      final pasosCompletadosAntes = _estadoActual!.pasosCompletados.length;
      
      // TIMEOUT PROTECTION
      if (stopwatch.elapsedMilliseconds > timeoutMs) {
        final completados = _estadoActual!.pasosCompletados.length;
        final faltantes = totalPasos - completados;
        throw TimeoutException(
          'TIMEOUT: Algoritmo excedió ${timeoutMs}ms. '
          'Completados: $completados/$totalPasos. Faltantes: $faltantes pasos.'
        );
      }
      
      _log('🔄 === ITERACIÓN $iteraciones ===');
      
      // Asignar recursos disponibles
      _asignarRecursosOptimizado();
      
      // Avanzar tiempo
      final proximoEvento = _estadoActual!.proximoEvento;
      if (proximoEvento != null && proximoEvento > _estadoActual!.tiempoActual) {
        _avanzarTiempo(proximoEvento);
      }
      
      // Procesar pasos terminados
      _procesarPasosTerminados();
      
      // Actualizar dependencias
      _actualizarDependencias();
      
      // DEADLOCK DETECTION MEJORADA
      final pasosCompletadosDespues = _estadoActual!.pasosCompletados.length;
      if (pasosCompletadosDespues == pasosCompletadosAntes) {
        iteracionesSinProgreso++;
        
        if (iteracionesSinProgreso >= maxSinProgreso) {
          final completados = _estadoActual!.pasosCompletados.length;
          final disponibles = _estadoActual!.pasosDisponibles.length;
          final pendientes = _estadoActual!.pasosPendientes.length;
          final faltantes = totalPasos - completados;
          
          // Análisis detallado del deadlock
          final analisisDeadlock = _analizarDeadlock();
          
          _log('🚨 DEADLOCK DETECTADO:');
          _log('   Completados: $completados/$totalPasos');
          _log('   Disponibles: $disponibles');
          _log('   Pendientes: $pendientes');
          _log('   Análisis: $analisisDeadlock');
          
          // Si hay pasos disponibles pero no se pueden asignar, es deadlock de recursos
          if (disponibles > 0) {
            throw DeadlockException(
              'DEADLOCK DE RECURSOS: $disponibles pasos disponibles pero sin recursos. '
              'Completados: $completados/$totalPasos. Análisis: $analisisDeadlock'
            );
          } else if (pendientes > 0) {
            throw DeadlockException(
              'DEADLOCK DE DEPENDENCIAS: $pendientes pasos con dependencias no resueltas. '
              'Completados: $completados/$totalPasos. Análisis: $analisisDeadlock'
            );
          }
        }
      } else {
        iteracionesSinProgreso = 0; // Reset counter si hay progreso
      }
      
      if (!_estadoActual!.hayTrabajoDisponible) break;
    }
    
    // VALIDACIÓN FINAL DE COMPLETITUD
    final pasosCompletados = _estadoActual!.pasosCompletados.length;
    if (pasosCompletados < totalPasos) {
      final faltantes = totalPasos - pasosCompletados;
      final pasosFaltantes = _estadoActual!.todosPasos
          .where((p) => !_estadoActual!.pasosCompletados.any((c) => c.id == p.id))
          .map((p) => '${p.nombre} (${p.id})')
          .toList();
      
      throw IncompletenessException(
        'ALGORITMO INCOMPLETO: $faltantes pasos no completados: $pasosFaltantes'
      );
    }
    
    _estadoActual!.completado = true;
    final tiempoFinal = stopwatch.elapsedMilliseconds;
    
    _log('🏁 Scheduling CORREGIDO completado en ${_estadoActual!.tiempoActual}s');
    _log('📊 Estadísticas: $pasosCompletados pasos, $iteraciones iteraciones, ${tiempoFinal}ms');
    
    return _estadoActual!.logEventos;
  }

  /// Asignar recursos con lógica mejorada
  void _asignarRecursosOptimizado() {
    final pasosOrdenados = _estadoActual!.pasosDisponibles.toList()
      ..sort((PasoSchedulingDinamico a, PasoSchedulingDinamico b) => b.prioridad.compareTo(a.prioridad));

    // Procesar pasos en orden de prioridad
    for (final paso in pasosOrdenados) {
      final combinacion = _encontrarMejorCombinacion(paso);
      if (combinacion != null) {
        _asignarRecursos(paso, combinacion.cocinero, combinacion.utensilio);
        
        // Look-ahead para pasos críticos
        if (_pasosEnCaminoCritico.contains(paso.id)) {
          _verificarDependientesCriticos(paso);
        }
      } else {
        // Log cuando no se puede asignar
        final tiposCocinero = _estadoActual!.cocineros.where((c) => c.tipo == paso.tipoCocinero).length;
        final tiposUtensilio = _estadoActual!.utensilios.where((u) => u.tipo == paso.tipoUtensilio).length;
        final cocinerosLibres = _estadoActual!.cocineros
            .where((c) => c.tipo == paso.tipoCocinero && _estaDisponible(c, _estadoActual!.tiempoActual))
            .length;
        final utensiliosLibres = _estadoActual!.utensilios
            .where((u) => u.tipo == paso.tipoUtensilio && _estaDisponible(u, _estadoActual!.tiempoActual))
            .length;
            
        _log('⏸️ NO SE PUEDE ASIGNAR "${paso.nombre}": requiere ${paso.tipoCocinero}+${paso.tipoUtensilio}');
        _log('   Disponibles: $cocinerosLibres/$tiposCocinero cocineros, $utensiliosLibres/$tiposUtensilio utensilios');
      }
    }
  }

  /// Analizar razones de deadlock
  String _analizarDeadlock() {
    final disponibles = _estadoActual!.pasosDisponibles;
    if (disponibles.isEmpty) {
      final pendientes = _estadoActual!.pasosPendientes;
      final dependenciasNoResueltas = <String, List<String>>{};
      
      for (final paso in pendientes) {
        dependenciasNoResueltas[paso.nombre] = paso.dependenciasPendientes;
      }
      
      return 'Sin pasos disponibles. Dependencias pendientes: $dependenciasNoResueltas';
    }
    
    // Analizar disponibilidad de recursos por tipo
    final recursosPorTipo = <String, Map<String, dynamic>>{};
    
    for (final paso in disponibles) {
      final tipoCocinero = paso.tipoCocinero;
      final tipoUtensilio = paso.tipoUtensilio;
      
      if (!recursosPorTipo.containsKey(tipoCocinero)) {
        final total = _estadoActual!.cocineros.where((c) => c.tipo == tipoCocinero).length;
        final libres = _estadoActual!.cocineros
            .where((c) => c.tipo == tipoCocinero && _estaDisponible(c, _estadoActual!.tiempoActual))
            .length;
        recursosPorTipo[tipoCocinero] = {'tipo': 'cocinero', 'total': total, 'libres': libres};
      }
      
      if (!recursosPorTipo.containsKey(tipoUtensilio)) {
        final total = _estadoActual!.utensilios.where((u) => u.tipo == tipoUtensilio).length;
        final libres = _estadoActual!.utensilios
            .where((u) => u.tipo == tipoUtensilio && _estaDisponible(u, _estadoActual!.tiempoActual))
            .length;
        recursosPorTipo[tipoUtensilio] = {'tipo': 'utensilio', 'total': total, 'libres': libres};
      }
    }
    
    final recursosInsuficientes = recursosPorTipo.entries
        .where((entry) => entry.value['libres'] == 0)
        .map((entry) => '${entry.key}: ${entry.value['libres']}/${entry.value['total']}')
        .toList();
    
    if (recursosInsuficientes.isNotEmpty) {
      return 'Recursos agotados: $recursosInsuficientes';
    }
    
    return 'Deadlock no identificado - posible error de lógica';
  }

  /// Calcular caminos críticos
  void _calcularCaminosCriticos() {
    _caminosCriticos.clear();
    
    for (final paso in _estadoActual!.todosPasos) {
      if (paso.dependenciasOriginales.isEmpty) {
        _calcularCaminoDesde(paso.id, [paso.id], 0);
      }
    }
    
    _log('🎯 Caminos críticos calculados: ${_caminosCriticos.keys.length}');
  }

  /// Calcular camino crítico desde un paso
  void _calcularCaminoDesde(String pasoInicial, List<String> caminoActual, int tiempoAcumulado) {
    final pasoActual = _estadoActual!.todosPasos.firstWhere((p) => p.id == caminoActual.last);
    final nuevoTiempo = tiempoAcumulado + pasoActual.duracion;
    
    final dependientes = _estadoActual!.todosPasos
        .where((p) => p.dependenciasOriginales.contains(pasoActual.id))
        .toList();
    
    if (dependientes.isEmpty) {
      if (nuevoTiempo > 300) {
        _caminosCriticos[pasoInicial] = List.from(caminoActual);
        _log('🛤️ Camino crítico: $pasoInicial -> $caminoActual (${nuevoTiempo}s)');
      }
    } else {
      for (final dependiente in dependientes) {
        if (!caminoActual.contains(dependiente.id)) {
          final nuevoCamino = List<String>.from(caminoActual)..add(dependiente.id);
          _calcularCaminoDesde(pasoInicial, nuevoCamino, nuevoTiempo);
        }
      }
    }
  }

  /// Identificar pasos en camino crítico
  void _identificarPasosEnCaminoCritico() {
    _pasosEnCaminoCritico.clear();
    for (final camino in _caminosCriticos.values) {
      _pasosEnCaminoCritico.addAll(camino);
    }
    _log('🔥 Pasos en camino crítico: $_pasosEnCaminoCritico');
  }

  /// Calcular impacto en makespan
  void _calcularImpactoEnMakespan() {
    _impactoEnMakespan.clear();
    for (final paso in _estadoActual!.todosPasos) {
      double impacto = paso.duracion.toDouble();
      if (_pasosEnCaminoCritico.contains(paso.id)) {
        impacto *= 3.0;
      }
      final numDependientes = _estadoActual!.todosPasos
          .where((p) => p.dependenciasOriginales.contains(paso.id))
          .length;
      impacto += numDependientes * 50.0;
      _impactoEnMakespan[paso.id] = impacto;
    }
  }

  /// Calcular prioridades optimizadas
  void _calcularPrioridadesOptimizadas() {
    for (final paso in _estadoActual!.todosPasos) {
      double prioridad = 0.0;
      
      if (_pasosEnCaminoCritico.contains(paso.id)) {
        prioridad = 10000.0 + _impactoEnMakespan[paso.id]!;
        _log('🔥 PRIORIDAD CRÍTICA: ${paso.nombre} = $prioridad');
      } else {
        final criticidad = paso.calcularCriticidad(_estadoActual!.todosPasos);
        prioridad = criticidad * 10.0 + paso.duracion;
      }
      
      paso.prioridad = prioridad.toInt();
    }
  }

  /// Verificar dependientes críticos
  void _verificarDependientesCriticos(PasoSchedulingDinamico pasoCompletado) {
    final dependientes = _estadoActual!.pasosPendientes
        .where((p) => p.dependenciasPendientes.contains(pasoCompletado.id))
        .where((p) => _pasosEnCaminoCritico.contains(p.id))
        .toList();
    
    for (final dependiente in dependientes) {
      _log('🔍 LOOK-AHEAD: Preparando recursos para dependiente crítico ${dependiente.nombre}');
      if (dependiente.dependenciasPendientes.length == 1) {
        _log('🎯 RESERVA: Recursos disponibles para ${dependiente.nombre} en T${pasoCompletado.tiempoFin}');
      }
    }
  }

  /// Marcar pasos disponibles iniciales
  void _marcarPasosDisponiblesIniciales() {
    for (final paso in _estadoActual!.todosPasos) {
      if (paso.dependenciasOriginales.isEmpty) {
        paso.estado = EstadoPaso.disponible;
        if (_pasosEnCaminoCritico.contains(paso.id)) {
          _log('🔥 Paso inicial disponible: ${paso.nombre}');
        } else {
          _log('🔓 Paso inicial disponible: ${paso.nombre}');
        }
      }
    }
  }

  // [Métodos auxiliares del algoritmo original]
  _CombinacionRecursos? _encontrarMejorCombinacion(PasoSchedulingDinamico paso) {
    final cocinerosDisponibles = _estadoActual!.cocineros
        .where((c) => c.tipo == paso.tipoCocinero && _estaDisponible(c, _estadoActual!.tiempoActual))
        .toList();

    final utensiliosDisponibles = _estadoActual!.utensilios
        .where((u) => u.tipo == paso.tipoUtensilio && _estaDisponible(u, _estadoActual!.tiempoActual))
        .toList();

    if (cocinerosDisponibles.isEmpty || utensiliosDisponibles.isEmpty) {
      return null;
    }

    _CombinacionRecursos? mejorCombinacion;
    int menorTiempoEspera = double.maxFinite.toInt();

    for (final cocinero in cocinerosDisponibles) {
      for (final utensilio in utensiliosDisponibles) {
        final tiempoInicioCocinero = _calcularProximoTiempoDisponible(cocinero);
        final tiempoInicioUtensilio = _calcularProximoTiempoDisponible(utensilio);
        final tiempoInicio = [tiempoInicioCocinero, tiempoInicioUtensilio, _estadoActual!.tiempoActual].reduce((a, b) => a > b ? a : b);
        
        final tiempoEspera = tiempoInicio - _estadoActual!.tiempoActual;
        
        if (tiempoEspera < menorTiempoEspera) {
          menorTiempoEspera = tiempoEspera;
          mejorCombinacion = _CombinacionRecursos(cocinero, utensilio, tiempoInicio);
        }
      }
    }

    return mejorCombinacion;
  }

  void _asignarRecursos(PasoSchedulingDinamico paso, CocineroScheduling cocinero, UtensilioScheduling utensilio) {
    final tiempoInicioCocinero = _calcularProximoTiempoDisponible(cocinero);
    final tiempoInicioUtensilio = _calcularProximoTiempoDisponible(utensilio);
    final tiempoInicio = [tiempoInicioCocinero, tiempoInicioUtensilio, _estadoActual!.tiempoActual].reduce((a, b) => a > b ? a : b);
    
    paso.iniciarEjecucion(tiempoInicio, cocinero.id, utensilio.id);
    
    cocinero.horario.add(HorarioItem(tiempoInicio: tiempoInicio, duracion: paso.duracion, pasoId: paso.id));
    utensilio.horario.add(HorarioItem(tiempoInicio: tiempoInicio, duracion: paso.duracion, pasoId: paso.id));
    
    _estadoActual!.agregarEvento('⚡ Iniciado: ${paso.nombre} (${cocinero.nombre}+${utensilio.nombre}) hasta T${paso.tiempoFin}');
    
    if (_pasosEnCaminoCritico.contains(paso.id)) {
      _log('🔥 Asignado paso "${paso.nombre}" a ${cocinero.nombre}+${utensilio.nombre} desde T$tiempoInicio hasta T${paso.tiempoFin}');
    } else {
      _log('⚡ Asignado paso "${paso.nombre}" a ${cocinero.nombre}+${utensilio.nombre} desde T$tiempoInicio hasta T${paso.tiempoFin}');
    }
  }

  void _avanzarTiempo(int nuevoTiempo) {
    _log('⏰ Avanzando tiempo de T${_estadoActual!.tiempoActual} a T$nuevoTiempo');
    _estadoActual!.tiempoActual = nuevoTiempo;
  }

  void _procesarPasosTerminados() {
    final pasosACompletar = _estadoActual!.pasosEnProceso
        .where((p) => p.tiempoFin == _estadoActual!.tiempoActual)
        .toList();

    for (final paso in pasosACompletar) {
      paso.completarEjecucion(_estadoActual!.tiempoActual);
      _estadoActual!.agregarEvento('✅ Completado: ${paso.nombre}');
      _log('✅ Completado paso "${paso.nombre}" en T${_estadoActual!.tiempoActual}');
    }
  }

  void _actualizarDependencias() {
    final pasosRecienCompletados = _estadoActual!.pasosCompletados
        .where((p) => p.tiempoFin == _estadoActual!.tiempoActual)
        .toList();

    for (final pasoCompletado in pasosRecienCompletados) {
      final pasosAfectados = _estadoActual!.pasosPendientes
          .where((p) => p.dependenciasPendientes.contains(pasoCompletado.id))
          .toList();

      for (final pasoAfectado in pasosAfectados) {
        pasoAfectado.completarDependencia(pasoCompletado.id);
        
        if (pasoAfectado.estaDisponible) {
          if (_pasosEnCaminoCritico.contains(pasoAfectado.id)) {
            _log('🔥 Paso "${pasoAfectado.nombre}" ahora disponible (crítico)');
          } else {
            _log('🔓 Paso "${pasoAfectado.nombre}" ahora disponible');
          }
        }
      }
    }
  }

  bool _estaDisponible(dynamic recurso, int tiempo) {
    return recurso.horario.every((HorarioItem item) => 
        (item.tiempoInicio + item.duracion) <= tiempo || item.tiempoInicio > tiempo);
  }

  int _calcularProximoTiempoDisponible(dynamic recurso) {
    if (recurso.horario.isEmpty) return _estadoActual!.tiempoActual;
    
    final ultimoTrabajo = recurso.horario
        .where((HorarioItem item) => (item.tiempoInicio + item.duracion) > _estadoActual!.tiempoActual)
        .fold<int>(_estadoActual!.tiempoActual, (int max, HorarioItem item) => 
            (item.tiempoInicio + item.duracion) > max ? (item.tiempoInicio + item.duracion) : max);
    
    return ultimoTrabajo;
  }

  void _log(String mensaje) {
    if (_debugMode) {
      print(mensaje);
    }
  }

  void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }
}

/// Clases de excepción para manejo de errores
class DeadlockException implements Exception {
  final String message;
  DeadlockException(this.message);
  
  @override
  String toString() => 'DeadlockException: $message';
}

class IncompletenessException implements Exception {
  final String message;
  IncompletenessException(this.message);
  
  @override
  String toString() => 'IncompletenessException: $message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: $message';
}

/// Clase auxiliar para representar una combinación de recursos
class _CombinacionRecursos {
  final CocineroScheduling cocinero;
  final UtensilioScheduling utensilio;
  final int tiempoInicio;

  _CombinacionRecursos(this.cocinero, this.utensilio, this.tiempoInicio);
}
