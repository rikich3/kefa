import 'package:hive/hive.dart';
import 'paso_scheduling.dart';
import 'cocinero_scheduling.dart';
import 'utensilio_scheduling.dart';

part 'estado_scheduling.g.dart';

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
  String? cocineroAsignado;

  @HiveField(11)
  String? utensilioAsignado;

  @HiveField(12)
  int prioridad; // Calculada dinámicamente

  PasoSchedulingDinamico({
    required this.id,
    required this.nombre,
    required this.tipoCocinero,
    required this.tipoUtensilio,
    required this.duracion,
    List<String>? dependenciasOriginales,
    this.estado = EstadoPaso.pendiente,
    this.tiempoInicio,
    this.tiempoFin,
    this.cocineroAsignado,
    this.utensilioAsignado,
    this.prioridad = 0,
  }  ) : dependenciasOriginales = dependenciasOriginales ?? [],
       dependenciasPendientes = List.from(dependenciasOriginales ?? []);

  /// Crear desde un PasoScheduling básico
  factory PasoSchedulingDinamico.fromPasoScheduling(PasoScheduling paso) {
    return PasoSchedulingDinamico(
      id: paso.id,
      nombre: paso.nombre,
      tipoCocinero: paso.tipoCocinero,
      tipoUtensilio: paso.tipoUtensilio,
      duracion: paso.duracion,
      dependenciasOriginales: List.from(paso.dependencias),
    );
  }

  /// Verificar si el paso está listo para ejecutarse
  bool get estaDisponible => dependenciasPendientes.isEmpty && estado == EstadoPaso.pendiente;

  /// Marcar una dependencia como completada
  void completarDependencia(String dependenciaId) {
    dependenciasPendientes.remove(dependenciaId);
    if (dependenciasPendientes.isEmpty && estado == EstadoPaso.pendiente) {
      estado = EstadoPaso.disponible;
    }
  }

  /// Iniciar la ejecución del paso
  void iniciarEjecucion(int tiempo, String cocinero, String utensilio) {
    estado = EstadoPaso.enProceso;
    tiempoInicio = tiempo;
    tiempoFin = tiempo + duracion;
    cocineroAsignado = cocinero;
    utensilioAsignado = utensilio;
  }

  /// Completar la ejecución del paso
  void completarEjecucion(int tiempo) {
    estado = EstadoPaso.completado;
    tiempoFin = tiempo;
  }

  /// Calcular la criticidad del paso (cuántos pasos dependen de este)
  int calcularCriticidad(List<PasoSchedulingDinamico> todosPasos) {
    return todosPasos.where((p) => p.dependenciasOriginales.contains(id)).length;
  }

  @override
  String toString() {
    return '$nombre [$estado] (${tiempoInicio ?? "?"}s-${tiempoFin ?? "?"}s) deps: ${dependenciasPendientes.length}/${dependenciasOriginales.length}';
  }
}

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
