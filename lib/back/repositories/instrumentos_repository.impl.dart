import 'instrumentos_repository.dart'; // La interface
import '../data_sources/hive/hive_instrumentos_data_source.dart'; // La fuente de datos Hive
import '../dataModels/instrumentos.dart'; // El modelo

class InstrumentosRepositoryImpl implements InstrumentosRepository {
  final HiveInstrumentosDataSource hiveDataSource; // Dependencia a la fuente de datos Hive

  // Constructor que recibe la fuente de datos
  InstrumentosRepositoryImpl({required this.hiveDataSource});

  @override
  Future<List<Instrumento>> getAllInstrumentos() {
    // Llama al método correspondiente en la fuente de datos Hive
    return hiveDataSource.getAllInstrumentos();
  }

  @override
  Future<void> addInstrumento(Instrumento instrumento) {
    // Por ahora, solo usamos Hive. Si tuvieras Firestore también, aquí decidirías dónde guardar.
    return hiveDataSource.addInstrumento(instrumento);
  }

  @override
  Future<void> updateInstrumento(dynamic key, Instrumento instrumento) {
    return hiveDataSource.updateInstrumento(key,instrumento);
  }

  @override
  Future<void> deleteInstrumento(dynamic key) {
    return hiveDataSource.deleteInstrumento(key);
  }

  // Si implementas watchAllIngredients con Streams, la lógica iría aquí
  // @override
  // Stream<List<Ingredient>> watchAllIngredients() {
  //   // Lógica para emitir actualizaciones, tal vez usando Hive.watchBox()
  //   // Esto es más avanzado y opcional con Hive, más común con Firestore.
  // }
}