import '../dataModels/worker.dart';

abstract class WorkerRepository {
  // Definir los métodos que el Repository debe implementar
  // No hay lógica específica de Hive o Firestore aquí
  Future<List<Worker>> getAllWorkers();
  Future<void> addWorker(Worker worker);
  Future<void> updateWorker(dynamic key, Worker worker); // Usando dynamic key por ahora
  Future<void> deleteWorker(dynamic key); // Usando dynamic key por ahora
  // Puedes añadir Streams en el futuro si lo necesitas
  // Stream<List<Ingredient>> watchAllIngredients();
}