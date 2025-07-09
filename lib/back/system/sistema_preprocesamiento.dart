import '../dataModels/receta.dart';
import '../dataModels/paso.dart';
import '../dataModels/worker.dart';
import '../dataModels/instrumentos.dart';
import 'agenda_models.dart';

/// Representa una receta con la cantidad de veces que se debe realizar
class RecetaConCantidad {
  final Receta receta;
  final int cantidad;
  
  RecetaConCantidad({
    required this.receta,
    required this.cantidad,
  });
}

/// Maneja el preprocesamiento y generación de agendas
class SistemaPreprocesamiento {
  final List<Worker> trabajadoresDisponibles;
  final List<Instrumento> utensiliosDisponibles;
  
  // Agendas por requisito
  //nombre, agenda
  final Map<String, Agenda> _agendasTrabajadores = {};
  //cat(nombre,autoincrement), agenda
  final Map<String, Agenda> _agendasUtensilios = {};
  
  SistemaPreprocesamiento({
    required this.trabajadoresDisponibles,
    required this.utensiliosDisponibles,
  }) {
    _inicializarAgendas();
  }
  
  /// Inicializa las agendas vacías para todos los requisitos
  void _inicializarAgendas() {
    // Inicializar agendas de trabajadores
    for (final trabajador in trabajadoresDisponibles) {
      _agendasTrabajadores[trabajador.nombre] = Agenda(
        requisitoId: trabajador.id.toString(),
        requisitoNombre: trabajador.nombre,
        tipo: TipoRequisito.trabajador,
      );
    }
    
    // Inicializar agendas de utensilios
    for (final utensilio in utensiliosDisponibles) {
      _agendasUtensilios[utensilio.nombre] = Agenda(
        requisitoId: utensilio.id.toString(),
        requisitoNombre: utensilio.nombre,
        tipo: TipoRequisito.utensilio,
      );
    }
  }
  
  /// Ejecuta el preprocesamiento completo
  void preprocesar(List<RecetaConCantidad> recetasAProcesar) {
    // Limpiar agendas existentes
    _limpiarAgendas();
    
    // Procesar cada receta
    for (final recetaConCantidad in recetasAProcesar) {
      _procesarReceta(recetaConCantidad.receta, recetaConCantidad.cantidad);
    }
  }
  
  /// Limpia todas las agendas
  void _limpiarAgendas() {
    for (final agenda in _agendasTrabajadores.values) {
      agenda.entradas.clear();
    }
    for (final agenda in _agendasUtensilios.values) {
      agenda.entradas.clear();
    }
  }
  
  /// Procesa una receta específica
  void _procesarReceta(Receta receta, int cantidad) {
    for (int instancia = 1; instancia <= cantidad; instancia++) {
      for (final paso in receta.pasos) {
        _procesarPaso(paso, receta.nombre, instancia);
      }
    }
  }
  
  /// Procesa un paso específico aplicando el algoritmo
  void _procesarPaso(Paso paso, String recetaNombre, int instancia) {
    // 1. Calcular ori_min
    final oriMin = _calcularOriMin(paso);
    
    // 2. Formar conjuntos de requisitos y ordenarlos
    final conjuntos = _formarConjuntosRequisitos(paso);
    conjuntos.sort((a, b) => a.origenMinimo.compareTo(b.origenMinimo));
    
    // 3. Encontrar el conjunto óptimo
    ConjuntoRequisitos conjuntoOptimo = conjuntos.first;
    int ohMin = conjuntos.first.overhead;
    
    for (final conjunto in conjuntos) {
      final oh = conjunto.origenMaximo - oriMin;
      
      if (oh == 0) {
        conjuntoOptimo = conjunto;
        break;
      } else if (oh < ohMin) {
        ohMin = oh;
        conjuntoOptimo = conjunto;
      }
    }
    
    // 4. Agregar el paso a las agendas del conjunto óptimo
    final tiempoInicio = conjuntoOptimo.origenMaximo;
    final entrada = EntradaAgenda(
      tiempoInicio: tiempoInicio,
      paso: paso,
      recetaNombre: recetaNombre,
      recetaInstancia: instancia,
    );
    
    for (final agenda in conjuntoOptimo.agendas) {
      agenda.agregarEntrada(entrada);
    }
  }
  
  /// Calcula el origen mínimo entre los trabajadores necesarios para el paso
  int _calcularOriMin(Paso paso) {
    int oriMin = 0;
    
    for (final tipoTrabajador in paso.trabajadores) {
      final agenda = _agendasTrabajadores[tipoTrabajador];
      if (agenda != null) {
        if (oriMin == 0 || agenda.origen < oriMin) {
          oriMin = agenda.origen;
        }
      }
    }
    
    return oriMin;
  }
  
  /// Forma todos los conjuntos posibles de requisitos para el paso
  List<ConjuntoRequisitos> _formarConjuntosRequisitos(Paso paso) {
    final conjuntos = <ConjuntoRequisitos>[];
    
    // Obtener agendas de trabajadores necesarios
    final agendasTrabajadores = <Agenda>[];
    for (final tipoTrabajador in paso.trabajadores) {
      final agenda = _agendasTrabajadores[tipoTrabajador];
      if (agenda != null) {
        agendasTrabajadores.add(agenda);
      }
    }
    
    // Obtener agendas de utensilios necesarios
    final agendasUtensilios = <Agenda>[];
    for (int i = 0; i < paso.utensilioTipos.length; i++) {
      final tipoUtensilio = paso.utensilioTipos[i];
      final cantidadNecesaria = paso.utensilioCantidades[i];
      
      // Obtener todas las agendas disponibles de este tipo de utensilio
      final agendasDisponibles = _agendasUtensilios.values
          .where((agenda) => agenda.requisitoNombre == tipoUtensilio)
          .take(cantidadNecesaria)
          .toList();
      
      agendasUtensilios.addAll(agendasDisponibles);
    }
    
    // Por simplicidad, creamos un conjunto con todos los requisitos necesarios
    // En una implementación más compleja, se podrían generar múltiples combinaciones
    if (agendasTrabajadores.isNotEmpty || agendasUtensilios.isNotEmpty) {
      final todasLasAgendas = [...agendasTrabajadores, ...agendasUtensilios];
      conjuntos.add(ConjuntoRequisitos(todasLasAgendas));
    }
    
    return conjuntos;
  }
  
  /// Obtiene todas las agendas combinadas y ordenadas cronológicamente
  List<EntradaAgenda> obtenerAgendasCombinadas() {
    final todasLasEntradas = <EntradaAgenda>[];
    
    // Agregar entradas de trabajadores
    for (final agenda in _agendasTrabajadores.values) {
      todasLasEntradas.addAll(agenda.entradas);
    }
    
    // Agregar entradas de utensilios
    for (final agenda in _agendasUtensilios.values) {
      todasLasEntradas.addAll(agenda.entradas);
    }
    
    // Ordenar cronológicamente
    todasLasEntradas.sort((a, b) => a.tiempoInicio.compareTo(b.tiempoInicio));
    
    return todasLasEntradas;
  }
  
  /// Obtiene las agendas de trabajadores
  Map<String, Agenda> get agendasTrabajadores => Map.unmodifiable(_agendasTrabajadores);
  
  /// Obtiene las agendas de utensilios
  Map<String, Agenda> get agendasUtensilios => Map.unmodifiable(_agendasUtensilios);
  
  /// Obtiene el tiempo total estimado de ejecución
  int get tiempoTotalEstimado {
    int tiempoMaximo = 0;
    
    // Buscar el tiempo máximo entre todas las agendas
    for (final agenda in _agendasTrabajadores.values) {
      if (agenda.origen > tiempoMaximo) {
        tiempoMaximo = agenda.origen;
      }
    }
    
    for (final agenda in _agendasUtensilios.values) {
      if (agenda.origen > tiempoMaximo) {
        tiempoMaximo = agenda.origen;
      }
    }
    
    return tiempoMaximo;
  }
}
