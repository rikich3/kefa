import 'package:hive/hive.dart';

part 'horario_item.g.dart';

@HiveType(typeId: 10)
class HorarioItem extends HiveObject {
  @HiveField(0)
  int tiempoInicio; // A - momento en el tiempo en segundos donde inicia

  @HiveField(1)
  int duracion; // B - tiempo en segundos que demora

  @HiveField(2)
  String pasoId; // PasoID - identificador del paso

  HorarioItem({
    required this.tiempoInicio,
    required this.duracion,
    required this.pasoId,
  });

  @override
  String toString() {
    return '($tiempoInicio, $duracion, $pasoId)';
  }
}
