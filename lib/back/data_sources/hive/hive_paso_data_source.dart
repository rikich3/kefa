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
    print('🔧 HivePasoDataSource: Actualizando paso con key: $key');
    print('   Paso ID: ${paso.id}, Nombre: ${paso.nombrePaso}');
    print('   Total pasos en caja antes: ${box.length}');
    
    // Verificar si la key existe
    if (box.containsKey(key)) {
      await box.put(key, paso);
      print('   ✅ Paso actualizado exitosamente');
    } else {
      print('   ❌ La key $key no existe en la caja');
      print('   Keys disponibles: ${box.keys.toList()}');
      throw Exception('Key $key no encontrada para actualizar');
    }
    
    print('   Total pasos en caja después: ${box.length}');
  }

  // Eliminar un paso
  Future<void> deletePaso(dynamic key) async {
    final box = await _pasoBox;
    print('🔥 HivePasoDataSource: Eliminando paso con key: $key');
    print('🔥 HivePasoDataSource: Pasos antes de eliminar: ${box.length}');
    
    // Verificar si la key existe
    if (box.containsKey(key)) {
      final paso = box.get(key);
      print('🔥 HivePasoDataSource: Eliminando paso: ${paso?.nombrePaso} (ID: ${paso?.id})');
      await box.delete(key);
      print('🔥 HivePasoDataSource: Paso eliminado exitosamente');
    } else {
      print('🔥 HivePasoDataSource: ❌ La key $key no existe en la caja');
      print('🔥 HivePasoDataSource: Keys disponibles: ${box.keys.toList()}');
      throw Exception('Key $key no encontrada para eliminar');
    }
    
    print('🔥 HivePasoDataSource: Pasos después de eliminar: ${box.length}');
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
