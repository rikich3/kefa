import 'receta_repository.dart';
import '../data_sources/hive/hive_receta_data_source.dart';
import '../dataModels/receta.dart';

class RecetaRepositoryImpl implements RecetaRepository {
  final HiveRecetaDataSource hiveDataSource;

  RecetaRepositoryImpl({required this.hiveDataSource});

  @override
  Future<List<Receta>> getAllRecetas() {
    return hiveDataSource.getAllRecetas();
  }

  // Nuevo método para obtener recetas con sus keys de Hive
  Future<List<MapEntry<dynamic, Receta>>> getAllRecetasWithKeys() {
    return hiveDataSource.getAllRecetasWithKeys();
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
  Future<Receta?> getRecetaById(String id) {
    return hiveDataSource.getRecetaById(id);
  }
}
