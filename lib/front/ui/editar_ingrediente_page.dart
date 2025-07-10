import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/ingredientes.dart';
import '../state/ingredientes_provider.dart';

class EditarIngredientePage extends StatefulWidget {
  final dynamic ingredienteKey;
  final Ingredientes ingrediente;

  const EditarIngredientePage({
    super.key,
    required this.ingredienteKey,
    required this.ingrediente,
  });

  @override
  State<EditarIngredientePage> createState() => _EditarIngredientePageState();
}

class _EditarIngredientePageState extends State<EditarIngredientePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _cantidadController;
  late TextEditingController _precioController;

  String _unidadMedidaSeleccionada = 'gramos';
  final List<String> _unidadesMedida = Ingredientes.unidadesMedidaDisponibles;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con valores actuales
    _nombreController = TextEditingController(text: widget.ingrediente.name);
    _descripcionController = TextEditingController(text: widget.ingrediente.descripcion);
    _cantidadController = TextEditingController(text: widget.ingrediente.cantidad.toString());
    _precioController = TextEditingController(text: widget.ingrediente.precio.toString());
    _unidadMedidaSeleccionada = widget.ingrediente.unidadMedida;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final ingredienteActualizado = Ingredientes(
        name: _nombreController.text,
        descripcion: _descripcionController.text,
        unidadMedida: _unidadMedidaSeleccionada,
        cantidad: int.parse(_cantidadController.text),
        precio: double.parse(_precioController.text),
      );

      try {
        await Provider.of<IngredientesProvider>(context, listen: false)
            .updateIngredient(widget.ingredienteKey, ingredienteActualizado);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ingrediente actualizado exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar ingrediente: $e')),
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
        title: Text('Editar Ingrediente', style: textTheme.headlineSmall),
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
                    content: Text('¿Está seguro de que desea eliminar "${widget.ingrediente.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await Provider.of<IngredientesProvider>(context, listen: false)
                                .deleteIngredient(widget.ingredienteKey);
                            if (mounted) {
                              Navigator.of(context).pop(); // Cerrar diálogo
                              Navigator.of(context).pop(); // Volver a lista
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ingrediente eliminado exitosamente')),
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
            tooltip: 'Eliminar ingrediente',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del ingrediente',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del ingrediente';
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

              // Cantidad
              TextFormField(
                controller: _cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la cantidad';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Unidad de medida
              DropdownButtonFormField<String>(
                value: _unidadMedidaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Unidad de medida',
                  border: OutlineInputBorder(),
                ),
                items: _unidadesMedida.map((String unidad) {
                  return DropdownMenuItem<String>(
                    value: unidad,
                    child: Text(unidad),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _unidadMedidaSeleccionada = newValue;
                    });
                  }
                },
                validator: (value) => (value == null || value.isEmpty) ? 'Seleccione una unidad de medida' : null,
              ),
              const SizedBox(height: 16),

              // Precio
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$ ',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el precio';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingrese un precio válido';
                  }
                  return null;
                },
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
