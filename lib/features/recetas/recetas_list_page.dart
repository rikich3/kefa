import 'package:flutter/material.dart';
import 'receta_model.dart';
import 'receta_detalle_page.dart';

class RecetasListPage extends StatelessWidget {
  RecetasListPage({super.key});

  final List<Receta> recetasCompartidas = [
    Receta(
      nombre: 'Lomo Saltado',
      descripcion: 'Plato típico peruano con carne, papas y verduras.',
      ingredientes: ['Carne', 'Papas', 'Cebolla', 'Tomate', 'Sillao'],
      pasos: [
        'Cortar la carne y las verduras',
        'Freír las papas',
        'Saltear la carne',
        'Agregar verduras y sillao',
        'Mezclar todo y servir'
      ],
      autor: 'Chef Juan',
    ),
    Receta(
      nombre: 'Ceviche',
      descripcion: 'Pescado marinado en limón con cebolla y ají.',
      ingredientes: ['Pescado', 'Limón', 'Cebolla', 'Ají', 'Cilantro'],
      pasos: [
        'Cortar el pescado en cubos',
        'Mezclar con jugo de limón',
        'Agregar cebolla y ají',
        'Dejar reposar',
        'Servir frío con cilantro'
      ],
      autor: 'Chef Ana',
    ),
    Receta(
      nombre: 'Aji de Gallina',
      descripcion: 'Plato cremoso de pollo deshilachado con ají amarillo.',
      ingredientes: ['Pollo', 'Ají amarillo', 'Pan', 'Leche', 'Nuez moscada'],
      pasos: [
        'Cocer el pollo y deshilachar',
        'Preparar la crema con pan y leche',
        'Saltear ají amarillo',
        'Mezclar todo y cocinar',
        'Servir con arroz y huevo duro'
      ],
      autor: 'Chef Luis',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recetas Compartidas')),
      body: ListView.builder(
        itemCount: recetasCompartidas.length,
        itemBuilder: (context, index) {
          final receta = recetasCompartidas[index];
          return Card(
            child: ListTile(
              title: Text(receta.nombre),
              subtitle: Text('Por: ${receta.autor}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecetaDetallePage(receta: receta),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
