import 'package:flutter/foundation.dart';
import '../../back/repositories/tarea_asignada_repository.dart';
import '../../back/dataModels/tarea_asignada.dart';

class TareaAsignadaProvider extends ChangeNotifier {
  final TareaAsignadaRepository _repository;

  TareaAsignadaProvider({required TareaAsignadaRepository repository})
      : _repository = repository;

  Map<String, List<TareaAsignada>> _tareasPorCocinero = {};
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  Map<String, List<TareaAsignada>> get tareasPorCocinero => _tareasPorCocinero;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Obtener tareas de un cocinero específico
  List<TareaAsignada> getTareasCocinero(String cocineroId) {
    return _tareasPorCocinero[cocineroId] ?? [];
  }

  // Obtener tareas ordenadas de un cocinero específico
  List<TareaAsignada> getTareasSortedCocinero(String cocineroId) {
    final tareas = getTareasCocinero(cocineroId);
    tareas.sort((a, b) => a.tiempoInicioSegundos.compareTo(b.tiempoInicioSegundos));
    return tareas;
  }

  // Verificar si hay tareas asignadas
  bool get hayTareasAsignadas => _tareasPorCocinero.isNotEmpty;

  // Contar total de tareas
  int get totalTareas => _tareasPorCocinero.values
      .fold(0, (total, tareas) => total + tareas.length);

  // Cargar todas las tareas
  Future<void> cargarTareas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tareasPorCocinero = await _repository.obtenerTodasLasTareas();
      print('📋 TareaAsignadaProvider: Cargadas ${totalTareas} tareas para ${_tareasPorCocinero.length} cocineros');
    } catch (e) {
      _errorMessage = 'Error al cargar tareas: $e';
      print('❌ Error en cargarTareas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Guardar múltiples tareas
  Future<void> guardarTareas(List<TareaAsignada> tareas) async {
    try {
      await _repository.guardarTareas(tareas);
      await cargarTareas(); // Recargar para actualizar la UI
      print('✅ Guardadas ${tareas.length} tareas');
    } catch (e) {
      _errorMessage = 'Error al guardar tareas: $e';
      print('❌ Error en guardarTareas: $e');
      notifyListeners();
    }
  }

  // Borrar tareas de un cocinero específico
  Future<void> borrarTareasCocinero(String cocineroId) async {
    try {
      await _repository.borrarTareasPorCocinero(cocineroId);
      await cargarTareas(); // Recargar para actualizar la UI
      print('🗑️ Borradas tareas del cocinero: $cocineroId');
    } catch (e) {
      _errorMessage = 'Error al borrar tareas del cocinero: $e';
      print('❌ Error en borrarTareasCocinero: $e');
      notifyListeners();
    }
  }

  // Borrar todas las tareas
  Future<void> borrarTodasLasTareas() async {
    try {
      await _repository.borrarTodasLasTareas();
      _tareasPorCocinero.clear();
      print('🗑️ Todas las tareas han sido borradas');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error al borrar todas las tareas: $e';
      print('❌ Error en borrarTodasLasTareas: $e');
      notifyListeners();
    }
  }

  // Verificar si un cocinero tiene tareas asignadas
  bool cocineroTieneTareas(String cocineroId) {
    return _tareasPorCocinero.containsKey(cocineroId) && 
           _tareasPorCocinero[cocineroId]!.isNotEmpty;
  }

  // Contar tareas de un cocinero
  int contarTareasCocinero(String cocineroId) {
    return _tareasPorCocinero[cocineroId]?.length ?? 0;
  }
}
