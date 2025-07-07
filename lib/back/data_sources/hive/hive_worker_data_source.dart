import 'package:hive_flutter/hive_flutter.dart';
import '../../dataModels/worker.dart';

class HiveWorkerDataSource {
  // Lazy-load la caja cuando se necesite
  // Si prefieres abrirla al inicio, ya la tendrías disponible aquí.
  Future<Box<Worker>> get _workerBox async =>
      await Hive.openBox<Worker>('worker'); // Nombre de la caja

  // Obtener todos los workers con sus keys de Hive
  Future<List<MapEntry<dynamic, Worker>>> getAllWorkersWithKeys() async {
    final box = await _workerBox;
    print('📖 Cargando workers con keys desde Hive. Total encontrados: ${box.length}');
    
    List<MapEntry<dynamic, Worker>> entries = [];
    for (var key in box.keys) {
      final worker = box.get(key);
      if (worker != null) {
        entries.add(MapEntry(key, worker));
      }
    }
    
    if (entries.isNotEmpty) {
      print('🔍 Workers encontrados: ${entries.map((e) => '${e.key}:${e.value.nombre}').toList()}');
    }
    return entries;
  }

  // Obtener todos los worker
  Future<List<Worker>> getAllWorkers() async {
    final box = await _workerBox;
    return box.values.toList();
  }

  // Añadir un nuevo worker
  Future<void> addWorker(Worker worker) async {
    final box = await _workerBox;
    // Hive usa índices o claves para guardar. Usar add() guarda con un índice autoincremental.
    // Puedes usar put(key, value) si quieres usar tus propias claves (ej: UUID)
    await box.add(worker);
  }

  // Actualizar un worker (usando su key)
  Future<void> updateWorker(dynamic key, Worker worker) async {
     final box = await _workerBox;
     await box.put(key, worker); // key es el índice/clave con el que se guardó
  }

  // Eliminar un worker (usando su key)
  Future<void> deleteWorker(dynamic key) async {
    final box = await _workerBox;
    print('🗑️ Intentando eliminar worker con key: $key');
    print('📊 Estado antes: ${box.length} workers');
    print('🔍 Workers antes: ${box.values.map((w) => w.nombre).toList()}');
    
    await box.delete(key);
    await box.flush(); // Forzar guardado
    
    print('📊 Estado después: ${box.length} workers');
    print('🔍 Workers después: ${box.values.map((w) => w.nombre).toList()}');
    print('✅ Eliminación completada y guardada');
  }

  // Cerrar la caja cuando ya no se necesite (opcional, Flutter cierra al terminar)
  Future<void> closeBox() async {
     final box = await _workerBox;
     await box.close();
  }
}