import 'dart:async';

// Mover a features/trabajadores/trabajador_model.dart

class Trabajador {
  final String nombre;
  final String rol;
  List<String> especialidades;
  String? tareaAsignada;
  DateTime? tareaAsignadaInicio;
  Duration? duracionTarea;
  Timer? timer;
  Duration tiempoRestante;

  Trabajador({
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
  Trabajador(nombre: 'Juan Pérez', rol: 'Cocinero', especialidades: ['Parrilla', 'Pastas']),
  Trabajador(nombre: 'Ana López', rol: 'Ayudante', especialidades: ['Fríos', 'Postres']),
  Trabajador(nombre: 'Luis Torres', rol: 'Chef', especialidades: ['General']),
  Trabajador(nombre: 'Pedro García', rol: 'Lavaplatos', especialidades: ['Limpieza']),
  Trabajador(nombre: 'María Ruiz', rol: 'Pastelera', especialidades: ['Postres']),
];
