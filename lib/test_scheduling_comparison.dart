// Test script to compare original vs optimized scheduling algorithms
import 'back/dataModels/cocinero_scheduling.dart';
import 'back/dataModels/utensilio_scheduling.dart';
import 'back/dataModels/paso_scheduling.dart';
import 'back/algorithms/kitchen_scheduling_algorithm.dart';

void testSchedulingComparison() {
  print('🧪 TESTING SCHEDULING ALGORITHM COMPARISON');
  print('==========================================\n');

  // Create test data
  List<CocineroScheduling> cocineros = [
    CocineroScheduling(id: '1', nombre: '1', tipo: 'cocinero', ori: 0),
    CocineroScheduling(id: '2', nombre: '2', tipo: 'cocinero', ori: 0),
  ];

  List<UtensilioScheduling> utensilios = [
    UtensilioScheduling(id: 'A1', nombre: 'A 1', tipo: 'A', ori: 0),
    UtensilioScheduling(id: 'B1', nombre: 'B 1', tipo: 'B', ori: 0),
    UtensilioScheduling(id: 'B2', nombre: 'B 2', tipo: 'B', ori: 0),
  ];

  List<PasoScheduling> pasos = [
    // Plato 1
    PasoScheduling(
      id: 'A_plato1',
      nombre: 'A (Plato 1)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'A',
      duracion: 10,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'B_plato1',
      nombre: 'B (Plato 1)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'B',
      duracion: 10,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'C_plato1',
      nombre: 'C (Plato 1)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'B',
      duracion: 10,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'D_plato1',
      nombre: 'D (Plato 1)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'A',
      duracion: 15,
      dependencias: ['A_plato1', 'B_plato1', 'C_plato1'],
    ),
    PasoScheduling(
      id: 'F_plato1',
      nombre: 'F (Plato 1)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'B',
      duracion: 12,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'E_plato1',
      nombre: 'E (Plato 1)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'A',
      duracion: 20,
      dependencias: ['D_plato1', 'F_plato1'],
    ),
    // Plato 2
    PasoScheduling(
      id: 'A_plato2',
      nombre: 'A (Plato 2)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'A',
      duracion: 10,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'B_plato2',
      nombre: 'B (Plato 2)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'B',
      duracion: 10,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'C_plato2',
      nombre: 'C (Plato 2)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'B',
      duracion: 10,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'D_plato2',
      nombre: 'D (Plato 2)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'A',
      duracion: 15,
      dependencias: ['A_plato2', 'B_plato2', 'C_plato2'],
    ),
    PasoScheduling(
      id: 'F_plato2',
      nombre: 'F (Plato 2)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'B',
      duracion: 12,
      dependencias: [],
    ),
    PasoScheduling(
      id: 'E_plato2',
      nombre: 'E (Plato 2)',
      tipoCocinero: 'cocinero',
      tipoUtensilio: 'A',
      duracion: 20,
      dependencias: ['D_plato2', 'F_plato2'],
    ),
  ];

  // Test 1: Original Algorithm
  print('🔵 TESTING ORIGINAL ALGORITHM');
  print('==============================');
  
  var algoritmoOriginal = KitchenSchedulingAlgorithm();
  algoritmoOriginal.inicializarRecursos(
    listaCocineros: _deepCopyCocineros(cocineros),
    listaUtensilios: _deepCopyUtensilios(utensilios),
    listaPasos: pasos,
  );
  
  algoritmoOriginal.ejecutarAlgoritmo('A_plato1', 2);
  
  // Get results
  var resultadoOriginal = _extractResults(algoritmoOriginal);
  
  print('\n' + '='*50 + '\n');
  
  // Test 2: Optimized Algorithm
  print('🟢 TESTING OPTIMIZED ALGORITHM');
  print('===============================');
  
  var algoritmoOptimizado = KitchenSchedulingAlgorithm();
  algoritmoOptimizado.inicializarRecursos(
    listaCocineros: _deepCopyCocineros(cocineros),
    listaUtensilios: _deepCopyUtensilios(utensilios),
    listaPasos: pasos,
  );
  
  algoritmoOptimizado.ejecutarAlgoritmoOptimizado('A_plato1', 2);
  
  // Get results
  var resultadoOptimizado = _extractResults(algoritmoOptimizado);
  
  print('\n' + '='*50 + '\n');
  
  // Compare results
  print('📊 COMPARISON RESULTS');
  print('=====================');
  print('Original Algorithm:');
  print('  Total time: ${resultadoOriginal['tiempoTotal']}s');
  print('  Cook balance: ${resultadoOriginal['balanceCocineros']}');
  print('  Cook 1 workload: ${resultadoOriginal['carga1']}s');
  print('  Cook 2 workload: ${resultadoOriginal['carga2']}s');
  
  print('\nOptimized Algorithm:');
  print('  Total time: ${resultadoOptimizado['tiempoTotal']}s');
  print('  Cook balance: ${resultadoOptimizado['balanceCocineros']}');
  print('  Cook 1 workload: ${resultadoOptimizado['carga1']}s');
  print('  Cook 2 workload: ${resultadoOptimizado['carga2']}s');
  
  print('\nImprovement:');
  int mejoraTiempo = resultadoOriginal['tiempoTotal'] - resultadoOptimizado['tiempoTotal'];
  double mejoraBalance = (resultadoOptimizado['balanceCocineros'] - resultadoOriginal['balanceCocineros']).abs();
  print('  Time saved: ${mejoraTiempo}s (${((mejoraTiempo / resultadoOriginal['tiempoTotal']) * 100).toStringAsFixed(1)}%)');
  print('  Balance improvement: ${mejoraBalance.toStringAsFixed(1)}s difference');
  
  if (mejoraTiempo > 0) {
    print('  ✅ OPTIMIZED ALGORITHM IS FASTER!');
  } else if (mejoraTiempo == 0) {
    print('  ⚖️ Same total time, but potentially better balance');
  } else {
    print('  ❓ Original algorithm was faster (this suggests room for improvement)');
  }
}

List<CocineroScheduling> _deepCopyCocineros(List<CocineroScheduling> original) {
  return original.map((c) => CocineroScheduling(
    id: c.id,
    nombre: c.nombre,
    tipo: c.tipo,
    ori: c.ori,
  )).toList();
}

List<UtensilioScheduling> _deepCopyUtensilios(List<UtensilioScheduling> original) {
  return original.map((u) => UtensilioScheduling(
    id: u.id,
    nombre: u.nombre,
    tipo: u.tipo,
    ori: u.ori,
  )).toList();
}

Map<String, dynamic> _extractResults(KitchenSchedulingAlgorithm algoritmo) {
  var cocineros = algoritmo.cocineros.where((c) => c.tipo == 'cocinero').toList();
  
  int tiempoTotal = cocineros.map((c) => c.ori).reduce((a, b) => a > b ? a : b);
  int carga1 = cocineros.firstWhere((c) => c.nombre == '1').ori;
  int carga2 = cocineros.firstWhere((c) => c.nombre == '2').ori;
  double balanceCocineros = (carga1 - carga2).abs().toDouble();
  
  return {
    'tiempoTotal': tiempoTotal,
    'carga1': carga1,
    'carga2': carga2,
    'balanceCocineros': balanceCocineros,
  };
}
