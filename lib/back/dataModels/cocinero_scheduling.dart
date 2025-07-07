import 'package:hive/hive.dart';
import 'horario_item.dart';

part 'cocinero_scheduling.g.dart';

@HiveType(typeId: 11)
class CocineroScheduling extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String tipo; // 'cocinero' o 'olla'

  @HiveField(3)
  List<HorarioItem> horario;

  @HiveField(4)
  int ori; // tiempo de origen - el menor tiempo posible que tiene libre

  CocineroScheduling({
    required this.id,
    required this.nombre,
    required this.tipo,
    List<HorarioItem>? horario,
    this.ori = 0,
  }) : horario = horario ?? [];

  @override
  String toString() {
    return '$nombre ($tipo) - ori: $ori, horario: $horario';
  }
}
