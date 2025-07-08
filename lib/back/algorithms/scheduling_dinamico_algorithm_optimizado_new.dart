import 'dart:math';  // For min/max functions
import '../dataModels/estado_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/horario_item.dart';

/// Estados posibles de un paso
enum EstadoPaso {
  pendiente,
  enProceso,
  completado
}

/// Extensión para pasos con información dinámica adicional
class PasoSchedulingDinamico extends PasoScheduling {
  EstadoPaso estado = EstadoPaso.pendiente;
  int tiempoInicio = 0;
  int tiempoFin = 0;
  List<String> dependenciasPendientes = [];
  
  PasoSchedulingDinamico.fromPasoScheduling(PasoScheduling paso)
      : super(
          id: paso.id,
          nombre: paso.nombre,
          duracion: paso.duracion,
          dependencias: paso.dependencias,
        ) {
    dependenciasPendientes = List.from(paso.dependencias);
  }
  
  void iniciarEjecucion(int tiempo) {
    estado = EstadoPaso.enProceso;
    tiempoInicio = tiempo;
    tiempoFin = tiempo + duracion;
  }
  
  void completarEjecucion(int tiempo) {
    estado = EstadoPaso.completado;
    tiempoFin = tiempo;
  }
}

/// Algoritmo de scheduling dinámico OPTIMIZADO con detección de camino crítico
class SchedulingDinamicoAlgorithmOptimizado {
  EstadoScheduling? _estadoActual;
  bool _debugMode = true;
  DateTime _tiempoInicio = DateTime.now();
  int _ultimosCompletados = 0;
  
  // NUEVAS ESTRUCTURAS PARA OPTIMIZACIÓN
  Map<String, List<String>> _caminosCriticos = {};
  Map<String, double> _impactoEnMakespan = {};
  Set<String> _pasosEnCaminoCritico = {};

  /// Getter para acceder al estado actual
  EstadoScheduling? get estadoActual => _estadoActual;

  /// Debug logging
  void _log(String mensaje) {
    if (_debugMode) print(mensaje);
  }

  /// Inicializar el algoritmo con pasos, cocineros y utensilios
  void inicializar({
    required List<PasoScheduling> pasos,
    required List<CocineroScheduling> cocineros,
    required List<UtensilioScheduling> utensilios,
  }) {
    _log('🚀 Inicializando scheduling dinámico OPTIMIZADO');
    
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

    // NUEVAS OPTIMIZACIONES
    _calcularCaminosCriticos();
    _identificarPasosEnCaminoCritico();
  }

  /// Ejecuta el algoritmo de scheduling hasta que todos los pasos estén completados
  /// o se detecte un deadlock
  EstadoScheduling ejecutarCompleto() {
    if (_estadoActual == null) {
      throw Exception('No se ha inicializado el algoritmo');
    }

    _log('\n🔄 INICIANDO EJECUCIÓN COMPLETA');
    _tiempoInicio = DateTime.now();
    _ultimosCompletados = 0;

    while (!_todosPasosCompletados()) {
      // Procesar pasos que terminan en el tiempo actual
      _procesarPasosTerminados();

      // Intentar programar nuevos pasos
      final nuevosAsignados = _asignarNuevosPasos();
      if (nuevosAsignados == 0 && _estadoActual!.pasosEnProceso.isEmpty) {
        // No se pudieron asignar nuevos pasos y no hay pasos en proceso = deadlock
        _diagnosticarPasosIncompletos();
        throw Exception('Deadlock detectado: No se pueden asignar más pasos');
      }

      // Avanzar al siguiente evento
      final siguienteTiempo = _encontrarSiguienteTiempo();
      if (siguienteTiempo > _estadoActual!.tiempoActual) {
        _avanzarTiempo(siguienteTiempo);
      } else {
        // No hay más eventos futuros = deadlock
        _diagnosticarPasosIncompletos();
        throw Exception('Deadlock detectado: No hay eventos futuros');
      }

      // Detectar estancamiento
      final completados = _contarPasosCompletados();
      if (completados == _ultimosCompletados) {
        final tiempoTranscurrido = DateTime.now().difference(_tiempoInicio).inSeconds;
        if (tiempoTranscurrido > 10) { // 10 segundos de timeout
          _diagnosticarPasosIncompletos();
          throw Exception('Timeout: Posible estancamiento detectado');
        }
      } else {
        _ultimosCompletados = completados;
        _tiempoInicio = DateTime.now(); // Reiniciar timeout
      }
    }

    _log('\n✨ EJECUCIÓN COMPLETA FINALIZADA');
    return _estadoActual!;
  }

  /// Cuenta el número de pasos completados
  int _contarPasosCompletados() {
    return _estadoActual!.todosPasos
        .where((p) => p.estado == EstadoPaso.completado)
        .length;
  }

  /// Verifica si todos los pasos están completados
  bool _todosPasosCompletados() {
    return _estadoActual!.todosPasos
        .every((p) => p.estado == EstadoPaso.completado);
  }

  /// Encuentra el siguiente tiempo de evento (fin de paso o inicio posible)
  int _encontrarSiguienteTiempo() {
    final tiemposFinPasos = _estadoActual!.pasosEnProceso
        .map((p) => p.tiempoFin)
        .where((t) => t > _estadoActual!.tiempoActual);
    
    final tiemposDisponibilidad = _estadoActual!.todosPasos
        .where((p) => p.estado == EstadoPaso.pendiente && _todasDependenciasCompletadas(p))
        .map((p) => _encontrarSiguienteDisponibilidad(p))
        .where((t) => t > _estadoActual!.tiempoActual);

    final todosEventos = [...tiemposFinPasos, ...tiemposDisponibilidad];
    return todosEventos.isEmpty ? _estadoActual!.tiempoActual : todosEventos.reduce(min);
  }

  /// Encuentra el siguiente tiempo en que los recursos estarán disponibles para un paso
  int _encontrarSiguienteDisponibilidad(PasoSchedulingDinamico paso) {
    // Lista de tiempos de disponibilidad de cocineros y utensilios
    final tiemposDisponibilidad = <int>[];
    
    for (final cocinero in _estadoActual!.cocineros) {
      for (final utensilio in _estadoActual!.utensilios) {
        if (paso.cocineroRequerido == cocinero.id && 
            paso.utensilioRequerido == utensilio.id) {
          // Encontrar el primer momento en que ambos recursos están disponibles
          final tiempoCocinero = _siguienteDisponibilidad(cocinero);
          final tiempoUtensilio = _siguienteDisponibilidad(utensilio);
          tiemposDisponibilidad.add(max(tiempoCocinero, tiempoUtensilio));
        }
      }
    }
    
    return tiemposDisponibilidad.isEmpty ? 
        _estadoActual!.tiempoActual : 
        tiemposDisponibilidad.reduce(min);
  }

  /// Encuentra el siguiente tiempo en que un recurso estará disponible
  int _siguienteDisponibilidad(dynamic recurso) {
    if (recurso.horario.isEmpty) {
      return _estadoActual!.tiempoActual;
    }
    return recurso.horario
        .map((item) => item.tiempoInicio + item.duracion)
        .reduce(max);
  }

  /// Asigna nuevos pasos para ejecución
  int _asignarNuevosPasos() {
    int asignados = 0;
    final pasosPendientes = _estadoActual!.todosPasos
        .where((p) => p.estado == EstadoPaso.pendiente)
        .where((p) => _todasDependenciasCompletadas(p))
        .toList();

    // Ordenar por prioridad y camino crítico
    pasosPendientes.sort((a, b) {
      if (_pasosEnCaminoCritico.contains(a.id) != _pasosEnCaminoCritico.contains(b.id)) {
        return _pasosEnCaminoCritico.contains(a.id) ? -1 : 1;
      }
      final impactoA = _impactoEnMakespan[a.id] ?? 0;
      final impactoB = _impactoEnMakespan[b.id] ?? 0;
      return impactoB.compareTo(impactoA);
    });

    for (final paso in pasosPendientes) {
      final mejorCombinacion = _encontrarMejorCombinacion(paso);
      if (mejorCombinacion != null) {
        _asignarRecursos(paso, mejorCombinacion);
        asignados++;
      }
    }

    return asignados;
  }

  /// Encuentra la mejor combinación de recursos para un paso
  _CombinacionRecursos? _encontrarMejorCombinacion(PasoSchedulingDinamico paso) {
    _CombinacionRecursos? mejorCombinacion;
    
    for (final cocinero in _estadoActual!.cocineros) {
      for (final utensilio in _estadoActual!.utensilios) {
        if (paso.cocineroRequerido == cocinero.id && 
            paso.utensilioRequerido == utensilio.id &&
            _puedeEjecutarse(paso, cocinero, utensilio, _estadoActual!.tiempoActual)) {
          final nuevaCombinacion = _CombinacionRecursos(
            cocinero, 
            utensilio, 
            _estadoActual!.tiempoActual
          );
          
          if (mejorCombinacion == null) {
            mejorCombinacion = nuevaCombinacion;
          }
        }
      }
    }
    
    return mejorCombinacion;
  }

  /// Asigna recursos a un paso y lo inicia
  void _asignarRecursos(PasoSchedulingDinamico paso, _CombinacionRecursos combinacion) {
    paso.iniciarEjecucion(_estadoActual!.tiempoActual);
    
    // Agregar al horario de los recursos
    final horarioItem = HorarioItem(
      pasoId: paso.id,
      tiempoInicio: combinacion.tiempoInicio,
      duracion: paso.duracion
    );
    
    combinacion.cocinero.horario.add(horarioItem);
    combinacion.utensilio.horario.add(horarioItem);
    
    _log('✨ Asignado "${paso.nombre}" a C${combinacion.cocinero.id}/U${combinacion.utensilio.id} en T${_estadoActual!.tiempoActual}');
  }

  /// Verificar si un recurso está disponible en un momento dado
  bool _estaDisponible(dynamic recurso, int tiempo) {
    return recurso.horario.every((HorarioItem item) => 
        (item.tiempoInicio + item.duracion) <= tiempo || item.tiempoInicio > tiempo);
  }

  /// Verificar si un paso puede ejecutarse con un conjunto de recursos
  bool _puedeEjecutarse(PasoSchedulingDinamico paso, CocineroScheduling cocinero, UtensilioScheduling utensilio, int tiempo) {
    // Verificar disponibilidad de recursos
    if (!_estaDisponible(cocinero, tiempo) || !_estaDisponible(utensilio, tiempo)) {
      return false;
    }
    
    // Si es paso crítico, verificar que no hay otros pasos críticos en ejecución
    if (_pasosEnCaminoCritico.contains(paso.id)) {
      final hayCriticosEnEjecucion = _estadoActual!.pasosEnProceso
          .where((p) => _pasosEnCaminoCritico.contains(p.id))
          .isNotEmpty;
      if (hayCriticosEnEjecucion) {
        return false;
      }
    }
    
    return true;
  }

  /// Verifica si todas las dependencias de un paso están completadas
  bool _todasDependenciasCompletadas(PasoSchedulingDinamico paso) {
    return paso.dependenciasPendientes.isEmpty;
  }

  /// Calcular caminos críticos del proyecto
  void _calcularCaminosCriticos() {
    _caminosCriticos.clear();
    _impactoEnMakespan.clear();
    
    // TODO: Implementar cálculo de caminos críticos
    // Por ahora, una implementación simple basada en duración y dependencias
    for (final paso in _estadoActual!.todosPasos) {
      _impactoEnMakespan[paso.id] = paso.duracion.toDouble();
    }
  }

  /// Identificar pasos que están en el camino crítico
  void _identificarPasosEnCaminoCritico() {
    _pasosEnCaminoCritico.clear();
    
    // TODO: Implementar identificación de pasos en camino crítico
    // Por ahora, identificar pasos con mayor impacto
    final maxImpacto = _impactoEnMakespan.values.reduce(max);
    _pasosEnCaminoCritico.addAll(
      _impactoEnMakespan.entries
        .where((e) => e.value >= maxImpacto * 0.8)
        .map((e) => e.key)
    );
  }

  /// Verificar dependientes después de completar un paso
  void _verificarDependientesCriticosConservador(PasoSchedulingDinamico paso) {
    final todosPasos = _estadoActual!.todosPasos;
    for (final otroPaso in todosPasos) {
      otroPaso.dependenciasPendientes.remove(paso.id);
    }
  }
}

/// Clase auxiliar para representar una combinación de recursos
class _CombinacionRecursos {
  final CocineroScheduling cocinero;
  final UtensilioScheduling utensilio;
  final int tiempoInicio;

  _CombinacionRecursos(this.cocinero, this.utensilio, this.tiempoInicio);
}
