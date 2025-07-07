import 'package:hive/hive.dart';

part 'paso_scheduling.g.dart';

@HiveType(typeId: 13)
class PasoScheduling extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String tipoCocinero; // 'cocinero' o 'olla'

  @HiveField(3)
  String tipoUtensilio; // tipo de utensilio requerido

  @HiveField(4)
  int duracion; // tiempo que demora en segundos

  @HiveField(5)
  List<String> dependencias; // IDs de pasos que deben completarse antes

  @HiveField(6)
  bool completado;

  PasoScheduling({
    required this.id,
    required this.nombre,
    required this.tipoCocinero,
    required this.tipoUtensilio,
    required this.duracion,
    List<String>? dependencias,
    this.completado = false,
  }) : dependencias = dependencias ?? [];

  @override
  String toString() {
    return '$nombre (${tipoCocinero}, ${tipoUtensilio}, ${duracion}s) - deps: $dependencias';
  }
}
