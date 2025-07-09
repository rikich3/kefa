import '../dataModels/paso.dart';

/// Representa una entrada en la agenda de un requisito (trabajador o utensilio)
class EntradaAgenda {
  final int tiempoInicio; // Tiempo en segundos desde el inicio
  final Paso paso;
  final String recetaNombre;
  final int recetaInstancia; // Número de instancia de la receta (1, 2, 3...)
  
  EntradaAgenda({
    required this.tiempoInicio,
    required this.paso,
    required this.recetaNombre,
    required this.recetaInstancia,
  });
  
  int get tiempoFin => tiempoInicio + paso.tiempoSegundos;
}

/// Representa la agenda completa de un requisito
class Agenda {
  final String requisitoId; // ID del trabajador o utensilio
  final String requisitoNombre;
  final TipoRequisito tipo;
  final List<EntradaAgenda> entradas;
  
  Agenda({
    required this.requisitoId,
    required this.requisitoNombre,
    required this.tipo,
    List<EntradaAgenda>? entradas,
  }) : entradas = entradas ?? [];
  
  /// Calcula el origen (tiempo en que se desocupa) del requisito
  int get origen {
    if (entradas.isEmpty) return 0;
    return entradas.map((e) => e.tiempoFin).reduce((a, b) => a > b ? a : b);
  }
  
  /// Agrega una entrada a la agenda manteniendo el orden cronológico
  void agregarEntrada(EntradaAgenda entrada) {
    entradas.add(entrada);
    entradas.sort((a, b) => a.tiempoInicio.compareTo(b.tiempoInicio));
  }
}

/// Tipo de requisito
enum TipoRequisito {
  trabajador,
  utensilio,
}

/// Representa un conjunto de requisitos para evaluar en el algoritmo
class ConjuntoRequisitos {
  final List<Agenda> agendas;
  
  ConjuntoRequisitos(this.agendas);
  
  /// Calcula el origen mínimo entre todos los requisitos del conjunto
  int get origenMinimo {
    if (agendas.isEmpty) return 0;
    return agendas.map((a) => a.origen).reduce((a, b) => a < b ? a : b);
  }
  
  /// Calcula el origen máximo entre todos los requisitos del conjunto
  int get origenMaximo {
    if (agendas.isEmpty) return 0;
    return agendas.map((a) => a.origen).reduce((a, b) => a > b ? a : b);
  }
  
  /// Calcula el overhead (diferencia entre origen máximo y mínimo)
  int get overhead => origenMaximo - origenMinimo;
}

/// Resultado del preprocesamiento de las recetas
class ResultadoPreprocesamiento {
  final Map<String, Agenda> agendasTrabajadores;
  final Map<String, Agenda> agendasUtensilios;
  final int tiempoTotalSegundos;
  
  ResultadoPreprocesamiento({
    required this.agendasTrabajadores,
    required this.agendasUtensilios,
    required this.tiempoTotalSegundos,
  });
  
  /// Obtiene todas las agendas combinadas
  List<Agenda> get todasLasAgendas => [
    ...agendasTrabajadores.values,
    ...agendasUtensilios.values,
  ];
  
  /// Obtiene todas las entradas ordenadas cronológicamente
  List<EntradaAgenda> get entradasCronologicas {
    final todasEntradas = <EntradaAgenda>[];
    for (final agenda in todasLasAgendas) {
      todasEntradas.addAll(agenda.entradas);
    }
    todasEntradas.sort((a, b) => a.tiempoInicio.compareTo(b.tiempoInicio));
    return todasEntradas;
  }
}
