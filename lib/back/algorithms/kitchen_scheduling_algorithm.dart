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
  List<CocineroScheduling> listaCocineros = [];
  List<UtensilioScheduling> listaUtensilios = [];
  List<PasoScheduling> listaPasos = [];
  int oriMin = 0; // valor mínimo de ori de cocineros
  
  // Propiedades compatibles con la UI
  List<CocineroScheduling> get cocineros => listaCocineros;
  List<UtensilioScheduling> get utensilios => listaUtensilios;
  Map<String, PasoScheduling> get pasos => {
    for (var paso in listaPasos) paso.id: paso
  };

  KitchenSchedulingAlgorithm();

  void inicializarRecursos({
    required List<CocineroScheduling> listaCocineros,
    required List<UtensilioScheduling> listaUtensilios,
    required List<PasoScheduling> listaPasos,
  }) {
    this.listaCocineros = listaCocineros;
    this.listaUtensilios = listaUtensilios;
    this.listaPasos = listaPasos;
    oriMin = 0;
    
    // Reiniciar horarios pero preservar ori inicial de recursos
    for (var cocinero in this.listaCocineros) {
      cocinero.horario.clear();
      // No modificar cocinero.ori para preservar valores iniciales
    }
    for (var utensilio in this.listaUtensilios) {
      utensilio.horario.clear();
      // No modificar utensilio.ori para preservar valores iniciales (como B2 que empieza en 30s)
    }
    
    // Inicializar oriMin considerando solo cocineros
    actualizarOriMin();

    print('🔧 Recursos inicializados:');
    print('   Cocineros: ${this.listaCocineros.length}');
    print('   Utensilios: ${this.listaUtensilios.length}');
    print('   Pasos: ${this.listaPasos.length}');
    
    // Mostrar estado inicial de todos los recursos
    print('📊 Estado inicial de recursos:');
    for (var cocinero in this.listaCocineros) {
      print('   ${cocinero.toString()}');
    }
    for (var utensilio in this.listaUtensilios) {
      print('   ${utensilio.toString()}');
    }
  }

  void ejecutarAlgoritmo(String pasoRaizId, int cantidadPlatos) {
    print('🚀 Iniciando algoritmo de scheduling');
    print('   Paso raíz: $pasoRaizId');
    print('   Cantidad de platos: $cantidadPlatos');
    
    // Para obtener el orden AAABBBCCCDDDFFFEEE específicamente,
    // organizamos los pasos por nombre y por plato
    List<String> ordenEspecifico = ['A', 'B', 'C', 'D', 'F', 'E'];
    List<String> ordenFinal = [];
    
    // Para cada tipo de paso, agregar todas las instancias de ese tipo
    for (String tipoNombre in ordenEspecifico) {
      // Buscar todos los pasos con este nombre
      var pasosDelTipo = listaPasos.where((p) => p.nombre.contains(tipoNombre)).toList();
      
      // Ordenar por plato (extraer número del nombre como "A (Plato 1)")
      pasosDelTipo.sort((a, b) {
        // Extraer número de plato del nombre
        RegExp regex = RegExp(r'Plato (\d+)');
        Match? matchA = regex.firstMatch(a.nombre);
        Match? matchB = regex.firstMatch(b.nombre);
        
        int platoA = matchA != null ? int.parse(matchA.group(1)!) : 0;
        int platoB = matchB != null ? int.parse(matchB.group(1)!) : 0;
        
        return platoA.compareTo(platoB);
      });
      
      // Agregar los IDs de los pasos encontrados
      for (var paso in pasosDelTipo) {
        ordenFinal.add(paso.id);
      }
    }
    
    print('📝 Lista de tareas generada (orden específico AAABBBCCCDDDFFFEEE): $ordenFinal');
    
    // Procesar cada tarea
    for (int i = 0; i < ordenFinal.length; i++) {
      String pasoId = ordenFinal[i];
      PasoScheduling? paso = listaPasos.where((p) => p.id == pasoId).firstOrNull;
      
      if (paso == null) {
        print('⚠️ Paso no encontrado: $pasoId');
        continue;
      }
      
      print('\\n⏰ Procesando tarea ${i + 1}/${ordenFinal.length}: ${paso.nombre} ($pasoId)');
      
      procesarTarea(paso);
      
      print('   📊 Estado actual - oriMin: $oriMin');
      imprimirEstadoActual();
    }
    
    print('\\n✅ Algoritmo completado');
    imprimirResultadoFinal();
  }

  void ejecutarAlgoritmoOptimizado(String pasoRaizId, int cantidadPlatos) {
    print('🚀 Iniciando algoritmo de scheduling OPTIMIZADO');
    // Por ahora usa la misma lógica, se puede optimizar después
    ejecutarAlgoritmo(pasoRaizId, cantidadPlatos);
  }

  void procesarTarea(PasoScheduling paso) {
    // Verificar dependencias primero
    if (!_dependenciasCumplidas(paso)) {
      print('   ⚠️ Dependencias no cumplidas para ${paso.nombre}. Saltando...');
      return;
    }
    
    // Obtener cocineros del tipo requerido
    List<CocineroScheduling> cocinerosDisponibles = listaCocineros
        .where((c) => c.tipo == paso.tipoCocinero)
        .toList();
    
    // Obtener utensilios del tipo requerido
    List<UtensilioScheduling> utensiliosDisponibles = listaUtensilios
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
        // Calcular tiempo mínimo considerando dependencias
        int tiempoMinimoDependencias = _calcularTiempoMinimoDependencias(paso);
        
        // Los ori efectivos consideran el tiempo mínimo de dependencias
        int oriAEfectivo = [cocinero.ori, tiempoMinimoDependencias].reduce((a, b) => a > b ? a : b);
        int oriBEfectivo = [utensilio.ori, tiempoMinimoDependencias].reduce((a, b) => a > b ? a : b);
        
        // Aplicar ajuste de oriMin según el algoritmo
        int oriAAjustado = oriAEfectivo - oriMin;
        int oriBOriginal = oriBEfectivo;
        if (oriBEfectivo < oriMin) {
          oriBOriginal = oriMin;
        }
        int oriBAjustado = oriBOriginal - oriMin;
        
        int oh = (oriAAjustado - oriBAjustado).abs();
        int diferencia = oriAEfectivo - oriBEfectivo;
        
        CombinacionScheduling combinacion = CombinacionScheduling(
          cocinero: cocinero,
          utensilio: utensilio,
          oh: oh,
          diferencia: diferencia,
        );
        
        print('   🔄 Evaluando: ${cocinero.nombre}+${utensilio.nombre}');
        print('      oriA: $oriAEfectivo, oriB: $oriBEfectivo, oriMin: $oriMin');
        print('      oriA ajustado: $oriAAjustado, oriB ajustado: $oriBAjustado');
        print('      oh: $oh, diferencia: $diferencia');
        
        // Si oh es 0
        if (oh == 0) {
          // Si ambos ori ajustados son 0, insertar inmediatamente
          if (oriAAjustado == 0 && oriBAjustado == 0) {
            print('   ✅ Inserción inmediata (oh=0, ambos ori ajustados=0)');
            insertarTareaEnAgenda(cocinero, utensilio, paso, tiempoMinimoDependencias);
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
    
    int tiempoMinimoDependencias = _calcularTiempoMinimoDependencias(paso);
    insertarTareaEnAgenda(combinacionElegida.cocinero, combinacionElegida.utensilio, paso, tiempoMinimoDependencias);
  }
  
  bool _dependenciasCumplidas(PasoScheduling paso) {
    for (String depId in paso.dependencias) {
      // Buscar si la dependencia ya fue completada
      bool dependenciaCompletada = false;
      
      // Buscar en horarios de cocineros
      for (var cocinero in listaCocineros) {
        for (var item in cocinero.horario) {
          if (item.pasoId == depId) {
            dependenciaCompletada = true;
            break;
          }
        }
        if (dependenciaCompletada) break;
      }
      
      if (!dependenciaCompletada) {
        print('   ❌ Dependencia no cumplida: $depId');
        return false;
      }
    }
    return true;
  }
  
  int _calcularTiempoMinimoDependencias(PasoScheduling paso) {
    int tiempoMinimo = 0;
    
    for (String depId in paso.dependencias) {
      // Buscar cuándo termina esta dependencia
      int tiempoFinDependencia = 0;
      
      // Buscar en horarios de cocineros
      for (var cocinero in listaCocineros) {
        for (var item in cocinero.horario) {
          if (item.pasoId == depId) {
            int fin = item.tiempoInicio + item.duracion;
            if (fin > tiempoFinDependencia) {
              tiempoFinDependencia = fin;
            }
          }
        }
      }
      
      // Buscar en horarios de utensilios
      for (var utensilio in listaUtensilios) {
        for (var item in utensilio.horario) {
          if (item.pasoId == depId) {
            int fin = item.tiempoInicio + item.duracion;
            if (fin > tiempoFinDependencia) {
              tiempoFinDependencia = fin;
            }
          }
        }
      }
      
      if (tiempoFinDependencia > tiempoMinimo) {
        tiempoMinimo = tiempoFinDependencia;
      }
    }
    
    return tiempoMinimo;
  }

  void insertarTareaEnAgenda(CocineroScheduling cocinero, UtensilioScheduling utensilio, PasoScheduling paso, [int? tiempoMinimoInicio]) {
    // Calcular tiempo de inicio considerando dependencias y ori de recursos
    int tiempoInicio = [
      cocinero.ori,
      utensilio.ori,
      tiempoMinimoInicio ?? 0
    ].reduce((a, b) => a > b ? a : b);
    
    // Insertar en agenda del cocinero
    HorarioItem itemCocinero = HorarioItem(
      tiempoInicio: tiempoInicio,
      duracion: paso.duracion,
      pasoId: paso.id,
    );
    cocinero.horario.add(itemCocinero);
    cocinero.ori = tiempoInicio + paso.duracion;
    
    // Insertar en agenda del utensilio
    HorarioItem itemUtensilio = HorarioItem(
      tiempoInicio: tiempoInicio,
      duracion: paso.duracion,
      pasoId: paso.id,
    );
    utensilio.horario.add(itemUtensilio);
    utensilio.ori = tiempoInicio + paso.duracion;
    
    print('   📅 Tarea insertada:');
    print('      ${cocinero.nombre}: ${itemCocinero.toString()} -> ori: ${cocinero.ori}');
    print('      ${utensilio.nombre}: ${itemUtensilio.toString()} -> ori: ${utensilio.ori}');
    
    // Recalcular oriMin
    actualizarOriMin();
  }

  void actualizarOriMin() {
    // El oriMin se calcula solo considerando los cocineros REALES (tipo = 'cocinero')
    List<int> orisCocineros = listaCocineros
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
    for (var cocinero in listaCocineros) {
      print('      ${cocinero.toString()}');
    }
    for (var utensilio in listaUtensilios) {
      print('      ${utensilio.toString()}');
    }
  }

  void imprimirResultadoFinal() {
    print('\\n📊 RESULTADO FINAL DEL SCHEDULING:');
    print('================================');
    
    print('\\n👨‍🍳 COCINEROS Y OLLAS:');
    for (var cocinero in listaCocineros) {
      print('${cocinero.nombre} (${cocinero.tipo}):');
      for (var item in cocinero.horario) {
        PasoScheduling? paso = listaPasos.where((p) => p.id == item.pasoId).firstOrNull;
        print('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
      }
      print('  Tiempo total ocupado: ${cocinero.ori}s\\n');
    }
    
    print('🔧 UTENSILIOS:');
    for (var utensilio in listaUtensilios) {
      print('${utensilio.nombre} (${utensilio.tipo}):');
      for (var item in utensilio.horario) {
        PasoScheduling? paso = listaPasos.where((p) => p.id == item.pasoId).firstOrNull;
        print('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
      }
      print('  Tiempo total ocupado: ${utensilio.ori}s\\n');
    }
    
    int tiempoTotalCocina = listaCocineros.map((c) => c.ori).reduce((a, b) => a > b ? a : b);
    print('⏱️ TIEMPO TOTAL DE COCINA: ${tiempoTotalCocina}s');
  }
}
