import '../dataModels/estado_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/horario_item.dart';
import 'dart:math';
import 'package:hive/hive.dart';

part 'scheduling_dinamico_algorithm_optimizado_fixed.g.dart';

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

/// Algoritmo de scheduling dinámico optimizado
class SchedulingDinamicoAlgorithmOptimizado {
  // Estado interno
  List<PasoSchedulingDinamico>? _pasos;
  List<CocineroScheduling>? _cocineros;
  List<UtensilioScheduling>? _utensilios;
  EstadoScheduling? _estadoActual;

  // Getters
  EstadoScheduling? get estadoActual => _estadoActual;
  List<PasoSchedulingDinamico>? get pasos => _pasos;

  // Inicialización
  void inicializar({
    required List<PasoScheduling> pasos,
    required List<CocineroScheduling> cocineros,
    required List<UtensilioScheduling> utensilios,
  }) {
    _pasos = pasos.map((p) => PasoSchedulingDinamico.fromPasoScheduling(p)).toList();
    _cocineros = List.from(cocineros);
    _utensilios = List.from(utensilios);
    _estadoActual = EstadoScheduling(
      pasosCompletados: [],
      tiempoActual: 0,
    );

    _inicializarPrioridades();
  }

  // Ejecución principal
  List<String> ejecutarCompleto() {
    if (_pasos == null) throw Exception('El algoritmo no ha sido inicializado');

    final logs = <String>[];
    logs.add('🚀 Iniciando ejecución del algoritmo optimizado');

    while (!_todosLosPasosCompletados()) {
      final tiempo = _estadoActual!.tiempoActual;
      logs.add('\n⏰ T=$tiempo');

      // 1. Actualizar estado de pasos y recursos
      _actualizarEstado(tiempo);
      logs.add('📊 Estado actualizado');

      // 2. Obtener pasos disponibles y ordenarlos por prioridad
      final disponibles = _obtenerPasosDisponibles();
      if (disponibles.isEmpty) {
        // Avanzar al siguiente evento si no hay pasos disponibles
        _avanzarSiguienteEvento();
        continue;
      }

      // 3. Intentar asignar recursos a los pasos disponibles
      var asignacionesRealizadas = false;
      for (final paso in disponibles) {
        // Buscar la mejor combinación de recursos
        final mejorCombinacion = _encontrarMejorCombinacionRecursos(paso, tiempo);
        
        if (mejorCombinacion != null) {
          // Asignar recursos y marcar paso como en proceso
          _asignarRecursos(
            paso,
            mejorCombinacion.cocinero,
            mejorCombinacion.utensilio,
            mejorCombinacion.tiempoInicio,
          );
          asignacionesRealizadas = true;
          logs.add('✅ ${paso.nombre} iniciado en T=${mejorCombinacion.tiempoInicio}');
        }
      }

      if (!asignacionesRealizadas) {
        // Si no se pudo asignar ningún paso, avanzar al siguiente evento
        _avanzarSiguienteEvento();
      }
    }

    logs.add('\n🏁 Ejecución completada');
    logs.add('⏱️ Makespan final: ${_estadoActual!.tiempoActual}');
    return logs;
  }

  // Métodos auxiliares privados
  void _inicializarPrioridades() {
    // Calcular prioridades basadas en camino crítico y cantidad de dependientes
    final dependientes = <String, Set<String>>{};
    for (final paso in _pasos!) {
      dependientes[paso.id] = {};
      for (final dep in paso.dependenciasOriginales) {
        dependientes[dep] ??= {};
        dependientes[dep]!.add(paso.id);
      }
    }

    // Calcular tiempos más tardíos (backwards)
    final tiemposMax = <String, int>{};
    for (final paso in _pasos!) {
      _calcularTiempoMaximo(paso.id, tiemposMax, dependientes);
    }

    // Asignar prioridades basadas en tiempo máximo y dependientes
    for (final paso in _pasos!) {
      final tiempoMax = tiemposMax[paso.id] ?? 0;
      final cantDependientes = dependientes[paso.id]?.length ?? 0;
      paso.prioridad = tiempoMax + (cantDependientes * 100);
    }
  }

  int _calcularTiempoMaximo(
    String pasoId,
    Map<String, int> tiemposMax,
    Map<String, Set<String>> dependientes,
  ) {
    if (tiemposMax.containsKey(pasoId)) return tiemposMax[pasoId]!;

    final paso = _pasos!.firstWhere((p) => p.id == pasoId);
    if (dependientes[pasoId]?.isEmpty ?? true) {
      tiemposMax[pasoId] = paso.duracion;
      return paso.duracion;
    }

    var maxTiempo = 0;
    for (final depId in dependientes[pasoId]!) {
      final tiempoDep = _calcularTiempoMaximo(depId, tiemposMax, dependientes);
      maxTiempo = max(maxTiempo, tiempoDep);
    }

    tiemposMax[pasoId] = maxTiempo + paso.duracion;
    return tiemposMax[pasoId]!;
  }

  bool _todosLosPasosCompletados() {
    return _pasos!.every((p) => p.estaCompletado);
  }

  void _actualizarEstado(int tiempo) {
    // Actualizar estado de pasos en proceso
    for (final paso in _pasos!) {
      if (paso.estaEnProceso && paso.tiempoFin! <= tiempo) {
        paso.completarEjecucion(tiempo);
        _estadoActual!.pasosCompletados.add(PasoScheduling(
          id: paso.id,
          nombre: paso.nombre,
          tipoCocinero: paso.tipoCocinero,
          tipoUtensilio: paso.tipoUtensilio,
          duracion: paso.duracion,
          dependencias: paso.dependenciasOriginales,
          cocineroAsignado: paso.tiempoInicio.toString(),
          utensilioAsignado: paso.tiempoFin.toString(),
          tiempoInicio: paso.tiempoInicio,
          tiempoFin: paso.tiempoFin,
        ));

        // Actualizar dependencias de otros pasos
        for (final otroPaso in _pasos!) {
          if (!otroPaso.estaCompletado) {
            otroPaso.completarDependencia(paso.id);
          }
        }
      }
    }
  }

  List<PasoSchedulingDinamico> _obtenerPasosDisponibles() {
    final disponibles = _pasos!
        .where((p) => p.estaDisponible)
        .toList();
    disponibles.sort((a, b) => b.prioridad.compareTo(a.prioridad));
    return disponibles;
  }

  _CombinacionRecursos? _encontrarMejorCombinacionRecursos(
    PasoSchedulingDinamico paso,
    int tiempoActual,
  ) {
    var mejorTiempo = double.infinity;
    _CombinacionRecursos? mejorCombinacion;

    // Encontrar cocineros y utensilios disponibles del tipo requerido
    final cocinerosDisponibles = _cocineros!
        .where((c) => c.tipo == paso.tipoCocinero)
        .toList();
    final utensiliosDisponibles = _utensilios!
        .where((u) => u.tipo == paso.tipoUtensilio)
        .toList();

    // Probar todas las combinaciones posibles
    for (final cocinero in cocinerosDisponibles) {
      for (final utensilio in utensiliosDisponibles) {
        final tiempoInicio = _encontrarTiempoInicioValido(
          cocinero,
          utensilio,
          tiempoActual,
          paso.duracion,
        );

        if (tiempoInicio < mejorTiempo) {
          mejorTiempo = tiempoInicio.toDouble();
          mejorCombinacion = _CombinacionRecursos(
            cocinero,
            utensilio,
            tiempoInicio,
          );
        }
      }
    }

    return mejorCombinacion;
  }

  int _encontrarTiempoInicioValido(
    CocineroScheduling cocinero,
    UtensilioScheduling utensilio,
    int tiempoMinimo,
    int duracion,
  ) {
    // Obtener horarios ocupados de cocinero y utensilio
    final horariosCocinero = _obtenerHorariosOcupados(cocinero.tipo);
    final horariosUtensilio = _obtenerHorariosOcupados(utensilio.tipo);

    // Encontrar el primer hueco que funcione para ambos recursos
    var tiempoInicio = tiempoMinimo;
    while (true) {
      final tiempoFin = tiempoInicio + duracion;
      
      // Verificar si hay conflicto con horarios existentes
      final hayConflictoCocinero = horariosCocinero.any((h) =>
          _hayInterseccion(tiempoInicio, tiempoFin, h.tiempoInicio!, h.tiempoFin!));
      
      final hayConflictoUtensilio = horariosUtensilio.any((h) =>
          _hayInterseccion(tiempoInicio, tiempoFin, h.tiempoInicio!, h.tiempoFin!));

      if (!hayConflictoCocinero && !hayConflictoUtensilio) {
        return tiempoInicio;
      }

      // Avanzar al siguiente tiempo disponible
      var siguienteTiempo = tiempoInicio + 1;
      for (final h in [...horariosCocinero, ...horariosUtensilio]) {
        if (h.tiempoInicio! > tiempoInicio) {
          siguienteTiempo = max(siguienteTiempo, h.tiempoFin!);
        }
      }
      tiempoInicio = siguienteTiempo;
    }
  }

  bool _hayInterseccion(int inicio1, int fin1, int inicio2, int fin2) {
    return inicio1 < fin2 && fin1 > inicio2;
  }

  List<HorarioItem> _obtenerHorariosOcupados(String tipo) {
    return _estadoActual!.pasosCompletados
        .where((p) =>
            (p.tipoCocinero == tipo || p.tipoUtensilio == tipo) &&
            p.tiempoInicio != null &&
            p.tiempoFin != null)
        .map((p) => HorarioItem(
              nombre: p.nombre,
              tiempoInicio: p.tiempoInicio,
              tiempoFin: p.tiempoFin,
            ))
        .toList();
  }

  void _asignarRecursos(
    PasoSchedulingDinamico paso,
    CocineroScheduling cocinero,
    UtensilioScheduling utensilio,
    int tiempoInicio,
  ) {
    paso.iniciarEjecucion(tiempoInicio);
  }

  void _avanzarSiguienteEvento() {
    // Encontrar el siguiente tiempo donde ocurre un evento (fin de un paso)
    var siguienteTiempo = double.infinity;
    for (final paso in _pasos!) {
      if (paso.estaEnProceso && paso.tiempoFin! < siguienteTiempo) {
        siguienteTiempo = paso.tiempoFin!.toDouble();
      }
    }

    if (siguienteTiempo < double.infinity) {
      _estadoActual!.tiempoActual = siguienteTiempo.toInt();
    } else {
      // Si no hay eventos futuros, avanzar un tick
      _estadoActual!.tiempoActual++;
    }
  }
}
