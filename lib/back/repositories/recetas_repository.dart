import '../dataModels/receta.dart';

abstract class RecetasRepository {
  // Definir los métodos que el Repository debe implementar
  Future<List<MapEntry<dynamic, Receta>>> getAllRecetas();
  Future<void> addReceta(Receta receta);
  Future<void> updateReceta(dynamic key, Receta receta);
  Future<void> deleteReceta(dynamic key);
  Future<Receta?> getRecetaById(int id);
  Future<int> getNextId();
}
