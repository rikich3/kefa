import '../dataModels/paso.dart';

abstract class PasoRepository {
  Future<List<Paso>> getAllPasos();
  Future<List<Paso>> getPasosByRecetaId(String recetaId);
  Future<void> addPaso(Paso paso);
  Future<void> updatePaso(dynamic key, Paso paso);
  Future<void> deletePaso(dynamic key);
  Future<void> deletePasosByRecetaId(String recetaId);
}
