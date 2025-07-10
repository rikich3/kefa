import '../../back/dataModels/paso.dart';
import '../../back/dataModels/receta.dart';
import '../../back/dataModels/instrumentos.dart';
import '../../back/dataModels/worker.dart';
import 'dart:collection';

/// Representa una tarea asignada a un cocinero con toda la información necesaria para la agenda.
class TareaCocinaOptimizada {
  final String id;
  final String cocineroId;
  final String nombreTarea;
  final String descripcion;
  final List<String> utensiliosRequeridos;
  final int tiempoInicioSegundos;
  final int duracionSegundos;
  final int orden;
  final DateTime fechaAsignacion;

  TareaCocinaOptimizada({
    required this.id,
    required this.cocineroId,
    required this.nombreTarea,
    required this.descripcion,
    required this.utensiliosRequeridos,
    required this.tiempoInicioSegundos,
    required this.duracionSegundos,
    required this.orden,
    required this.fechaAsignacion,
  });
}

/// Algoritmo de scheduling optimizado para cocina con lógica de lotes y dependencias.
class AlgoritmoCocinaOptimizado {
  final List<Paso> pasos;
  final List<Worker> cocineros;
  final List<Instrumento> utensilios;
  final int cantidadPlatos;

  AlgoritmoCocinaOptimizado({
    required this.pasos,
    required this.cocineros,
    required this.utensilios,
    required this.cantidadPlatos,
  });

  /// Ejecuta el algoritmo y retorna la lista de tareas optimizadas para todos los cocineros.
  List<TareaCocinaOptimizada> generarAgenda() {
    // 1. Agrupar pasos por tipo de utensilio y lotear según capacidad
    // 2. Resolver dependencias: un paso no puede empezar hasta que sus dependencias estén listas
    // 3. Asignar tareas a cocineros de forma balanceada
    // 4. Minimizar makespan (tiempo total)
    // ---
    // Para simplificar, se asume que todos los pasos tienen utensilio y cocinero asignable
    // y que los pasos de almacenamiento pueden agrupar varios platos según capacidad

    // Paso 1: Agrupar pasos por receta y por lote
    final List<_PasoLoteado> pasosLoteados = _generarLoteoDePasos();

    // Paso 2: Resolver dependencias y calcular tiempos de inicio
    final List<_PasoLoteado> pasosOrdenados = _resolverDependenciasYCalcularTiempos(pasosLoteados);

    // Paso 3: Asignar tareas a cocineros (round robin simple)
    final List<TareaCocinaOptimizada> tareas = _asignarTareasACocineros(pasosOrdenados);

    return tareas;
  }

  List<_PasoLoteado> _generarLoteoDePasos() {
    final List<_PasoLoteado> resultado = [];
    for (final paso in pasos) {
      final instrumento = utensilios.firstWhere(
        (u) => u.nombre == paso.tipoUtensilio,
        orElse: () => Instrumento(nombre: paso.tipoUtensilio ?? '-', id: 0, descripcion: '', cantidad: 1, tipo: 'Normal', capacidadMaximaKg: null),
      );
      final capacidad = instrumento.capacidadMaximaKg ?? double.infinity;
      final cantidadTotal = cantidadPlatos.toDouble();
      if (instrumento.tipo == 'Almacenamiento' && capacidad < double.infinity) {
        // Solo lotear si es de almacenamiento y tiene capacidad definida
        int lotes = (cantidadTotal / capacidad).ceil();
        for (int i = 0; i < lotes; i++) {
          final cantidadLote = (i == lotes - 1) ? (cantidadTotal - capacidad * (lotes - 1)) : capacidad;
          resultado.add(_PasoLoteado(
            paso: paso,
            lote: i + 1,
            totalLotes: lotes,
            cantidad: cantidadLote,
          ));
        }
      } else {
        // Si NO es de almacenamiento, crear una instancia por cada plato
        for (int i = 0; i < cantidadPlatos; i++) {
          resultado.add(_PasoLoteado(
            paso: paso,
            lote: i + 1,
            totalLotes: cantidadPlatos,
            cantidad: 1,
          ));
        }
      }
    }
    return resultado;
  }

  List<_PasoLoteado> _resolverDependenciasYCalcularTiempos(List<_PasoLoteado> pasosLoteados) {
    final List<_PasoLoteado> ordenados = [];
    final Set<String> completados = {};
    final Map<String, int> tiemposFin = {};
    final Map<String, _PasoLoteado> idToPaso = {for (var p in pasosLoteados) p.paso.id + '_lote${p.lote}': p};

    while (ordenados.length < pasosLoteados.length) {
      bool progreso = false;
      for (final pasoLote in pasosLoteados) {
        final idLote = pasoLote.paso.id + '_lote${pasoLote.lote}';
        if (ordenados.contains(pasoLote)) continue;
        final deps = pasoLote.paso.dependencias ?? [];
        // Verificar que TODOS los lotes de cada dependencia estén completados
        bool depsCompletadas = deps.every((depId) {
          final lotesDep = pasosLoteados.where((pl) => pl.paso.id == depId);
          return lotesDep.isNotEmpty && lotesDep.every((pl) => completados.contains(pl.paso.id + '_lote${pl.lote}'));
        });
        if (depsCompletadas) {
          // El paso puede empezar cuando TODAS las dependencias (todos sus lotes) estén listas
          final inicio = deps.map((depId) {
            final lotesDep = pasosLoteados.where((pl) => pl.paso.id == depId);
            if (lotesDep.isEmpty) return 0;
            // El tiempo de inicio es el máximo tiempo de fin de todos los lotes de la dependencia
            return lotesDep.map((pl) => pl.tiempoFin ?? 0).fold(0, (a, b) => a > b ? a : b);
          }).fold(0, (a, b) => a > b ? a : b);
          pasoLote.tiempoInicio = inicio;
          pasoLote.tiempoFin = inicio + pasoLote.paso.tiempoCoccionSegundos + pasoLote.paso.tiempoPreparacionSegundos;
          ordenados.add(pasoLote);
          completados.add(idLote);
          tiemposFin[idLote] = pasoLote.tiempoFin!;
          progreso = true;
        }
      }
      if (!progreso) break;
    }
    return ordenados;
  }

  List<TareaCocinaOptimizada> _asignarTareasACocineros(List<_PasoLoteado> pasosOrdenados) {
    final List<TareaCocinaOptimizada> tareas = [];
    int idxCocinero = 0;
    int orden = 1;
    for (final pasoLote in pasosOrdenados) {
      final cocinero = cocineros[idxCocinero % cocineros.length];
      tareas.add(TareaCocinaOptimizada(
        id: '${cocinero.nombre}_${pasoLote.paso.id}_${DateTime.now().millisecondsSinceEpoch}',
        cocineroId: cocinero.nombre,
        nombreTarea: pasoLote.paso.nombrePaso + (pasoLote.totalLotes > 1 ? ' (Lote ${pasoLote.lote}/${pasoLote.totalLotes})' : ''),
        descripcion: pasoLote.paso.contenidoAccion,
        utensiliosRequeridos: [pasoLote.paso.tipoUtensilio ?? '-'],
        tiempoInicioSegundos: pasoLote.tiempoInicio ?? 0,
        duracionSegundos: (pasoLote.paso.tiempoCoccionSegundos + pasoLote.paso.tiempoPreparacionSegundos),
        orden: orden++,
        fechaAsignacion: DateTime.now(),
      ));
      idxCocinero++;
    }
    return tareas;
  }
}

class _PasoLoteado {
  final Paso paso;
  final int lote;
  final int totalLotes;
  final double cantidad;
  int? tiempoInicio;
  int? tiempoFin;
  _PasoLoteado({
    required this.paso,
    required this.lote,
    required this.totalLotes,
    required this.cantidad,
    this.tiempoInicio,
    this.tiempoFin,
  });
}
