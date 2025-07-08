import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado_nuevo.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';
import '../lib/back/dataModels/estado_scheduling.dart';

void main() {
  group('📊 VALIDACIÓN ALGORITMO OPTIMIZADO NUEVO', () {
    late List<PasoScheduling> pasos;
    late List<CocineroScheduling> cocineros;
    late List<UtensilioScheduling> utensilios;

    setUp(() {
      // Configurar datos de prueba (Tiramisú completo)
      pasos = [
        // Preparar café (0 dependencias)
        PasoScheduling(
          id: 'cafe',
          nombre: 'Preparar café',
          duracion: 300,
          tipoCocinero: 'normal',
          tipoUtensilio: 'cafetera',
          dependencias: [],
        ),
        
        // Preparar mascarpone (0 dependencias)
        PasoScheduling(
          id: 'mascarpone',
          nombre: 'Preparar mascarpone',
          duracion: 240,
          tipoCocinero: 'normal',
          tipoUtensilio: 'batidora',
          dependencias: [],
        ),
        
        // Preparar crutones (0 dependencias)
        PasoScheduling(
          id: 'crutones',
          nombre: 'Preparar crutones',
          duracion: 180,
          tipoCocinero: 'normal',
          tipoUtensilio: 'horno',
          dependencias: [],
        ),
        
        // Mojar bizcochos (depende de café) - CRÍTICO
        PasoScheduling(
          id: 'bizcochos',
          nombre: 'Mojar bizcochos',
          duracion: 180,
          tipoCocinero: 'normal',
          tipoUtensilio: 'molde',
          dependencias: ['cafe'],
        ),
        
        // Preparar aderezo1 (0 dependencias)
        PasoScheduling(
          id: 'aderezo1',
          nombre: 'Preparar aderezo1',
          duracion: 120,
          tipoCocinero: 'normal',
          tipoUtensilio: 'bowl',
          dependencias: [],
        ),
        
        // Preparar aderezo2 (depende de aderezo1)
        PasoScheduling(
          id: 'aderezo2',
          nombre: 'Preparar aderezo2',
          duracion: 150,
          tipoCocinero: 'normal',
          tipoUtensilio: 'bowl',
          dependencias: ['aderezo1'],
        ),
        
        // Preparar aderezo3 (0 dependencias) - COMPETIDOR CRÍTICO
        PasoScheduling(
          id: 'aderezo3',
          nombre: 'Preparar aderezo3',
          duracion: 240,
          tipoCocinero: 'normal',
          tipoUtensilio: 'bowl',
          dependencias: [],
        ),
        
        // Lavar lechuga (0 dependencias)
        PasoScheduling(
          id: 'lechuga',
          nombre: 'Lavar lechuga',
          duracion: 180,
          tipoCocinero: 'normal',
          tipoUtensilio: 'lavabo',
          dependencias: [],
        ),
        
        // Montar capas (depende de bizcochos y mascarpone) - CRÍTICO
        PasoScheduling(
          id: 'capas',
          nombre: 'Montar capas',
          duracion: 480,
          tipoCocinero: 'normal',
          tipoUtensilio: 'molde',
          dependencias: ['bizcochos', 'mascarpone'],
        ),
      ];

      cocineros = [
        CocineroScheduling(id: 'chef1', nombre: 'Chef1', tipo: 'normal'),
        CocineroScheduling(id: 'chef2', nombre: 'Chef2', tipo: 'normal'),
        CocineroScheduling(id: 'chef3', nombre: 'Chef3', tipo: 'normal'),
        CocineroScheduling(id: 'chef4', nombre: 'Chef4', tipo: 'normal'),
      ];

      utensilios = [
        UtensilioScheduling(id: 'cafetera1', nombre: 'Cafetera1', tipo: 'cafetera'),
        UtensilioScheduling(id: 'batidora1', nombre: 'Batidora1', tipo: 'batidora'),
        UtensilioScheduling(id: 'horno1', nombre: 'Horno1', tipo: 'horno'),
        UtensilioScheduling(id: 'molde1', nombre: 'Molde1', tipo: 'molde'),
        UtensilioScheduling(id: 'bowl1', nombre: 'Bowl1', tipo: 'bowl'),
        UtensilioScheduling(id: 'bowl2', nombre: 'Bowl2', tipo: 'bowl'),
        UtensilioScheduling(id: 'lavabo1', nombre: 'Lavabo1', tipo: 'lavabo'),
      ];
    });

    test('🔍 VALIDACIÓN INICIAL SCHEDULER', () {
      // 1. Crear y configurar scheduler
      final scheduler = SchedulingDinamicoAlgorithmOptimizado();
      
      // 2. Inicializar
      scheduler.inicializar(
        pasos: List.from(pasos),
        cocineros: List.from(cocineros),
        utensilios: List.from(utensilios),
      );
      
      expect(scheduler.estadoActual, isNotNull);
      expect(scheduler.estadoActual!.todosPasos.length, equals(pasos.length));
    });

    test('⚡ EJECUCIÓN COMPLETA SCHEDULER', () {
      // 1. Crear y configurar scheduler
      final scheduler = SchedulingDinamicoAlgorithmOptimizado();
      
      // 2. Inicializar
      scheduler.inicializar(
        pasos: List.from(pasos),
        cocineros: List.from(cocineros),
        utensilios: List.from(utensilios),
      );
      
      // 3. Ejecutar
      scheduler.ejecutarCompleto();
      
      // 4. Validar resultados
      expect(scheduler.estadoActual!.tiempoActual, lessThanOrEqualTo(1200),
        reason: 'El makespan debe ser menor o igual a 20 minutos');
        
      // Verificar que todos los pasos estén completados
      final pasosCompletados = scheduler.estadoActual!.todosPasos
        .where((p) => p.estado == EstadoPaso.completado)
        .length;
      expect(pasosCompletados, equals(pasos.length),
        reason: 'Todos los pasos deben estar completados');
        
      // Validar decisión crítica en T300
      final pasosEnT300 = scheduler.estadoActual!.todosPasos
        .where((p) => p.tiempoInicio == 300)
        .toList();
        
      if (pasosEnT300.isNotEmpty) {
        final pasoEnT300 = pasosEnT300.first;
        print('DECISIÓN EN T300: ${pasoEnT300.nombre}');
        
        // El paso ideal en T300 es 'Mojar bizcochos' (camino crítico)
        if (pasoEnT300.nombre.contains('bizcochos')) {
          print('✅ DECISIÓN ÓPTIMA: Se eligió el paso crítico');
        } else {
          print('⚠️ DECISIÓN SUBÓPTIMA: Se eligió ${pasoEnT300.nombre}');
        }
      }
      
      // Verificar makespan óptimo
      const optimalTheoretical = 960;
      final makespan = scheduler.estadoActual!.tiempoActual;
      final eficiencia = (optimalTheoretical / makespan * 100).toStringAsFixed(1);
      
      print('📊 RESULTADOS:');
      print('- Makespan: ${makespan}s');
      print('- Óptimo teórico: ${optimalTheoretical}s');
      print('- Eficiencia: ${eficiencia}%');
      
      expect(makespan, equals(optimalTheoretical),
        reason: 'El makespan debe alcanzar el óptimo teórico de 960s');
    });
  });
}
