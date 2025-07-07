import 'recetas_repository.dart'; // La interface
import '../data_sources/hive/hive_recetas_data_source.dart'; // La fuente de datos Hive
import '../dataModels/receta.dart'; // El modelo

class RecetasRepositoryImpl implements RecetasRepository {
  final HiveRecetasDataSource hiveDataSource; // Dependencia a la fuente de datos Hive

  // Constructor que recibe la fuente de datos
  RecetasRepositoryImpl({required this.hiveDataSource});

  @override
  Future<List<MapEntry<dynamic, Receta>>> getAllRecetas() {
    // Llama al método correspondiente en la fuente de datos Hive
    return hiveDataSource.getAllRecetas();
  }

  @override
  Future<void> addReceta(Receta receta) {
    return hiveDataSource.addReceta(receta);
  }

  @override
  Future<void> updateReceta(dynamic key, Receta receta) {
    return hiveDataSource.updateReceta(key, receta);
  }

  @override
  Future<void> deleteReceta(dynamic key) {
    return hiveDataSource.deleteReceta(key);
  }

  @override
  Future<Receta?> getRecetaById(int id) {
    return hiveDataSource.getRecetaById(id);
  }

  @override
  Future<int> getNextId() {
    return hiveDataSource.getNextId();
  }
}
