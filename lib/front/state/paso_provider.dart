import 'package:flutter/foundation.dart';
import '../../back/repositories/paso_repository.dart';
import '../../back/dataModels/paso.dart';

class PasoProvider extends ChangeNotifier {
  final PasoRepository pasoRepository;

  PasoProvider({required this.pasoRepository});

  // Estado
  List<MapEntry<dynamic, Paso>> _pasoEntries = [];
  List<MapEntry<dynamic, Paso>> _pasosCurrentReceta = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentRecetaId;

  // Getters
  List<MapEntry<dynamic, Paso>> get pasoEntries => _pasoEntries;
  List<MapEntry<dynamic, Paso>> get pasosCurrentReceta => _pasosCurrentReceta;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentRecetaId => _currentRecetaId;

  // Cargar todos los pasos
  Future<void> loadPasos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pasos = await pasoRepository.getAllPasos();
      _pasoEntries = pasos.asMap().entries.map((entry) {
        return MapEntry(entry.key, entry.value);
      }).toList();
    } catch (e) {
      _errorMessage = 'Error al cargar pasos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar pasos por receta ID
  Future<void> loadPasosByRecetaId(String recetaId) async {
    _isLoading = true;
    _errorMessage = null;
    _currentRecetaId = recetaId;
    notifyListeners();

    try {
      final pasos = await pasoRepository.getPasosByRecetaId(recetaId);
      _pasosCurrentReceta = pasos.asMap().entries.map((entry) {
        return MapEntry(entry.key, entry.value);
      }).toList();
    } catch (e) {
      _errorMessage = 'Error al cargar pasos de la receta: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Agregar paso
  Future<void> addPaso(Paso paso) async {
    try {
      await pasoRepository.addPaso(paso);
      if (_currentRecetaId == paso.recetaId) {
        await loadPasosByRecetaId(paso.recetaId); // Recargar pasos de la receta actual
      }
      await loadPasos(); // Recargar todos los pasos
    } catch (e) {
      _errorMessage = 'Error al agregar paso: $e';
      notifyListeners();
    }
  }

  // Actualizar paso
  Future<void> updatePaso(dynamic key, Paso paso) async {
    try {
      await pasoRepository.updatePaso(key, paso);
      if (_currentRecetaId == paso.recetaId) {
        await loadPasosByRecetaId(paso.recetaId); // Recargar pasos de la receta actual
      }
      await loadPasos(); // Recargar todos los pasos
    } catch (e) {
      _errorMessage = 'Error al actualizar paso: $e';
      notifyListeners();
    }
  }

  // Eliminar paso
  Future<void> deletePaso(dynamic key) async {
    try {
      print('🔥 PasoProvider: Eliminando paso con key: $key');
      await pasoRepository.deletePaso(key);
      print('🔥 PasoProvider: Paso eliminado del repositorio, recargando listas...');
      
      if (_currentRecetaId != null) {
        await loadPasosByRecetaId(_currentRecetaId!); // Recargar pasos de la receta actual
      }
      await loadPasos(); // Recargar todos los pasos
      print('🔥 PasoProvider: Listas recargadas exitosamente');
    } catch (e) {
      print('🔥 PasoProvider: Error al eliminar paso: $e');
      _errorMessage = 'Error al eliminar paso: $e';
      notifyListeners();
    }
  }

  // Eliminar todos los pasos de una receta
  Future<void> deletePasosByRecetaId(String recetaId) async {
    try {
      await pasoRepository.deletePasosByRecetaId(recetaId);
      if (_currentRecetaId == recetaId) {
        _pasosCurrentReceta.clear();
      }
      await loadPasos(); // Recargar todos los pasos
    } catch (e) {
      _errorMessage = 'Error al eliminar pasos de la receta: $e';
      notifyListeners();
    }
  }
}
