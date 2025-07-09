import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../front/state/recetas_provider.dart';
import '../back/dataModels/receta.dart';
import '../back/system/sistema_preprocesamiento.dart';

class SeleccionRecetasWidget extends StatefulWidget {
  final List<RecetaConCantidad> recetasSeleccionadas;
  final Function(Receta, int) onAgregarReceta;
  final Function(int) onEliminarReceta;

  const SeleccionRecetasWidget({
    super.key,
    required this.recetasSeleccionadas,
    required this.onAgregarReceta,
    required this.onEliminarReceta,
  });

  @override
  State<SeleccionRecetasWidget> createState() => _SeleccionRecetasWidgetState();
}

class _SeleccionRecetasWidgetState extends State<SeleccionRecetasWidget> {
  void _mostrarDialogoSeleccion() {
    showDialog(
      context: context,
      builder: (context) => _DialogoSeleccionReceta(
        onSeleccionar: widget.onAgregarReceta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botón para agregar recetas
        OutlinedButton.icon(
          onPressed: _mostrarDialogoSeleccion,
          icon: const Icon(Icons.add),
          label: const Text('Agregar Receta'),
        ),
        
        const SizedBox(height: 16),
        
        // Lista de recetas seleccionadas
        if (widget.recetasSeleccionadas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.restaurant_menu_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay recetas seleccionadas',
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Agregue recetas para comenzar el preprocesamiento',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.recetasSeleccionadas.length,
            itemBuilder: (context, index) {
              final recetaConCantidad = widget.recetasSeleccionadas[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      '${recetaConCantidad.cantidad}x',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(recetaConCantidad.receta.nombre),
                  subtitle: Text(
                    '${recetaConCantidad.receta.pasos.length} pasos • '
                  ),
                  trailing: IconButton(
                    onPressed: () => widget.onEliminarReceta(index),
                    icon: const Icon(Icons.delete),
                    color: colorScheme.error,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  
  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final seg = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }
}

class _DialogoSeleccionReceta extends StatefulWidget {
  final Function(Receta, int) onSeleccionar;

  const _DialogoSeleccionReceta({
    required this.onSeleccionar,
  });

  @override
  State<_DialogoSeleccionReceta> createState() => _DialogoSeleccionRecetaState();
}

class _DialogoSeleccionRecetaState extends State<_DialogoSeleccionReceta> {
  Receta? _recetaSeleccionada;
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Receta',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            
            // Selector de receta
            Text('Receta:', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Consumer<RecetasProvider>(
              builder: (context, recetasProvider, child) {
                if (recetasProvider.recetas.isEmpty) {
                  return const Text('No hay recetas disponibles');
                }
                
                return DropdownButtonFormField<Receta>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: _recetaSeleccionada,
                  hint: const Text('Seleccionar receta'),
                  items: recetasProvider.recetas.map((receta) {
                    return DropdownMenuItem(
                      value: receta,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(receta.nombre),
                          Text(
                            '${receta.pasos.length} pasos',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (receta) {
                    setState(() {
                      _recetaSeleccionada = receta;
                    });
                  },
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Selector de cantidad
            Text('Cantidad:', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _cantidad > 1 ? () {
                    setState(() {
                      _cantidad--;
                    });
                  } : null,
                  icon: const Icon(Icons.remove),
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$_cantidad',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _cantidad < 10 ? () {
                    setState(() {
                      _cantidad++;
                    });
                  } : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _recetaSeleccionada != null ? () {
                    widget.onSeleccionar(_recetaSeleccionada!, _cantidad);
                    Navigator.pop(context);
                  } : null,
                  child: const Text('Agregar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final seg = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }
}
