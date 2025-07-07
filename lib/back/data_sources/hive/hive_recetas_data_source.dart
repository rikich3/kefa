import 'package:hive_flutter/hive_flutter.dart';
import '../../dataModels/receta.dart';

class HiveRecetasDataSource {
  // Lazy-load la caja cuando se necesite
  Future<Box<Receta>> get _recetasBox async =>
      await Hive.openBox<Receta>('recetas'); // Nombre de la caja

  // Obtener todas las recetas
  Future<List<MapEntry<dynamic, Receta>>> getAllRecetas() async {
    final box = await _recetasBox;
    return box.toMap().entries.toList();
  }

  // Añadir una nueva receta
  Future<void> addReceta(Receta receta) async {
    final box = await _recetasBox;
    await box.add(receta);
  }

  // Actualizar una receta (usando su key)
  Future<void> updateReceta(dynamic key, Receta receta) async {
     final box = await _recetasBox;
     await box.put(key, receta);
  }

  // Eliminar una receta (usando su key)
  Future<void> deleteReceta(dynamic key) async {
    final box = await _recetasBox;
    await box.delete(key);
  }

  // Obtener una receta por ID
  Future<Receta?> getRecetaById(int id) async {
    final box = await _recetasBox;
    final recetas = box.values.where((receta) => receta.id == id);
    return recetas.isNotEmpty ? recetas.first : null;
  }

  // Obtener el próximo ID disponible
  Future<int> getNextId() async {
    final box = await _recetasBox;
    if (box.isEmpty) return 1;
    final maxId = box.values.map((receta) => receta.id).reduce((a, b) => a > b ? a : b);
    return maxId + 1;
  }

  // Cerrar la caja cuando ya no se necesite
  Future<void> closeBox() async {
     final box = await _recetasBox;
     await box.close();
  }
}
