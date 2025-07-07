import '../dataModels/receta.dart';

abstract class RecetaRepository {
  Future<List<Receta>> getAllRecetas();
  Future<void> addReceta(Receta receta);
  Future<void> updateReceta(dynamic key, Receta receta);
  Future<void> deleteReceta(dynamic key);
  Future<Receta?> getRecetaById(String id);
}
