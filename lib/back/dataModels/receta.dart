import 'package:hive/hive.dart';

part 'receta.g.dart';

@HiveType(typeId: 4)
class Receta extends HiveObject {
  @HiveField(0)
  String nombre;

  @HiveField(1)
  String descripcion;

  @HiveField(2)
  int cantidadPorciones;

  @HiveField(3)
  String categoria; // entrada, fondo, postre

  @HiveField(4)
  List<String> etiquetas; // vegetariano, rapido, picante, etc.

  @HiveField(5)
  int duracionEstimadaMinutos;

  @HiveField(6)
  String? imagenPath; // Para futuro uso

  @HiveField(7)
  List<String> pasosIds; // IDs de los pasos asociados

  Receta({
    required this.nombre,
    required this.descripcion,
    required this.cantidadPorciones,
    required this.categoria,
    required this.etiquetas,
    required this.duracionEstimadaMinutos,
    this.imagenPath,
    required this.pasosIds,
  });
}
