import 'package:hive/hive.dart';

part 'worker.g.dart';

@HiveType(typeId: 3)
class Worker extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String nombre;

  @HiveField(2)
  String descripcion;

  @HiveField(3)
  String funcion;

  Worker({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.funcion,
  });
}