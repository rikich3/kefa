import 'package:hive_flutter/hive_flutter.dart';
import '../dataModels/tarea_asignada.dart';

class TareaAsignadaRepository {
  static const String _boxName = 'tareas_asignadas';
  Box<TareaAsignada>? _box;

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<TareaAsignada>(_boxName);
    } else {
      _box = Hive.box<TareaAsignada>(_boxName);
    }
  }

  Future<List<TareaAsignada>> obtenerTareasPorCocinero(String cocineroId) async {
    await init();
    return _box!.values
        .where((tarea) => tarea.cocineroId == cocineroId)
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  Future<Map<String, List<TareaAsignada>>> obtenerTodasLasTareas() async {
    await init();
    final tareasPorCocinero = <String, List<TareaAsignada>>{};
    
    for (final tarea in _box!.values) {
      if (!tareasPorCocinero.containsKey(tarea.cocineroId)) {
        tareasPorCocinero[tarea.cocineroId] = [];
      }
      tareasPorCocinero[tarea.cocineroId]!.add(tarea);
    }

    // Ordenar cada lista por orden
    for (final lista in tareasPorCocinero.values) {
      lista.sort((a, b) => a.orden.compareTo(b.orden));
    }

    return tareasPorCocinero;
  }

  Future<void> guardarTarea(TareaAsignada tarea) async {
    await init();
    await _box!.put(tarea.id, tarea);
  }

  Future<void> guardarTareas(List<TareaAsignada> tareas) async {
    await init();
    final Map<String, TareaAsignada> tareasMap = {
      for (var tarea in tareas) tarea.id: tarea
    };
    await _box!.putAll(tareasMap);
  }

  Future<void> borrarTareasPorCocinero(String cocineroId) async {
    await init();
    final tareasABorrar = _box!.values
        .where((tarea) => tarea.cocineroId == cocineroId)
        .map((tarea) => tarea.key)
        .toList();
    
    for (final key in tareasABorrar) {
      await _box!.delete(key);
    }
  }

  Future<void> borrarTodasLasTareas() async {
    await init();
    await _box!.clear();
  }

  Future<bool> tieneTasksAsignadas() async {
    await init();
    return _box!.isNotEmpty;
  }

  Future<int> contarTareasPorCocinero(String cocineroId) async {
    await init();
    return _box!.values
        .where((tarea) => tarea.cocineroId == cocineroId)
        .length;
  }
}
