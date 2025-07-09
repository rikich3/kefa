import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado_nuevo.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_ultra_optimizado.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';
import 'dart:math';

void main() {
  group('🔬 VALIDACIÓN AVANZADA: ¿Algoritmos realmente óptimos?', () {
    
    test('🚨 CASO 1: Un solo recurso, secuencia forzada', () {
      print('\n' + '='*70);
      print('🚨 INVESTIGACIÓN: ¿Los resultados rápidos son REALES o FALSOS?');
      print('='*70);
      
      // CASO IMPOSIBLE DE OPTIMIZAR: Una sola estufa, secuencia obligatoria
      final pasos = [
        PasoScheduling(id: 'A', nombre: 'Calentar agua', duracion: 300, tipoCocinero: 'normal', tipoUtensilio: 'estufa', dependencias: []),
        PasoScheduling(id: 'B', nombre: 'Hervir pasta', duracion: 600, tipoCocinero: 'normal', tipoUtensilio: 'estufa', dependencias: ['A']),
        PasoScheduling(id: 'C', nombre: 'Escurrir pasta', duracion: 180, tipoCocinero: 'normal', tipoUtensilio: 'estufa', dependencias: ['B']),
        PasoScheduling(id: 'D', nombre: 'Preparar salsa', duracion: 400, tipoCocinero: 'normal', tipoUtensilio: 'estufa', dependencias: ['C']),
      ];
      
      final cocineros = [
        CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal'),
        CocineroScheduling(id: 'chef2', nombre: 'Chef2', tipo: 'normal'), // Extra, pero no útil
      ];
      
      final utensilios = [
        UtensilioScheduling(id: 'estufa1', nombre: 'Estufa1', tipo: 'estufa'), // ÚNICO
      ];
      
      print('🎯 RESULTADO TEÓRICO ÓPTIMO:');
      print('   A: 0-300s (estufa)');
      print('   B: 300-900s (estufa, depende A)');
      print('   C: 900-1080s (estufa, depende B)');
      print('   D: 1080-1480s (estufa, depende C)');
      print('   📊 MAKESPAN ÓPTIMO: 1480s');
      print('   ⚠️ Imposible mejorar: solo 1 estufa + dependencias secuenciales');
      
      // Probar todos los algoritmos
      final algoritmos = [
        ('Original', SchedulingDinamicoAlgorithm() as dynamic),
        ('Optimizado', SchedulingDinamicoAlgorithmOptimizado() as dynamic),
        ('Ultra-Optimizado', SchedulingDinamicoAlgorithmUltraOptimizado() as dynamic),
      ];
      
      for (final (nombre, algoritmo) in algoritmos) {
        print('\n🧪 Probando algoritmo: $nombre');
        
        // Resetear para cada algoritmo
        for (var c in cocineros) { c.horario.clear(); c.ori = 0; }
        for (var u in utensilios) { u.horario.clear(); }
        
        algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
        
        final stopwatch = Stopwatch()..start();
        final logs = algoritmo.ejecutarCompleto();
        stopwatch.stop();
        
        final makespan = algoritmo.estadoActual!.tiempoActual;
        final tiempo = stopwatch.elapsedMilliseconds;
        
        print('   📈 Makespan: ${makespan}s');
        print('   ⏱️ Tiempo: ${tiempo}ms');
        
        // VALIDACIÓN CRÍTICA
        final esCorrecto = makespan == 1480;
        final esSospechoso = makespan < 1480 || tiempo > 100;
        
        print('   🔍 Validación: ${esCorrecto ? "✅ CORRECTO" : "❌ INCORRECTO (Makespan=$makespan)"}');
        
        if (!esCorrecto) {
          print('   🚨 ERROR: Resultado imposible de mejorar, pero algoritmo dio $makespan vs 1480 esperado');
          print('   📋 Cronología real:');
          for (final paso in algoritmo.estadoActual!.pasosCompletados) {
            print('     ${paso.nombre}: T${paso.tiempoInicio} - T${paso.tiempoFin}');
          }
        }
        
        expect(makespan, equals(1480), reason: '$nombre debe dar makespan óptimo de 1480s');
      }
    });

    test('🔬 CASO 2: Dependencias tipo "Diamond" - Validación de camino crítico', () {
      print('\n🔬 CASO DIAMOND...');
      
      // Patrón Diamond: A -> {B,C} -> D
      // B y C pueden ejecutarse en paralelo, pero D depende de ambos
      final pasos = [
        PasoScheduling(id: 'A', nombre: 'Preparar base', duracion: 300, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: []),
        PasoScheduling(id: 'B', nombre: 'Cocinar proteína', duracion: 900, tipoCocinero: 'normal', tipoUtensilio: 'sarten', dependencias: ['A']),
        PasoScheduling(id: 'C', nombre: 'Preparar vegetales', duracion: 600, tipoCocinero: 'normal', tipoUtensilio: 'wok', dependencias: ['A']),
        PasoScheduling(id: 'D', nombre: 'Mezclar todo', duracion: 200, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: ['B', 'C']),
      ];
      
      final cocineros = [
        CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal'),
        CocineroScheduling(id: 'chef2', nombre: 'Chef2', tipo: 'normal'),
        CocineroScheduling(id: 'chef3', nombre: 'Chef3', tipo: 'normal'),
      ];
      
      final utensilios = [
        UtensilioScheduling(id: 'bowl1', nombre: 'Bowl1', tipo: 'bowl'),
        UtensilioScheduling(id: 'sarten1', nombre: 'Sarten1', tipo: 'sarten'),
        UtensilioScheduling(id: 'wok1', nombre: 'Wok1', tipo: 'wok'),
      ];
      
      print('🎯 CRONOLOGÍA ÓPTIMA:');
      print('   A: 0-300s (cualquier chef + bowl)');
      print('   B: 300-1200s (chef1 + sarten) - CAMINO CRÍTICO');
      print('   C: 300-900s (chef2 + wok)');
      print('   D: 1200-1400s (chef3 + bowl, espera que termine B)');
      print('   📊 MAKESPAN ÓPTIMO: 1400s');
      
      final algoritmos = [
        ('Original', SchedulingDinamicoAlgorithm() as dynamic),
        ('Optimizado', SchedulingDinamicoAlgorithmOptimizado() as dynamic),
        ('Ultra-Optimizado', SchedulingDinamicoAlgorithmUltraOptimizado() as dynamic),
      ];
      
      for (final (nombre, algoritmo) in algoritmos) {
        print('\n🧪 Probando $nombre...');
        
        // Resetear recursos
        for (var c in cocineros) { c.horario.clear(); c.ori = 0; }
        for (var u in utensilios) { u.horario.clear(); }
        
        algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
        
        final stopwatch = Stopwatch()..start();
        algoritmo.ejecutarCompleto();
        stopwatch.stop();
        
        final makespan = algoritmo.estadoActual!.tiempoActual;
        final tiempo = stopwatch.elapsedMilliseconds;
        
        print('   📈 Makespan: ${makespan}s (esperado: 1400s)');
        print('   ⏱️ Tiempo: ${tiempo}ms');
        
        // Verificar paralelización de B y C
        final pasoB = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'B');
        final pasoC = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'C');
        final pasoD = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'D');
        
        final bYcEnParalelo = pasoB.tiempoInicio == pasoC.tiempoInicio;
        final dEsperaB = pasoD.tiempoInicio >= pasoB.tiempoFin;
        
        print('   🔍 B y C en paralelo: ${bYcEnParalelo ? "✅" : "❌"}');
        print('   🔍 D espera a B: ${dEsperaB ? "✅" : "❌"}');
        
        if (makespan > 1400) {
          print('   ⚠️ Makespan subóptimo detectado');
        }
        
        expect(makespan, lessThanOrEqualTo(1400), reason: '$nombre no debe exceder makespan óptimo');
        expect(bYcEnParalelo, isTrue, reason: 'B y C deben ejecutarse en paralelo');
        expect(dEsperaB, isTrue, reason: 'D debe esperar a que termine B');
      }
    });

    test('⚡ CASO 3: Escenario de estrés simple - ¿Sub-segundo es realista?', () {
      print('\n⚡ ESCENARIO DE ESTRÉS...');
      
      // Generar un escenario de mediana complejidad pero calculable
      final random = Random(42); // Seed fijo para reproducibilidad
      final pasos = <PasoScheduling>[];
      
      // 50 pasos con dependencias realistas
      for (int i = 0; i < 50; i++) {
        final dependencias = <String>[];
        
        // Algunos pasos dependen de anteriores (cadena realista)
        if (i > 0 && random.nextDouble() < 0.4) {
          final numDep = min(3, i);
          for (int j = 0; j < numDep; j++) {
            final depIndex = random.nextInt(i);
            dependencias.add('paso_$depIndex');
          }
        }
        
        pasos.add(PasoScheduling(
          id: 'paso_$i',
          nombre: 'Paso $i',
          duracion: 100 + random.nextInt(500), // 100-600s
          tipoCocinero: ['normal', 'especialista'][random.nextInt(2)],
          tipoUtensilio: ['bowl', 'sarten', 'cuchillo', 'estufa'][random.nextInt(4)],
          dependencias: dependencias,
        ));
      }
      
      final cocineros = List.generate(8, (i) => CocineroScheduling(
        id: 'chef_$i',
        nombre: 'Chef $i',
        tipo: i < 4 ? 'normal' : 'especialista',
      ));
      
      final utensilios = [
        ...List.generate(5, (i) => UtensilioScheduling(id: 'bowl_$i', nombre: 'Bowl $i', tipo: 'bowl')),
        ...List.generate(3, (i) => UtensilioScheduling(id: 'sarten_$i', nombre: 'Sarten $i', tipo: 'sarten')),
        ...List.generate(4, (i) => UtensilioScheduling(id: 'cuchillo_$i', nombre: 'Cuchillo $i', tipo: 'cuchillo')),
        ...List.generate(2, (i) => UtensilioScheduling(id: 'estufa_$i', nombre: 'Estufa $i', tipo: 'estufa')),
      ];
      
      print('📊 ESCENARIO: 50 pasos, 8 cocineros, 14 utensilios');
      print('   Dependencias promedio por paso: ${pasos.map((p) => p.dependencias.length).reduce((a, b) => a + b) / pasos.length}');
      print('   🤔 ¿Puede calcularse realmente en sub-segundo?');
      
      final algoritmos = [
        ('Optimizado', SchedulingDinamicoAlgorithmOptimizado() as dynamic),
        ('Ultra-Optimizado', SchedulingDinamicoAlgorithmUltraOptimizado() as dynamic),
      ];
      
      for (final (nombre, algoritmo) in algoritmos) {
        print('\n🧪 Probando $nombre...');
        
        // Resetear recursos
        for (var c in cocineros) { c.horario.clear(); c.ori = 0; }
        for (var u in utensilios) { u.horario.clear(); }
        
        algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
        
        final stopwatch = Stopwatch()..start();
        algoritmo.ejecutarCompleto();
        stopwatch.stop();
        
        final makespan = algoritmo.estadoActual!.tiempoActual;
        final tiempo = stopwatch.elapsedMilliseconds;
        final pasosCompletados = algoritmo.estadoActual!.pasosCompletados.length;
        
        print('   📈 Makespan: ${makespan}s');
        print('   ⏱️ Tiempo cálculo: ${tiempo}ms');
        print('   ✅ Pasos completados: $pasosCompletados/50');
        
        // VALIDACIONES DE CORDURA
        final tiempoRazonable = tiempo < 1000; // < 1 segundo
        final todosCompletados = pasosCompletados == 50;
        final makespanRazonable = makespan > 500 && makespan < 10000; // Entre 8min y 2.7h
        
        print('   🔍 Tiempo razonable: ${tiempoRazonable ? "✅" : "❌"} (${tiempo}ms)');
        print('   🔍 Todos completados: ${todosCompletados ? "✅" : "❌"}');
        print('   🔍 Makespan razonable: ${makespanRazonable ? "✅" : "❌"} (${makespan}s)');
        
        // Verificar que no hay solapamientos de recursos
        final errorRecursos = _verificarUsoRecursos(algoritmo.estadoActual!);
        print('   🔍 Uso recursos válido: ${errorRecursos == null ? "✅" : "❌ $errorRecursos"}');
        
        expect(todosCompletados, isTrue, reason: 'Todos los pasos deben completarse');
        expect(errorRecursos, isNull, reason: 'No debe haber conflictos de recursos');
        expect(makespanRazonable, isTrue, reason: 'Makespan debe estar en rango razonable');
      }
    });
  });
}

/// Verificar que no hay solapamientos de recursos
String? _verificarUsoRecursos(estado) {
  // Verificar cocineros
  for (final cocinero in estado.cocineros) {
    for (int i = 0; i < cocinero.horario.length - 1; i++) {
      final actual = cocinero.horario[i];
      final siguiente = cocinero.horario[i + 1];
      final actualFin = actual.tiempoInicio + actual.duracion;
      if (actualFin > siguiente.tiempoInicio) {
        return 'Cocinero ${cocinero.nombre}: solapamiento entre ${actual.tiempoInicio}-$actualFin y ${siguiente.tiempoInicio}-${siguiente.tiempoInicio + siguiente.duracion}';
      }
    }
  }
  
  // Verificar utensilios
  for (final utensilio in estado.utensilios) {
    for (int i = 0; i < utensilio.horario.length - 1; i++) {
      final actual = utensilio.horario[i];
      final siguiente = utensilio.horario[i + 1];
      final actualFin = actual.tiempoInicio + actual.duracion;
      if (actualFin > siguiente.tiempoInicio) {
        return 'Utensilio ${utensilio.nombre}: solapamiento entre ${actual.tiempoInicio}-$actualFin y ${siguiente.tiempoInicio}-${siguiente.tiempoInicio + siguiente.duracion}';
      }
    }
  }
  
  return null; // Todo bien
}
