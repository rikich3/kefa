import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';
import 'dart:math';

void main() {
  group('🔍 ANÁLISIS DE VALIDEZ DE RESULTADOS', () {
    
    test('🚨 VERIFICAR SI LOS RESULTADOS SON REALMENTE ÓPTIMOS', () {
      print('\n' + '='*70);
      print('🚨 INVESTIGACIÓN: ¿SON VÁLIDOS LOS RESULTADOS RÁPIDOS?');
      print('='*70);
      
      // Caso simple conocido para verificar
      final casoSimple = _generarCasoConocido();
      print('📊 CASO SIMPLE CONOCIDO (resultado esperado manual):');
      print('   📝 Pasos: ${casoSimple.pasos.length}');
      print('   👨‍🍳 Cocineros: ${casoSimple.cocineros.length}');
      print('   🔧 Utensilios: ${casoSimple.utensilios.length}');
      print('   🎯 Makespan esperado manualmente: ~480s');
      
      // Ejecutar algoritmo
      final algoritmo = SchedulingDinamicoAlgorithm();
      algoritmo.setDebugMode(true); // ACTIVAR DEBUG PARA VER QUÉ PASA
      algoritmo.inicializar(
        pasos: casoSimple.pasos,
        cocineros: casoSimple.cocineros,
        utensilios: casoSimple.utensilios,
      );
      
      final stopwatch = Stopwatch()..start();
      algoritmo.ejecutarCompleto();
      stopwatch.stop();
      
      final makespan = algoritmo.estadoActual!.tiempoActual;
      final tiempo = stopwatch.elapsedMilliseconds;
      
      print('\n📊 RESULTADO DEL ALGORITMO:');
      print('   📈 Makespan obtenido: ${makespan}s');
      print('   ⏱️ Tiempo de cálculo: ${tiempo}ms');
      print('   🎯 ¿Es razonable? ${makespan >= 400 && makespan <= 600 ? "✅ SÍ" : "❌ NO"}');
      
      // Analizar utilización de recursos
      _analizarUtilizacionDetallada(algoritmo);
      
      // Verificar si hay pasos sin asignar
      _verificarCompletitudAsignacion(algoritmo);
      
      expect(makespan, greaterThan(300), reason: 'El resultado es demasiado optimista');
      expect(makespan, lessThan(1000), reason: 'El resultado es demasiado pesimista');
    });

    test('🔍 ANÁLISIS DE ESCALABILIDAD SOSPECHOSA', () {
      print('\n🔍 INVESTIGANDO ESCALABILIDAD...');
      
      final resultados = <int, Map<String, dynamic>>{};
      
      // Probar con diferentes tamaños
      for (final numPasos in [10, 50, 100, 200, 500]) {
        print('\\n🧪 Probando con ~$numPasos pasos...');
        
        final caso = _generarCasoParametrizado(numPasos);
        
        final algoritmo = SchedulingDinamicoAlgorithm();
        algoritmo.setDebugMode(false);
        algoritmo.inicializar(
          pasos: caso.pasos,
          cocineros: caso.cocineros,
          utensilios: caso.utensilios,
        );
        
        final stopwatch = Stopwatch()..start();
        algoritmo.ejecutarCompleto();
        stopwatch.stop();
        
        final makespan = algoritmo.estadoActual!.tiempoActual;
        final tiempo = stopwatch.elapsedMilliseconds;
        final pasosReales = caso.pasos.length;
        
        resultados[pasosReales] = {
          'makespan': makespan,
          'tiempo': tiempo,
          'eficiencia': _calcularEficienciaTeórica(pasosReales, caso.cocineros.length),
        };
        
        print('   📊 ${pasosReales} pasos → ${makespan}s makespan, ${tiempo}ms cálculo');
        
        // Verificar si la escalabilidad es lineal o exponencial
        final eficienciaEsperada = resultados[pasosReales]!['eficiencia'];
        final ratioEficiencia = makespan / eficienciaEsperada;
        print('   🎯 Ratio eficiencia: ${ratioEficiencia.toStringAsFixed(2)} (1.0 = perfecto)');
      }
      
      print('\n📈 ANÁLISIS DE ESCALABILIDAD:');
      print('Pasos | Makespan | Tiempo | Eficiencia');
      print('-' * 45);
      
      for (final entry in resultados.entries) {
        final pasos = entry.key;
        final data = entry.value;
        print('${pasos.toString().padLeft(5)} | ${data["makespan"].toString().padLeft(8)} | ${data["tiempo"].toString().padLeft(6)}ms | ${(data["makespan"] / data["eficiencia"]).toStringAsFixed(2)}');
      }
      
      // Verificar si hay un patrón sospechoso
      _detectarPatronesSospechosos(resultados);
    });

    test('🚨 VERIFICAR CALIDAD DEL SCHEDULING', () {
      print('\n🚨 VERIFICANDO CALIDAD REAL DEL SCHEDULING...');
      
      final caso = _generarCasoParametrizado(100);
      final algoritmo = SchedulingDinamicoAlgorithm();
      algoritmo.setDebugMode(false);
      algoritmo.inicializar(
        pasos: caso.pasos,
        cocineros: caso.cocineros,
        utensilios: caso.utensilios,
      );
      algoritmo.ejecutarCompleto();
      
      // ANÁLISIS DETALLADO DE CALIDAD
      print('\\n🔍 ANÁLISIS DE CALIDAD:');
      
      // 1. Utilización de recursos
      final utilizacionCocineros = _calcularUtilizacion(algoritmo.estadoActual!.cocineros, algoritmo.estadoActual!.tiempoActual);
      final utilizacionUtensilios = _calcularUtilizacion(algoritmo.estadoActual!.utensilios, algoritmo.estadoActual!.tiempoActual);
      
      print('👨‍🍳 Utilización cocineros: ${utilizacionCocineros.toStringAsFixed(1)}%');
      print('🔧 Utilización utensilios: ${utilizacionUtensilios.toStringAsFixed(1)}%');
      
      // 2. Distribución de trabajo
      _analizarDistribucionTrabajo(algoritmo);
      
      // 3. Tiempos de espera
      _analizarTiemposEspera(algoritmo);
      
      // 4. Verificar si hay recursos inactivos sospechosos
      _detectarRecursosInactivos(algoritmo);
      
      // VEREDICTO FINAL
      print('\\n🏆 VEREDICTO DE CALIDAD:');
      if (utilizacionCocineros > 90 && utilizacionUtensilios > 90) {
        print('❌ SOSPECHOSO: Utilización demasiado alta, posible error');
      } else if (utilizacionCocineros < 30 || utilizacionUtensilios < 30) {
        print('❌ MALO: Recursos subutilizados, scheduling ineficiente');
      } else {
        print('✅ RAZONABLE: Utilización balanceada');
      }
    });
  });
}

class _CasoTest {
  final List<PasoScheduling> pasos;
  final List<CocineroScheduling> cocineros;
  final List<UtensilioScheduling> utensilios;
  
  _CasoTest(this.pasos, this.cocineros, this.utensilios);
}

_CasoTest _generarCasoConocido() {
  // Caso simple donde podemos calcular el resultado manualmente
  final pasos = [
    PasoScheduling(id: 'A', nombre: 'Paso A', duracion: 120, tipoCocinero: 'normal', tipoUtensilio: 'horno', dependencias: []),
    PasoScheduling(id: 'B', nombre: 'Paso B', duracion: 180, tipoCocinero: 'normal', tipoUtensilio: 'estufa', dependencias: []),
    PasoScheduling(id: 'C', nombre: 'Paso C', duracion: 150, tipoCocinero: 'normal', tipoUtensilio: 'horno', dependencias: ['A']),
    PasoScheduling(id: 'D', nombre: 'Paso D', duracion: 90, tipoCocinero: 'normal', tipoUtensilio: 'estufa', dependencias: ['B']),
    PasoScheduling(id: 'E', nombre: 'Paso E', duracion: 60, tipoCocinero: 'normal', tipoUtensilio: 'bowl', dependencias: ['C', 'D']),
  ];
  
  final cocineros = [
    CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal'),
    CocineroScheduling(id: 'chef2', nombre: 'Chef2', tipo: 'normal'),
  ];
  
  final utensilios = [
    UtensilioScheduling(id: 'horno1', nombre: 'Horno1', tipo: 'horno'),
    UtensilioScheduling(id: 'estufa1', nombre: 'Estufa1', tipo: 'estufa'),
    UtensilioScheduling(id: 'bowl1', nombre: 'Bowl1', tipo: 'bowl'),
  ];
  
  return _CasoTest(pasos, cocineros, utensilios);
}

_CasoTest _generarCasoParametrizado(int numPasosObjetivo) {
  final random = Random(42);
  final pasos = <PasoScheduling>[];
  final cocineros = <CocineroScheduling>[];
  final utensilios = <UtensilioScheduling>[];
  
  // Generar cocineros (proporción razonable)
  final numCocineros = (numPasosObjetivo / 20).ceil().clamp(2, 10);
  for (int i = 0; i < numCocineros; i++) {
    cocineros.add(CocineroScheduling(id: 'chef$i', nombre: 'Chef$i', tipo: 'normal'));
  }
  
  // Generar utensilios
  final tiposUtensilio = ['horno', 'estufa', 'bowl', 'batidora'];
  for (final tipo in tiposUtensilio) {
    final cantidad = (numCocineros / 2).ceil().clamp(1, 5);
    for (int i = 0; i < cantidad; i++) {
      utensilios.add(UtensilioScheduling(id: '${tipo}_$i', nombre: '${tipo.toUpperCase()}$i', tipo: tipo));
    }
  }
  
  // Generar pasos con dependencias realistas
  for (int i = 0; i < numPasosObjetivo; i++) {
    final dependencias = <String>[];
    
    // Añadir dependencias para crear estructura realista
    if (i > 0 && random.nextDouble() < 0.3) {
      final pasoAnterior = random.nextInt(i);
      dependencias.add('paso$pasoAnterior');
    }
    
    pasos.add(PasoScheduling(
      id: 'paso$i',
      nombre: 'Paso $i',
      duracion: 60 + random.nextInt(240), // 1-5 minutos
      tipoCocinero: 'normal',
      tipoUtensilio: tiposUtensilio[random.nextInt(tiposUtensilio.length)],
      dependencias: dependencias,
    ));
  }
  
  return _CasoTest(pasos, cocineros, utensilios);
}

double _calcularEficienciaTeórica(int numPasos, int numCocineros) {
  // Cálculo teórico simplificado: duración promedio * pasos / cocineros
  const duracionPromedio = 150; // segundos
  return (duracionPromedio * numPasos / numCocineros).toDouble();
}

void _analizarUtilizacionDetallada(SchedulingDinamicoAlgorithm algoritmo) {
  print('\n🔍 ANÁLISIS DETALLADO DE UTILIZACIÓN:');
  
  final estado = algoritmo.estadoActual!;
  
  for (final cocinero in estado.cocineros) {
    final tiempoTrabajo = cocinero.horario.fold(0, (sum, item) => sum + item.duracion);
    final utilizacion = (tiempoTrabajo / estado.tiempoActual * 100);
    print('👨‍🍳 ${cocinero.nombre}: ${utilizacion.toStringAsFixed(1)}% (${tiempoTrabajo}s de ${estado.tiempoActual}s)');
  }
  
  for (final utensilio in estado.utensilios) {
    final tiempoUso = utensilio.horario.fold(0, (sum, item) => sum + item.duracion);
    final utilizacion = (tiempoUso / estado.tiempoActual * 100);
    print('🔧 ${utensilio.nombre}: ${utilizacion.toStringAsFixed(1)}% (${tiempoUso}s de ${estado.tiempoActual}s)');
  }
}

void _verificarCompletitudAsignacion(SchedulingDinamicoAlgorithm algoritmo) {
  final estado = algoritmo.estadoActual!;
  final pasosNoCompletados = estado.todosPasos.where((p) => p.estado != EstadoPaso.completado).toList();
  
  if (pasosNoCompletados.isNotEmpty) {
    print('\n❌ PROBLEMA: ${pasosNoCompletados.length} pasos NO completados:');
    for (final paso in pasosNoCompletados) {
      print('   - ${paso.nombre} (estado: ${paso.estado})');
    }
  } else {
    print('\n✅ Todos los pasos fueron completados correctamente');
  }
}

double _calcularUtilizacion(List<dynamic> recursos, int tiempoTotal) {
  if (recursos.isEmpty || tiempoTotal == 0) return 0.0;
  
  final tiempoTotalUso = recursos.fold(0, (sum, recurso) => 
    sum + recurso.horario.fold(0, (subSum, item) => subSum + item.duracion));
  
  return (tiempoTotalUso / (recursos.length * tiempoTotal) * 100);
}

void _analizarDistribucionTrabajo(SchedulingDinamicoAlgorithm algoritmo) {
  final estado = algoritmo.estadoActual!;
  
  print('\n📊 DISTRIBUCIÓN DE TRABAJO:');
  final trabajoPorCocinero = <String, int>{};
  
  for (final cocinero in estado.cocineros) {
    trabajoPorCocinero[cocinero.id] = cocinero.horario.fold(0, (sum, item) => sum + item.duracion);
  }
  
  final trabajos = trabajoPorCocinero.values.toList()..sort();
  final min = trabajos.first;
  final max = trabajos.last;
  final promedio = trabajos.fold(0, (sum, t) => sum + t) / trabajos.length;
  
  print('   📈 Trabajo mínimo: ${min}s');
  print('   📈 Trabajo máximo: ${max}s');
  print('   📈 Trabajo promedio: ${promedio.toStringAsFixed(1)}s');
  print('   📈 Desviación: ${((max - min) / promedio * 100).toStringAsFixed(1)}%');
}

void _analizarTiemposEspera(SchedulingDinamicoAlgorithm algoritmo) {
  final estado = algoritmo.estadoActual!;
  var tiemposEsperaTotales = 0;
  var numAsignaciones = 0;
  
  for (final paso in estado.pasosCompletados) {
    if (paso.tiempoInicio != null) {
      // Calcular tiempo de espera desde que estuvo disponible
      final tiempoEspera = paso.tiempoInicio! - 0; // Simplificado
      tiemposEsperaTotales += tiempoEspera;
      numAsignaciones++;
    }
  }
  
  if (numAsignaciones > 0) {
    final esperaPromedio = tiemposEsperaTotales / numAsignaciones;
    print('\n⏱️ TIEMPOS DE ESPERA:');
    print('   📊 Espera promedio: ${esperaPromedio.toStringAsFixed(1)}s');
  }
}

void _detectarRecursosInactivos(SchedulingDinamicoAlgorithm algoritmo) {
  final estado = algoritmo.estadoActual!;
  
  print('\n🔍 DETECCIÓN DE RECURSOS INACTIVOS:');
  
  for (final cocinero in estado.cocineros) {
    if (cocinero.horario.isEmpty) {
      print('❌ ${cocinero.nombre} NO USADA (0% utilización)');
    }
  }
  
  for (final utensilio in estado.utensilios) {
    if (utensilio.horario.isEmpty) {
      print('❌ ${utensilio.nombre} NO USADO (0% utilización)');
    }
  }
}

void _detectarPatronesSospechosos(Map<int, Map<String, dynamic>> resultados) {
  print('\n🚨 DETECCIÓN DE PATRONES SOSPECHOSOS:');
  
  final entradas = resultados.entries.toList();
  
  for (int i = 1; i < entradas.length; i++) {
    final anterior = entradas[i-1];
    final actual = entradas[i];
    
    final factorPasos = actual.key / anterior.key;
    final factorTiempo = actual.value['tiempo'] / anterior.value['tiempo'];
    final factorMakespan = actual.value['makespan'] / anterior.value['makespan'];
    
    print('${anterior.key} → ${actual.key} pasos:');
    print('   ⏱️ Factor tiempo: ${factorTiempo.toStringAsFixed(2)}x');
    print('   📊 Factor makespan: ${factorMakespan.toStringAsFixed(2)}x');
    
    if (factorTiempo < factorPasos * 0.5) {
      print('   🚨 SOSPECHOSO: Tiempo crece demasiado lento');
    }
    if (factorMakespan < factorPasos * 0.3) {
      print('   🚨 SOSPECHOSO: Makespan crece demasiado lento');
    }
  }
}
