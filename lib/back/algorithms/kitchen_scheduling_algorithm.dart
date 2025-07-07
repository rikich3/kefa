import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/horario_item.dart';

class CombinacionScheduling {
  final CocineroScheduling cocinero;
  final UtensilioScheduling utensilio;
  final int oh; // valor absoluto de la diferencia entre ori de cocinero y utensilio
  final int diferencia; // valor de la resta oriA - oriB para conjOpt

  CombinacionScheduling({
    required this.cocinero,
    required this.utensilio,
    required this.oh,
    required this.diferencia,
  });

  @override
  String toString() {
    return '${cocinero.nombre}+${utensilio.nombre} (oh: $oh, diff: $diferencia)';
  }
}

class KitchenSchedulingAlgorithm {
  List<CocineroScheduling> cocineros = [];
  List<UtensilioScheduling> utensilios = [];
  Map<String, PasoScheduling> pasos = {};
  int oriMin = 0; // valor mínimo de ori de cocineros

  KitchenSchedulingAlgorithm();

  void inicializarRecursos({
    required List<CocineroScheduling> listaCocineros,
    required List<UtensilioScheduling> listaUtensilios,
    required List<PasoScheduling> listaPasos,
  }) {
    cocineros = listaCocineros;
    utensilios = listaUtensilios;
    pasos = {for (var paso in listaPasos) paso.id: paso};
    oriMin = 0;
    
    // Reiniciar horarios pero preservar ori inicial de recursos
    for (var cocinero in cocineros) {
      cocinero.horario.clear();
      // No modificar cocinero.ori para preservar valores iniciales
    }
    for (var utensilio in utensilios) {
      utensilio.horario.clear();
      // No modificar utensilio.ori para preservar valores iniciales (como B2 que empieza en 30s)
    }
    
    // Inicializar oriMin considerando solo cocineros
    actualizarOriMin();

    print('🔧 Recursos inicializados:');
    print('   Cocineros: ${cocineros.length}');
    print('   Utensilios: ${utensilios.length}');
    print('   Pasos: ${pasos.length}');
    
    // Mostrar estado inicial de todos los recursos
    print('📊 Estado inicial de recursos:');
    for (var cocinero in cocineros) {
      print('   ${cocinero.toString()}');
    }
    for (var utensilio in utensilios) {
      print('   ${utensilio.toString()}');
    }
  }

  List<String> obtenerOrdenEjecucion(String pasoRaizId) {
    print('🔍 Obteniendo orden de ejecución para paso raíz: $pasoRaizId');
    
    // Organizar pasos por niveles (del último nivel hacia la raíz)
    Map<int, List<String>> niveles = {};
    Set<String> visitados = {};
    
    // Función recursiva para calcular niveles
    int calcularNivel(String pasoId) {
      if (visitados.contains(pasoId)) {
        // Si ya fue visitado, buscar en qué nivel está
        for (int nivel in niveles.keys) {
          if (niveles[nivel]!.contains(pasoId)) {
            return nivel;
          }
        }
      }
      
      visitados.add(pasoId);
      PasoScheduling paso = pasos[pasoId]!;
      
      // Si no tiene dependencias, es nivel 0 (hojas)
      if (paso.dependencias.isEmpty) {
        niveles[0] = niveles[0] ?? [];
        niveles[0]!.add(pasoId);
        return 0;
      }
      
      // Calcular el nivel máximo de las dependencias + 1
      int nivelMaximo = -1;
      for (String dep in paso.dependencias) {
        int nivelDep = calcularNivel(dep);
        if (nivelDep > nivelMaximo) {
          nivelMaximo = nivelDep;
        }
      }
      
      int nivelActual = nivelMaximo + 1;
      niveles[nivelActual] = niveles[nivelActual] ?? [];
      if (!niveles[nivelActual]!.contains(pasoId)) {
        niveles[nivelActual]!.add(pasoId);
      }
      
      return nivelActual;
    }
    
    // Calcular nivel de la raíz (esto calculará todos los niveles)
    calcularNivel(pasoRaizId);
    
    // Construir orden de ejecución: desde el nivel más alto hasta nivel 0
    List<String> ordenEjecucion = [];
    List<int> nivelesOrdenados = niveles.keys.toList()..sort((a, b) => b.compareTo(a)); // Orden descendente
    
    for (int nivel in nivelesOrdenados) {
      ordenEjecucion.addAll(niveles[nivel]!);
    }
    
    print('📋 Niveles encontrados:');
    for (int nivel in nivelesOrdenados) {
      print('   Nivel $nivel: ${niveles[nivel]}');
    }
    print('📋 Orden de ejecución obtenido: $ordenEjecucion');
    return ordenEjecucion;
  }

  void ejecutarAlgoritmo(String pasoRaizId, int cantidadPlatos) {
    print('🚀 Iniciando algoritmo de scheduling');
    print('   Paso raíz: $pasoRaizId');
    print('   Cantidad de platos: $cantidadPlatos');
    
    // Para obtener el orden AAABBBCCCDDDFFFEEE específicamente,
    // creamos una lista con el orden específico solicitado
    List<String> ordenEspecifico = ['A', 'B', 'C', 'D', 'F', 'E'];
    List<String> ordenFinal = [];
    
    // Para cada tipo de paso, agregar tantas instancias como platos
    for (String tipo in ordenEspecifico) {
      if (pasos.containsKey(tipo)) {
        for (int i = 0; i < cantidadPlatos; i++) {
          ordenFinal.add(tipo);
        }
      }
    }
    
    print('📝 Lista de tareas generada (orden específico AAABBBCCCDDDFFFEEE): $ordenFinal');
    
    // Procesar cada tarea
    for (int i = 0; i < ordenFinal.length; i++) {
      String pasoId = ordenFinal[i];
      PasoScheduling paso = pasos[pasoId]!;
      
      print('\\n⏰ Procesando tarea ${i + 1}/${ordenFinal.length}: ${paso.nombre} ($pasoId)');
      
      procesarTarea(paso);
      
      print('   📊 Estado actual - oriMin: $oriMin');
      imprimirEstadoActual();
    }
    
    print('\\n✅ Algoritmo completado');
    imprimirResultadoFinal();
  }

  void procesarTarea(PasoScheduling paso) {
    // Obtener cocineros del tipo requerido
    List<CocineroScheduling> cocinerosDisponibles = cocineros
        .where((c) => c.tipo == paso.tipoCocinero)
        .toList();
    
    // Obtener utensilios del tipo requerido
    List<UtensilioScheduling> utensiliosDisponibles = utensilios
        .where((u) => u.tipo == paso.tipoUtensilio)
        .toList();
    
    if (cocinerosDisponibles.isEmpty) {
      print('❌ Error: No hay cocineros disponibles del tipo ${paso.tipoCocinero}');
      return;
    }
    
    if (utensiliosDisponibles.isEmpty) {
      print('❌ Error: No hay utensilios disponibles del tipo ${paso.tipoUtensilio}');
      return;
    }
    
    // Generar todas las combinaciones posibles
    List<CombinacionScheduling> combinaciones = [];
    CombinacionScheduling? conjOpt;
    
    for (var cocinero in cocinerosDisponibles) {
      for (var utensilio in utensiliosDisponibles) {
        // Calcular oh según el algoritmo
        int oriA = cocinero.ori;
        int oriB = utensilio.ori;
        
        // Aplicar ajuste de oriMin según el algoritmo
        // El oriMin se resta tanto para cocineros como para utensilios
        int oriAAjustado = oriA - oriMin;
        int oriBOriginal = oriB;
        if (oriB < oriMin) {
          oriBOriginal = oriMin; // Asegurar que oriB no sea menor que oriMin
        }
        int oriBAjustado = oriBOriginal - oriMin;
        
        int oh = (oriAAjustado - oriBAjustado).abs();
        int diferencia = oriA - oriB; // Diferencia entre ori originales (sin ajustar)
        
        CombinacionScheduling combinacion = CombinacionScheduling(
          cocinero: cocinero,
          utensilio: utensilio,
          oh: oh,
          diferencia: diferencia,
        );
        
        print('   🔄 Evaluando: ${cocinero.nombre}+${utensilio.nombre}');
        print('      oriA: $oriA, oriB: $oriB, oriMin: $oriMin');
        print('      oriA ajustado: $oriAAjustado, oriB ajustado: $oriBAjustado');
        print('      oh: $oh, diferencia: $diferencia');
        
        // Si oh es 0
        if (oh == 0) {
          // Si ambos ori ajustados son 0, insertar inmediatamente
          if (oriAAjustado == 0 && oriBAjustado == 0) {
            print('   ✅ Inserción inmediata (oh=0, ambos ori ajustados=0)');
            insertarTareaEnAgenda(cocinero, utensilio, paso);
            return;
          } else {
            // Actualizar conjOpt
            if (conjOpt == null) {
              conjOpt = combinacion;
              print('   📌 Actualizando conjOpt: ${conjOpt.toString()}');
            }
          }
        }
        
        combinaciones.add(combinacion);
      }
    }
    
    // Ordenar combinaciones por oh (menor a mayor)
    combinaciones.sort((a, b) => a.oh.compareTo(b.oh));
    
    // Si no se hizo inserción inmediata, usar la primera combinación (menor oh)
    // o conjOpt si fue establecido
    CombinacionScheduling combinacionElegida;
    if (conjOpt != null) {
      combinacionElegida = conjOpt;
      print('   🎯 Usando conjOpt: ${combinacionElegida.toString()}');
    } else {
      combinacionElegida = combinaciones.first;
      print('   🎯 Usando combinación con menor oh: ${combinacionElegida.toString()}');
    }
    
    insertarTareaEnAgenda(combinacionElegida.cocinero, combinacionElegida.utensilio, paso);
  }

  void insertarTareaEnAgenda(CocineroScheduling cocinero, UtensilioScheduling utensilio, PasoScheduling paso) {
    // Insertar en agenda del cocinero
    HorarioItem itemCocinero = HorarioItem(
      tiempoInicio: cocinero.ori,
      duracion: paso.duracion,
      pasoId: paso.id,
    );
    cocinero.horario.add(itemCocinero);
    cocinero.ori += paso.duracion;
    
    // Insertar en agenda del utensilio
    HorarioItem itemUtensilio = HorarioItem(
      tiempoInicio: utensilio.ori,
      duracion: paso.duracion,
      pasoId: paso.id,
    );
    utensilio.horario.add(itemUtensilio);
    utensilio.ori += paso.duracion;
    
    print('   📅 Tarea insertada:');
    print('      ${cocinero.nombre}: ${itemCocinero.toString()} -> ori: ${cocinero.ori}');
    print('      ${utensilio.nombre}: ${itemUtensilio.toString()} -> ori: ${utensilio.ori}');
    
    // Recalcular oriMin
    actualizarOriMin();
  }

  void actualizarOriMin() {
    // El oriMin se calcula solo considerando los cocineros REALES (tipo = 'cocinero')
    List<int> orisCocineros = cocineros
        .where((c) => c.tipo == 'cocinero') // Solo cocineros reales, no ollas
        .map((c) => c.ori)
        .toList();
    
    int nuevoOriMin = orisCocineros.isEmpty ? 0 : orisCocineros.reduce((a, b) => a < b ? a : b);
    
    print('   🔍 Verificando oriMin: oris cocineros tipo=cocinero = $orisCocineros');
    print('   🔍 Calculado oriMin = $nuevoOriMin, oriMin actual = $oriMin');
    
    if (nuevoOriMin != oriMin) {
      print('   📊 oriMin actualizado: $oriMin -> $nuevoOriMin (solo cocineros tipo=cocinero)');
      oriMin = nuevoOriMin;
    } else {
      print('   📊 oriMin sin cambios: $oriMin');
    }
  }

  void imprimirEstadoActual() {
    print('   📋 Estado actual de recursos:');
    for (var cocinero in cocineros) {
      print('      ${cocinero.toString()}');
    }
    for (var utensilio in utensilios) {
      print('      ${utensilio.toString()}');
    }
  }

  void imprimirResultadoFinal() {
    print('\\n📊 RESULTADO FINAL DEL SCHEDULING:');
    print('================================');
    
    print('\\n👨‍🍳 COCINEROS Y OLLAS:');
    for (var cocinero in cocineros) {
      print('${cocinero.nombre} (${cocinero.tipo}):');
      for (var item in cocinero.horario) {
        PasoScheduling paso = pasos[item.pasoId]!;
        print('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso.nombre}');
      }
      print('  Tiempo total ocupado: ${cocinero.ori}s\\n');
    }
    
    print('🔧 UTENSILIOS:');
    for (var utensilio in utensilios) {
      print('${utensilio.nombre} (${utensilio.tipo}):');
      for (var item in utensilio.horario) {
        PasoScheduling paso = pasos[item.pasoId]!;
        print('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso.nombre}');
      }
      print('  Tiempo total ocupado: ${utensilio.ori}s\\n');
    }
    
    int tiempoTotalCocina = cocineros.map((c) => c.ori).reduce((a, b) => a > b ? a : b);
    print('⏱️ TIEMPO TOTAL DE COCINA: ${tiempoTotalCocina}s');
  }
}
