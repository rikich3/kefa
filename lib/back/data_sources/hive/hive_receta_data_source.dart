import 'package:hive_flutter/hive_flutter.dart';
import '../../dataModels/receta.dart';

class HiveRecetaDataSource {
  Future<Box<Receta>> get _recetaBox async =>
      await Hive.openBox<Receta>('recetas');

  // Obtener todas las recetas con sus keys de Hive
  Future<List<MapEntry<dynamic, Receta>>> getAllRecetasWithKeys() async {
    final box = await _recetaBox;
    print('📖 Cargando recetas con keys desde Hive. Total encontradas: ${box.length}');
    
    List<MapEntry<dynamic, Receta>> entries = [];
    for (var key in box.keys) {
      final receta = box.get(key);
      if (receta != null) {
        entries.add(MapEntry(key, receta));
      }
    }
    
    if (entries.isNotEmpty) {
      print('🔍 Recetas encontradas: ${entries.map((e) => '${e.key}:${e.value.nombre}').toList()}');
    }
    return entries;
  }

  // Obtener todas las recetas
  Future<List<Receta>> getAllRecetas() async {
    final box = await _recetaBox;
    print('📖 Cargando recetas desde Hive. Total encontradas: ${box.length}');
    if (box.isNotEmpty) {
      print('🔍 Recetas encontradas: ${box.values.map((r) => r.nombre).toList()}');
    }
    return box.values.toList();
  }

  // Añadir una nueva receta
  Future<void> addReceta(Receta receta) async {
    final box = await _recetaBox;
    print('📦 Abriendo caja de recetas. Total existentes: ${box.length}');
    
    await box.add(receta);
    
    // Forzar el guardado inmediato
    await box.flush();
    
    print('💾 Receta agregada a Hive. Nuevo total: ${box.length}');
    print('🔍 Recetas en la caja: ${box.values.map((r) => r.nombre).toList()}');
    print('💽 Datos forzadamente guardados en disco');
  }

  // Actualizar una receta
  Future<void> updateReceta(dynamic key, Receta receta) async {
    final box = await _recetaBox;
    await box.put(key, receta);
  }

  // Eliminar una receta
  Future<void> deleteReceta(dynamic key) async {
    final box = await _recetaBox;
    print('🗑️ Intentando eliminar receta con key: $key');
    print('📊 Estado antes: ${box.length} recetas');
    print('🔍 Recetas antes: ${box.values.map((r) => r.nombre).toList()}');
    
    await box.delete(key);
    await box.flush(); // Forzar guardado
    
    print('📊 Estado después: ${box.length} recetas');
    print('🔍 Recetas después: ${box.values.map((r) => r.nombre).toList()}');
    print('✅ Eliminación completada y guardada');
  }

  // Obtener receta por ID
  Future<Receta?> getRecetaById(String id) async {
    final box = await _recetaBox;
    return box.values.firstWhere(
      (receta) => receta.key.toString() == id,
      orElse: () => throw StateError('Receta no encontrada'),
    );
  }

  // Cerrar la caja
  Future<void> closeBox() async {
    final box = await _recetaBox;
    await box.close();
  }
}
