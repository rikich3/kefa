import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/receta.dart';
import '../state/receta_provider.dart';
import 'crear_paso_page.dart';

class EditarRecetaPage extends StatefulWidget {
  final dynamic recetaKey;
  final Receta receta;

  const EditarRecetaPage({
    super.key,
    required this.recetaKey,
    required this.receta,
  });

  @override
  State<EditarRecetaPage> createState() => _EditarRecetaPageState();
}

class _EditarRecetaPageState extends State<EditarRecetaPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _porcionesController;
  late TextEditingController _duracionController;

  late String _categoriaSeleccionada;
  final List<String> _categorias = ['entrada', 'fondo', 'postre'];

  late List<String> _etiquetasSeleccionadas;
  final List<String> _etiquetasDisponibles = [
    'vegetariano',
    'rapido',
    'picante',
    'ensalada',
    'sarten',
    'horno'
  ];

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con valores actuales
    _nombreController = TextEditingController(text: widget.receta.nombre);
    _descripcionController = TextEditingController(text: widget.receta.descripcion);
    _porcionesController = TextEditingController(text: widget.receta.cantidadPorciones.toString());
    _duracionController = TextEditingController(text: widget.receta.duracionEstimadaMinutos.toString());
    _categoriaSeleccionada = widget.receta.categoria;
    _etiquetasSeleccionadas = List.from(widget.receta.etiquetas);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _porcionesController.dispose();
    _duracionController.dispose();
    super.dispose();
  }

  void _mostrarSelectorEtiquetas() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Seleccionar Etiquetas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _etiquetasDisponibles.map((etiqueta) {
                    return CheckboxListTile(
                      title: Text(etiqueta),
                      value: _etiquetasSeleccionadas.contains(etiqueta),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            if (!_etiquetasSeleccionadas.contains(etiqueta)) {
                              _etiquetasSeleccionadas.add(etiqueta);
                            }
                          } else {
                            _etiquetasSeleccionadas.remove(etiqueta);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {}); // Actualizar la UI principal
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _gestionarPasos() async {
    // Calcular el siguiente orden de paso
    int siguienteOrden = widget.receta.pasosIds.length + 1;
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearPasoPage(
          recetaId: widget.receta.nombre, // Usando nombre como ID
          orden: siguienteOrden,
        ),
      ),
    );
    
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paso agregado exitosamente')),
      );
      setState(() {
        // Actualizar la UI para reflejar el nuevo paso
      });
    }
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final recetaActualizada = Receta(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        cantidadPorciones: int.parse(_porcionesController.text),
        categoria: _categoriaSeleccionada,
        etiquetas: List.from(_etiquetasSeleccionadas),
        duracionEstimadaMinutos: int.parse(_duracionController.text),
        imagenPath: widget.receta.imagenPath,
        pasosIds: widget.receta.pasosIds, // Mantener los pasos existentes
      );

      try {
        await Provider.of<RecetaProvider>(context, listen: false)
            .updateReceta(widget.recetaKey, recetaActualizada);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receta actualizada exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar receta: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Receta', style: textTheme.headlineSmall),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirmar eliminación'),
                    content: Text('¿Está seguro de que desea eliminar "${widget.receta.nombre}"?\nEsto también eliminará todos los pasos asociados.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await Provider.of<RecetaProvider>(context, listen: false)
                                .deleteReceta(widget.recetaKey);
                            if (mounted) {
                              Navigator.of(context).pop(); // Cerrar diálogo
                              Navigator.of(context).pop(); // Volver a lista
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Receta eliminada exitosamente')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al eliminar: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.delete),
            tooltip: 'Eliminar receta',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre de la receta
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la receta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre de la receta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cantidad de porciones
              TextFormField(
                controller: _porcionesController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de porciones',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la cantidad de porciones';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Categoría
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
                items: _categorias.map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _categoriaSeleccionada = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Imagen representativa (placeholder)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Imagen representativa\n(Próximamente)',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Etiquetas
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Etiquetas: ${_etiquetasSeleccionadas.join(', ')}',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _mostrarSelectorEtiquetas,
                    icon: const Icon(Icons.tag),
                    label: const Text('Seleccionar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Duración estimada
              TextFormField(
                controller: _duracionController,
                decoration: const InputDecoration(
                  labelText: 'Duración estimada (minutos)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la duración estimada';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Información de pasos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasos de la receta',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pasos asociados: ${widget.receta.pasosIds.length}',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _gestionarPasos,
                            icon: const Icon(Icons.add_task),
                            label: const Text('Agregar Paso'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ver pasos existentes próximamente'),
                                ),
                              );
                            },
                            icon: const Icon(Icons.list),
                            label: const Text('Ver Pasos'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botón de guardar
              FilledButton.icon(
                onPressed: _guardarCambios,
                icon: const Icon(Icons.save),
                label: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
