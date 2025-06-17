import 'package:flutter/material.dart';
import 'receta_model.dart';
import 'compartir_receta_dialog.dart';
import 'realizar_receta_page.dart';

class RecetaDetallePage extends StatelessWidget {
  final Receta receta;
  const RecetaDetallePage({Key? key, required this.receta}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receta.nombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => CompartirRecetaDialog(receta: receta),
              );
            },
            tooltip: 'Compartir receta',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(receta.descripcion, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Ingredientes:', style: const TextStyle(fontWeight: FontWeight.bold)),
            ...receta.ingredientes.map((i) => Text('- $i')),
            const SizedBox(height: 16),
            Text('Pasos:', style: const TextStyle(fontWeight: FontWeight.bold)),
            ...receta.pasos.map((p) => Text('• $p')),
            const SizedBox(height: 16),
            Text('Autor: ${receta.autor}', style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            Center(
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
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
