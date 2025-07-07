import 'package:hive_flutter/hive_flutter.dart';
import '../../dataModels/ingredientes.dart';

class HiveIngredientesDataSource {
  // Lazy-load la caja cuando se necesite
  // Si prefieres abrirla al inicio, ya la tendrías disponible aquí.
  Future<Box<Ingredientes>> get _ingredientesBox async =>
      await Hive.openBox<Ingredientes>('ingredientes'); // Nombre de la caja

  // Obtener todos los ingredienteses
  Future<List<MapEntry<dynamic, Ingredientes>>> getAllIngredientes() async {
    final box = await _ingredientesBox;
    print('📖 Cargando ingredientes desde Hive. Total encontrados: ${box.length}');
    if (box.isNotEmpty) {
      print('🔍 Ingredientes encontrados: ${box.values.map((i) => i.name).toList()}');
    }
    return box.toMap().entries.toList();
  }

  // Añadir un nuevo ingredientese
  Future<void> addIngredientes(Ingredientes ingrediente) async {
    final box = await _ingredientesBox;
    print('📦 Abriendo caja de ingredientes. Total existentes: ${box.length}');

    // Hive usa índices o claves para guardar. Usar add() guarda con un índice autoincremental.
    await box.add(ingrediente);

    // Forzar el guardado inmediato
    await box.flush();

    print('💾 Ingrediente agregado a Hive. Nuevo total: ${box.length}');
    print('🔍 Ingredientes en la caja: ${box.values.map((i) => i.name).toList()}');
    print('💽 Datos forzadamente guardados en disco');
  }

  // Actualizar un ingredientese (usando su key)
  Future<void> updateIngrediente(dynamic key, Ingredientes ingrediente) async {
     final box = await _ingredientesBox;
     await box.put(key, ingrediente); // key es el índice/clave con el que se guardó
  }

  // Eliminar un ingredientese (usando su key)
  Future<void> deleteIngrediente(dynamic key) async {
    final box = await _ingredientesBox;
    await box.delete(key);
  }

  // Cerrar la caja cuando ya no se necesite (opcional, Flutter cierra al terminar)
  Future<void> closeBox() async {
     final box = await _ingredientesBox;
     await box.close();
  }
}