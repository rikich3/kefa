import 'package:hive/hive.dart';

part 'tarea_asignada.g.dart';

@HiveType(typeId: 17)
class TareaAsignada extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String cocineroId;

  @HiveField(2)
  String nombreTarea;

  @HiveField(3)
  String descripcion;

  @HiveField(4)
  List<String> utensiliosRequeridos;

  @HiveField(5)
  int tiempoInicioSegundos;

  @HiveField(6)
  int duracionSegundos;

  @HiveField(7)
  int orden; // Para el orden T1, T2, T3...

  @HiveField(8)
  DateTime fechaAsignacion;

  TareaAsignada({
    required this.id,
    required this.cocineroId,
    required this.nombreTarea,
    required this.descripcion,
    required this.utensiliosRequeridos,
    required this.tiempoInicioSegundos,
    required this.duracionSegundos,
    required this.orden,
    required this.fechaAsignacion,
  });

  int get tiempoFinSegundos => tiempoInicioSegundos + duracionSegundos;

  String get tiempoInicioFormateado {
    final minutos = tiempoInicioSegundos ~/ 60;
    final segundos = tiempoInicioSegundos % 60;
    return '${minutos}m ${segundos}s';
  }

  String get duracionFormateada {
    final minutos = duracionSegundos ~/ 60;
    final segundos = duracionSegundos % 60;
    return '${minutos}m ${segundos}s';
  }
}
