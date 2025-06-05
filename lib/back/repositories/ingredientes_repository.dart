import '../dataModels/ingredientes.dart';

abstract class IngredientesRepository {
  // Definir los métodos que el Repository debe implementar
  // No hay lógica específica de Hive o Firestore aquí
  Future<List<MapEntry<dynamic, Ingredientes>>> getAllIngredientes();
  Future<void> addIngrediente(Ingredientes ingrediente);
  Future<void> updateIngrediente(dynamic key, Ingredientes ingrediente); // Usando dynamic key por ahora
  Future<void> deleteIngrediente(dynamic key); // Usando dynamic key por ahora
  // Puedes añadir Streams en el futuro si lo necesitas
  // Stream<List<Ingredient>> watchAllIngredients();
}