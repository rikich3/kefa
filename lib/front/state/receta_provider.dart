import 'package:flutter/foundation.dart';
import '../../back/repositories/receta_repository.dart';
import '../../back/repositories/receta_repository_impl.dart';
import '../../back/repositories/paso_repository.dart';
import '../../back/dataModels/receta.dart';

class RecetaProvider extends ChangeNotifier {
  final RecetaRepository recetaRepository;
  final PasoRepository pasoRepository;

  RecetaProvider({
    required this.recetaRepository,
    required this.pasoRepository,
  }) {
    loadRecetas();
  }

  // Estado
  List<MapEntry<dynamic, Receta>> _recetaEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<MapEntry<dynamic, Receta>> get recetaEntries => _recetaEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar todas las recetas
  Future<void> loadRecetas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔄 Cargando recetas desde el repositorio...');
      final recetaEntries = await (recetaRepository as RecetaRepositoryImpl).getAllRecetasWithKeys();
      print('📥 Recetas obtenidas del repositorio: ${recetaEntries.length}');
      _recetaEntries = recetaEntries;
      print('📋 Recetas cargadas en provider: ${_recetaEntries.length}');
      for (var entry in _recetaEntries) {
        print('   - Key: ${entry.key}, Receta: ${entry.value.nombre}');
      }
    } catch (e) {
      print('❌ Error al cargar recetas: $e');
      _errorMessage = 'Error al cargar recetas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar receta
  Future<void> addReceta(Receta receta) async {
    try {
      print('🔄 Intentando guardar receta: ${receta.nombre}');
      await recetaRepository.addReceta(receta);
      print('✅ Receta guardada exitosamente en repositorio');
      await loadRecetas(); // Recargar la lista
      print('📋 Lista recargada. Total recetas: ${_recetaEntries.length}');
    } catch (e) {
      print('❌ Error al agregar receta: $e');
      _errorMessage = 'Error al agregar receta: $e';
      notifyListeners();
    }
  }

  // Actualizar receta
  Future<void> updateReceta(dynamic key, Receta receta) async {
    try {
      await recetaRepository.updateReceta(key, receta);
      await loadRecetas(); // Recargar la lista
    } catch (e) {
      _errorMessage = 'Error al actualizar receta: $e';
      notifyListeners();
    }
  }

  // Eliminar receta
  Future<void> deleteReceta(dynamic key) async {
    print('🔥 Provider: Iniciando eliminación de receta con key: $key (tipo: ${key.runtimeType})');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Obtener la receta antes de eliminarla para saber su nombre/ID
      final recetaEntry = _recetaEntries.firstWhere(
        (entry) => entry.key == key,
        orElse: () => throw Exception('Receta no encontrada'),
      );
      final nombreReceta = recetaEntry.value.nombre;
      
      print('🔥 Provider: Eliminando pasos de la receta: $nombreReceta');
      // Primero eliminar todos los pasos asociados a esta receta
      await pasoRepository.deletePasosByRecetaId(nombreReceta);
      print('🔥 Provider: Pasos eliminados exitosamente');
      
      // Luego eliminar la receta
      await recetaRepository.deleteReceta(key);
      print('🔥 Provider: Eliminación exitosa, recargando lista...');
      await loadRecetas(); // Recargar la lista
      print('🔥 Provider: Lista recargada exitosamente');
    } catch (e) {
      print('🔥 Provider: Error durante eliminación: $e');
      _errorMessage = 'Error al eliminar receta: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Obtener receta por ID
  Future<Receta?> getRecetaById(String id) async {
    try {
      return await recetaRepository.getRecetaById(id);
    } catch (e) {
      _errorMessage = 'Error al obtener receta: $e';
      notifyListeners();
      return null;
    }
  }
}
