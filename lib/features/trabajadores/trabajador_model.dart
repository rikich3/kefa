import 'dart:async';

// Mover a features/trabajadores/trabajador_model.dart

class Trabajador {
  final String id; // Identificador único
  final String nombre;
  final String rol;
  List<String> especialidades;
  String? tareaAsignada;
  DateTime? tareaAsignadaInicio;
  Duration? duracionTarea;
  Timer? timer;
  Duration tiempoRestante;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.rol,
    this.especialidades = const [],
    this.tareaAsignada,
    this.tareaAsignadaInicio,
    this.duracionTarea,
    this.timer,
    this.tiempoRestante = Duration.zero,
  });
}

// Lista simulada de trabajadores para la app
defaultTrabajadores() => [
  Trabajador(id: 't1', nombre: 'Juan Pérez', rol: 'Cocinero', especialidades: ['Parrilla', 'Pastas']),
  Trabajador(id: 't2', nombre: 'Ana López', rol: 'Ayudante', especialidades: ['Fríos', 'Postres']),
  Trabajador(id: 't3', nombre: 'Luis Torres', rol: 'Chef', especialidades: ['General']),
  Trabajador(id: 't4', nombre: 'Pedro García', rol: 'Lavaplatos', especialidades: ['Limpieza']),
  Trabajador(id: 't5', nombre: 'María Ruiz', rol: 'Pastelera', especialidades: ['Postres']),
];
