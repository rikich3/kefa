import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';

void main() {
  group('SchedulingDinamicoAlgorithmOptimizado - Versión Mejorada', () {
    late SchedulingDinamicoAlgorithmOptimizado algoritmo;

    setUp(() {
      algoritmo = SchedulingDinamicoAlgorithmOptimizado();
      algoritmo.setDebugMode(false); // Reducir ruido en tests
    });

    test('Debe completar correctamente un caso básico sin deadlock', () {
      // Crear pasos simples
      final pasos = [
        PasoScheduling(
          id: 'p1',
          nombre: 'Preparar ingredientes',
          duracion: 10,
          dependencias: [],
          tipoCocinero: 'chef',
          tipoUtensilio: 'cuchillo',
        ),
        PasoScheduling(
          id: 'p2',
          nombre: 'Cocinar',
          duracion: 15,
          dependencias: ['p1'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'sarten',
        ),
        PasoScheduling(
          id: 'p3',
          nombre: 'Servir',
          duracion: 5,
          dependencias: ['p2'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'plato',
        ),
      ];

      final cocineros = [
        CocineroScheduling(id: 'c1', nombre: 'Chef Principal', tipo: 'chef', ori: 0),
      ];

      final utensilios = [
        UtensilioScheduling(id: 'u1', nombre: 'Cuchillo', tipo: 'cuchillo'),
        UtensilioScheduling(id: 'u2', nombre: 'Sarten', tipo: 'sarten'),
        UtensilioScheduling(id: 'u3', nombre: 'Plato', tipo: 'plato'),
      ];

      // Ejecutar algoritmo
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      final logs = algoritmo.ejecutarCompletoOptimizado();

      // Verificaciones
      expect(algoritmo.estadoActual, isNotNull);
      expect(algoritmo.estadoActual!.pasosCompletados.length, equals(3));
      expect(algoritmo.estadoActual!.tiempoActual, equals(30)); // 10+15+5
      
      // Verificar que no hay mensajes de error en los logs
      final errores = logs.where((log) => log.contains('ERROR')).toList();
      expect(errores, isEmpty);
    });

    test('Debe manejar correctamente dependencias múltiples', () {
      // Patrón diamante: A -> B,C -> D
      final pasos = [
        PasoScheduling(
          id: 'a',
          nombre: 'Inicio',
          duracion: 5,
          dependencias: [],
          tipoCocinero: 'chef',
          tipoUtensilio: 'cuchillo',
        ),
        PasoScheduling(
          id: 'b',
          nombre: 'Rama B',
          duracion: 10,
          dependencias: ['a'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'sarten',
        ),
        PasoScheduling(
          id: 'c',
          nombre: 'Rama C',
          duracion: 8,
          dependencias: ['a'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'olla',
        ),
        PasoScheduling(
          id: 'd',
          nombre: 'Final',
          duracion: 12,
          dependencias: ['b', 'c'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'plato',
        ),
      ];

      final cocineros = [
        CocineroScheduling(id: 'c1', nombre: 'Chef', tipo: 'chef', ori: 0),
      ];

      final utensilios = [
        UtensilioScheduling(id: 'u1', nombre: 'Cuchillo', tipo: 'cuchillo'),
        UtensilioScheduling(id: 'u2', nombre: 'Sarten', tipo: 'sarten'),
        UtensilioScheduling(id: 'u3', nombre: 'Olla', tipo: 'olla'),
        UtensilioScheduling(id: 'u4', nombre: 'Plato', tipo: 'plato'),
      ];

      // Ejecutar algoritmo
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      final logs = algoritmo.ejecutarCompletoOptimizado();

      // Verificaciones
      expect(algoritmo.estadoActual!.pasosCompletados.length, equals(4));
      
      // Verificar orden de ejecución correcto
      final pasoA = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'a');
      final pasoB = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'b');
      final pasoC = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'c');
      final pasoD = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'd');

      expect(pasoA.tiempoFin!, lessThanOrEqualTo(pasoB.tiempoInicio!));
      expect(pasoA.tiempoFin!, lessThanOrEqualTo(pasoC.tiempoInicio!));
      expect(pasoB.tiempoFin!, lessThanOrEqualTo(pasoD.tiempoInicio!));
      expect(pasoC.tiempoFin!, lessThanOrEqualTo(pasoD.tiempoInicio!));

      // Verificar que no hay errores
      final errores = logs.where((log) => log.contains('ERROR')).toList();
      expect(errores, isEmpty);
    });

    test('Debe detectar y reportar deadlocks correctamente', () {
      // Crear dependencia circular: A -> B -> C -> A
      final pasos = [
        PasoScheduling(
          id: 'a',
          nombre: 'Paso A',
          duracion: 10,
          dependencias: ['c'], // Depende de C (circular)
          tipoCocinero: 'chef',
          tipoUtensilio: 'cuchillo',
        ),
        PasoScheduling(
          id: 'b',
          nombre: 'Paso B',
          duracion: 10,
          dependencias: ['a'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'sarten',
        ),
        PasoScheduling(
          id: 'c',
          nombre: 'Paso C',
          duracion: 10,
          dependencias: ['b'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'olla',
        ),
      ];

      final cocineros = [
        CocineroScheduling(id: 'c1', nombre: 'Chef', tipo: 'chef', ori: 0),
      ];

      final utensilios = [
        UtensilioScheduling(id: 'u1', nombre: 'Cuchillo', tipo: 'cuchillo'),
        UtensilioScheduling(id: 'u2', nombre: 'Sarten', tipo: 'sarten'),
        UtensilioScheduling(id: 'u3', nombre: 'Olla', tipo: 'olla'),
      ];

      // Ejecutar algoritmo
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      final logs = algoritmo.ejecutarCompletoOptimizado();

      // Verificar que se detectó el deadlock
      expect(algoritmo.estadoActual!.pasosCompletados.length, lessThan(3));
      
      // Verificar que se reportó el error
      final errores = logs.where((log) => log.contains('ERROR')).toList();
      expect(errores, isNotEmpty);
    });

    test('Debe manejar correctamente casos con múltiples recursos', () {
      final pasos = [
        PasoScheduling(
          id: 'p1',
          nombre: 'Preparar A',
          duracion: 10,
          dependencias: [],
          tipoCocinero: 'chef',
          tipoUtensilio: 'cuchillo',
        ),
        PasoScheduling(
          id: 'p2',
          nombre: 'Preparar B',
          duracion: 8,
          dependencias: [],
          tipoCocinero: 'ayudante',
          tipoUtensilio: 'tabla',
        ),
        PasoScheduling(
          id: 'p3',
          nombre: 'Combinar',
          duracion: 15,
          dependencias: ['p1', 'p2'],
          tipoCocinero: 'chef',
          tipoUtensilio: 'olla',
        ),
      ];

      final cocineros = [
        CocineroScheduling(id: 'c1', nombre: 'Chef', tipo: 'chef', ori: 0),
        CocineroScheduling(id: 'c2', nombre: 'Ayudante', tipo: 'ayudante', ori: 0),
      ];

      final utensilios = [
        UtensilioScheduling(id: 'u1', nombre: 'Cuchillo', tipo: 'cuchillo'),
        UtensilioScheduling(id: 'u2', nombre: 'Tabla', tipo: 'tabla'),
        UtensilioScheduling(id: 'u3', nombre: 'Olla', tipo: 'olla'),
      ];

      // Ejecutar algoritmo
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      final logs = algoritmo.ejecutarCompletoOptimizado();

      // Verificaciones
      expect(algoritmo.estadoActual!.pasosCompletados.length, equals(3));
      
      // Con dos recursos paralelos, debería ser más eficiente
      expect(algoritmo.estadoActual!.tiempoActual, lessThanOrEqualTo(25)); // 10+15 o 8+15
      
      final errores = logs.where((log) => log.contains('ERROR')).toList();
      expect(errores, isEmpty);
    });

    test('Rendimiento - Debe completar caso mediano en tiempo razonable', () {
      // Generar 20 pasos con dependencias más complejas
      final pasos = <PasoScheduling>[];
      
      // Pasos iniciales (sin dependencias)
      for (int i = 1; i <= 5; i++) {
        pasos.add(PasoScheduling(
          id: 'inicio_$i',
          nombre: 'Paso inicial $i',
          duracion: 5 + (i % 3),
          dependencias: [],
          tipoCocinero: 'chef',
          tipoUtensilio: 'utensilio_${i % 3 + 1}',
        ));
      }
      
      // Pasos intermedios (dependen de iniciales)
      for (int i = 1; i <= 10; i++) {
        final dep = 'inicio_${(i % 5) + 1}';
        pasos.add(PasoScheduling(
          id: 'medio_$i',
          nombre: 'Paso medio $i',
          duracion: 8 + (i % 4),
          dependencias: [dep],
          tipoCocinero: i % 2 == 0 ? 'chef' : 'ayudante',
          tipoUtensilio: 'utensilio_${(i % 4) + 1}',
        ));
      }
      
      // Pasos finales (dependen de intermedios)
      for (int i = 1; i <= 5; i++) {
        final dep1 = 'medio_${i * 2 - 1}';
        final dep2 = 'medio_${i * 2}';
        pasos.add(PasoScheduling(
          id: 'final_$i',
          nombre: 'Paso final $i',
          duracion: 10 + (i % 2),
          dependencias: [dep1, dep2],
          tipoCocinero: 'chef',
          tipoUtensilio: 'utensilio_final',
        ));
      }

      final cocineros = [
        CocineroScheduling(id: 'c1', nombre: 'Chef 1', tipo: 'chef', ori: 0),
        CocineroScheduling(id: 'c2', nombre: 'Chef 2', tipo: 'chef', ori: 0),
        CocineroScheduling(id: 'a1', nombre: 'Ayudante 1', tipo: 'ayudante', ori: 0),
        CocineroScheduling(id: 'a2', nombre: 'Ayudante 2', tipo: 'ayudante', ori: 0),
      ];

      final utensilios = [
        UtensilioScheduling(id: 'u1', nombre: 'Utensilio 1', tipo: 'utensilio_1'),
        UtensilioScheduling(id: 'u2', nombre: 'Utensilio 2', tipo: 'utensilio_2'),
        UtensilioScheduling(id: 'u3', nombre: 'Utensilio 3', tipo: 'utensilio_3'),
        UtensilioScheduling(id: 'u4', nombre: 'Utensilio 4', tipo: 'utensilio_4'),
        UtensilioScheduling(id: 'uf', nombre: 'Utensilio Final', tipo: 'utensilio_final'),
      ];

      // Medir tiempo de ejecución
      final stopwatch = Stopwatch()..start();
      
      algoritmo.inicializar(pasos: pasos, cocineros: cocineros, utensilios: utensilios);
      final logs = algoritmo.ejecutarCompletoOptimizado();
      
      stopwatch.stop();

      // Verificaciones
      expect(algoritmo.estadoActual!.pasosCompletados.length, equals(20));
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // Menos de 5 segundos
      
      final errores = logs.where((log) => log.contains('ERROR')).toList();
      expect(errores, isEmpty);
      
      print('✅ Test de rendimiento: ${algoritmo.estadoActual!.pasosCompletados.length} pasos en ${stopwatch.elapsedMilliseconds}ms');
      print('   Makespan: ${algoritmo.estadoActual!.tiempoActual} segundos');
    });
  });
}
