import 'package:flutter/material.dart';
import '../../back/dataModels/receta.dart';
import '../../back/repositories/recetas_repository.dart';

class RecetasProvider extends ChangeNotifier {
  final RecetasRepository _recetasRepository;

  List<MapEntry<dynamic, Receta>> _recetasEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Constructor que recibe el Repository
  RecetasProvider({required RecetasRepository recetasRepository})
      : _recetasRepository = recetasRepository {
    loadRecetas();
  }

  // Getters para acceder al estado desde la UI
  List<MapEntry<dynamic, Receta>> get recetasEntries => _recetasEntries;
  List<Receta> get recetas => _recetasEntries.map((e) => e.value).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Método para cargar recetas desde el Repository
  Future<void> loadRecetas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recetasEntries = await _recetasRepository.getAllRecetas();
    } catch (e) {
      _errorMessage = 'Error al cargar recetas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para añadir una receta
  Future<void> addReceta(Receta receta) async {
    if (receta.nombre.isEmpty) {
      _errorMessage = 'El nombre de la receta no puede estar vacío';
      notifyListeners();
      return;
    }

    try {
      // Generar ID único
      receta.id = await _recetasRepository.getNextId();
      
      // Calcular tiempo total
      receta.calcularTiempoTotal();
      
      await _recetasRepository.addReceta(receta);
      await loadRecetas(); // Recargar para mostrar la nueva receta
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al añadir receta: $e';
    }
    notifyListeners();
  }

  // Método para actualizar una receta
  Future<void> updateReceta(dynamic key, Receta receta) async {
    try {
      receta.calcularTiempoTotal(); // Recalcular tiempo total
      await _recetasRepository.updateReceta(key, receta);
      await loadRecetas();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al actualizar receta: $e';
    }
    notifyListeners();
  }

  // Método para eliminar una receta
  Future<void> deleteReceta(dynamic key) async {
    try {
      await _recetasRepository.deleteReceta(key);
      await loadRecetas();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Error al eliminar receta: $e';
    }
    notifyListeners();
  }

  // Método para obtener una receta por ID
  Future<Receta?> getRecetaById(int id) async {
    try {
      return await _recetasRepository.getRecetaById(id);
    } catch (e) {
      _errorMessage = 'Error al obtener receta: $e';
      notifyListeners();
      return null;
    }
  }

  // Limpiar errores
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
