import 'worker_repository.dart'; // La interface
import '../data_sources/hive/hive_worker_data_source.dart'; // La fuente de datos Hive
import '../dataModels/worker.dart'; // El modelo

class WorkersRepositoryImpl implements WorkerRepository {
  final HiveWorkerDataSource hiveDataSource; // Dependencia a la fuente de datos Hive

  // Constructor que recibe la fuente de datos
  WorkersRepositoryImpl({required this.hiveDataSource});

  @override
  Future<List<Worker>> getAllWorkers() {
    // Llama al método correspondiente en la fuente de datos Hive
    return hiveDataSource.getAllWorkers();
  }

  @override
  Future<void> addWorker(Worker worker) {
    // Por ahora, solo usamos Hive. Si tuvieras Firestore también, aquí decidirías dónde guardar.
    return hiveDataSource.addWorker(worker);
  }

  @override
  Future<void> updateWorker(dynamic key, Worker worker) {
    return hiveDataSource.updateWorker(key, worker);
  }

  @override
  Future<void> deleteWorker(dynamic key) {
    return hiveDataSource.deleteWorker(key);
  }

  // Si implementas watchAllIngredients con Streams, la lógica iría aquí
  // @override
  // Stream<List<Ingredient>> watchAllIngredients() {
  //   // Lógica para emitir actualizaciones, tal vez usando Hive.watchBox()
  //   // Esto es más avanzado y opcional con Hive, más común con Firestore.
  // }
}