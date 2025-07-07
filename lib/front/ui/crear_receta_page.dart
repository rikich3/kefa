import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/receta.dart';
import '../../front/state/receta_provider.dart';
import 'crear_paso_page.dart';

class CrearRecetaPage extends StatefulWidget {
  const CrearRecetaPage({super.key});

  @override
  State<CrearRecetaPage> createState() => _CrearRecetaPageState();
}

class _CrearRecetaPageState extends State<CrearRecetaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _porcionesController = TextEditingController();
  final _duracionController = TextEditingController();

  String _categoriaSeleccionada = 'entrada';
  final List<String> _categorias = ['entrada', 'fondo', 'postre'];

  List<String> _etiquetasSeleccionadas = [];
  final List<String> _etiquetasDisponibles = [
    'vegetariano',
    'rapido',
    'picante',
    'ensalada',
    'sarten',
    'horno'
  ];

  Receta? _recetaCreada; // Para almacenar la receta después de crearla
  int _siguienteOrdenPaso = 1;

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

  void _guardarReceta() async {
    if (_formKey.currentState!.validate()) {
      final receta = Receta(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        cantidadPorciones: int.parse(_porcionesController.text),
        categoria: _categoriaSeleccionada,
        etiquetas: List.from(_etiquetasSeleccionadas),
        duracionEstimadaMinutos: int.parse(_duracionController.text),
        pasosIds: [], // Inicialmente vacío
      );

      try {
        await Provider.of<RecetaProvider>(context, listen: false).addReceta(receta);
        if (mounted) {
          setState(() {
            _recetaCreada = receta;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receta guardada exitosamente. Ahora puede agregar pasos.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar receta: $e')),
          );
        }
      }
    }
  }

  void _agregarPaso() async {
    if (_recetaCreada != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CrearPasoPage(
            recetaId: _recetaCreada!.nombre, // Usando nombre como ID
            orden: _siguienteOrdenPaso,
          ),
        ),
      );
      
      if (result == true && mounted) {
        setState(() {
          _siguienteOrdenPaso++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paso agregado exitosamente')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Receta', style: textTheme.headlineSmall),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
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

              // Botón para agregar paso
              OutlinedButton.icon(
                onPressed: _recetaCreada != null ? _agregarPaso : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Primero guarde la receta, luego podrá agregar pasos'),
                    ),
                  );
                },
                icon: const Icon(Icons.add_task),
                label: Text(_recetaCreada != null ? 'Agregar paso' : 'Agregar paso (Guarde primero)'),
              ),
              const SizedBox(height: 16),

              // Lista de pasos
              Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: _recetaCreada == null 
                    ? Text(
                        'Lista de pasos\n(Se mostrará después de crear la receta)',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Text(
                        'Pasos agregados: ${_siguienteOrdenPaso - 1}\n¡Listo para crear pasos de la receta!',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              if (_recetaCreada == null) ...[
                // Botón de guardar (solo cuando no se ha guardado)
                FilledButton.icon(
                  onPressed: _guardarReceta,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Receta'),
                ),
              ] else ...[
                // Botones cuando ya se ha guardado la receta
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _agregarPaso,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Agregar Otro Paso'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Finalizar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
