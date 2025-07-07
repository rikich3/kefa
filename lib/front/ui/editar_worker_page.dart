import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/worker.dart';
import '../state/workers_provider.dart';

class EditarWorkerPage extends StatefulWidget {
  final dynamic workerKey;
  final Worker worker;

  const EditarWorkerPage({
    super.key,
    required this.workerKey,
    required this.worker,
  });

  @override
  State<EditarWorkerPage> createState() => _EditarWorkerPageState();
}

class _EditarWorkerPageState extends State<EditarWorkerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _funcionController;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con valores actuales
    _idController = TextEditingController(text: widget.worker.id.toString());
    _nombreController = TextEditingController(text: widget.worker.nombre);
    _descripcionController = TextEditingController(text: widget.worker.descripcion);
    _funcionController = TextEditingController(text: widget.worker.funcion);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _funcionController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final workerActualizado = Worker(
        id: int.parse(_idController.text),
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        funcion: _funcionController.text,
      );

      try {
        await Provider.of<WorkersProvider>(context, listen: false)
            .updateWorker(widget.workerKey, workerActualizado);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trabajador actualizado exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar trabajador: $e')),
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
        title: Text('Editar Trabajador', style: textTheme.headlineSmall),
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
                    content: Text('¿Está seguro de que desea eliminar "${widget.worker.nombre}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await Provider.of<WorkersProvider>(context, listen: false)
                                .deleteWorker(widget.workerKey);
                            if (mounted) {
                              Navigator.of(context).pop(); // Cerrar diálogo
                              Navigator.of(context).pop(); // Volver a lista
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Trabajador eliminado exitosamente')),
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
            tooltip: 'Eliminar trabajador',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ID
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID del trabajador',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el ID del trabajador';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del trabajador',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del trabajador';
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

              // Función
              TextFormField(
                controller: _funcionController,
                decoration: const InputDecoration(
                  labelText: 'Función',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la función';
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
