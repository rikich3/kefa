import 'package:hive/hive.dart';

part 'ingredientes.g.dart';

@HiveType(typeId: 1)
class ingredientes{
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String descripcion;
  @HiveField(2)
  final String unidadMedida;
  @HiveField(3)
  final int cantidad;
  @HiveField(4)
  final double precio;
  ingredientes({
    required this.name,
    required this.descripcion,
    required this.unidadMedida,
    required this. cantidad,
    required this. precio
  });
}