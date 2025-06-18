import 'package:flutter/material.dart';
import 'receta_model.dart';
import 'receta_detalle_page.dart';
import 'compartir_receta_dialog.dart';
import 'realizar_receta_page.dart';

class AdministrarRecetasPage extends StatefulWidget {
  const AdministrarRecetasPage({super.key});

  @override
  State<AdministrarRecetasPage> createState() => _AdministrarRecetasPageState();
}

class _AdministrarRecetasPageState extends State<AdministrarRecetasPage> {
  List<Receta> recetas = [
    Receta(
      nombre: 'Tallarines Verdes',
      descripcion: 'Pasta con salsa de espinaca y albahaca.',
      ingredientes: ['Tallarines', 'Espinaca', 'Albahaca', 'Queso', 'Leche'],
      pasos: [
        'Cocer los tallarines',
        'Preparar la salsa verde',
        'Mezclar y servir'
      ],
      autor: 'Chef Mario',
    ),
    Receta(
      nombre: 'Arroz Chaufa',
      descripcion: 'Arroz frito al estilo chino-peruano.',
      ingredientes: ['Arroz', 'Pollo', 'Cebolla', 'Sillao', 'Huevo'],
      pasos: [
        'Freír el pollo',
        'Agregar arroz y verduras',
        'Añadir huevo y sillao',
        'Saltear y servir'
      ],
      autor: 'Chef Rosa',
    ),
  ];

  void _eliminarReceta(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 120),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Eliminar receta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Text('¿Estás seguro de eliminar esta receta?'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        recetas.removeAt(index);
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _editarReceta(int index) {
    final receta = recetas[index];
    final nombreController = TextEditingController(text: receta.nombre);
    final descripcionController = TextEditingController(text: receta.descripcion);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 120),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Editar Receta', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        recetas[index] = Receta(
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          ingredientes: receta.ingredientes,
                          pasos: receta.pasos,
                          autor: receta.autor,
                        );
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Recetas')),
      body: ListView.builder(
        itemCount: recetas.length,
        itemBuilder: (context, index) {
          final receta = recetas[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editar',
                          onPressed: () => _editarReceta(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarReceta(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.share, color: Colors.green),
                          tooltip: 'Compartir',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => CompartirRecetaDialog(receta: receta),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar preparación'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RealizarRecetaPage(receta: receta),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(minimumSize: const Size(180, 40)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
