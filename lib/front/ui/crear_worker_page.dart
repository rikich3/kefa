import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/worker.dart';
import '../state/workers_provider.dart';

class CrearWorkerPage extends StatefulWidget {
  const CrearWorkerPage({super.key});

  @override
  State<CrearWorkerPage> createState() => _CrearWorkerPageState();
}

class _CrearWorkerPageState extends State<CrearWorkerPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _funcionController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _funcionController.dispose();
    super.dispose();
  }

  void _saveWorker() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nuevoWorker = Worker(
        id: DateTime.now().millisecondsSinceEpoch, // O usa tu lógica de IDs
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        funcion: _funcionController.text.trim(),
      );

      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);

      try {
        await workersProvider.addWorker(nuevoWorker);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabajador guardado con éxito!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar trabajador: ${e.toString()}')),
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
        title: const Text('Crear Trabajador'),
        elevation: 4, // Da elevación a la AppBar
        backgroundColor: colorScheme.surface, // Tono claro del esquema
        foregroundColor: colorScheme.onSurface,
        shadowColor: colorScheme.primary.withOpacity(0.15), // Sombra ligera
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del trabajador',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _funcionController,
                decoration: const InputDecoration(
                  labelText: 'Función',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingrese una función' : null,
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: _saveWorker,
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}