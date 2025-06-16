import 'package:flutter/material.dart';

class Utensilio {
  final String nombre;
  final int cantidadMaxima;
  int disponibles;
  int enUso;
  int enLavadero;
  List<String> usuariosEnUso;

  Utensilio({
    required this.nombre,
    this.cantidadMaxima = 3,
    this.disponibles = 3,
    this.enUso = 0,
    this.enLavadero = 0,
    List<String>? usuariosEnUso,
  }) : usuariosEnUso = usuariosEnUso ?? [];
}

class UtensiliosPage extends StatefulWidget {
  const UtensiliosPage({super.key});

  @override
  State<UtensiliosPage> createState() => _UtensiliosPageState();
}

class _UtensiliosPageState extends State<UtensiliosPage> {
  final List<Utensilio> _utensilios = [
    Utensilio(nombre: "Cuchillo", disponibles: 2, enUso: 1, enLavadero: 0, usuariosEnUso: ["Juan"]),
    Utensilio(nombre: "Tenedor", disponibles: 1, enUso: 1, enLavadero: 1, usuariosEnUso: ["Ana"]),
    Utensilio(nombre: "Sartén", disponibles: 3, enUso: 0, enLavadero: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Disponible')),
          DataColumn(label: Text('En uso')),
          DataColumn(label: Text('Lavadero')),
          DataColumn(label: Text('Usuario(s)')),
        ],
        rows: _utensilios.map((u) {
          return DataRow(cells: [
            DataCell(Text(u.nombre)),
            DataCell(Text('${u.disponibles}')),
            DataCell(Text('${u.enUso}')),
            DataCell(Text('${u.enLavadero}')),
            DataCell(Text(u.usuariosEnUso.isNotEmpty ? u.usuariosEnUso.join(', ') : '-')),
          ]);
        }).toList(),
      ),
    );
  }
}
