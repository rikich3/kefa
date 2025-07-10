import 'package:hive/hive.dart';
import '../algorithms/scheduling_dinamico_algorithm_optimizado.dart';

part 'paso_scheduling.g.dart';

@HiveType(typeId: 12)
class PasoScheduling extends HiveObject {
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
  List<String> dependencias;

  PasoScheduling({
    required this.id,
    required this.nombre,
    required this.tipoCocinero,
    required this.tipoUtensilio,
    required this.duracion,
    required this.dependencias,
  });
}
