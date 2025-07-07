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
  late TextEditingController _pesoController;
  late TextEditingController _cantidadController;
  late TextEditingController _altoController;
  late TextEditingController _anchoController;
  late TextEditingController _profundidadController;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con valores actuales
    _nombreController = TextEditingController(text: widget.instrumento.nombre);
    _idController = TextEditingController(text: widget.instrumento.id.toString());
    _descripcionController = TextEditingController(text: widget.instrumento.descripcion);
    _pesoController = TextEditingController(text: widget.instrumento.peso.toString());
    _cantidadController = TextEditingController(text: widget.instrumento.cantidad.toString());
    
    // Dimensiones (asumiendo que son [alto, ancho, profundidad])
    final dimensiones = widget.instrumento.dimensiones;
    _altoController = TextEditingController(text: dimensiones.isNotEmpty ? dimensiones[0].toString() : '0');
    _anchoController = TextEditingController(text: dimensiones.length > 1 ? dimensiones[1].toString() : '0');
    _profundidadController = TextEditingController(text: dimensiones.length > 2 ? dimensiones[2].toString() : '0');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _idController.dispose();
    _descripcionController.dispose();
    _pesoController.dispose();
    _cantidadController.dispose();
    _altoController.dispose();
    _anchoController.dispose();
    _profundidadController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final instrumentoActualizado = Instrumento(
        nombre: _nombreController.text,
        id: int.parse(_idController.text),
        descripcion: _descripcionController.text,
        peso: double.parse(_pesoController.text),
        dimensiones: [
          double.parse(_altoController.text),
          double.parse(_anchoController.text),
          double.parse(_profundidadController.text),
        ],
        cantidad: int.parse(_cantidadController.text),
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

              // Peso
              TextFormField(
                controller: _pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el peso';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Por favor ingrese un peso válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Dimensiones
              Text('Dimensiones (cm)', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _altoController,
                      decoration: const InputDecoration(
                        labelText: 'Alto',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _anchoController,
                      decoration: const InputDecoration(
                        labelText: 'Ancho',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _profundidadController,
                      decoration: const InputDecoration(
                        labelText: 'Profundidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
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
