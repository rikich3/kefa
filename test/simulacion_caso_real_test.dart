import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_ultra_optimizado.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';
import 'dart:math';

void main() {
  group('🍽️ SIMULACIÓN CASO REAL ESPECÍFICO', () {
    
    test('📊 TU ESCENARIO EXACTO: 5 cocineros, 175 recetas, 1000+ pasos', () {
      print('\n' + '='*70);
      print('🍽️ SIMULACIÓN DE TU CASO REAL ESPECÍFICO');
      print('='*70);
      
      final escenario = _generarEscenarioEspecifico();
      
      print('📊 ESCENARIO GENERADO:');
      print('   👨‍🍳 Cocineros: ${escenario.cocineros.length}');
      print('   📝 Recetas totales: ${escenario.numRecetas}');
      print('   🔧 Pasos totales: ${escenario.pasos.length}');
      print('   🍴 Utensilios totales: ${escenario.utensilios.length}');
      print('   🔗 Dependencias totales: ${escenario.pasos.fold(0, (sum, p) => sum + p.dependencias.length)}');
      
      _mostrarDistribucionRecetas(escenario);
      _mostrarDistribucionUtensilios(escenario);
      
      // MEDIR ALGORITMO DINÁMICO ESTÁNDAR
      print('\n⏱️ MIDIENDO ALGORITMO DINÁMICO ESTÁNDAR...');
      final tiemposDinamico = _medirRendimiento(() {
        final algoritmo = SchedulingDinamicoAlgorithm();
        algoritmo.setDebugMode(false);
        algoritmo.inicializar(
          pasos: List.from(escenario.pasos),
          cocineros: List.from(escenario.cocineros),
          utensilios: List.from(escenario.utensilios),
        );
        algoritmo.ejecutarCompleto();
        return algoritmo.estadoActual!.tiempoActual;
      });
      
      // MEDIR ALGORITMO OPTIMIZADO
      print('\n🚀 MIDIENDO ALGORITMO OPTIMIZADO...');
      final tiemposOptimizado = _medirRendimiento(() {
        final algoritmo = SchedulingDinamicoAlgorithmOptimizado();
        algoritmo.setDebugMode(false);
        algoritmo.inicializar(
          pasos: List.from(escenario.pasos),
          cocineros: List.from(escenario.cocineros),
          utensilios: List.from(escenario.utensilios),
        );
        algoritmo.ejecutarCompleto();
        return algoritmo.estadoActual!.tiempoActual;
      });
      
      // ANÁLISIS DETALLADO
      print('\n📊 RESULTADOS COMPARATIVOS DETALLADOS:');
      print('='*60);
      print('⚙️  ALGORITMO DINÁMICO ESTÁNDAR:');
      print('   📈 Makespan: ${tiemposDinamico.makespan}s (${(tiemposDinamico.makespan/3600).toStringAsFixed(1)}h)');
      print('   ⏱️ Tiempo cálculo: ${tiemposDinamico.tiempoCalculo}ms');
      print('   💻 Rendimiento: ${_evaluarRendimiento(tiemposDinamico.tiempoCalculo)}');
      
      print('\n🚀 ALGORITMO OPTIMIZADO:');
      print('   📈 Makespan: ${tiemposOptimizado.makespan}s (${(tiemposOptimizado.makespan/3600).toStringAsFixed(1)}h)');
      print('   ⏱️ Tiempo cálculo: ${tiemposOptimizado.tiempoCalculo}ms');
      print('   💻 Rendimiento: ${_evaluarRendimiento(tiemposOptimizado.tiempoCalculo)}');
      
      final mejoraMakespan = tiemposDinamico.makespan - tiemposOptimizado.makespan;
      final factorVelocidad = tiemposDinamico.tiempoCalculo / tiemposOptimizado.tiempoCalculo;
      final porcentajeMejora = (mejoraMakespan / tiemposDinamico.makespan * 100).toStringAsFixed(1);
      
      print('\n🎯 ANÁLISIS DE MEJORA:');
      print('   📈 Reducción makespan: ${mejoraMakespan}s (${porcentajeMejora}%)');
      print('   ⚡ Factor velocidad: ${factorVelocidad.toStringAsFixed(2)}x');
      print('   🏆 Veredicto: ${_evaluarMejora(mejoraMakespan, factorVelocidad)}');
      
      // ANÁLISIS DE ESCALABILIDAD
      print('\n📐 ANÁLISIS DE COMPLEJIDAD:');
      final n = escenario.pasos.length;
      final m = escenario.cocineros.length + escenario.utensilios.length;
      print('   📝 Pasos (n): $n');
      print('   🔧 Recursos (m): $m');
      print('   📊 Complejidad teórica O(n²): ${n * n}');
      print('   ⏱️ Tiempo real observado: ${tiemposOptimizado.tiempoCalculo}ms');
      print('   📈 Eficiencia: ${_calcularEficiencia(n, tiemposOptimizado.tiempoCalculo)}');
      
      // VERIFICACIONES
      expect(tiemposOptimizado.tiempoCalculo, lessThan(10000), 
        reason: 'Debe ejecutarse en menos de 10 segundos');
      expect(tiemposOptimizado.makespan, lessThanOrEqualTo(tiemposDinamico.makespan), 
        reason: 'El algoritmo optimizado debe ser igual o mejor');
        
      print('\n🎪 CONCLUSIÓN PARA TU CASO ESPECÍFICO:');
      if (tiemposOptimizado.tiempoCalculo < 5000) {
        print('✅ EXCELENTE: Totalmente viable para uso en producción');
      } else if (tiemposOptimizado.tiempoCalculo < 15000) {
        print('✅ BUENO: Aceptable para planificación offline');
      } else {
        print('⚠️ LENTO: Requiere optimizaciones adicionales');
      }
    });

    test('🔍 ANÁLISIS DE CUELLOS DE BOTELLA', () {
      print('\n🔍 IDENTIFICANDO CUELLOS DE BOTELLA...');
      
      final escenario = _generarEscenarioEspecifico();
      
      // Analizar distribución de tipos de recursos
      final distribucionCocineros = <String, int>{};
      final distribucionUtensilios = <String, int>{};
      
      for (final paso in escenario.pasos) {
        distribucionCocineros[paso.tipoCocinero] = 
          (distribucionCocineros[paso.tipoCocinero] ?? 0) + 1;
        distribucionUtensilios[paso.tipoUtensilio] = 
          (distribucionUtensilios[paso.tipoUtensilio] ?? 0) + 1;
      }
      
      print('\n📊 ANÁLISIS DE DEMANDA VS OFERTA:');
      print('\n👨‍🍳 COCINEROS:');
      for (final entry in distribucionCocineros.entries) {
        final disponibles = escenario.cocineros.where((c) => c.tipo == entry.key).length;
        final demanda = entry.value;
        final ratio = demanda / disponibles;
        print('   ${entry.key}: ${disponibles} disponibles, ${demanda} demanda, ratio ${ratio.toStringAsFixed(1)}');
      }
      
      print('\n🔧 UTENSILIOS:');
      for (final entry in distribucionUtensilios.entries) {
        final disponibles = escenario.utensilios.where((u) => u.tipo == entry.key).length;
        final demanda = entry.value;
        final ratio = demanda / disponibles;
        final criticidad = ratio > 10 ? '🔴 CRÍTICO' : ratio > 5 ? '🟡 ALTO' : '🟢 OK';
        print('   ${entry.key}: ${disponibles} disponibles, ${demanda} demanda, ratio ${ratio.toStringAsFixed(1)} $criticidad');
      }
    });
    
    test('🚀 COMPARACIÓN TRIPLE: DINÁMICO vs OPTIMIZADO vs ULTRA-OPTIMIZADO', () {
      print('\n' + '='*70);
      print('🚀 COMPARACIÓN TRIPLE DE ALGORITMOS');
      print('='*70);
      
      final escenario = _generarEscenarioEspecifico();
      
      print('📊 ESCENARIO: ${escenario.pasos.length} pasos, ${escenario.cocineros.length} cocineros');
      
      // 1. ALGORITMO DINÁMICO ESTÁNDAR
      print('\n⚙️ ALGORITMO DINÁMICO ESTÁNDAR...');
      final tiemposDinamico = _medirRendimiento(() {
        final algoritmo = SchedulingDinamicoAlgorithm();
        algoritmo.setDebugMode(false);
        algoritmo.inicializar(
          pasos: List.from(escenario.pasos),
          cocineros: List.from(escenario.cocineros),
          utensilios: List.from(escenario.utensilios),
        );
        algoritmo.ejecutarCompleto();
        return algoritmo.estadoActual!.tiempoActual;
      });
      
      // 2. ALGORITMO OPTIMIZADO O(n²)
      print('\n🚀 ALGORITMO OPTIMIZADO O(n²)...');
      final tiemposOptimizado = _medirRendimiento(() {
        final algoritmo = SchedulingDinamicoAlgorithmOptimizado();
        algoritmo.setDebugMode(false);
        algoritmo.inicializar(
          pasos: List.from(escenario.pasos),
          cocineros: List.from(escenario.cocineros),
          utensilios: List.from(escenario.utensilios),
        );
        algoritmo.ejecutarCompleto();
        return algoritmo.estadoActual!.tiempoActual;
      });
      
      // 3. ALGORITMO ULTRA-OPTIMIZADO O(n log n)
      print('\n⚡ ALGORITMO ULTRA-OPTIMIZADO O(n log n)...');
      final tiemposUltra = _medirRendimiento(() {
        final algoritmo = SchedulingDinamicoAlgorithmUltraOptimizado();
        algoritmo.setDebugMode(false);
        algoritmo.inicializar(
          pasos: List.from(escenario.pasos),
          cocineros: List.from(escenario.cocineros),
          utensilios: List.from(escenario.utensilios),
        );
        algoritmo.ejecutarCompleto();
        return algoritmo.estadoActual!.tiempoActual;
      });
      
      // TABLA COMPARATIVA
      print('\n📊 TABLA COMPARATIVA COMPLETA:');
      print('='*80);
      print('Algoritmo                | Makespan    | Tiempo Cálc | Rendimiento | Complejidad');
      print('-'*80);
      print('Dinámico Estándar       | ${tiemposDinamico.makespan.toString().padLeft(8)}s  | ${tiemposDinamico.tiempoCalculo.toString().padLeft(8)}ms | ${_evaluarRendimiento(tiemposDinamico.tiempoCalculo).padRight(11)} | O(n²)');
      print('Optimizado Crítico      | ${tiemposOptimizado.makespan.toString().padLeft(8)}s  | ${tiemposOptimizado.tiempoCalculo.toString().padLeft(8)}ms | ${_evaluarRendimiento(tiemposOptimizado.tiempoCalculo).padRight(11)} | O(n²)');
      print('Ultra-Optimizado        | ${tiemposUltra.makespan.toString().padLeft(8)}s  | ${tiemposUltra.tiempoCalculo.toString().padLeft(8)}ms | ${_evaluarRendimiento(tiemposUltra.tiempoCalculo).padRight(11)} | O(n log n)');
      
      // ANÁLISIS DE MEJORAS
      final mejoraDinamicoVsOptimizado = ((tiemposDinamico.makespan - tiemposOptimizado.makespan) / tiemposDinamico.makespan * 100);
      final mejoraDinamicoVsUltra = ((tiemposDinamico.makespan - tiemposUltra.makespan) / tiemposDinamico.makespan * 100);
      final mejoraOptimizadoVsUltra = ((tiemposOptimizado.makespan - tiemposUltra.makespan) / tiemposOptimizado.makespan * 100);
      
      final speedupOptimizado = tiemposDinamico.tiempoCalculo / tiemposOptimizado.tiempoCalculo;
      final speedupUltra = tiemposDinamico.tiempoCalculo / tiemposUltra.tiempoCalculo;
      final speedupUltraVsOpt = tiemposOptimizado.tiempoCalculo / tiemposUltra.tiempoCalculo;
      
      print('\n🎯 ANÁLISIS DE MEJORA
