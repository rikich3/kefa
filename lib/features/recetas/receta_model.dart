class Receta {
  final String nombre;
  final String descripcion;
  final List<String> ingredientes;
  final List<String> pasos;
  final String autor;

  Receta({
    required this.nombre,
    required this.descripcion,
    required this.ingredientes,
    required this.pasos,
    required this.autor,
  });
}
