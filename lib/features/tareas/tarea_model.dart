
/// Modelo de Tarea para la gestión y asignación automática en cocina profesional.
class Tarea {
  final String id;
  final String nombre;
  final String descripcion;
  final int prioridad; // 1 = alta, 2 = media, 3 = baja
  final String estado; // pendiente, en_progreso, completada, cancelada
  final String? trabajadorId; // id del trabajador asignado
  final String? recetaId; // id de la receta asociada (si aplica)
  final DateTime? inicio;
  final DateTime? fin;
  final Map<String, dynamic>? metadata; // Para extensibilidad (ej: métricas, etiquetas)

  Tarea({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.prioridad = 2,
    this.estado = 'pendiente',
    this.trabajadorId,
    this.recetaId,
    this.inicio,
    this.fin,
    this.metadata,
  });

  Tarea copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    int? prioridad,
    String? estado,
    String? trabajadorId,
    String? recetaId,
    DateTime? inicio,
    DateTime? fin,
    Map<String, dynamic>? metadata,
  }) {
    return Tarea(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      prioridad: prioridad ?? this.prioridad,
      estado: estado ?? this.estado,
      trabajadorId: trabajadorId ?? this.trabajadorId,
      recetaId: recetaId ?? this.recetaId,
      inicio: inicio ?? this.inicio,
      fin: fin ?? this.fin,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'prioridad': prioridad,
      'estado': estado,
      'trabajadorId': trabajadorId,
      'recetaId': recetaId,
      'inicio': inicio?.toIso8601String(),
      'fin': fin?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory Tarea.fromMap(Map<String, dynamic> map) {
    return Tarea(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      prioridad: map['prioridad'] ?? 2,
      estado: map['estado'] ?? 'pendiente',
      trabajadorId: map['trabajadorId'],
      recetaId: map['recetaId'],
      inicio: map['inicio'] != null ? DateTime.parse(map['inicio']) : null,
      fin: map['fin'] != null ? DateTime.parse(map['fin']) : null,
      metadata: map['metadata'],
    );
  }
}
