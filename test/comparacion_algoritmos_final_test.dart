import 'package:flutter_test/flutter_test.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm.dart';
import '../lib/back/algorithms/scheduling_dinamico_algorithm_optimizado.dart';
import '../lib/back/dataModels/paso_scheduling.dart';
import '../lib/back/dataModels/cocinero_scheduling.dart';
import '../lib/back/dataModels/utensilio_scheduling.dart';

void main() {
  group('🚀 COMPARACIÓN FINAL DE ALGORITMOS', () {
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
        CocineroScheduling(id: 'chef5', nombre: 'Chef5', tipo: 'normal'),
        CocineroScheduling(id: 'chef6', nombre: 'Chef6', tipo: 'normal'),
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

    test('📊 COMPARAR RENDIMIENTO: ALGORITMO DINÁMICO vs OPTIMIZADO', () {
      print('\n' + '='*60);
      print('🚀 COMPARACIÓN FINAL DE ALGORITMOS');
      print('='*60);
      
      // 1. EJECUTAR ALGORITMO DINÁMICO ESTÁNDAR
      print('\n🔄 EJECUTANDO ALGORITMO DINÁMICO ESTÁNDAR...');
      final algoritmoDinamico = SchedulingDinamicoAlgorithm();
      algoritmoDinamico.setDebugMode(false); // Silenciar debug para test limpio
      
      algoritmoDinamico.inicializar(
        pasos: List.from(pasos),
        cocineros: List.from(cocineros),
        utensilios: List.from(utensilios),
      );
      
      algoritmoDinamico.ejecutarCompleto();
      final makespanDinamico = algoritmoDinamico.estadoActual!.tiempoActual;
      
      // 2. EJECUTAR ALGORITMO OPTIMIZADO
      print('\n🚀 EJECUTANDO ALGORITMO OPTIMIZADO...');
      final algoritmoOptimizado = SchedulingDinamicoAlgorithmOptimizado();
      algoritmoOptimizado.setDebugMode(false); // Silenciar debug para test limpio
      
      algoritmoOptimizado.inicializar(
        pasos: List.from(pasos),
        cocineros: List.from(cocineros),
        utensilios: List.from(utensilios),
      );
      
      algoritmoOptimizado.ejecutarCompleto();
      final makespanOptimizado = algoritmoOptimizado.estadoActual!.tiempoActual;
      
      // 3. ANÁLISIS COMPARATIVO
      print('\n📊 RESULTADOS COMPARATIVOS:');
      print('='*40);
      print('⚙️  Algoritmo Dinámico Estándar: ${makespanDinamico}s');
      print('🚀 Algoritmo Optimizado:        ${makespanOptimizado}s');
      
      final mejora = makespanDinamico - makespanOptimizado;
      final porcentajeMejora = ((mejora / makespanDinamico) * 100).toStringAsFixed(1);
      
      if (mejora > 0) {
        print('✅ MEJORA: ${mejora}s (${porcentajeMejora}% más rápido)');
      } else if (mejora < 0) {
        print('⚠️  REGRESIÓN: ${mejora.abs()}s (${porcentajeMejora.replaceAll('-', '')}% más lento)');
      } else {
        print('🔄 IGUAL RENDIMIENTO: Sin diferencia');
      }
      
      // 4. ANÁLISIS DE DECISIONES CRÍTICAS
      print('\n🔍 ANÁLISIS DE DECISIONES EN T300:');
      _analizarDecisionCritica(algoritmoDinamico, 'DINÁMICO');
      _analizarDecisionCritica(algoritmoOptimizado, 'OPTIMIZADO');
      
      // 5. VERIFICACIONES
      print('\n✅ VERIFICACIONES:');
      
      // Verificar que el optimizado es mejor o igual
      expect(makespanOptimizado, lessThanOrEqualTo(makespanDinamico), 
        reason: 'El algoritmo optimizado debe ser igual o mejor que el dinámico estándar');
      
      // Verificar óptimo teórico (960s)
      const optimalTheoretical = 960;
      if (makespanOptimizado == optimalTheoretical) {
        print('🎯 ÓPTIMO ALCANZADO: ${makespanOptimizado}s = ${optimalTheoretical}s');
      } else {
        print('📍 DISTANCIA DEL ÓPTIMO: ${makespanOptimizado - optimalTheoretical}s');
      }
      
      // Verificar eficiencia
      final eficiencia = (optimalTheoretical / makespanOptimizado * 100).toStringAsFixed(1);
      print('📈 EFICIENCIA ALCANZADA: ${eficiencia}%');
      
      expect(makespanOptimizado, lessThanOrEqualTo(1200), 
        reason: 'El algoritmo optimizado debe completar en menos de 20 minutos');
      
      print('\n🏆 CONCLUSIÓN: ${makespanOptimizado <= optimalTheoretical ? "ÓPTIMO PERFECTO" : "MEJORA SIGNIFICATIVA"}');
      print('='*60);
    });

    test('📈 VERIFICAR ESCALABILIDAD CON DIFERENTES NÚMEROS DE COCINEROS', () {
      print('\n📈 TESTE DE ESCALABILIDAD...');
      
      final resultados = <int, Map<String, int>>{};
      
      for (int numCocineros = 4; numCocineros <= 8; numCocineros++) {
        print('\n🧪 Probando con $numCocineros cocineros...');
        
        final cocinerosTest = List.generate(numCocineros, (i) => 
          CocineroScheduling(id: 'chef${i+1}', nombre: 'Chef${i+1}', tipo: 'normal'));
        
        // Algoritmo dinámico
        final algoritmoDinamico = SchedulingDinamicoAlgorithm();
        algoritmoDinamico.setDebugMode(false);
        algoritmoDinamico.inicializar(
          pasos: List.from(pasos), 
          cocineros: List.from(cocinerosTest), 
          utensilios: List.from(utensilios)
        );
        algoritmoDinamico.ejecutarCompleto();
        final makespanDinamico = algoritmoDinamico.estadoActual!.tiempoActual;
        
        // Algoritmo optimizado
        final algoritmoOptimizado = SchedulingDinamicoAlgorithmOptimizado();
        algoritmoOptimizado.setDebugMode(false);
        algoritmoOptimizado.inicializar(
          pasos: List.from(pasos), 
          cocineros: List.from(cocinerosTest), 
          utensilios: List.from(utensilios)
        );
        algoritmoOptimizado.ejecutarCompleto();
        final makespanOptimizado = algoritmoOptimizado.estadoActual!.tiempoActual;
        
        resultados[numCocineros] = {
          'dinamico': makespanDinamico,
          'optimizado': makespanOptimizado,
        };
        
        print('  Dinámico: ${makespanDinamico}s | Optimizado: ${makespanOptimizado}s');
      }
      
      print('\n📊 RESUMEN DE ESCALABILIDAD:');
      print('Cocineros | Dinámico | Optimizado | Mejora');
      print('-' * 45);
      for (final entry in resultados.entries) {
        final num = entry.key;
        final dinamico = entry.value['dinamico']!;
        final optimizado = entry.value['optimizado']!;
        final mejora = dinamico - optimizado;
        print('${num.toString().padLeft(8)} | ${dinamico.toString().padLeft(8)} | ${optimizado.toString().padLeft(10)} | ${mejora.toString().padLeft(6)}s');
      }
    });
  });
}

void _analizarDecisionCritica(dynamic algoritmo, String nombre) {
  final estado = algoritmo.estadoActual!;
  
  // Buscar qué paso se ejecutó en T300
  final pasosEnT300 = estado.pasosCompletados
    .where((p) => p.tiempoInicio == 300)
    .toList();
  
  if (pasosEnT300.isNotEmpty) {
    final pasoEnT300 = pasosEnT300.first;
    print('$nombre T300: Ejecutó "${pasoEnT300.nombre}"');
    
    if (pasoEnT300.nombre.contains('bizcochos')) {
      print('  ✅ DECISIÓN CORRECTA: Eligió camino crítico');
    } else if (pasoEnT300.nombre.contains('aderezo3')) {
      print('  ❌ DECISIÓN SUBÓPTIMA: Eligió paso no crítico');
    } else {
      print('  🔄 DECISIÓN ALTERNATIVA: ${pasoEnT300.nombre}');
    }
  } else {
    print('$nombre T300: No se encontró paso ejecutado en T300');
  }
}
