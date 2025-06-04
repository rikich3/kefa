import 'package:hive/hive.dart';

part 'instrumentos.g.dart';

@HiveType(typeId:2)
class Instrumento extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  int id;

  @HiveField(2)
  String descripcion;

  @HiveField(3)
  double peso;

  @HiveField(4)
  List<double> dimensiones;

  @HiveField(5)
  int cantidad;

  Instrumento({
    required this.nombre,
    required this.id,
    required this.descripcion,
    required this.peso,
    required this.dimensiones,
    required this.cantidad,
  });
}