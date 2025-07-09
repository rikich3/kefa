import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';
// import 'dart:math'; // Unused

void main() {
  group('🚨 VALIDACIÓN DE RESULTADOS SOSPECHOSOS', () {
    
    test('🔍 CASO SIMPLE: Verificar lógica básica', () {
      print('\n' + '='*60);
      print('🔍 INVESTIGANDO RESULTADOS RÁPIDOS SOSPECHOSOS');
      print('='*60);
      
      // Caso MUY simple donde podemos calcular manualmente
      final pasos = [
        PasoScheduling(id: 'A', nombre: 'Lavar verduras', duracion: 300, tipoCocinero: 'normal', tipoUtensilio: 'lavabo', dependencias: []),
        PasoScheduling(id: 'B', nombre: 'Cortar verduras', duracion: 600, tipoCocinero: 'normal', tipoUtensilio: 'cuchillo', dependencias: ['A']),
        PasoScheduling(id: 'C', nombre: 'Cocinar verduras', duracion: 900, tipoCocinero: 'normal', tipoUtensilio: 'estufa', dependencias: ['B']),
      ];
      
      final cocineros = [
        CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal'),
      ];
      
      final utensilios = [
        UtensilioScheduling(id: 'lavabo1', nombre: 'Lavabo1', tipo: 'lavabo'),
        UtensilioScheduling(id: 'cuchillo1', nombre: 'Cuchillo1', tipo: 'cuchillo'),
        UtensilioScheduling(id: 'estufa1', nombre: 'Estufa1', tipo: 'estufa'),
      ];
      
      print('📊 CASO MANUAL CALCULADO:');
      print('   Step A: 0-300s (Lavar)');
      print('   Step B: 300-900s (Cortar, depende de A)');
      print('   Step C: 900-1800s (Cocinar, depende de B)');
      print('   🎯 RESULTADO ESPERADO: 1800s (30 minutos)');
      
      // Ejecutar algoritmo con debug
      final algoritmo = SchedulingDinamicoAlgorithm();
      algoritmo.setDebugMode(true);
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      
      final stopwatch = Stopwatch()..start();
      final logs = algoritmo.ejecutarCompleto();
      stopwatch.stop();
      
      final makespan = algoritmo.estadoActual!.tiempoActual;
      final tiempo = stopwatch.elapsedMilliseconds;
      
      print('\n📊 RESULTADO DEL ALGORITMO:');
      print('   📈 Makespan: ${makespan}s');
      print('   ⏱️ Tiempo cálculo: ${tiempo}ms');
      print('   📋 Logs generados: ${logs.length}');
      
      // Verificar cronología
      print('\n⏰ CRONOLOGÍA REAL:');
      for (final paso in algoritmo.estadoActual!.pasosCompletados) {
        print('   ${paso.nombre}: T${paso.tiempoInicio} - T${paso.tiempoFin}');
      }
      
      // Verificar si es correcto
      final esCorrectoTiempo = makespan >= 1700 && makespan <= 1900;
      final esCorrectoRapidez = tiempo < 100;
      
      print('\n🎯 VERIFICACIÓN:');
      print('   ✓ Tiempo resultado: ${esCorrectoTiempo ? "✅ CORRECTO" : "❌ INCORRECTO"} ($makespan vs 1800 esperado)');
      print('   ✓ Velocidad cálculo: ${esCorrectoRapidez ? "✅ RÁPIDO" : "❌ LENTO"} (${tiempo}ms)');
      
      expect(makespan, equals(1800), reason: 'Secuencia debe tomar exactamente 1800s');
    });

    test('📊 CASO PARALELO: Verificar paralelización', () {
      print('\n📊 CASO PARALELO...');
      
      // Dos secuencias independientes que pueden ejecutarse en paralelo
      final pasos = [
        // Secuencia 1
        PasoScheduling(id: 'A1', nombre: 'Prep 1A', duracion: 600, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: []),
        PasoScheduling(id: 'A2', nombre: 'Prep 1B', duracion: 600, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: ['A1']),
        
        // Secuencia 2 (independiente)
        PasoScheduling(id: 'B1', nombre: 'Prep 2A', duracion: 600, tipoCocinero: 'normal', tipoUtensilio: 'sarten', dependencias: []),
        PasoScheduling(id: 'B2', nombre: 'Prep 2B', duracion: 600, tipoCocinero: 'normal', tipoUtensilio: 'sarten', dependencias: ['B1']),
      ];
      
      final cocineros = [
        CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal'),
        CocineroScheduling(id: 'chef2', nombre: 'Chef2', tipo: 'normal'),
      ];
      
      final utensilios = [
        UtensilioScheduling(id: 'bowl1', nombre: 'Bowl1', tipo: 'bowl'),
        UtensilioScheduling(id: 'sarten1', nombre: 'Sarten1', tipo: 'sarten'),
      ];
      
      print('🎯 EXPECTATIVA: 2 cocineros trabajando en paralelo');
      print('   Secuencia 1: Chef1+Bowl (0-600s, 600-1200s)');
      print('   Secuencia 2: Chef2+Sarten (0-600s, 600-1200s)');
      print('   🎯 RESULTADO ESPERADO: 1200s (paralelo perfecto)');
      
      final algoritmo = SchedulingDinamicoAlgorithm();
      algoritmo.setDebugMode(false);
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      algoritmo.ejecutarCompleto();
      
      final makespan = algoritmo.estadoActual!.tiempoActual;
      
      print('📊 RESULTADO: ${makespan}s');
      
      // Verificar utilización de cocineros
      var chef1Tiempo = 0;
      var chef2Tiempo = 0;
      
      for (final cocinero in algoritmo.estadoActual!.cocineros) {
        final tiempoTrabajo = cocinero.horario.fold(0, (sum, item) => sum + item.duracion);
        if (cocinero.id == 'chef1') chef1Tiempo = tiempoTrabajo;
        if (cocinero.id == 'chef2') chef2Tiempo = tiempoTrabajo;
        print('${cocinero.nombre}: ${tiempoTrabajo}s de trabajo');
      }
      
      final esParaleloEficiente = makespan <= 1300; // Tolerancia
      final esBalanceado = (chef1Tiempo - chef2Tiempo).abs() <= 200;
      
      print('🎯 VERIFICACIÓN PARALELIZACIÓN:');
      print('   ✓ Eficiencia paralela: ${esParaleloEficiente ? "✅ SÍ" : "❌ NO"} (${makespan}s vs 1200s ideal)');
      print('   ✓ Balance trabajo: ${esBalanceado ? "✅ SÍ" : "❌ NO"} (diff: ${(chef1Tiempo - chef2Tiempo).abs()}s)');
      
      expect(makespan, lessThanOrEqualTo(1300), reason: 'Debería paralelizar eficientemente');
    });

    test('🚨 ESTRÉS: Muchos pasos con pocos recursos', () {
      print('\n🚨 PRUEBA DE ESTRÉS...');
      
      // Generar muchos pasos simples
      final pasos = <PasoScheduling>[];
      for (int i = 0; i < 100; i++) {
        pasos.add(PasoScheduling(
          id: 'paso$i',
          nombre: 'Paso $i',
          duracion: 60, // 1 minuto cada uno
          tipoCocinero: 'normal',
          tipoUtensilio: 'bowl',
          dependencias: [],
        ));
      }
      
      // Solo 1 cocinero y 1 utensilio (cuello de botella extremo)
      final cocineros = [
        CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal'),
      ];
      
      final utensilios = [
        UtensilioScheduling(id: 'bowl1', nombre: 'Bowl1', tipo: 'bowl'),
      ];
      
      print('🎯 EXPECTATIVA: 100 pasos × 60s = 6000s mínimo (secuencial)');
      
      final algoritmo = SchedulingDinamicoAlgorithm();
      algoritmo.setDebugMode(false);
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      
      final stopwatch = Stopwatch()..start();
      algoritmo.ejecutarCompleto();
      stopwatch.stop();
      
      final makespan = algoritmo.estadoActual!.tiempoActual;
      final tiempo = stopwatch.elapsedMilliseconds;
      
      print('📊 RESULTADO ESTRÉS:');
      print('   📈 Makespan: ${makespan}s (${(makespan/60).toStringAsFixed(1)} min)');
      print('   ⏱️ Tiempo cálculo: ${tiempo}ms');
      print('   🎯 ¿Es mínimo teórico? ${makespan >= 6000 ? "✅ SÍ" : "❌ NO"}');
      
      // Verificar que realmente se ejecutaron todos los pasos
      final pasosCompletados = algoritmo.estadoActual!.pasosCompletados.length;
      print('   ✓ Pasos completados: $pasosCompletados/100');
      
      expect(makespan, greaterThanOrEqualTo(6000), reason: 'No puede ser menor que el mínimo teórico');
      expect(pasosCompletados, equals(100), reason: 'Deben completarse todos los pasos');
      expect(tiempo, lessThan(5000), reason: 'Aún debe ser rápido de calcular');
    });

    test('🎯 DEPENDENCIAS COMPLEJAS: Verificar lógica', () {
      print('\n🎯 DEPENDENCIAS COMPLEJAS...');
      
      // Red de dependencias tipo "diamond"
      final pasos = [
        PasoScheduling(id: 'A', nombre: 'Base', duracion: 100, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: []),
        PasoScheduling(id: 'B', nombre: 'Rama 1', duracion: 200, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: ['A']),
        PasoScheduling(id: 'C', nombre: 'Rama 2', duracion: 300, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: ['A']),
        PasoScheduling(id: 'D', nombre: 'Convergencia', duracion: 150, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: ['B', 'C']),
      ];
      
      final cocineros = [CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal')];
      final utensilios = [UtensilioScheduling(id: 'bowl1', nombre: 'Bowl1', tipo: 'bowl')];
      
      print('🎯 EXPECTATIVA: A(0-100) → C(100-400) → B(400-600) → D(600-750)');
      print('   Makespan esperado: 750s (secuencial con 1 chef)');
      
      final algoritmo = SchedulingDinamicoAlgorithm();
      algoritmo.setDebugMode(true);
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      algoritmo.ejecutarCompleto();
      
      final makespan = algoritmo.estadoActual!.tiempoActual;
      
      print('\\n📊 RESULTADO: ${makespan}s');
      
      // Verificar orden de ejecución
      final pasosOrdenados = algoritmo.estadoActual!.pasosCompletados.toList()
        ..sort((a, b) => (a.tiempoInicio ?? 0).compareTo(b.tiempoInicio ?? 0));
      
      print('⏰ ORDEN DE EJECUCIÓN:');
      for (final paso in pasosOrdenados) {
        print('   ${paso.nombre}: T${paso.tiempoInicio} - T${paso.tiempoFin}');
      }
      
      expect(makespan, equals(750), reason: 'Dependencias diamond con 1 recurso deben ejecutarse secuencialmente');
    });
  });
}
