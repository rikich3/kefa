import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado_fixed.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';

void main() {
  group('🚀 PRUEBA MASIVA - ALGORITMO OPTIMIZADO', () {
    late SchedulingDinamicoAlgorithmOptimizado algoritmo;
    late List<PasoScheduling> pasos;
    late List<CocineroScheduling> cocineros;
    late List<UtensilioScheduling> utensilios;

    setUp(() {
      // Crear cocineros (8)
      cocineros = List.generate(8, (i) => CocineroScheduling(
        id: 'chef_${i + 1}',
        nombre: 'Chef ${i + 1}',
        tipo: 'cocinero',
        ori: 0,
      ));

      // Crear utensilios (diferentes cantidades entre 5-8)
      utensilios = [
        ...List.generate(8, (i) => UtensilioScheduling(
          id: 'bowl_${i + 1}',
          nombre: 'Bowl ${i + 1}',
          tipo: 'bowl',
          ori: 0,
        )),
        ...List.generate(7, (i) => UtensilioScheduling(
          id: 'sarten_${i + 1}',
          nombre: 'Sartén ${i + 1}',
          tipo: 'sarten',
          ori: 0,
        )),
        ...List.generate(6, (i) => UtensilioScheduling(
          id: 'horno_${i + 1}',
          nombre: 'Horno ${i + 1}',
          tipo: 'horno',
          ori: 0,
        )),
        ...List.generate(5, (i) => UtensilioScheduling(
          id: 'batidora_${i + 1}',
          nombre: 'Batidora ${i + 1}',
          tipo: 'batidora',
          ori: 0,
        )),
      ];

      // Crear 5 recetas con diferentes números de pasos
      final recetas = [
        _crearReceta(numPasos: 10, cantidadPlatos: 20, nombre: 'Receta1'),
        _crearReceta(numPasos: 9, cantidadPlatos: 10, nombre: 'Receta2'),
        _crearReceta(numPasos: 15, cantidadPlatos: 70, nombre: 'Receta3'),
        _crearReceta(numPasos: 8, cantidadPlatos: 80, nombre: 'Receta4'),
        _crearReceta(numPasos: 5, cantidadPlatos: 10, nombre: 'Receta5'),
      ];

      // Combinar todos los pasos
      pasos = recetas.expand((r) => r).toList();

      // Crear instancia del algoritmo
      algoritmo = SchedulingDinamicoAlgorithmOptimizado();
    });

    test('🔥 Prueba de rendimiento masiva', () async {
      // Inicializar algoritmo
      algoritmo.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );

      print('📊 INICIANDO PRUEBA MASIVA');
      print('👨‍🍳 Cocineros: ${cocineros.length}');
      print('🔧 Utensilios: ${utensilios.length}');
      print('📝 Total pasos: ${pasos.length}');

      // Ejecutar algoritmo
      final logs = algoritmo.ejecutarCompleto();

      // Imprimir resultados
      print('=' * 50);
      print('📈 RESULTADOS:');
      print('⏱️ Makespan: ${algoritmo.estadoActual?.tiempoActual}');
      print('✅ Pasos completados: ${algoritmo.estadoActual?.pasosCompletados.length}/${pasos.length}');
      
      // Validaciones
      expect(algoritmo.estadoActual, isNotNull);
      expect(algoritmo.estadoActual!.pasosCompletados.length, equals(pasos.length));
      
      // Verificar asignación de recursos
      for (final paso in algoritmo.estadoActual!.pasosCompletados) {
        expect(paso.cocineroAsignado, isNotNull);
        expect(paso.utensilioAsignado, isNotNull);
        expect(paso.tiempoInicio, isNotNull);
        expect(paso.tiempoFin, isNotNull);
      }

      // Analizar camino crítico y generar análisis detallado
      final pasosOrdenados = algoritmo.estadoActual!.pasosCompletados.toList()
        ..sort((a, b) => (a.tiempoInicio ?? 0).compareTo(b.tiempoInicio ?? 0));

      print('\n📊 ANÁLISIS DE EJECUCIÓN:');
      print('Primeros 5 pasos ejecutados:');
      for (var i = 0; i < 5 && i < pasosOrdenados.length; i++) {
        final paso = pasosOrdenados[i];
        print('${paso.nombre}: T${paso.tiempoInicio}-T${paso.tiempoFin}');
      }
      
      print('\nÚltimos 5 pasos ejecutados:');
      for (var i = pasosOrdenados.length - 5; i < pasosOrdenados.length; i++) {
        final paso = pasosOrdenados[i];
        print('${paso.nombre}: T${paso.tiempoInicio}-T${paso.tiempoFin}');
      }

      // Análisis de utilización de recursos
      final utilizacionCocineros = <String, List<int>>{};
      final utilizacionUtensilios = <String, List<int>>{};

      for (final paso in algoritmo.estadoActual!.pasosCompletados) {
        utilizacionCocineros.putIfAbsent(paso.cocineroAsignado!, () => [])
          .add(paso.tiempoFin! - paso.tiempoInicio!);
        
        utilizacionUtensilios.putIfAbsent(paso.utensilioAsignado!, () => [])
          .add(paso.tiempoFin! - paso.tiempoInicio!);
      }

      print('\n📈 UTILIZACIÓN DE RECURSOS:');
      print('\nCocineros:');
      utilizacionCocineros.forEach((cocinero, tiempos) {
        final totalTiempo = tiempos.reduce((a, b) => a + b);
        final promedioDuracion = totalTiempo / tiempos.length;
        print('$cocinero: ${totalTiempo}s total, ${tiempos.length} tareas, ${promedioDuracion.toStringAsFixed(1)}s promedio');
      });

      print('\nUtensilios:');
      utilizacionUtensilios.forEach((utensilio, tiempos) {
        final totalTiempo = tiempos.reduce((a, b) => a + b);
        final promedioDuracion = totalTiempo / tiempos.length;
        print('$utensilio: ${totalTiempo}s total, ${tiempos.length} usos, ${promedioDuracion.toStringAsFixed(1)}s promedio');
      });

      // Análisis de paralelismo y eficiencia
      final eventos = <Map<String, dynamic>>[];
      for (final paso in algoritmo.estadoActual!.pasosCompletados) {
        if (paso.tiempoInicio != null && paso.tiempoFin != null) {
          eventos.add({
            'tiempo': int.parse(paso.cocineroAsignado!),
            'tipo': 'inicio',
          });
          eventos.add({
            'tiempo': int.parse(paso.utensilioAsignado!),
            'tipo': 'fin',
          });
        }
      }
      eventos.sort((a, b) => a['tiempo'].compareTo(b['tiempo']));

      var tareasParalelas = 0;
      var maxParalelas = 0;
      for (final evento in eventos) {
        if (evento['tipo'] == 'inicio') {
          tareasParalelas++;
          if (tareasParalelas > maxParalelas) maxParalelas = tareasParalelas;
        } else {
          tareasParalelas--;
        }
      }

      print('\n🔄 Máximo de tareas en paralelo: $maxParalelas');

      // Análisis de eficiencia
      final makespan = algoritmo.estadoActual!.tiempoActual;
      final totalTrabajo = algoritmo.estadoActual!.pasosCompletados
          .map((p) => int.parse(p.utensilioAsignado!) - int.parse(p.cocineroAsignado!))
          .reduce((a, b) => a + b);
      final eficiencia = totalTrabajo / (makespan * cocineros.length) * 100;
      
      print('\n⚡ MÉTRICAS DE EFICIENCIA:');
      print('Makespan: ${makespan}s');
      print('Trabajo total: ${totalTrabajo}s');
      print('Eficiencia: ${eficiencia.toStringAsFixed(1)}% (trabajo_total / (makespan * cocineros))');
    });
  });
}

List<PasoScheduling> _crearReceta({
  required int numPasos,
  required int cantidadPlatos,
  required String nombre,
}) {
  final pasos = <PasoScheduling>[];
  final utensilios = ['bowl', 'sarten', 'horno', 'batidora'];
  final duraciones = [180, 240, 300, 360, 420];

  // Crear pasos base
  for (var i = 0; i < numPasos; i++) {
    final paso = PasoScheduling(
      id: '${nombre}_paso${i + 1}',
      nombre: '$nombre - Paso ${i + 1}',
      tipoCocinero: 'cocinero',
      tipoUtensilio: utensilios[i % utensilios.length],
      duracion: duraciones[i % duraciones.length],
      dependencias: i > 0 ? ['${nombre}_paso$i'] : [],
    );
    pasos.add(paso);
  }

  // Multiplicar por la cantidad de platos
  final todosLosPasos = <PasoScheduling>[];
  for (var plato = 1; plato <= cantidadPlatos; plato++) {
    for (final pasoBase in pasos) {
      final pasoNuevo = PasoScheduling(
        id: '${pasoBase.id}_plato$plato',
        nombre: '${pasoBase.nombre} (Plato $plato)',
        tipoCocinero: pasoBase.tipoCocinero,
        tipoUtensilio: pasoBase.tipoUtensilio,
        duracion: pasoBase.duracion,
        dependencias: pasoBase.dependencias
            .map((d) => '${d}_plato$plato')
            .toList(),
      );
      todosLosPasos.add(pasoNuevo);
    }
  }

  return todosLosPasos;
}
