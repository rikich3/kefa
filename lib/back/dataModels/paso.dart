import 'package:hive/hive.dart';

part 'paso.g.dart';

@HiveType(typeId: 4)
class Paso extends HiveObject {
  @HiveField(0)
  List<String> trabajadores;

  @HiveField(1)
  List<String> utensilioTipos;

  @HiveField(2)
  List<int> utensilioCantidades;

  @HiveField(3)
  int tiempoSegundos;

  @HiveField(4)
  String descripcion; // Descripción del paso

  Paso({
    required this.trabajadores,
    required this.utensilioTipos,
    required this.utensilioCantidades,
    required this.tiempoSegundos,
    required this.descripcion,
  });
}
