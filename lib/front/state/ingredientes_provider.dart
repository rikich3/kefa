import 'package:flutter/material.dart';
import '../../back/dataModels/ingredientes.dart';
import '../../back/repositories/ingredientes_repository.dart'; // Usamos la interface del Repository

class IngredientesProvider extends ChangeNotifier {
  final IngredientesRepository _ingredientesRepository; // Dependencia al Repository

  List<MapEntry<dynamic, Ingredientes>> _ingredientesEntries = []; // El estado que la UI observará
  bool _isLoading = false; // Estado de carga (opcional pero útil)
  String? _errorMessage; // Mensaje de error (opcional)

  // Constructor que recibe el Repository
  IngredientesProvider({required IngredientesRepository ingredientRepository})
      : _ingredientesRepository = ingredientRepository {
    // Opcional: Cargar datos al crear el Provider
    loadIngredients();
  }

  // Getters para acceder al estado desde la UI
  List<MapEntry<dynamic, Ingredientes>> get ingredientesEntries => _ingredientesEntries;
  List<Ingredientes> get ingredients => _ingredientesEntries.map((e) => e.value).toList(); 
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Método para cargar ingredientes desde el Repository
  Future<void> loadIngredients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Notificar a los listeners que empezó la carga

    try {
      _ingredientesEntries = await _ingredientesRepository.getAllIngredientes();
      // Si implementas Streams en el Repository, podrías suscribirte aquí:
      // _ingredientRepository.watchAllIngredients().listen((data) {
      //   _ingredients = data;
      //   notifyListeners(); // Notificar cada vez que el stream emite datos
      // });
    } catch (e) {
      _errorMessage = 'Error al cargar ingredientes: $e';
      //print(_errorMessage); // Imprimir error en consola
    } finally {
      _isLoading = false;
      notifyListeners(); // Notificar a los listeners que la carga terminó (éxito o error)
    }
  }

  // Método para añadir un ingrediente (llamado desde la UI)
  Future<void> addIngredient(Ingredientes ingredient) async {
     // Lógica de negocio, validación, etc. antes de llamar al repo
     if (ingredient.name.isEmpty) {
        _errorMessage = 'El nombre del ingrediente no puede estar vacío';
        notifyListeners();
        return;
     }

     _isLoading = true; // Opcional: Mostrar estado de carga para la acción
     _errorMessage = null;
     notifyListeners();

     try {
        await _ingredientesRepository.addIngrediente(ingredient);
        // Después de añadir, recargar la lista o añadir localmente (dependiendo de tu estrategia)
        // Si usas Streams en el repo, el stream automáticamente emitirá la nueva lista.
        // Si no, podrías recargar:
        await loadIngredients(); // Opcional: Recargar toda la lista
        // O añadir localmente (más rápido pero debes manejar las keys de Hive si usaste put)
        // _ingredients.add(ingredient);
        // notifyListeners();
     } catch (e) {
       _errorMessage = 'Error al añadir ingrediente: $e';
       //print(_errorMessage);
     } finally {
        _isLoading = false;
        notifyListeners();
     }
  }

   // Implementar updateIngredient y deleteIngredient de forma similar
   Future<void> updateIngredient(dynamic key, Ingredientes ingredient) async {
      // ... lógica similar a addIngredient, llamando a _ingredientRepository.updateIngredient(key, ingredient) ...
      await _ingredientesRepository.updateIngrediente(key, ingredient);
      await loadIngredients(); // O actualizar la lista localmente
   }

   Future<void> deleteIngredient(dynamic key) async {
      // ... lógica similar a addIngredient, llamando a _ingredientRepository.deleteIngredient(key) ...
       await _ingredientesRepository.deleteIngrediente(key);
       await loadIngredients(); // O eliminar localmente de la lista
   }


  // Asegúrate de limpiar recursos si usaste Streams que necesitan cancelación
  // @override
  // void dispose() {
  //   _streamSubscription?.cancel(); // Si tienes una suscripción de stream
  //   super.dispose();
  // }
}