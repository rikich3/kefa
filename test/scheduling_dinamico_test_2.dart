import 'package:flutter_test/flutter_test.dart';
import 'package:kefa/back/algorithms/scheduling_dinamico_algorithm.dart';
import 'package:kefa/back/dataModels/paso_scheduling.dart';
import 'package:kefa/back/dataModels/cocinero_scheduling.dart';
import 'package:kefa/back/dataModels/utensilio_scheduling.dart';

void main() {
  group('Scheduling Dinámico Algorithm Tests', () {
    late SchedulingDinamicoAlgorithm algoritmo;
    late List<PasoScheduling> pasos;
    late List<CocineroScheduling> cocineros;
    late List<UtensilioScheduling> utensilios;

    setUp(() {
      algoritmo = SchedulingDinamicoAlgorithm();
      
      // Crear pasos de prueba con dependencias
      pasos = [
        PasoScheduling(
          id: 'A',
          nombre: 'Paso A',
          tipoCocinero: 'cocinero',
          tipoUtensilio: 'A',
          duracion: 10,
          dependencias: [],
        ),
        PasoScheduling(
          id: 'B',
          nombre: 'Paso B',
          tipoCocinero: 'cocinero',
          tipoUtensilio: 'B',
          duracion: 15,
          dependencias: [],
        ),
        PasoScheduling(
          id: 'C',
          nombre: 'Paso C',
          tipoCocinero: 'cocinero',
          tipoUtensilio: 'A',
          duracion: 20,
          dependencias: ['A', 'B'], // C depende de A y B
        ),
      ];
      
      // Crear recursos de prueba
      cocineros = [
        CocineroScheduling(id: 'c1', nombre: 'Cocinero1', tipo: 'cocinero'),
        CocineroScheduling(id: 'c2', nombre: 'Cocinero2', tipo: 'cocinero'),
      ];
      
      utensilios = [
        UtensilioScheduling(id: 'u1', nombre: 'UtensilioA', tipo: 'A'),
        UtensilioScheduling(id: 'u2', nombre: 'UtensilioB', tipo: 'B'),
      ];
    });

    test('Debe inicializar correctamente el estado', () {
      algoritmo.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );

      final estado = algoritmo.estadoActual;
      expect(estado, isNotNull);
      expect(estado!.todosPasos.length, equals(3));
      expect(estado.cocineros.length, equals(2));
      expect(estado.utensilios.length, equals(2));
      expect(estado.tiempoActual, equals(0));
      expect(estado.pasosCompletados.length, equals(0));
    });

    test('Debe ejecutar algoritmo completo sin errores', () {
      algoritmo.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );

      final logs = algoritmo.ejecutarCompleto();
      
      expect(logs, isNotEmpty);
      expect(algoritmo.estadoActual!.pasosCompletados.length, equals(3));
      expect(algoritmo.estadoActual!.tiempoActual, greaterThan(0));
      
      // Verificar que el algoritmo respeta las dependencias
      // C no debería empezar antes que A y B terminen
      final pasoA = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'A');
      final pasoB = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'B');
      final pasoC = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'C');
      
      expect(pasoC.tiempoInicio!, greaterThanOrEqualTo(pasoA.tiempoFin!));
      expect(pasoC.tiempoInicio!, greaterThanOrEqualTo(pasoB.tiempoFin!));
    });

    test('Debe generar logs detallados del proceso', () {
      algoritmo.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );

      final logs = algoritmo.ejecutarCompleto();
      
      expect(logs, isNotEmpty);
      expect(logs.first, contains('Iniciando scheduling dinámico'));
      expect(logs.any((log) => log.contains('Algoritmo completado')), isTrue);
      expect(logs.any((log) => log.contains('Paso A')), isTrue);
      expect(logs.any((log) => log.contains('Paso B')), isTrue);
      expect(logs.any((log) => log.contains('Paso C')), isTrue);
    });

    test('Debe manejar correctamente casos sin dependencias', () {
      // Pasos sin dependencias
      final pasosSimples = [
        PasoScheduling(
          id: 'X',
          nombre: 'Paso X',
          tipoCocinero: 'cocinero',
          tipoUtensilio: 'A',
          duracion: 5,
          dependencias: [],
        ),
        PasoScheduling(
          id: 'Y',
          nombre: 'Paso Y',
          tipoCocinero: 'cocinero',
          tipoUtensilio: 'B',
          duracion: 5,
          dependencias: [],
        ),
      ];

      algoritmo.inicializar(
        pasos: pasosSimples,
        cocineros: cocineros,
        utensilios: utensilios,
      );

      final logs = algoritmo.ejecutarCompleto();
      
      expect(logs, isNotEmpty);
      expect(algoritmo.estadoActual!.pasosCompletados.length, equals(2));
      
      // Ambos pasos deberían poder ejecutarse en paralelo
      final pasoX = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'X');
      final pasoY = algoritmo.estadoActual!.pasosCompletados.firstWhere((p) => p.id == 'Y');
      
      expect(pasoX.tiempoInicio, equals(0));
      expect(pasoY.tiempoInicio, equals(0));
    });
  });
}
