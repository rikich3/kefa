import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para portapapeles
import 'receta_model.dart';

class CompartirRecetaDialog extends StatelessWidget {
  final Receta receta;
  const CompartirRecetaDialog({super.key, required this.receta});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Compartir Receta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo quieres compartir la receta?'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar texto de receta'),
            onPressed: () {
              final texto = _recetaComoTexto(receta);
              Clipboard.setData(ClipboardData(text: texto)); // Copia al portapapeles
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Receta copiada al portapapeles')),
              );
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Compartir por apps'),
            onPressed: () {
              // Aquí podrías integrar un paquete como share_plus para compartir
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad de compartir simulada')), // Simulación
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }

  String _recetaComoTexto(Receta receta) {
    return 'Receta: ${receta.nombre}\n\nDescripción: ${receta.descripcion}\n\nIngredientes:\n- ${receta.ingredientes.join('\n- ')}\n\nPasos:\n- ${receta.pasos.join('\n- ')}\n\nAutor: ${receta.autor}';
  }
}
