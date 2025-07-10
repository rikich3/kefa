import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/receta_provider.dart';
import 'crear_receta_page.dart';
import 'editar_receta_page.dart';

class RecetasModal extends StatefulWidget {
  const RecetasModal({super.key});

  @override
  State<RecetasModal> createState() => _RecetasModalState();
}

class _RecetasModalState extends State<RecetasModal> {
  @override
  void initState() {
    super.initState();
    // Forzar recarga de recetas cuando se abre el modal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecetaProvider>(context, listen: false).loadRecetas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 12),
              Text(
                'Gestión de Recetas',
                style: textTheme.headlineSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Botón crear nueva receta
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrearRecetaPage(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {}); // Refrescar la lista
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Nueva Receta'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Lista de recetas
          Expanded(
            child: Consumer<RecetaProvider>(
              builder: (context, provider, child) {
                if (provider.recetaEntries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 64,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay recetas creadas',
                          style: textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crea tu primera receta para comenzar',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: provider.recetaEntries.length,
                  itemBuilder: (context, index) {
                    final entry = provider.recetaEntries[index];
                    final receta = entry.value;
                    final key = entry.key;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            Icons.restaurant,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          receta.nombre,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(receta.descripcion),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${receta.cantidadPorciones} porciones',
                                  style: textTheme.bodySmall,
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.category,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  receta.categoria,
                                  style: textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          icon: const Icon(Icons.more_vert),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: const Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Editar'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'edit') {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditarRecetaPage(
                                    recetaParaEditar: receta,
                                    recetaKey: key,
                                  ),
                                ),
                              );
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            } else if (value == 'delete') {
                              _confirmarEliminarReceta(key, receta.nombre);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Botón cerrar
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminarReceta(dynamic key, String nombreReceta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Está seguro que desea eliminar la receta "$nombreReceta"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await Provider.of<RecetaProvider>(context, listen: false)
                      .deleteReceta(key);
                  if (mounted) {
                    Navigator.of(context).pop(); // Cerrar dialog
                    // No necesitamos setState aquí, el Consumer se actualiza automáticamente
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receta eliminada exitosamente')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.of(context).pop(); // Cerrar dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al eliminar receta: $e')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
