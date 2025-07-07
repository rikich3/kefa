import 'package:hive/hive.dart';

part 'paso.g.dart';

@HiveType(typeId: 5)
class IngredienteRequerido extends HiveObject {
  @HiveField(0)
  String ingredienteId;

  @HiveField(1)
  double cantidad;

  @HiveField(2)
  String unidadMedida; // gr, ml, cc, taza, cuchara, cucharita

  IngredienteRequerido({
    required this.ingredienteId,
    required this.cantidad,
    required this.unidadMedida,
  });
}

@HiveType(typeId: 6)
class Paso extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String recetaId;

  @HiveField(2)
  String nombrePaso;

  @HiveField(3)
  String contenidoAccion;

  @HiveField(4)
  List<String> recursosCocinasRequeridos; // IDs de utensilios y workers

  @HiveField(5)
  List<IngredienteRequerido> ingredientesRequeridos;

  @HiveField(6)
  List<String> recursoAlmacenamiento; // IDs de utensilios

  @HiveField(7)
  int tiempoCoccionSegundos;

  @HiveField(8)
  int tiempoPreparacionSegundos;

  @HiveField(9)
  String tipoCoccion; // carnes, vegetales, pescados y mariscos, etc.

  @HiveField(10)
  String tipoAlmacenamiento; // carnes, vegetales, pescados y mariscos, etc.

  @HiveField(11)
  List<String> tareasAnterioresDirectas; // IDs de pasos previos

  @HiveField(12)
  int orden; // Para mantener el orden de los pasos

  // Campos para scheduling
  @HiveField(13)
  String? tipoCocinero; // cocinero, olla

  @HiveField(14)
  String? tipoUtensilio; // A, B, C, D

  @HiveField(15)
  List<String>? dependencias; // Nombres de pasos de los que depende

  Paso({
    required this.id,
    required this.recetaId,
    required this.nombrePaso,
    required this.contenidoAccion,
    required this.recursosCocinasRequeridos,
    required this.ingredientesRequeridos,
    required this.recursoAlmacenamiento,
    required this.tiempoCoccionSegundos,
    required this.tiempoPreparacionSegundos,
    required this.tipoCoccion,
    required this.tipoAlmacenamiento,
    required this.tareasAnterioresDirectas,
    required this.orden,
    this.tipoCocinero,
    this.tipoUtensilio,
    this.dependencias,
  });
}
