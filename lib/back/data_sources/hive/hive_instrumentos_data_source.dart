import 'package:hive_flutter/hive_flutter.dart';
import '../../dataModels/instrumentos.dart';

class HiveInstrumentosDataSource {
  // Lazy-load la caja cuando se necesite
  // Si prefieres abrirla al inicio, ya la tendrías disponible aquí.
  Future<Box<Instrumento>> get _instrumentosBox async =>
      await Hive.openBox<Instrumento>('instrumentos'); // Nombre de la caja

  // Obtener todos los instrumentoses
  Future<List<Instrumento>> getAllInstrumentos() async {
    final box = await _instrumentosBox;
    return box.values.toList();
  }

  // Añadir un nuevo instrumentose
  Future<void> addInstrumento(Instrumento instrumento) async {
    final box = await _instrumentosBox;
    // Hive usa índices o claves para guardar. Usar add() guarda con un índice autoincremental.
    // Puedes usar put(key, value) si quieres usar tus propias claves (ej: UUID)
    await box.add(instrumento);
  }

  // Actualizar un instrumentose (usando su key)
  Future<void> updateInstrumento(dynamic key, Instrumento instrumento) async {
     final box = await _instrumentosBox;
     await box.put(key, instrumento); // key es el índice/clave con el que se guardó
  }

  // Eliminar un instrumentose (usando su key)
  Future<void> deleteInstrumento(dynamic key) async {
    final box = await _instrumentosBox;
    await box.delete(key);
  }

  // Cerrar la caja cuando ya no se necesite (opcional, Flutter cierra al terminar)
  Future<void> closeBox() async {
     final box = await _instrumentosBox;
     await box.close();
  }
}