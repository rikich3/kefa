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
  int cantidad;

  @HiveField(4)
  String tipo; // "Normal" o "Almacenamiento"

  @HiveField(5)
  double? capacidadMaximaKg; // Solo si es de almacenamiento

  Instrumento({
    required this.nombre,
    required this.id,
    required this.descripcion,
    required this.cantidad,
    required this.tipo,
    this.capacidadMaximaKg,
  });
}