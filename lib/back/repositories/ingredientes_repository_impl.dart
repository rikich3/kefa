import 'ingredientes_repository.dart'; // La interface
import '../data_sources/hive/hive_ingredientes_data_source.dart'; // La fuente de datos Hive
import '../dataModels/ingredientes.dart'; // El modelo

class IngredientesRepositoryImpl implements IngredientesRepository {
  final HiveIngredientesDataSource hiveDataSource; // Dependencia a la fuente de datos Hive

  // Constructor que recibe la fuente de datos
  IngredientesRepositoryImpl({required this.hiveDataSource});

  @override
  Future<List<MapEntry<dynamic, Ingredientes>>> getAllIngredientes() {
    // Llama al método correspondiente en la fuente de datos Hive
    return hiveDataSource.getAllIngredientes();
  }

  @override
  Future<void> addIngrediente(Ingredientes ingredient) {
    // Por ahora, solo usamos Hive. Si tuvieras Firestore también, aquí decidirías dónde guardar.
    return hiveDataSource.addIngredientes(ingredient);
  }

  @override
  Future<void> updateIngrediente(dynamic key, Ingredientes ingredient) {
    return hiveDataSource.updateIngrediente(key, ingredient);
  }

  @override
  Future<void> deleteIngrediente(dynamic key) {
    return hiveDataSource.deleteIngrediente(key);
  }

  // Si implementas watchAllIngredients con Streams, la lógica iría aquí
  // @override
  // Stream<List<Ingredient>> watchAllIngredients() {
  //   // Lógica para emitir actualizaciones, tal vez usando Hive.watchBox()
  //   // Esto es más avanzado y opcional con Hive, más común con Firestore.
  // }
}