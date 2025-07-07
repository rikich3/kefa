import 'package:hive/hive.dart';
import 'paso.dart';

part 'receta.g.dart';

@HiveType(typeId: 5)
class Receta extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  String descripcion;

  @HiveField(2)
  List<Paso> pasos;

  @HiveField(3)
  int tiempoTotalSegundos; // Tiempo total de la receta

  @HiveField(4)
  DateTime fechaCreacion;

  @HiveField(5)
  int id;

  Receta({
    required this.nombre,
    required this.descripcion,
    required this.pasos,
    required this.tiempoTotalSegundos,
    required this.fechaCreacion,
    required this.id,
  });

  // Método para calcular el tiempo total basado en los pasos
  void calcularTiempoTotal() {
    tiempoTotalSegundos = pasos.fold(0, (sum, paso) => sum + paso.tiempoSegundos);
  }
}
