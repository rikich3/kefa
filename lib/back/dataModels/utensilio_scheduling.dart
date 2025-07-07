import 'package:hive/hive.dart';
import 'horario_item.dart';

part 'utensilio_scheduling.g.dart';

@HiveType(typeId: 12)
class UtensilioScheduling extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String tipo; // tipo del utensilio (ej: 'cuchillo', 'sarten')

  @HiveField(3)
  List<HorarioItem> horario;

  @HiveField(4)
  int ori; // tiempo de origen

  UtensilioScheduling({
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
