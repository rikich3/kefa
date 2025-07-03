import '../trabajadores/trabajador_model.dart';
import 'tarea_model.dart';

/// Lógica de asignación automática de tareas a trabajadores.
class AsignadorTareas {
  /// Asigna tareas pendientes a los trabajadores disponibles según prioridad y carga de trabajo.
  ///
  /// [tareas]: Lista de tareas a asignar (pueden estar sin asignar).
  /// [trabajadores]: Lista de trabajadores disponibles.
  /// Devuelve una nueva lista de tareas con el campo trabajadorId asignado.
  static List<Tarea> asignarTareas({
    required List<Tarea> tareas,
    required List<Trabajador> trabajadores,
  }) {
    // Filtrar tareas pendientes y sin asignar
    final tareasPendientes = tareas.where((t) => t.estado == 'pendiente' && t.trabajadorId == null).toList();
    final tareasAsignadas = List<Tarea>.from(tareas.where((t) => t.trabajadorId != null));

    // Ordenar tareas por prioridad (1=alta primero)
    tareasPendientes.sort((a, b) => a.prioridad.compareTo(b.prioridad));

    // Inicializar mapa de carga de trabajo
    final carga = {for (var w in trabajadores) w.id: 0};
    for (var t in tareasAsignadas) {
      if (t.trabajadorId != null && carga.containsKey(t.trabajadorId!)) {
        carga[t.trabajadorId!] = carga[t.trabajadorId!]! + 1;
      }
    }

    // Asignar tareas pendientes al trabajador con menor carga
    for (var tarea in tareasPendientes) {
      // Puedes agregar lógica de especialidad aquí
      final trabajadorMenorCarga = carga.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
      tareasAsignadas.add(tarea.copyWith(trabajadorId: trabajadorMenorCarga));
      carga[trabajadorMenorCarga] = carga[trabajadorMenorCarga]! + 1;
    }

    return tareasAsignadas;
  }
}
