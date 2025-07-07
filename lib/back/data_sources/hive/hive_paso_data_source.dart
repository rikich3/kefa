import 'package:hive_flutter/hive_flutter.dart';
import '../../dataModels/paso.dart';

class HivePasoDataSource {
  Future<Box<Paso>> get _pasoBox async =>
      await Hive.openBox<Paso>('pasos');

  // Obtener todos los pasos
  Future<List<Paso>> getAllPasos() async {
    final box = await _pasoBox;
    return box.values.toList();
  }

  // Obtener pasos por receta ID
  Future<List<Paso>> getPasosByRecetaId(String recetaId) async {
    final box = await _pasoBox;
    final pasos = box.values.where((paso) => paso.recetaId == recetaId).toList();
    // Ordenar por campo orden
    pasos.sort((a, b) => a.orden.compareTo(b.orden));
    return pasos;
  }

  // Añadir un nuevo paso
  Future<void> addPaso(Paso paso) async {
    final box = await _pasoBox;
    await box.add(paso);
  }

  // Actualizar un paso
  Future<void> updatePaso(dynamic key, Paso paso) async {
    final box = await _pasoBox;
    await box.put(key, paso);
  }

  // Eliminar un paso
  Future<void> deletePaso(dynamic key) async {
    final box = await _pasoBox;
    print('🔥 HivePasoDataSource: Eliminando paso con key: $key');
    print('🔥 HivePasoDataSource: Pasos antes de eliminar: ${box.length}');
    await box.delete(key);
    print('🔥 HivePasoDataSource: Pasos después de eliminar: ${box.length}');
    print('🔥 HivePasoDataSource: Paso eliminado exitosamente');
  }

  // Eliminar todos los pasos de una receta
  Future<void> deletePasosByRecetaId(String recetaId) async {
    final box = await _pasoBox;
    final keysToDelete = <dynamic>[];
    
    print('🔥 HivePasoDataSource: Eliminando pasos de receta: $recetaId');
    print('🔥 HivePasoDataSource: Total pasos antes: ${box.length}');
    
    for (final entry in box.toMap().entries) {
      if (entry.value.recetaId == recetaId) {
        keysToDelete.add(entry.key);
        print('🔥 HivePasoDataSource: Marcando para eliminar paso: ${entry.value.nombrePaso} (key: ${entry.key})');
      }
    }
    
    print('🔥 HivePasoDataSource: Se eliminarán ${keysToDelete.length} pasos');
    
    for (final key in keysToDelete) {
      await box.delete(key);
    }
    
    print('🔥 HivePasoDataSource: Total pasos después: ${box.length}');
    print('🔥 HivePasoDataSource: Eliminación en cascada completada');
  }

  // Cerrar la caja
  Future<void> closeBox() async {
    final box = await _pasoBox;
    await box.close();
  }
}
