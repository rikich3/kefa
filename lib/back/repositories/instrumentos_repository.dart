import '../dataModels/instrumentos.dart';

abstract class InstrumentosRepository {
  // Definir los métodos que el Repository debe implementar
  // No hay lógica específica de Hive o Firestore aquí
  Future<List<Instrumento>> getAllInstrumentos();
  Future<void> addInstrumento(Instrumento instrumento);
  Future<void> updateInstrumento(dynamic key, Instrumento instrumento); // Usando dynamic key por ahora
  Future<void> deleteInstrumento(dynamic key); // Usando dynamic key por ahora
  // Puedes añadir Streams en el futuro si lo necesitas
  // Stream<List<Ingredient>> watchAllIngredients();
}