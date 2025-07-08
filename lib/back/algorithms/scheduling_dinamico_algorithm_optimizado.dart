import 'dart:math';  // For min/max functions

import '../dataModels/estado_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/horario_item.dart';

import 'package:hive/hive.dart';

/// Importaciones necesarias
import 'dart:math';

part 'scheduling_dinamico_algorithm_optimizado.g.dart';

/// Clase auxiliar para representar una combinación de recursos
class _CombinacionRecursos {
  final CocineroScheduling cocinero;
  final UtensilioScheduling utensilio;
  final int tiempoInicio;

  _CombinacionRecursos(this.cocinero, this.utensilio, this.tiempoInicio);
}

/// Estados posibles de un paso en el scheduling
@HiveType(typeId: 14)
enum EstadoPaso {
  @HiveField(0)
  pendiente,
  
  @HiveField(1)
  disponible,
  
  @HiveField(2)
  enProceso,
  
  @HiveField(3)
  completado
}

/// Información extendida de un paso para el scheduling dinámico
@HiveType(typeId: 15)
class PasoSchedulingDinamico extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String tipoCocinero;

  @HiveField(3)
  String tipoUtensilio;

  @HiveField(4)
  int duracion;

  @HiveField(5)
  List<String> dependenciasOriginales; // Nunca se modifica

  @HiveField(6)
  List<String> dependenciasPendientes; // Se reduce dinámicamente

  @HiveField(7)
  EstadoPaso estado;
  
  @HiveField(8)
  int? tiempoInicio;

  @HiveField(9)
  int? tiempoFin;

  @HiveField(10)
  int prioridad = 0;

  PasoSchedulingDinamico({
    required this.id,
    required this.nombre,
    required this.tipoCocinero,
    required this.tipoUtensilio,
    required this.duracion,
    required this.dependenciasOriginales,
    required this.dependenciasPendientes,
    required this.estado,
  });

  factory PasoSchedulingDinamico.fromPasoScheduling(PasoScheduling paso) {
    return PasoSchedulingDinamico(
      id: paso.id,
      nombre: paso.nombre,
      tipoCocinero: paso.tipoCocinero,
      tipoUtensilio: paso.tipoUtensilio,
      duracion: paso.duracion,
      dependenciasOriginales: List.from(paso.dependencias),
      dependenciasPendientes: List.from(paso.dependencias),
      estado: EstadoPaso.pendiente,
    );
  }

  void completarDependencia(String dependenciaId) {
    dependenciasPendientes.remove(dependenciaId);
    if (dependenciasPendientes.isEmpty) {
      estado = EstadoPaso.disponible;
    }
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

  bool get estaDisponible => estado == EstadoPaso.disponible;
  bool get estaEnProceso => estado == EstadoPaso.enProceso;
  bool get estaCompletado => estado == EstadoPaso.completado;
  bool get estaPendiente => estado == EstadoPaso.pendiente;

  @override
  String toString() {
    return 'PasoSchedulingDinamico($nombre, $estado)';
  }
}

  PasoSchedulingDinamico.fromPasoScheduling(PasoScheduling paso)
      : id = paso.id,
        nombre = paso.nombre,
        tipoCocinero = paso.tipoCocinero,
        tipoUtensilio = paso.tipoUtensilio,
        duracion = paso.duracion,
        dependenciasOriginales = List.from(paso.dependencias),
        dependenciasPendientes = List.from(paso.dependencias),
        estado = EstadoPaso.pendiente;
  
  PasoSchedulingDinamico.fromPasoBasico(PasoScheduling paso)
      : id = paso.id,
        nombre = paso.nombre,
        tipoCocinero = paso.tipoCocinero,
        tipoUtensilio = paso.tipoUtensilio,
        duracion = paso.duracion,
        dependenciasOriginales = List.from(paso.dependencias),
        dependenciasPendientes = List.from(paso.dependencias),
        estado = EstadoPaso.pendiente;
  
  void iniciarEjecucion(int tiempo) {
    estado = EstadoPaso.enProceso;
    tiempoInicio = tiempo;
    tiempoFin = tiempo + duracion;
  }
  
  void completarEjecucion(int tiempo) {
    estado = EstadoPaso.completado;
    tiempoFin = tiempo;
  }

  void completarDependencia(String dependenciaId) {
    dependenciasPendientes.remove(dependenciaId);
    if (estaDisponible) {
      estado = EstadoPaso.disponible;
    }
  }

  bool get estaDisponible => dependenciasPendientes.isEmpty;

  double calcularCriticidad(List<PasoSchedulingDinamico> todosPasos) {
    double criticidad = duracion.toDouble();
    
    // Encontrar pasos que dependen de este
    final dependientes = todosPasos
        .where((p) => p.dependenciasOriginales.contains(id))
        .toList();
    
    if (dependientes.isNotEmpty) {
      criticidad += dependientes.fold(0.0, 
          (sum, dep) => sum + dep.duracion / 2);
    }
    
    return criticidad;
  }
}

/// Algoritmo de scheduling dinámico OPTIMIZADO con detección de camino crítico
class SchedulingDinamicoAlgorithmOptimizado {
  EstadoScheduling? _estadoActual;
  bool _debugMode = true;
  DateTime _tiempoInicio = DateTime.now();
  int _ultimosCompletados = 0;
  List<String> _logEventos = [];
  
  /// Constructor con inicialización de recursos
  SchedulingDinamicoAlgorithmOptimizado({
    required List<CocineroScheduling> cocineros,
    required List<UtensilioScheduling> utensilios,
    required List<PasoScheduling> pasos,
  }) {
    _estadoActual = EstadoScheduling();
    _estadoActual!.cocineros = List.from(cocineros);
    _estadoActual!.utensilios = List.from(utensilios);
    _estadoActual!.pasos = pasos.map((p) => PasoSchedulingDinamico(
      id: p.id,
      nombre: p.nombre,
      tipoCocinero: p.tipoCocinero,
      tipoUtensilio: p.tipoUtensilio,
      duracion: p.duracion,
      dependenciasOriginales: List.from(p.dependencias),
      dependenciasPendientes: List.from(p.dependencias),
      estado: EstadoPaso.pendiente,
    )).toList();
  }
  
  // NUEVAS ESTRUCTURAS PARA OPTIMIZACIÓN
  Map<String, List<String>> _caminosCriticos = {};
  Map<String, double> _impactoEnMakespan = {};
  Set<String> _pasosEnCaminoCritico = {};

  /// Getter para acceder al estado actual
  EstadoScheduling? get estadoActual => _estadoActual;

  /// Debug logging
  void _log(String mensaje) {
    if (_debugMode) {
      print(mensaje);
      _logEventos.add(mensaje);
    }
  }

  /// Debug logging
  String _diagnosticarRazonNoAsignacion(PasoSchedulingDinamico paso) {
    if (paso.dependenciasPendientes.isNotEmpty) {
      return "Dependencias pendientes: ${paso.dependenciasPendientes}";
    }
    return "Recursos no disponibles";
  }

  /// Marca los pasos que están disponibles inicialmente
  void _marcarPasosDisponiblesIniciales() {
    for (final paso in _estadoActual!.todosPasos) {
      if (paso.dependenciasPendientes.isEmpty) {
        paso.estado = EstadoPaso.disponible;
      }
    }
  }

  /// Verifica si todos los pasos están completados
  bool _todosPasosCompletados() {
    return _estadoActual!.todosPasos
        .every((p) => p.estado == EstadoPaso.completado);
  }

  /// Verifica si un paso está completado
  bool _estaCompletado(PasoSchedulingDinamico paso) {
    return paso.estado == EstadoPaso.completado;
  }

  /// Procesa pasos que han terminado en el tiempo actual
  void _procesarPasosTerminados() {
    final pasosACompletar = _estadoActual!.todosPasos
        .where((p) => p.estado == EstadoPaso.enProceso)
        .where((p) => p.tiempoFin != null && p.tiempoFin == _estadoActual!.tiempoActual)
        .toList();

    for (final paso in pasosACompletar) {
      paso.completarEjecucion(_estadoActual!.tiempoActual);
      _log('✅ Completado paso "${paso.nombre}" en T${_estadoActual!.tiempoActual}');
      _verificarDependientesCriticosConservador(paso);
    }
  }

  /// Diagnostica los pasos que quedaron incompletos
  void _diagnosticarPasosIncompletos() {
    final pasosIncompletos = _estadoActual!.todosPasos
        .where((p) => p.estado != EstadoPaso.completado)
        .toList();

    if (pasosIncompletos.isNotEmpty) {
      _log('\n❌ PASOS INCOMPLETOS DETECTADOS:');
      for (final paso in pasosIncompletos) {
        _log('  - ${paso.nombre} (${paso.estado})');
        if (paso.dependenciasPendientes.isNotEmpty) {
          _log('    Dependencias pendientes: ${paso.dependenciasPendientes}');
        }
      }
    }
  }

  /// Verifica que todas las dependencias estén completas
  bool _todasDependenciasCompletadas(PasoSchedulingDinamico paso) {
    return paso.dependenciasPendientes.isEmpty;
  }

  /// Verifica si un recurso está disponible
  bool _estaDisponible(dynamic recurso, int tiempo) {
    return recurso.horario.every((item) => 
      (item.tiempoInicio + item.duracion) <= tiempo || item.tiempoInicio > tiempo);
  }

  /// Avanzar el tiempo del sistema
  void _avanzarTiempo(int nuevoTiempo) {
    _log('⏰ Avanzando tiempo de T${_estadoActual!.tiempoActual} a T$nuevoTiempo');
    _estadoActual!.tiempoActual = nuevoTiempo;
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
    _calcularImpactoEnMakespan();
    
    // Calcular prioridades con nuevo algoritmo optimizado
    _calcularPrioridadesOptimizadas();
    _marcarPasosDisponiblesIniciales();
    
    _log('📊 Estado inicial optimizado: ${_estadoActual}');
    _log('🔥 Pasos en camino crítico detectados: ${_pasosEnCaminoCritico.length}');
    _log('📋 Pasos disponibles inicialmente: ${_estadoActual!.pasosDisponibles.length}');
  }

  /// NUEVA FUNCIÓN CORREGIDA: Calcular caminos críticos conservadores
  void _calcularCaminosCriticos() {
    _caminosCriticos.clear();
    
    // Identificar caminos críticos más agresivamente (>30% del tiempo total estimado)
    final duracionTotalEstimada = _estadoActual!.todosPasos.fold(0, (sum, p) => sum + p.duracion);
    final umbralCritico = (duracionTotalEstimada * 0.3).round(); // 30% del tiempo total
    
    for (final paso in _estadoActual!.todosPasos) {
      if (paso.dependenciasOriginales.isEmpty) {
        // Paso inicial - calcular camino desde aquí
        _calcularCaminoDesde(paso.id, [paso.id], 0, umbralCritico);
      }
    }
    
    _log('🎯 Caminos críticos calculados (umbral: ${umbralCritico}s): ${_caminosCriticos.keys.length}');
  }

  /// NUEVA FUNCIÓN CORREGIDA: Calcular camino crítico desde un paso dado
  void _calcularCaminoDesde(String pasoInicial, List<String> caminoActual, int tiempoAcumulado, int umbralCritico) {
    // Evitar cadenas demasiado largas
    if (caminoActual.length > 15) {
      return;
    }
    
    final pasoActual = _estadoActual!.todosPasos.firstWhere((p) => p.id == caminoActual.last);
    final nuevoTiempo = tiempoAcumulado + pasoActual.duracion;
    
    // Encontrar pasos que dependen de este
    final dependientes = _estadoActual!.todosPasos
        .where((p) => p.dependenciasOriginales.contains(pasoActual.id))
        .toList();
    
    if (dependientes.isEmpty) {
      // Fin del camino - guardar solo si supera el umbral crítico
      if (nuevoTiempo >= umbralCritico) {
        _caminosCriticos[pasoInicial] = List.from(caminoActual);
        _log('🛤️ Camino crítico encontrado desde $pasoInicial: $caminoActual (${nuevoTiempo}s)');
      }
    } else {
      // Continuar el camino con cada dependiente
      for (final dependiente in dependientes) {
        if (!caminoActual.contains(dependiente.id)) { // Evitar ciclos
          final nuevoCamino = List<String>.from(caminoActual)..add(dependiente.id);
          _calcularCaminoDesde(pasoInicial, nuevoCamino, nuevoTiempo, umbralCritico);
        }
      }
    }
  }

  /// NUEVA FUNCIÓN: Identificar qué pasos están en algún camino crítico
  void _identificarPasosEnCaminoCritico() {
    _pasosEnCaminoCritico.clear();
    
    for (final camino in _caminosCriticos.values) {
      _pasosEnCaminoCritico.addAll(camino);
    }
    
    _log('🔥 Pasos identificados en camino crítico: $_pasosEnCaminoCritico');
  }

  /// NUEVA FUNCIÓN: Calcular impacto de cada paso en el makespan total
  void _calcularImpactoEnMakespan() {
    _impactoEnMakespan.clear();
    
    for (final paso in _estadoActual!.todosPasos) {
      double impacto = 0.0;
      
      // Impacto base por duración
      impacto += paso.duracion.toDouble();
      
      // Impacto multiplicado si está en camino crítico
      if (_pasosEnCaminoCritico.contains(paso.id)) {
        // Dar más peso a los pasos iniciales del camino crítico
        final esInicial = paso.dependenciasOriginales.isEmpty;
        impacto *= esInicial ? 5.0 : 3.0; // 5x para pasos iniciales, 3x para el resto
      }
      
      // Impacto adicional por número y tipo de dependientes
      final dependientes = _estadoActual!.todosPasos
          .where((p) => p.dependenciasOriginales.contains(paso.id));
      
      for (final dep in dependientes) {
        // Más peso si el dependiente también es crítico
        final multiplicador = _pasosEnCaminoCritico.contains(dep.id) ? 100.0 : 50.0;
        impacto += multiplicador;
      }
      
      _impactoEnMakespan[paso.id] = impacto;
    }
  }

  /// FUNCIÓN OPTIMIZADA MEJORADA: Calcular prioridades con énfasis en inicio temprano
  void _calcularPrioridadesOptimizadas() {
    for (final paso in _estadoActual!.todosPasos) {
      double prioridad = 0.0;
      
      // Detectar si es un paso inicial crítico
      final esInicial = paso.dependenciasOriginales.isEmpty;
      final esCritico = _pasosEnCaminoCritico.contains(paso.id);
      
      if (esCritico) {
        if (esInicial) {
          // Máxima prioridad para pasos iniciales en camino crítico
          prioridad = 10000.0 + _impactoEnMakespan[paso.id]!;
          _log('🔥 PRIORIDAD MÁXIMA INICIAL: ${paso.nombre} = $prioridad');
        } else {
          // Alta prioridad para otros pasos críticos
          prioridad = 5000.0 + _impactoEnMakespan[paso.id]!;
          _log('🔥 PRIORIDAD CRÍTICA: ${paso.nombre} = $prioridad');
        }
      } else if (esInicial) {
        // Prioridad aumentada para pasos iniciales no críticos
        final criticidad = paso.calcularCriticidad(_estadoActual!.todosPasos);
        prioridad = 3000.0 + (criticidad * 10 + paso.duracion);
        _log('⭐ PRIORIDAD INICIAL: ${paso.nombre} = $prioridad');
      } else {
        // Prioridad normal para otros pasos
        final criticidad = paso.calcularCriticidad(_estadoActual!.todosPasos);
        prioridad = (criticidad * 10 + paso.duracion).toDouble();
      }
      
      paso.prioridad = prioridad.toInt();
    }
  }

  /// FUNCIÓN OPTIMIZADA MEJORADA: Maximizar paralelismo y priorizar camino crítico
  void _asignarRecursosAPasosDisponiblesOptimizado() {
    // Separar pasos por tipo para maximizar paralelismo
    final pasosCriticosIniciales = _estadoActual!.pasosDisponibles
        .where((p) => _pasosEnCaminoCritico.contains(p.id) && p.dependenciasOriginales.isEmpty)
        .toList()
        ..sort((a, b) => b.prioridad.compareTo(a.prioridad));
        
    final pasosCriticos = _estadoActual!.pasosDisponibles
        .where((p) => _pasosEnCaminoCritico.contains(p.id) && !p.dependenciasOriginales.isEmpty)
        .toList()
        ..sort((a, b) => b.prioridad.compareTo(a.prioridad));
        
    final pasosIniciales = _estadoActual!.pasosDisponibles
        .where((p) => !_pasosEnCaminoCritico.contains(p.id) && p.dependenciasOriginales.isEmpty)
        .toList()
        ..sort((a, b) => b.prioridad.compareTo(a.prioridad));
        
    final pasosRestantes = _estadoActual!.pasosDisponibles
        .where((p) => !_pasosEnCaminoCritico.contains(p.id) && !p.dependenciasOriginales.isEmpty)
        .toList()
        ..sort((a, b) => b.prioridad.compareTo(a.prioridad));

    int asignacionesRealizadas = 0;
    
    // Procesar en orden de prioridad
    for (final paso in [...pasosCriticosIniciales, ...pasosCriticos, ...pasosIniciales, ...pasosRestantes]) {
      final combinacion = _encontrarMejorCombinacion(paso);
      if (combinacion != null) {
        _asignarRecursos(paso, combinacion.cocinero, combinacion.utensilio);
        asignacionesRealizadas++;
        
        // Look-ahead más agresivo para pasos críticos
        if (_pasosEnCaminoCritico.contains(paso.id)) {
          _verificarDependientesCriticosConservador(paso);
          
          // Reservar recursos para el siguiente paso crítico si es posible
          _intentarReservarRecursosParaSiguientePasoCritico(paso);
        }
      } else {
        final razon = _diagnosticarRazonNoAsignacion(paso);
        _log('⚠️ No se pudo asignar "${paso.nombre}": $razon');
      }
    }

    if (asignacionesRealizadas == 0 && _estadoActual!.pasosDisponibles.isNotEmpty) {
      _log('🚨 ADVERTENCIA: Ningún paso disponible pudo ser asignado');
    }
  }

  /// FUNCIÓN CONSERVADORA: Verificar dependientes críticos sin ser agresivo
  void _verificarDependientesCriticosConservador(PasoSchedulingDinamico pasoCompletado) {
    final dependientes = _estadoActual!.pasosPendientes
        .where((p) => p.dependenciasPendientes.contains(pasoCompletado.id))
        .where((p) => _pasosEnCaminoCritico.contains(p.id))
        .where((p) => p.dependenciasPendientes.length == 1) // Solo si es la única dependencia
        .toList();
    
    for (final dependiente in dependientes) {
      _log('🔍 LOOK-AHEAD CONSERVADOR: Preparando recursos para dependiente crítico ${dependiente.nombre}');
      // Solo logging, no reserva real
      _intentarReservarRecursos(dependiente, pasoCompletado.tiempoFin!);
    }
  }

  /// NUEVA FUNCIÓN: Intentar reservar recursos para pasos críticos
  void _intentarReservarRecursos(PasoSchedulingDinamico paso, int tiempoEsperado) {
    final cocinerosLibres = _estadoActual!.cocineros
        .where((c) => c.tipo == paso.tipoCocinero && _estaDisponibleEnTiempo(c, tiempoEsperado))
        .toList();
    
    final utensiliosLibres = _estadoActual!.utensilios
        .where((u) => u.tipo == paso.tipoUtensilio && _estaDisponibleEnTiempo(u, tiempoEsperado))
        .toList();
    
    if (cocinerosLibres.isNotEmpty && utensiliosLibres.isNotEmpty) {
      _log('🎯 RESERVA: Recursos disponibles para ${paso.nombre} en T$tiempoEsperado');
    }
  }

  /// NUEVA FUNCIÓN: Verificar si un recurso estará disponible en un tiempo específico
  bool _estaDisponibleEnTiempo(dynamic recurso, int tiempo) {
    return recurso.horario.every((HorarioItem item) => 
        (item.tiempoInicio + item.duracion) <= tiempo || item.tiempoInicio > tiempo);
  }

  /// NUEVA FUNCIÓN: Intentar reservar recursos para el siguiente paso crítico
  void _intentarReservarRecursosParaSiguientePasoCritico(PasoSchedulingDinamico pasoActual) {
    // Encontrar el siguiente paso crítico que depende de este
    final siguientesPasosCriticos = _estadoActual!.todosPasos
        .where((p) => _pasosEnCaminoCritico.contains(p.id))
        .where((p) => p.dependenciasOriginales.contains(pasoActual.id))
        .toList();
    
    if (siguientesPasosCriticos.isEmpty) return;
    
    // Ordenar por prioridad para elegir el más importante
    siguientesPasosCriticos.sort((a, b) => b.prioridad.compareTo(a.prioridad));
    final siguientePaso = siguientesPasosCriticos.first;
    
    // Calcular tiempo de inicio más temprano posible
    final tiempoInicio = pasoActual.tiempoInicio! + pasoActual.duracion;
    
    // Buscar y reservar los recursos necesarios
    final cocineroDisponible = _estadoActual!.cocineros
        .where((c) => c.tipo == siguientePaso.tipoCocinero)
        .where((c) => _estaDisponible(c, tiempoInicio))
        .firstOrNull;
        
    final utensilioDisponible = _estadoActual!.utensilios
        .where((u) => u.tipo == siguientePaso.tipoUtensilio)
        .where((u) => _estaDisponible(u, tiempoInicio))
        .firstOrNull;
        
    if (cocineroDisponible != null && utensilioDisponible != null) {
      // Crear reservas temporales
      cocineroDisponible.horario.add(HorarioItem(
        tiempoInicio: tiempoInicio,
        duracion: siguientePaso.duracion,
        pasoId: siguientePaso.id,
      ));
      
      utensilioDisponible.horario.add(HorarioItem(
        tiempoInicio: tiempoInicio,
        duracion: siguientePaso.duracion,
        pasoId: siguientePaso.id,
      ));
      
      _log('🔒 Recursos reservados para paso crítico "${siguientePaso.nombre}" en T$tiempoInicio');
    }
  }

  /// FUNCIÓN OPTIMIZADA CORREGIDA: Actualizar dependencias con verificación completa
  void _actualizarDependenciasOptimizado() {
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
          _log('🔓 Paso "${pasoAfectado.nombre}" ahora disponible');
          
          // PROCESAMIENTO INMEDIATO CONSERVADOR: Solo si hay muy pocos pasos disponibles
          // y el paso es crítico y hay recursos claramente disponibles
          if (_pasosEnCaminoCritico.contains(pasoAfectado.id) && 
              _estadoActual!.pasosDisponibles.length <= 2) {
            _log('⚡ PROCESAMIENTO INMEDIATO CONSERVADOR: ${pasoAfectado.nombre}');
            final combinacion = _encontrarMejorCombinacion(pasoAfectado);
            if (combinacion != null) {
              _asignarRecursos(pasoAfectado, combinacion.cocinero, combinacion.utensilio);
            }
          }
        }
      }
    }
    
    // CORRECCIÓN CRÍTICA: Verificación global tras cada iteración
    // Esta es la mejora más importante del algoritmo corregido
    _verificarYActualizarTodasLasDependencias();
  }

  /// NUEVA FUNCIÓN CRÍTICA MEJORADA: Verificación completa de dependencias
  /// Esta es la corrección más importante - garantiza que no se pierdan dependencias
  void _verificarYActualizarTodasLasDependencias() {
    final pasosCompletadosIds = _estadoActual!.pasosCompletados.map((p) => p.id).toSet();
    bool seHicieronCambios = false;
    
    for (final paso in _estadoActual!.pasosPendientes) {
      // Verificar si alguna dependencia debería estar marcada como completada
      final dependenciasAhCompletadas = paso.dependenciasPendientes
          .where((depId) => pasosCompletadosIds.contains(depId))
          .toList();
      
      for (final depId in dependenciasAhCompletadas) {
        _log('🔧 CORRECCIÓN GLOBAL: Marcando dependencia completada $depId para ${paso.nombre}');
        paso.completarDependencia(depId);
        seHicieronCambios = true;
      }
      
      // Verificar si el paso debe cambiar a disponible
      if (paso.estaDisponible && paso.estado == EstadoPaso.pendiente) {
        paso.estado = EstadoPaso.disponible;
        _log('🔓 CORRECCIÓN GLOBAL: Paso "${paso.nombre}" marcado como disponible');
        seHicieronCambios = true;
      }
    }
    
    if (seHicieronCambios) {
      _log('📋 VERIFICACIÓN GLOBAL: Se realizaron correcciones en dependencias');
    }
  }

  /// Ejecutar el algoritmo completo optimizado CON VALIDACIÓN
  List<String> ejecutarCompletoOptimizado() {
    final logs = <String>[];
    final stopwatch = Stopwatch()..start();
    _log('▶️ Iniciando ejecución completa del scheduling OPTIMIZADO');
    
    int iteracion = 1;
    int iteracionesSinProgreso = 0;
    int pasosCompletadosAnterior = 0;
    
    while (_estadoActual!.hayTrabajoDisponible) {
      // Timeout de seguridad
      if (stopwatch.elapsedMilliseconds > 30000) { // 30 segundos máximo
        _log('⏰ TIMEOUT: Ejecución detenida después de 30 segundos');
        break;
      }
      
      _log('\n🔄 === ITERACIÓN $iteracion ===');
      
      // Verificar progreso de manera más estricta
      final pasosCompletadosActual = _estadoActual!.pasosCompletados.length;
      if (pasosCompletadosActual == pasosCompletadosAnterior) {
        iteracionesSinProgreso++;
        _log('⚠️ Sin progreso: iteración $iteracionesSinProgreso/10');
        
        if (iteracionesSinProgreso >= 5) { // Reducido de 10 a 5 para detección más temprana
          _log('🚨 DEADLOCK DETECTADO: ${iteracionesSinProgreso} iteraciones sin progreso');
          _diagnosticarDeadlock();
          
          // Intentar recuperación una vez
          if (iteracionesSinProgreso == 5) {
            _log('🔧 INTENTANDO RECUPERACIÓN: Verificación completa de dependencias');
            _verificarYActualizarTodasLasDependencias();
          } else {
            _log('💔 DEADLOCK CONFIRMADO: Abandonando ejecución');
            break;
          }
        }
      } else {
        iteracionesSinProgreso = 0; // Reset contador
        pasosCompletadosAnterior = pasosCompletadosActual;
        _log('✅ Progreso: ${pasosCompletadosActual} pasos completados');
      }
      
      _asignarRecursosAPasosDisponiblesOptimizado(); // Versión optimizada
      
      final proximoEvento = _estadoActual!.proximoEvento;
      if (proximoEvento != null && proximoEvento > _estadoActual!.tiempoActual) {
        _avanzarTiempo(proximoEvento);
      }
      
      _procesarPasosTerminados();
      _actualizarDependenciasOptimizado(); // Versión optimizada
      
      iteracion++;
      if (iteracion > 200) { // Mayor límite para casos complejos
        _log('⚠️ ADVERTENCIA: Máximo de iteraciones alcanzado');
        break;
      }
    }
    
    stopwatch.stop();
    
    // VALIDACIÓN FINAL CRÍTICA MEJORADA
    final pasosCompletados = _estadoActual!.pasosCompletados.length;
    final pasosTotales = _estadoActual!.todosPasos.length;
    
    _log('\n📊 === RESUMEN FINAL OPTIMIZADO ===');
    _log('📈 Pasos completados: $pasosCompletados/$pasosTotales');
    _log('⏱️ Makespan final: ${_estadoActual!.tiempoActual} segundos');
    _log('🕒 Tiempo de cálculo: ${stopwatch.elapsedMilliseconds}ms');
    _log('🔄 Iteraciones realizadas: ${iteracion - 1}');
    
    if (pasosCompletados == pasosTotales) {
      _log('✅ ÉXITO: Todos los pasos han sido completados correctamente');
    } else {
      _log('🚨 FALLO: Solo se completaron $pasosCompletados de $pasosTotales pasos');
      _diagnosticarPasosIncompletos();
      
      // Agregar información adicional de diagnóstico
      _log('\n🔍 DIAGNÓSTICO ADICIONAL:');
      _log('   - Pasos disponibles sin asignar: ${_estadoActual!.pasosDisponibles.length}');
      _log('   - Pasos aún en proceso: ${_estadoActual!.pasosEnProceso.length}');
      _log('   - Pasos pendientes: ${_estadoActual!.pasosPendientes.length}');
      
      // Reportar explícitamente el problema pero no lanzar excepción
      _log('⚠️ ADVERTENCIA: El algoritmo no pudo completar todos los pasos');
      logs.add('ERROR: Algoritmo optimizado incompleto - solo $pasosCompletados/$pasosTotales pasos completados');
    }
    
    _log('🏁 Scheduling OPTIMIZADO finalizado');
    return logs;
  }

  /// Ejecutar el algoritmo completo automáticamente
  List<String> ejecutarCompleto() {
    if (_estadoActual == null) {
      throw StateError('Debe inicializar el algoritmo primero');
    }

    _log('▶️ Iniciando ejecución completa del scheduling OPTIMIZADO');
    
    int iteraciones = 0;
    const maxIteraciones = 1000; // Prevenir bucles infinitos
    
    while (_estadoActual!.hayTrabajoDisponible && iteraciones < maxIteraciones) {
      iteraciones++;
      _log('\n🔄 === ITERACIÓN $iteraciones ===');
      
      // Si hay progreso en la iteración anterior, recalcular prioridades
      if (iteraciones > 1 && _huboProgresoEnIteracionAnterior) {
        _calcularPrioridadesOptimizadas();
      }
      
      // Asignar recursos a pasos disponibles
      _asignarRecursosAPasosDisponiblesOptimizado();
      
      // Avanzar tiempo hasta el próximo evento
      final proximoEvento = _estadoActual!.proximoEvento;
      if (proximoEvento != null && proximoEvento > _estadoActual!.tiempoActual) {
        _avanzarTiempo(proximoEvento);
      }
      
      // Procesar pasos que terminan
      _procesarPasosTerminados();
      
      // Actualizar estado y verificar bloqueos
      if (!_estadoActual!.hayTrabajoDisponible) {
        if (_estadoActual!.pasosCompletados.length < _estadoActual!.todosPasos.length) {
          _log('⚠️ POSIBLE BLOQUEO DETECTADO');
          _diagnosticarPasosIncompletos();
          break;
        }
        _log('✅ Todos los pasos han sido completados');
        break;
      }
    }
    
    _estadoActual!.completado = true;
    
    final makespan = _estadoActual!.tiempoActual;
    _log('\n📊 === RESUMEN FINAL OPTIMIZADO ===');
    _log('📈 Pasos completados: ${_estadoActual!.pasosCompletados.length}/${_estadoActual!.todosPasos.length}');
    _log('⏱️ Makespan final: $makespan segundos');
    _log('🕒 Tiempo de cálculo: ${DateTime.now().difference(_tiempoInicio).inMilliseconds}ms');
    _log('🔄 Iteraciones realizadas: $iteraciones');
    
    if (_estadoActual!.pasosCompletados.length == _estadoActual!.todosPasos.length) {
      _log('✅ ÉXITO: Todos los pasos han sido completados correctamente');
    } else {
      _log('❌ ERROR: Algunos pasos quedaron sin completar');
      _diagnosticarPasosIncompletos();
    }
    
    _log('🏁 Scheduling OPTIMIZADO finalizado');
    
    return _estadoActual!.logEventos;
  }

  bool get _huboProgresoEnIteracionAnterior {
    final completadosAntes = _estadoActual!.pasosCompletados.length;
    return completadosAntes > _ultimosCompletados;
  }

  late final DateTime _tiempoInicio = DateTime.now();
  int _ultimosCompletados = 0;

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
        .where((t) => t != null)
        .toList();
    
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
}

/// Clase auxiliar para representar una combinación de recursos
class _CombinacionRecursos {
  final CocineroScheduling cocinero;
  final UtensilioScheduling utensilio;
  final int tiempoInicio;

  _CombinacionRecursos(this.cocinero, this.utensilio, this.tiempoInicio);
}

extension SchedulingDinamicoAlgorithmOptimizadoExtension on SchedulingDinamicoAlgorithmOptimizado {
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
      
      // Verificar dependientes después de completar
      _verificarDependientesCriticosConservador(paso);
    }
  }

  /// Diagnosticar pasos que quedaron incompletos
  void _diagnosticarPasosIncompletos() {
    final pasosIncompletos = _estadoActual!.todosPasos
        .where((p) => p.estado != EstadoPaso.completado)
        .toList();
        
    if (pasosIncompletos.isNotEmpty) {
      _log('\n❌ PASOS INCOMPLETOS DETECTADOS:');
      for (final paso in pasosIncompletos) {
        _log('  - ${paso.nombre} (${paso.estado})');
        if (paso.dependenciasPendientes.isNotEmpty) {
          _log('    Dependencias pendientes: ${paso.dependenciasPendientes}');
        }
      }
    }
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
}

/// Extensión para estado de scheduling
extension EstadoSchedulingExtension on EstadoScheduling {
  List<PasoSchedulingDinamico> get pasosDisponibles =>
      todosPasos.where((p) => p.estado == EstadoPaso.disponible).toList();
      
  List<PasoSchedulingDinamico> get pasosPendientes =>
      todosPasos.where((p) => p.estado == EstadoPaso.pendiente).toList();
      
  List<PasoSchedulingDinamico> get pasosEnProceso =>
      todosPasos.where((p) => p.estado == EstadoPaso.enProceso).toList();
      
  List<PasoSchedulingDinamico> get pasosCompletados =>
      todosPasos.where((p) => p.estado == EstadoPaso.completado).toList();
      
  bool get hayTrabajoDisponible =>
      pasosDisponibles.isNotEmpty || pasosEnProceso.isNotEmpty;
      
  int? get proximoEvento {
    final eventosFinPaso = pasosEnProceso
        .map((p) => p.tiempoFin)
        .where((t) => t != null)
        .toList();
    
    if (eventosFinPaso.isEmpty) return null;
    return eventosFinPaso.reduce(min);
  }
}
