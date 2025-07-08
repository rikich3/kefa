import '../dataModels/estado_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/horario_item.dart';

/// Algoritmo de scheduling dinámico con manejo de dependencias en tiempo real
class SchedulingDinamicoAlgorithm {
  EstadoScheduling? _estadoActual;
  bool _debugMode = true;

  /// Getter para acceder al estado actual
  EstadoScheduling? get estadoActual => _estadoActual;

  /// Inicializar el algoritmo con pasos, cocineros y utensilios
  void inicializar({
    required List<PasoScheduling> pasos,
    required List<CocineroScheduling> cocineros,
    required List<UtensilioScheduling> utensilios,
  }) {
    _log('🚀 Inicializando scheduling dinámico');
    
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

    // Calcular prioridades y marcar pasos disponibles iniciales
    _calcularPrioridades();
    _marcarPasosDisponiblesIniciales();
    
    _log('📊 Estado inicial: ${_estadoActual}');
    _log('📋 Pasos disponibles inicialmente: ${_estadoActual!.pasosDisponibles.length}');
  }

  /// Ejecutar el algoritmo completo automáticamente
  List<String> ejecutarCompleto() {
    if (_estadoActual == null) {
      throw StateError('Debe inicializar el algoritmo primero');
    }

    _log('▶️ Iniciando ejecución completa del scheduling');
    
    int iteraciones = 0;
    const maxIteraciones = 1000; // Prevenir bucles infinitos
    
    while (_estadoActual!.hayTrabajoDisponible && iteraciones < maxIteraciones) {
      iteraciones++;
      _log('\\n🔄 === ITERACIÓN $iteraciones ===');
      
      // Paso 1: Asignar recursos a pasos disponibles
      _asignarRecursosAPasosDisponibles();
      
      // Paso 2: Avanzar tiempo hasta el próximo evento
      final proximoEvento = _estadoActual!.proximoEvento;
      if (proximoEvento != null && proximoEvento > _estadoActual!.tiempoActual) {
        _avanzarTiempo(proximoEvento);
      }
      
      // Paso 3: Procesar pasos que terminan en este momento
      _procesarPasosTerminados();
      
      // Paso 4: Actualizar dependencias y liberar pasos
      _actualizarDependencias();
      
      if (!_estadoActual!.hayTrabajoDisponible) {
        _log('✅ Todos los pasos han sido completados');
        break;
      }
    }
    
    _estadoActual!.completado = true;
    _log('🏁 Scheduling completado en ${_estadoActual!.tiempoActual} segundos');
    
    return _estadoActual!.logEventos;
  }

  /// Ejecutar una sola iteración (para debugging paso a paso)
  bool ejecutarPaso() {
    if (_estadoActual == null || !_estadoActual!.hayTrabajoDisponible) {
      return false;
    }

    _asignarRecursosAPasosDisponibles();
    
    final proximoEvento = _estadoActual!.proximoEvento;
    if (proximoEvento != null && proximoEvento > _estadoActual!.tiempoActual) {
      _avanzarTiempo(proximoEvento);
    }
    
    _procesarPasosTerminados();
    _actualizarDependencias();
    
    return _estadoActual!.hayTrabajoDisponible;
  }

  /// Asignar recursos disponibles a pasos listos
  void _asignarRecursosAPasosDisponibles() {
    final pasosOrdenados = _estadoActual!.pasosDisponibles.toList()
      ..sort((PasoSchedulingDinamico a, PasoSchedulingDinamico b) => b.prioridad.compareTo(a.prioridad)); // Mayor prioridad primero

    for (final paso in pasosOrdenados) {
      final combinacion = _encontrarMejorCombinacion(paso);
      if (combinacion != null) {
        _asignarRecursos(paso, combinacion.cocinero, combinacion.utensilio);
      }
    }
  }

  /// Encontrar la mejor combinación cocinero-utensilio para un paso
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

    // Buscar la combinación óptima (menor tiempo de espera)
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

  /// Asignar recursos específicos a un paso
  void _asignarRecursos(PasoSchedulingDinamico paso, CocineroScheduling cocinero, UtensilioScheduling utensilio) {
    final tiempoInicioCocinero = _calcularProximoTiempoDisponible(cocinero);
    final tiempoInicioUtensilio = _calcularProximoTiempoDisponible(utensilio);
    final tiempoInicio = [tiempoInicioCocinero, tiempoInicioUtensilio, _estadoActual!.tiempoActual].reduce((a, b) => a > b ? a : b);
    
    paso.iniciarEjecucion(tiempoInicio, cocinero.id, utensilio.id);
    
    // Reservar recursos
    cocinero.horario.add(HorarioItem(tiempoInicio: tiempoInicio, duracion: paso.duracion, pasoId: paso.id));
    utensilio.horario.add(HorarioItem(tiempoInicio: tiempoInicio, duracion: paso.duracion, pasoId: paso.id));
    
    _estadoActual!.agregarEvento('⚡ Iniciado: ${paso.nombre} (${cocinero.nombre}+${utensilio.nombre}) hasta T${paso.tiempoFin}');
    
    _log('⚡ Asignado paso "${paso.nombre}" a ${cocinero.nombre}+${utensilio.nombre} desde T$tiempoInicio hasta T${paso.tiempoFin}');
  }

  /// Avanzar el tiempo del sistema
  void _avanzarTiempo(int nuevoTiempo) {
    _log('⏰ Avanzando tiempo de T${_estadoActual!.tiempoActual} a T$nuevoTiempo');
    _estadoActual!.tiempoActual = nuevoTiempo;
  }

  /// Procesar pasos que terminan en el tiempo actual
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

  /// Actualizar dependencias cuando se completan pasos
  void _actualizarDependencias() {
    final pasosRecienCompletados = _estadoActual!.pasosCompletados
        .where((p) => p.tiempoFin == _estadoActual!.tiempoActual)
        .toList();

    for (final pasoCompletado in pasosRecienCompletados) {
      // Buscar pasos que dependían de este
      final pasosAfectados = _estadoActual!.pasosPendientes
          .where((p) => p.dependenciasPendientes.contains(pasoCompletado.id))
          .toList();

      for (final pasoAfectado in pasosAfectados) {
        pasoAfectado.completarDependencia(pasoCompletado.id);
        
        if (pasoAfectado.estaDisponible) {
          _log('🔓 Paso "${pasoAfectado.nombre}" ahora disponible (dependencias resueltas)');
        }
      }
    }
  }

  /// Marcar pasos sin dependencias como disponibles al inicio
  void _marcarPasosDisponiblesIniciales() {
    for (final paso in _estadoActual!.todosPasos) {
      if (paso.dependenciasOriginales.isEmpty) {
        paso.estado = EstadoPaso.disponible;
        _log('🔓 Paso inicial disponible: ${paso.nombre}');
      }
    }
  }

  /// Calcular prioridades de todos los pasos
  void _calcularPrioridades() {
    for (final paso in _estadoActual!.todosPasos) {
      final criticidad = paso.calcularCriticidad(_estadoActual!.todosPasos);
      paso.prioridad = criticidad * 10 + paso.duracion; // Criticidad pesa más que duración
    }
  }

  /// Verificar si un recurso está disponible en un momento dado
  bool _estaDisponible(dynamic recurso, int tiempo) {
    return recurso.horario.every((HorarioItem item) => 
        (item.tiempoInicio + item.duracion) <= tiempo || item.tiempoInicio > tiempo);
  }

  /// Calcular el próximo momento en que un recurso estará disponible
  int _calcularProximoTiempoDisponible(dynamic recurso) {
    if (recurso.horario.isEmpty) return _estadoActual!.tiempoActual;
    
    final ultimoTrabajo = recurso.horario
        .where((HorarioItem item) => (item.tiempoInicio + item.duracion) > _estadoActual!.tiempoActual)
        .fold<int>(_estadoActual!.tiempoActual, (int max, HorarioItem item) => 
            (item.tiempoInicio + item.duracion) > max ? (item.tiempoInicio + item.duracion) : max);
    
    return ultimoTrabajo;
  }

  /// Logging interno
  void _log(String mensaje) {
    if (_debugMode) {
      print(mensaje);
    }
  }

  /// Activar/desactivar modo debug
  void setDebugMode(bool enabled) {
    _debugMode = enabled;
  }
}

/// Clase auxiliar para representar una combinación de recursos
class _CombinacionRecursos {
  final CocineroScheduling cocinero;
  final UtensilioScheduling utensilio;
  final int tiempoInicio;

  _CombinacionRecursos(this.cocinero, this.utensilio, this.tiempoInicio);
}
