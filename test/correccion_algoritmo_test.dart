import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado_nuevo.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';

void main() {
  group('🔧 CORRECCIÓN DE ALGORITMO OPTIMIZADO', () {
    
    test('🚨 Detectar y reportar deadlocks', () {
      print('\n🔧 PROPUESTA DE CORRECCIÓN PARA ALGORITMO OPTIMIZADO');
      print('='*60);
      
      // Escenario que causa deadlock: recursos insuficientes
      final pasos = [
        PasoScheduling(id: 'A', nombre: 'Prep A', duracion: 300, tipoCocinero: 'especialista', tipoUtensilio: 'horno', dependencias: []),
        PasoScheduling(id: 'B', nombre: 'Prep B', duracion: 400, tipoCocinero: 'especialista', tipoUtensilio: 'horno', dependencias: []),
        PasoScheduling(id: 'C', nombre: 'Prep C', duracion: 500, tipoCocinero: 'especialista', tipoUtensilio: 'horno', dependencias: []),
        // 3 pasos que requieren el mismo tipo de recursos
      ];
      
      final cocineros = [
        CocineroScheduling(id: 'chef1', nombre: 'Chef Especialista 1', tipo: 'especialista'),
        // Solo 1 cocinero especialista
      ];
      
      final utensilios = [
        UtensilioScheduling(id: 'horno1', nombre: 'Horno 1', tipo: 'horno'),
        // Solo 1 horno
      ];
      
      print('🎯 ESCENARIO DE DEADLOCK POTENCIAL:');
      print('   - 3 pasos requieren: especialista + horno');
      print('   - Solo hay: 1 especialista + 1 horno');
      print('   - Resultado esperado: 3 pasos secuenciales = 1200s');
      
      final algoritmo = SchedulingDinamicoAlgorithmOptimizado();
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      
      try {
        final stopwatch = Stopwatch()..start();
        algoritmo.ejecutarCompleto();
        stopwatch.stop();
        
        final makespan = algoritmo.estadoActual!.tiempoActual;
        final pasosCompletados = algoritmo.estadoActual!.pasosCompletados.length;
        final tiempo = stopwatch.elapsedMilliseconds;
        
        print('\n📊 RESULTADO ACTUAL (SIN CORRECCIÓN):');
        print('   📈 Makespan: ${makespan}s');
        print('   ✅ Pasos completados: $pasosCompletados/3');
        print('   ⏱️ Tiempo: ${tiempo}ms');
        
        if (pasosCompletados < 3) {
          print('   🚨 DEADLOCK DETECTADO: Algoritmo paró sin completar todos los pasos');
          print('   🔧 NECESITA CORRECCIÓN: Validación de completitud obligatoria');
        }
        
        // Este test DEBE fallar hasta que se corrija el algoritmo
        expect(pasosCompletados, equals(3), 
          reason: 'El algoritmo debe completar todos los pasos o lanzar un error explicativo');
        expect(makespan, equals(1200), 
          reason: 'Makespan debe ser 1200s (secuencial con 1 recurso)');
          
      } catch (e) {
        print('\n✅ EXCEPCIÓN CAPTURADA (COMPORTAMIENTO DESEADO):');
        print('   🎯 Error: $e');
        print('   💡 El algoritmo debería lanzar esta excepción cuando detecta deadlock');
        
        // Si lanza excepción explicativa, está bien
        expect(e.toString().contains('deadlock') || e.toString().contains('incompleto'), 
          isTrue, 
          reason: 'Excepción debe explicar el problema de deadlock');
      }
    });

    test('💡 Ejemplo de corrección propuesta', () {
      print('\n💡 CÓDIGO DE CORRECCIÓN PROPUESTO:');
      print('''
// EN SchedulingDinamicoAlgorithmOptimizado.ejecutarCompleto()

List<String> ejecutarCompleto() {
  if (_estadoActual == null) {
    throw StateError('Debe inicializar el algoritmo primero');
  }

  final totalPasos = _estadoActual!.todosPasos.length;
  final stopwatch = Stopwatch()..start();
  const timeoutMs = 30000; // 30 segundos máximo
  
  _log('▶️ Iniciando ejecución completa del scheduling OPTIMIZADO');
  
  int iteraciones = 0;
  int iteracionesSinProgreso = 0;
  const maxIteraciones = 5000;
  const maxSinProgreso = 10;
  
  while (_estadoActual!.hayTrabajoDisponible && iteraciones < maxIteraciones) {
    iteraciones++;
    final pasosCompletadosAntes = _estadoActual!.pasosCompletados.length;
    
    // TIMEOUT PROTECTION
    if (stopwatch.elapsedMilliseconds > timeoutMs) {
      final completados = _estadoActual!.pasosCompletados.length;
      final faltantes = totalPasos - completados;
      throw TimeoutException(
        'TIMEOUT: Algoritmo excedió \${timeoutMs}ms. '
        'Completados: \$completados/\$totalPasos. Faltantes: \$faltantes pasos.'
      );
    }
    
    _asignarRecursosOptimizado();
    
    final proximoEvento = _estadoActual!.proximoEvento;
    if (proximoEvento != null && proximoEvento > _estadoActual!.tiempoActual) {
      _avanzarTiempo(proximoEvento);
    }
    
    _procesarPasosTerminados();
    _actualizarDependenciasOptimizado();
    
    // DEADLOCK DETECTION
    final pasosCompletadosDespues = _estadoActual!.pasosCompletados.length;
    if (pasosCompletadosDespues == pasosCompletadosAntes) {
      iteracionesSinProgreso++;
      if (iteracionesSinProgreso >= maxSinProgreso) {
        final completados = _estadoActual!.pasosCompletados.length;
        final disponibles = _estadoActual!.pasosDisponibles.length;
        final faltantes = totalPasos - completados;
        
        // Analizar por qué no puede continuar
        final razonDeadlock = _analizarDeadlock();
        
        throw DeadlockException(
          'DEADLOCK: Sin progreso por \$maxSinProgreso iteraciones. '
          'Completados: \$completados/\$totalPasos. Disponibles: \$disponibles. '
          'Faltantes: \$faltantes pasos. Razón: \$razonDeadlock'
        );
      }
    } else {
      iteracionesSinProgreso = 0; // Reset counter si hay progreso
    }
    
    if (!_estadoActual!.hayTrabajoDisponible) break;
  }
  
  // COMPLETITUD VALIDATION
  final pasosCompletados = _estadoActual!.pasosCompletados.length;
  if (pasosCompletados < totalPasos) {
    final faltantes = totalPasos - pasosCompletados;
    final pasosFaltantes = _estadoActual!.todosPasos
        .where((p) => !_estadoActual!.pasosCompletados.any((c) => c.id == p.id))
        .map((p) => p.nombre)
        .toList();
    
    throw IncompletenessException(
      'ALGORITMO INCOMPLETO: \$faltantes pasos no completados: \$pasosFaltantes'
    );
  }
  
  _estadoActual!.completado = true;
  final tiempoFinal = stopwatch.elapsedMilliseconds;
  
  _log('🏁 Scheduling OPTIMIZADO completado en \${_estadoActual!.tiempoActual}s');
  _log('📊 Estadísticas: \$pasosCompletados pasos, \$iteraciones iteraciones, \${tiempoFinal}ms');
  
  return _estadoActual!.logEventos;
}

/// Analizar por qué el algoritmo no puede continuar
String _analizarDeadlock() {
  final disponibles = _estadoActual!.pasosDisponibles;
  if (disponibles.isEmpty) {
    return 'No hay pasos disponibles (todas las dependencias pendientes)';
  }
  
  final tiposCocineroRequeridos = disponibles.map((p) => p.tipoCocinero).toSet();
  final tiposUtensilioRequeridos = disponibles.map((p) => p.tipoUtensilio).toSet();
  
  final cocinerosLibres = _estadoActual!.cocineros
      .where((c) => _calcularProximoTiempoDisponible(c) <= _estadoActual!.tiempoActual)
      .map((c) => c.tipo)
      .toSet();
      
  final utensiliosLibres = _estadoActual!.utensilios
      .where((u) => _calcularProximoTiempoDisponible(u) <= _estadoActual!.tiempoActual)
      .map((u) => u.tipo)
      .toSet();
  
  final cocinerosInsuficientes = tiposCocineroRequeridos.difference(cocinerosLibres);
  final utensiliosInsuficientes = tiposUtensilioRequeridos.difference(utensiliosLibres);
  
  if (cocinerosInsuficientes.isNotEmpty) {
    return 'Cocineros insuficientes: faltan tipos \$cocinerosInsuficientes';
  }
  
  if (utensiliosInsuficientes.isNotEmpty) {
    return 'Utensilios insuficientes: faltan tipos \$utensiliosInsuficientes';
  }
  
  return 'Razón de deadlock no identificada - revisar lógica de asignación';
}

// EXCEPCIONES PERSONALIZADAS
class DeadlockException implements Exception {
  final String message;
  DeadlockException(this.message);
  
  @override
  String toString() => 'DeadlockException: \$message';
}

class IncompletenessException implements Exception {
  final String message;
  IncompletenessException(this.message);
  
  @override
  String toString() => 'IncompletenessException: \$message';
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => 'TimeoutException: \$message';
}
''');
      
      print('\n🎯 BENEFICIOS DE ESTA CORRECCIÓN:');
      print('✅ Detecta deadlocks antes de fallar silenciosamente');
      print('✅ Provee información diagnóstica útil');
      print('✅ Protege contra timeouts infinitos');
      print('✅ Valida completitud obligatoriamente');
      print('✅ Excepciones explicativas para debugging');
      
      // Este test siempre pasa - solo muestra la propuesta
      expect(true, isTrue);
    });
  });
}
