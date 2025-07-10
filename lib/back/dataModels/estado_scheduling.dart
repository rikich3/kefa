import 'package:hive/hive.dart';
import '../algorithms/scheduling_dinamico_algorithm_optimizado.dart';
import 'cocinero_scheduling.dart';
import 'utensilio_scheduling.dart';

part 'estado_scheduling.g.dart';

/// Estado completo del sistema de scheduling
@HiveType(typeId: 16)
class EstadoScheduling extends HiveObject {
  @HiveField(0)
  int tiempoActual;

  @HiveField(1)
  List<PasoSchedulingDinamico> todosPasos;

  @HiveField(2)
  List<CocineroScheduling> cocineros;

  @HiveField(3)
  List<UtensilioScheduling> utensilios;

  @HiveField(4)
  List<String> logEventos;

  @HiveField(5)
  bool completado;

  EstadoScheduling({
    this.tiempoActual = 0,
    List<PasoSchedulingDinamico>? todosPasos,
    List<CocineroScheduling>? cocineros,
    List<UtensilioScheduling>? utensilios,
    List<String>? logEventos,
    this.completado = false,
  }) : todosPasos = todosPasos ?? [],
       cocineros = cocineros ?? [],
       utensilios = utensilios ?? [],
       logEventos = logEventos ?? [];

  /// Obtener pasos por estado
  List<PasoSchedulingDinamico> get pasosPendientes => 
      todosPasos.where((p) => p.estado == EstadoPaso.pendiente).toList();

  List<PasoSchedulingDinamico> get pasosDisponibles => 
      todosPasos.where((p) => p.estado == EstadoPaso.disponible).toList();

  List<PasoSchedulingDinamico> get pasosEnProceso => 
      todosPasos.where((p) => p.estado == EstadoPaso.enProceso).toList();

  List<PasoSchedulingDinamico> get pasosCompletados => 
      todosPasos.where((p) => p.estado == EstadoPaso.completado).toList();

  /// Verificar si hay trabajo por hacer
  bool get hayTrabajoDisponible => pasosDisponibles.isNotEmpty || pasosEnProceso.isNotEmpty;

  /// Agregar evento al log
  void agregarEvento(String evento) {
    logEventos.add('T${tiempoActual}: $evento');
  }

  /// Encontrar el próximo evento (cuando termine algún paso)
  int? get proximoEvento {
    final tiemposFinalizacion = pasosEnProceso
        .where((p) => p.tiempoFin != null)
        .map((p) => p.tiempoFin!)
        .toList();
    
    if (tiemposFinalizacion.isEmpty) return null;
    return tiemposFinalizacion.reduce((a, b) => a < b ? a : b);
  }

  @override
  String toString() {
    return 'EstadoScheduling(t=$tiempoActual, disponibles=${pasosDisponibles.length}, en_proceso=${pasosEnProceso.length}, completados=${pasosCompletados.length})';
  }
}
