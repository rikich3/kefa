import 'paso_repository.dart';
import '../data_sources/hive/hive_paso_data_source.dart';
import '../dataModels/paso.dart';

class PasoRepositoryImpl implements PasoRepository {
  final HivePasoDataSource hiveDataSource;

  PasoRepositoryImpl({required this.hiveDataSource});

  @override
  Future<List<Paso>> getAllPasos() {
    return hiveDataSource.getAllPasos();
  }

  @override
  Future<List<Paso>> getPasosByRecetaId(String recetaId) {
    return hiveDataSource.getPasosByRecetaId(recetaId);
  }

  @override
  Future<void> addPaso(Paso paso) {
    return hiveDataSource.addPaso(paso);
  }

  @override
  Future<void> updatePaso(dynamic key, Paso paso) {
    return hiveDataSource.updatePaso(key, paso);
  }

  @override
  Future<void> deletePaso(dynamic key) {
    return hiveDataSource.deletePaso(key);
  }

  @override
  Future<void> deletePasosByRecetaId(String recetaId) {
    return hiveDataSource.deletePasosByRecetaId(recetaId);
  }
}
