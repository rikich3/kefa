import 'package:hive_flutter/hive_flutter.dart';

class HivePersistenceManager {
  static const String _testKey = 'persistence_test';
  static final List<String> _knownBoxes = ['ingredientes', 'recetas', 'workers', 'instrumentos', 'pasos'];
  
  /// Verifica si Hive puede persistir datos correctamente
  static Future<bool> testPersistence() async {
    try {
      final testBox = await Hive.openBox('persistence_test');
      
      // Escribir un valor de prueba
      await testBox.put(_testKey, DateTime.now().millisecondsSinceEpoch);
      await testBox.flush();
      
      // Leer el valor inmediatamente
      final value = testBox.get(_testKey);
      
      print('🔬 Test de persistencia: ${value != null ? "✅ EXITOSO" : "❌ FALLÓ"}');
      
      await testBox.close();
      return value != null;
    } catch (e) {
      print('❌ Error en test de persistencia: $e');
      return false;
    }
  }
  
  /// Fuerza el guardado de todas las cajas conocidas
  static Future<void> flushAllBoxes() async {
    try {
      print('💾 Forzando guardado de cajas conocidas: $_knownBoxes');
      
      for (final boxName in _knownBoxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.flush();
            print('   ✅ Caja "$boxName" guardada (${box.length} elementos)');
          } else {
            print('   📦 Caja "$boxName" no está abierta');
          }
        } catch (e) {
          print('   ❌ Error guardando caja "$boxName": $e');
        }
      }
    } catch (e) {
      print('❌ Error forzando guardado: $e');
    }
  }
  
  /// Cierra todas las cajas de forma segura
  static Future<void> closeAllBoxes() async {
    try {
      await flushAllBoxes();
      await Hive.close();
      print('📦 Todas las cajas cerradas correctamente');
    } catch (e) {
      print('❌ Error cerrando cajas: $e');
    }
  }
  
  /// Información de diagnóstico
  static Future<void> printDiagnostics() async {
    print('📊 === DIAGNÓSTICO DE HIVE ===');
    
    for (final boxName in _knownBoxes) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          print('   📋 $boxName: ${box.length} elementos (ABIERTA)');
          if (box.isNotEmpty) {
            print('      Claves: ${box.keys.take(5).toList()}${box.length > 5 ? "..." : ""}');
          }
        } else {
          print('   📦 $boxName: CERRADA');
        }
      } catch (e) {
        print('   ❌ Error accediendo a $boxName: $e');
      }
    }
    print('========================');
  }
}
