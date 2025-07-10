import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/instrumentos.dart';
import '../state/instrumentos_provider.dart';

class EditarInstrumentoPage extends StatefulWidget {
  final dynamic instrumentoKey;
  final Instrumento instrumento;

  const EditarInstrumentoPage({
    super.key,
    required this.instrumentoKey,
    required this.instrumento,
  });

  @override
  State<EditarInstrumentoPage> createState() => _EditarInstrumentoPageState();
}

class _EditarInstrumentoPageState extends State<EditarInstrumentoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _idController;
  late TextEditingController _descripcionController;
  late TextEditingController _cantidadController;
  late TextEditingController _capacidadMaximaController;
  String _tipo = 'Normal';

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.instrumento.nombre);
    _idController = TextEditingController(text: widget.instrumento.id.toString());
    _descripcionController = TextEditingController(text: widget.instrumento.descripcion);
    _cantidadController = TextEditingController(text: widget.instrumento.cantidad.toString());
    _tipo = widget.instrumento.tipo;
    _capacidadMaximaController = TextEditingController(text: widget.instrumento.capacidadMaximaKg?.toString() ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _idController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    _capacidadMaximaController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final instrumentoActualizado = Instrumento(
        nombre: _nombreController.text,
        id: int.parse(_idController.text),
        descripcion: _descripcionController.text,
        cantidad: int.parse(_cantidadController.text),
        tipo: _tipo,
        capacidadMaximaKg: _tipo == 'Almacenamiento' ? double.tryParse(_capacidadMaximaController.text.trim().replaceAll(',', '.')) : null,
      );
      try {
        await Provider.of<InstrumentosProvider>(context, listen: false)
            .updateInstrumento(widget.instrumentoKey, instrumentoActualizado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Instrumento actualizado exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar instrumento: $e')),
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
        title: Text('Editar Instrumento', style: textTheme.headlineSmall),
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
                    content: Text('¿Está seguro de que desea eliminar "${widget.instrumento.nombre}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await Provider.of<InstrumentosProvider>(context, listen: false)
                                .deleteInstrumento(widget.instrumentoKey);
                            if (mounted) {
                              Navigator.of(context).pop(); // Cerrar diálogo
                              Navigator.of(context).pop(); // Volver a lista
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Instrumento eliminado exitosamente')),
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
            tooltip: 'Eliminar instrumento',
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
                  labelText: 'Nombre del instrumento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del instrumento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ID
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID del instrumento',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el ID del instrumento';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
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
                  if (value == null || value.isEmpty) return 'Ingrese una cantidad';
                  if (int.tryParse(value.trim()) == null) return 'Debe ser un número entero válido';
                  if (int.parse(value.trim()) < 0) return 'La cantidad no puede ser negativa';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de utensilio',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'Almacenamiento', child: Text('De almacenamiento')),
                ],
                onChanged: (value) {
                  setState(() {
                    _tipo = value ?? 'Normal';
                  });
                },
              ),

              // Capacidad máxima (solo si es de almacenamiento)
              if (_tipo == 'Almacenamiento') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacidadMaximaController,
                  decoration: const InputDecoration(
                    labelText: 'Capacidad máxima (kg)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (_tipo == 'Almacenamiento') {
                      if (value == null || value.isEmpty) return 'Ingrese la capacidad máxima';
                      final cleaned = value.trim().replaceAll(',', '.');
                      if (double.tryParse(cleaned) == null) return 'Debe ser un número válido';
                      if (double.parse(cleaned) <= 0) return 'Debe ser mayor a cero';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 30),

              // Botones de guardar y cancelar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: _guardarCambios,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
