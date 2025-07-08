import 'package:flutter_test/flutter_test.dart';
import 'package:kefa/back/algorithms/scheduling_dinamico_algorithm.dart';
import 'package:kefa/back/dataModels/paso_scheduling.dart';
import 'package:kefa/back/dataModels/cocinero_scheduling.dart';
import 'package:kefa/back/dataModels/utensilio_scheduling.dart';

void main() {
  group('Análisis de Optimalidad del Algoritmo Dinámico', () {
    late SchedulingDinamicoAlgorithm algorithm;

    setUp(() {
      algorithm = SchedulingDinamicoAlgorithm();
    });

    test('Análisis con 6 cocineros - Verificación de límites teóricos', () {
      print('\n=== ANÁLISIS CON 6 COCINEROS ===');
      
      // Crear pasos basados en nuestras recetas de prueba
      final pasos = _crearPasosDeTest();
      final cocineros = _crearCocineros(6);
      final utensilios = _crearUtensilios();
      
      // Calcular límites teóricos
      final trabajoTotal = _calcularTrabajoTotal();
      final caminoCritico = _calcularCaminoCritico();
      final limitePorTrabajo = trabajoTotal / 6;
      final limiteInferior = caminoCritico > limitePorTrabajo ? caminoCritico : limitePorTrabajo;
      
      print('Trabajo total: ${trabajoTotal}s');
      print('Camino crítico: ${caminoCritico}s');
      print('Límite por trabajo (6 chefs): ${limitePorTrabajo.toStringAsFixed(1)}s');
      print('Límite inferior teórico: ${limiteInferior.toStringAsFixed(1)}s');
      
      // Ejecutar algoritmo
      algorithm.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );
      
      algorithm.ejecutarCompleto();
      final makespan = algorithm.estadoActual!.tiempoActual;
      final gap = makespan - limiteInferior;
      final porcentajeGap = (gap / limiteInferior) * 100;
      
      print('Makespan obtenido: ${makespan}s');
      print('Gap vs límite teórico: ${gap.toStringAsFixed(1)}s (${porcentajeGap.toStringAsFixed(1)}%)');
      
      // Verificar que es razonablemente óptimo (menos del 25% sobre el límite)
      expect(porcentajeGap, lessThan(25.0), 
        reason: 'El algoritmo debería estar dentro del 25% del óptimo teórico');
      
      _analizarUtilizacionRecursos(algorithm, 6);
    });

    test('Análisis con 7 cocineros - Rendimientos decrecientes', () {
      print('\n=== ANÁLISIS CON 7 COCINEROS ===');
      
      // Crear pasos basados en nuestras recetas de prueba
      final pasos = _crearPasosDeTest();
      final cocineros = _crearCocineros(7);
      final utensilios = _crearUtensilios();
      
      // Calcular límites teóricos
      final trabajoTotal = _calcularTrabajoTotal();
      final caminoCritico = _calcularCaminoCritico();
      final limitePorTrabajo = trabajoTotal / 7;
      final limiteInferior = caminoCritico > limitePorTrabajo ? caminoCritico : limitePorTrabajo;
      
      print('Trabajo total: ${trabajoTotal}s');
      print('Camino crítico: ${caminoCritico}s');
      print('Límite por trabajo (7 chefs): ${limitePorTrabajo.toStringAsFixed(1)}s');
      print('Límite inferior teórico: ${limiteInferior.toStringAsFixed(1)}s');
      
      // Ejecutar algoritmo
      algorithm.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );
      
      algorithm.ejecutarCompleto();
      final makespan = algorithm.estadoActual!.tiempoActual;
      final gap = makespan - limiteInferior;
      final porcentajeGap = (gap / limiteInferior) * 100;
      
      print('Makespan obtenido: ${makespan}s');
      print('Gap vs límite teórico: ${gap.toStringAsFixed(1)}s (${porcentajeGap.toStringAsFixed(1)}%)');
      
      // Con más chefs, debería ser aún más óptimo
      expect(porcentajeGap, lessThan(20.0), 
        reason: 'Con 7 chefs el algoritmo debería estar aún más cerca del óptimo');
      
      _analizarUtilizacionRecursos(algorithm, 7);
    });

    test('Comparación de rendimientos decrecientes', () {
      print('\n=== COMPARACIÓN DE RENDIMIENTOS ===');
      
      final pasos = _crearPasosDeTest();
      final utensilios = _crearUtensilios();
      
      final resultados = <int, int>{};
      
      for (int numChefs = 3; numChefs <= 8; numChefs++) {
        final cocineros = _crearCocineros(numChefs);
        
        final algorithmLocal = SchedulingDinamicoAlgorithm();
        algorithmLocal.setDebugMode(false); // Silenciar para resultados más limpios
        
        algorithmLocal.inicializar(
          pasos: List.from(pasos), // Copia para evitar mutación
          cocineros: cocineros,
          utensilios: List.from(utensilios), // Copia para evitar mutación
        );
        
        algorithmLocal.ejecutarCompleto();
        resultados[numChefs] = algorithmLocal.estadoActual!.tiempoActual;
      }
      
      print('Chefs\tMakespan\tMejora\tMejora%');
      for (int chefs = 3; chefs <= 8; chefs++) {
        final makespan = resultados[chefs]!;
        final mejora = chefs > 3 ? resultados[chefs-1]! - makespan : 0;
        final mejoraPorcentaje = chefs > 3 ? (mejora / resultados[chefs-1]!) * 100 : 0;
        
        print('$chefs\t${makespan}s\t\t${mejora}s\t${mejoraPorcentaje.toStringAsFixed(1)}%');
      }
      
      // Verificar que hay rendimientos decrecientes (cada chef adicional aporta menos)
      final mejora6a7 = resultados[6]! - resultados[7]!;
      final mejora7a8 = resultados[7]! - resultados[8]!;
      
      expect(mejora7a8, lessThanOrEqualTo(mejora6a7), 
        reason: 'Debería haber rendimientos decrecientes');
    });

    test('Análisis del camino crítico', () {
      print('\n=== ANÁLISIS DEL CAMINO CRÍTICO ===');
      
      final pasos = _crearPasosDeTest();
      final cocineros = _crearCocineros(6);
      final utensilios = _crearUtensilios();
      
      algorithm.inicializar(
        pasos: pasos,
        cocineros: cocineros,
        utensilios: utensilios,
      );
      
      algorithm.ejecutarCompleto();
      _analizarCaminoCritico(algorithm);
      
      // Verificar que todos los pasos se ejecutaron
      expect(algorithm.estadoActual!.pasosCompletados.length, equals(pasos.length));
      
      // Verificar que se respetaron las dependencias
      final pasoConDependencias = algorithm.estadoActual!.pasosCompletados
          .where((p) => p.dependenciasOriginales.isNotEmpty)
          .toList();
      
      for (final paso in pasoConDependencias) {
        for (final depId in paso.dependenciasOriginales) {
          final pasoDep = algorithm.estadoActual!.pasosCompletados
              .firstWhere((p) => p.id == depId);
          
          expect(paso.tiempoInicio!, greaterThanOrEqualTo(pasoDep.tiempoFin!),
              reason: 'Paso ${paso.id} debería iniciar después que ${depId} termine');
        }
      }
    });
  });
}

/// Crear pasos de test que simulan las recetas reales
List<PasoScheduling> _crearPasosDeTest() {
  return [
    // Pasta Carbonatada (2 platos)
    PasoScheduling(id: 'pasta_1', nombre: 'Batir huevos 1', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 180, dependencias: []),
    PasoScheduling(id: 'pasta_2', nombre: 'Batir huevos 2', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 180, dependencias: []),
    
    // Ensalada César (3 platos)
    PasoScheduling(id: 'ensalada_1_lavar', nombre: 'Lavar lechuga 1', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 180, dependencias: []),
    PasoScheduling(id: 'ensalada_1_crutones', nombre: 'Hacer Crutones 1', tipoCocinero: 'cocinero', tipoUtensilio: 'sarten', duracion: 480, dependencias: []),
    PasoScheduling(id: 'ensalada_1_aderezo', nombre: 'Preparar aderezo 1', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 240, dependencias: []),
    PasoScheduling(id: 'ensalada_1_armar', nombre: 'Armar ensalada 1', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 120, dependencias: ['ensalada_1_lavar', 'ensalada_1_crutones', 'ensalada_1_aderezo']),
    
    PasoScheduling(id: 'ensalada_2_lavar', nombre: 'Lavar lechuga 2', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 180, dependencias: []),
    PasoScheduling(id: 'ensalada_2_crutones', nombre: 'Hacer Crutones 2', tipoCocinero: 'cocinero', tipoUtensilio: 'sarten', duracion: 480, dependencias: []),
    PasoScheduling(id: 'ensalada_2_aderezo', nombre: 'Preparar aderezo 2', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 240, dependencias: []),
    PasoScheduling(id: 'ensalada_2_armar', nombre: 'Armar ensalada 2', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 120, dependencias: ['ensalada_2_lavar', 'ensalada_2_crutones', 'ensalada_2_aderezo']),
    
    PasoScheduling(id: 'ensalada_3_lavar', nombre: 'Lavar lechuga 3', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 180, dependencias: []),
    PasoScheduling(id: 'ensalada_3_crutones', nombre: 'Hacer Crutones 3', tipoCocinero: 'cocinero', tipoUtensilio: 'sarten', duracion: 480, dependencias: []),
    PasoScheduling(id: 'ensalada_3_aderezo', nombre: 'Preparar aderezo 3', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 240, dependencias: []),
    PasoScheduling(id: 'ensalada_3_armar', nombre: 'Armar ensalada 3', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 120, dependencias: ['ensalada_3_lavar', 'ensalada_3_crutones', 'ensalada_3_aderezo']),
    
    // Tiramisú Express (1 plato)
    PasoScheduling(id: 'tiramisu_cafe', nombre: 'Hacer café', tipoCocinero: 'cocinero', tipoUtensilio: 'cafetera', duracion: 300, dependencias: []),
    PasoScheduling(id: 'tiramisu_mascarpone', nombre: 'Batir Mascarpone', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 360, dependencias: []),
    PasoScheduling(id: 'tiramisu_bizcochos', nombre: 'Mojar bizcochos', tipoCocinero: 'cocinero', tipoUtensilio: 'bowl', duracion: 180, dependencias: ['tiramisu_cafe']),
    PasoScheduling(id: 'tiramisu_capas', nombre: 'Montar Capas', tipoCocinero: 'cocinero', tipoUtensilio: 'moldes', duracion: 480, dependencias: ['tiramisu_mascarpone', 'tiramisu_bizcochos']),
  ];
}

List<CocineroScheduling> _crearCocineros(int cantidad) {
  return List.generate(cantidad, (i) => 
      CocineroScheduling(id: 'chef_${i+1}', nombre: 'Chef ${i+1}', tipo: 'cocinero'));
}

List<UtensilioScheduling> _crearUtensilios() {
  return [
    // 5 bowls
    UtensilioScheduling(id: 'bowl_1', nombre: 'Bowl 1', tipo: 'bowl'),
    UtensilioScheduling(id: 'bowl_2', nombre: 'Bowl 2', tipo: 'bowl'),
    UtensilioScheduling(id: 'bowl_3', nombre: 'Bowl 3', tipo: 'bowl'),
    UtensilioScheduling(id: 'bowl_4', nombre: 'Bowl 4', tipo: 'bowl'),
    UtensilioScheduling(id: 'bowl_5', nombre: 'Bowl 5', tipo: 'bowl'),
    
    // 3 sartenes
    UtensilioScheduling(id: 'sarten_1', nombre: 'Sartén 1', tipo: 'sarten'),
    UtensilioScheduling(id: 'sarten_2', nombre: 'Sartén 2', tipo: 'sarten'),
    UtensilioScheduling(id: 'sarten_3', nombre: 'Sartén 3', tipo: 'sarten'),
    
    // 1 cafetera
    UtensilioScheduling(id: 'cafetera_1', nombre: 'Cafetera', tipo: 'cafetera'),
    
    // 1 moldes
    UtensilioScheduling(id: 'moldes_1', nombre: 'Moldes', tipo: 'moldes'),
  ];
}

int _calcularTrabajoTotal() {
  // Pasta: 2 × 180s = 360s
  // Ensalada: 3 × (180 + 480 + 240 + 120) = 3 × 1020s = 3060s
  // Tiramisú: 300 + 360 + 180 + 480 = 1320s
  return 360 + 3060 + 1320; // 4740s
}

int _calcularCaminoCritico() {
  // Camino crítico del Tiramisú: 300s (café) + 180s (bizcochos) + 480s (capas) = 960s
  // (Es el más largo entre todas las recetas)
  return 960;
}

void _analizarUtilizacionRecursos(SchedulingDinamicoAlgorithm algoritmo, int numChefs) {
  print('\n--- Análisis de Utilización de Recursos ---');
  
  final estado = algoritmo.estadoActual!;
  
  // Analizar utilización de sartenes (recurso crítico)
  final pasosSarten = estado.pasosCompletados.where((paso) => 
    paso.nombre.contains('Crutones')).toList();
  
  print('Pasos que usan Sartén:');
  for (final paso in pasosSarten) {
    print('  ${paso.nombre}: ${paso.tiempoInicio}s - ${paso.tiempoFin}s');
  }
  
  // Verificar paralelismo en sartenes
  final sartenesEnUso = <int, int>{}; // tiempo -> cantidad
  for (final paso in pasosSarten) {
    for (int t = paso.tiempoInicio!; t < paso.tiempoFin!; t++) {
      sartenesEnUso[t] = (sartenesEnUso[t] ?? 0) + 1;
    }
  }
  
  final maxSartenesUsadas = sartenesEnUso.values.isNotEmpty ? 
    sartenesEnUso.values.reduce((a, b) => a > b ? a : b) : 0;
  
  print('Máximo de sartenes usadas simultáneamente: $maxSartenesUsadas/3');
  
  print('Total de chefs usados: $numChefs');
  print('Makespan final: ${estado.tiempoActual}s');
}

void _analizarCaminoCritico(SchedulingDinamicoAlgorithm algoritmo) {
  print('\n--- Análisis del Camino Crítico Real ---');
  
  final estado = algoritmo.estadoActual!;
  
  // Encontrar el paso que termina último
  final ultimoPaso = estado.pasosCompletados.reduce((a, b) => a.tiempoFin! > b.tiempoFin! ? a : b);
  print('Último paso: ${ultimoPaso.nombre} (termina en ${ultimoPaso.tiempoFin}s)');
  
  // Encontrar secuencia del Tiramisú (camino crítico esperado)
  final pasosTiramisu = estado.pasosCompletados.where((paso) => 
    paso.nombre.contains('café') || 
    paso.nombre.contains('Mascarpone') ||
    paso.nombre.contains('bizcochos') ||
    paso.nombre.contains('Capas')).toList();
  
  pasosTiramisu.sort((a, b) => a.tiempoInicio!.compareTo(b.tiempoInicio!));
  
  print('Secuencia del Tiramisú (camino crítico):');
  for (final paso in pasosTiramisu) {
    print('  ${paso.nombre}: ${paso.tiempoInicio}s - ${paso.tiempoFin}s');
  }
}
