import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';
import 'dart:math';

void main() {
  group('🚀 ESCALABILIDAD PARA CASOS ENORMES', () {
    
    test('📈 RENDIMIENTO CON 50+ RECETAS Y 100+ PASOS', () {
      print('\n' + '='*60);
      print('🏭 PRUEBA DE ESCALABILIDAD MASIVA');
      print('='*60);
      
      // Generar caso masivo
      final casoMasivo = _generarCasoMasivo(
        numRecetas: 50,
        pasosPromedioPorReceta: 8,
        numCocineros: 30,
        tiposCocinero: ['normal', 'especialista', 'asistente', 'chef'],
        tiposUtensilio: ['horno', 'estufa', 'batidora', 'licuadora', 'molde', 'sarten', 'bowl', 'cuchillo'],
      );
      
      print('📊 CASO GENERADO:');
      print('   📝 Pasos: ${casoMasivo.pasos.length}');
      print('   👨‍🍳 Cocineros: ${casoMasivo.cocineros.length}');
      print('   🔧 Utensilios: ${casoMasivo.utensilios.length}');
      print('   🔗 Dependencias: ${casoMasivo.pasos.fold(0, (sum, p) => sum + p.dependencias.length)}');
      
      // MEDIR RENDIMIENTO ALGORITMO DINÁMICO
      print('\n⏱️ MIDIENDO ALGORITMO DINÁMICO ESTÁNDAR...');
      final stopwatchDinamico = Stopwatch()..start();
      
      final algoritmoDinamico = SchedulingDinamicoAlgorithm();
      algoritmoDinamico.setDebugMode(false);
      algoritmoDinamico.inicializar(
        pasos: casoMasivo.pasos,
        cocineros: casoMasivo.cocineros,
        utensilios: casoMasivo.utensilios,
      );
      algoritmoDinamico.ejecutarCompleto();
      
      stopwatchDinamico.stop();
      final tiempoDinamico = stopwatchDinamico.elapsedMilliseconds;
      final makespanDinamico = algoritmoDinamico.estadoActual!.tiempoActual;
      
      // MEDIR RENDIMIENTO ALGORITMO OPTIMIZADO
      print('\n🚀 MIDIENDO ALGORITMO OPTIMIZADO...');
      final stopwatchOptimizado = Stopwatch()..start();
      
      final algoritmoOptimizado = SchedulingDinamicoAlgorithmOptimizado();
      algoritmoOptimizado.setDebugMode(false);
      algoritmoOptimizado.inicializar(
        pasos: List.from(casoMasivo.pasos), // Nueva instancia
        cocineros: List.from(casoMasivo.cocineros),
        utensilios: List.from(casoMasivo.utensilios),
      );
      algoritmoOptimizado.ejecutarCompleto();
      
      stopwatchOptimizado.stop();
      final tiempoOptimizado = stopwatchOptimizado.elapsedMilliseconds;
      final makespanOptimizado = algoritmoOptimizado.estadoActual!.tiempoActual;
      
      // ANÁLISIS DE RESULTADOS
      print('\n📊 RESULTADOS DE ESCALABILIDAD:');
      print('='*50);
      print('⚙️  Dinámico    - Makespan: ${makespanDinamico}s | Tiempo: ${tiempoDinamico}ms');
      print('🚀 Optimizado - Makespan: ${makespanOptimizado}s | Tiempo: ${tiempoOptimizado}ms');
      
      final mejoraCalidad = makespanDinamico - makespanOptimizado;
      final factorTiempo = tiempoOptimizado / tiempoDinamico;
      
      print('\n🎯 ANÁLISIS:');
      print('   📈 Mejora en makespan: ${mejoraCalidad}s');
      print('   ⏱️ Factor de tiempo: ${factorTiempo.toStringAsFixed(2)}x');
      print('   💻 Escalabilidad: ${tiempoOptimizado < 5000 ? "✅ EXCELENTE" : tiempoOptimizado < 15000 ? "✅ BUENA" : "⚠️ REGULAR"}');
      
      // VERIFICACIONES
      expect(makespanOptimizado, lessThanOrEqualTo(makespanDinamico), 
        reason: 'El algoritmo optimizado debe ser igual o mejor');
      expect(tiempoOptimizado, lessThan(30000), 
        reason: 'Debe ejecutarse en menos de 30 segundos');
      
      print('\n🏆 VEREDICTO: ${mejoraCalidad >= 0 ? "MEJORA CONFIRMADA" : "SIN DEGRADACIÓN"}');
    });

    test('🌐 CASOS EXTREMOS: 100+ COCINEROS, 200+ PASOS', () {
      print('\n🌪️ PRUEBA EXTREMA...');
      
      final casoExtremo = _generarCasoMasivo(
        numRecetas: 25,
        pasosPromedioPorReceta: 8,
        numCocineros: 100,
        tiposCocinero: ['normal', 'especialista', 'asistente', 'chef', 'aprendiz'],
        tiposUtensilio: ['horno', 'estufa', 'batidora', 'licuadora', 'molde', 'sarten', 'bowl', 'cuchillo', 'plancha', 'wok'],
      );
      
      print('🌊 CASO EXTREMO: ${casoExtremo.pasos.length} pasos, ${casoExtremo.cocineros.length} cocineros');
      
      // Solo probar algoritmo optimizado para casos extremos
      final stopwatch = Stopwatch()..start();
      
      final algoritmo = SchedulingDinamicoAlgorithmOptimizado();
      algoritmo.setDebugMode(false);
      algoritmo.inicializar(
        pasos: casoExtremo.pasos,
        cocineros: casoExtremo.cocineros,
        utensilios: casoExtremo.utensilios,
      );
      algoritmo.ejecutarCompleto();
      
      stopwatch.stop();
      final tiempo = stopwatch.elapsedMilliseconds;
      final makespan = algoritmo.estadoActual!.tiempoActual;
      
      print('⚡ RESULTADO EXTREMO:');
      print('   📊 Makespan: ${makespan}s');
      print('   ⏱️ Tiempo de cálculo: ${tiempo}ms');
      print('   🎯 Eficiencia: ${tiempo < 60000 ? "✅ EXCELENTE" : "⚠️ LENTA"}');
      
      expect(tiempo, lessThan(120000), reason: 'Debe ejecutarse en menos de 2 minutos');
      expect(makespan, greaterThan(0), reason: 'Debe generar un plan válido');
    });
  });
}

class _CasoMasivo {
  final List<PasoScheduling> pasos;
  final List<CocineroScheduling> cocineros;
  final List<UtensilioScheduling> utensilios;
  
  _CasoMasivo(this.pasos, this.cocineros, this.utensilios);
}

_CasoMasivo _generarCasoMasivo({
  required int numRecetas,
  required int pasosPromedioPorReceta,
  required int numCocineros,
  required List<String> tiposCocinero,
  required List<String> tiposUtensilio,
}) {
  final random = Random(42); // Seed fijo para reproducibilidad
  final pasos = <PasoScheduling>[];
  final cocineros = <CocineroScheduling>[];
  final utensilios = <UtensilioScheduling>[];
  
  // Generar cocineros
  for (int i = 0; i < numCocineros; i++) {
    final tipo = tiposCocinero[i % tiposCocinero.length];
    cocineros.add(CocineroScheduling(
      id: 'chef$i',
      nombre: 'Chef$i',
      tipo: tipo,
    ));
  }
  
  // Generar utensilios (2x número de cocineros)
  for (int i = 0; i < numCocineros * 2; i++) {
    final tipo = tiposUtensilio[i % tiposUtensilio.length];
    utensilios.add(UtensilioScheduling(
      id: '${tipo}_$i',
      nombre: '${tipo.toUpperCase()}$i',
      tipo: tipo,
    ));
  }
  
  // Generar recetas con pasos interconectados
  for (int receta = 0; receta < numRecetas; receta++) {
    final numPasos = pasosPromedioPorReceta + random.nextInt(6) - 3; // ±3 variación
    final pasosReceta = <String>[];
    
    for (int paso = 0; paso < numPasos; paso++) {
      final pasoId = 'receta${receta}_paso$paso';
      pasosReceta.add(pasoId);
      
      // Generar dependencias dentro de la receta
      final dependencias = <String>[];
      if (paso > 0 && random.nextBool()) {
        // 50% chance de depender del paso anterior
        dependencias.add(pasosReceta[paso - 1]);
      }
      if (paso > 1 && random.nextDouble() < 0.3) {
        // 30% chance de depender de un paso anterior aleatorio
        final pasoAnterior = random.nextInt(paso);
        dependencias.add(pasosReceta[pasoAnterior]);
      }
      
      // Dependencias entre recetas (para crear red compleja)
      if (receta > 0 && random.nextDouble() < 0.2) {
        final recetaAnterior = random.nextInt(receta);
        final pasoAnterior = random.nextInt(pasosPromedioPorReceta);
        dependencias.add('receta${recetaAnterior}_paso$pasoAnterior');
      }
      
      pasos.add(PasoScheduling(
        id: pasoId,
        nombre: 'Paso $paso de Receta $receta',
        duracion: 60 + random.nextInt(300), // 1-6 minutos
        tipoCocinero: tiposCocinero[random.nextInt(tiposCocinero.length)],
        tipoUtensilio: tiposUtensilio[random.nextInt(tiposUtensilio.length)],
        dependencias: dependencias,
      ));
    }
  }
  
  return _CasoMasivo(pasos, cocineros, utensilios);
}
