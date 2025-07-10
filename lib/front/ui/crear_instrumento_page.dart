import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/instrumentos.dart';
import '../state/instrumentos_provider.dart';

class CrearInstrumentoPage extends StatefulWidget {
  const CrearInstrumentoPage({super.key});

  @override
  State<CrearInstrumentoPage> createState() => _CrearInstrumentoPageState();
}

class _CrearInstrumentoPageState extends State<CrearInstrumentoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _capacidadMaximaController = TextEditingController();

  String _tipo = 'Normal';

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _cantidadController.dispose();
    _capacidadMaximaController.dispose();
    super.dispose();
  }

  void _saveInstrumento() async {
    if (_formKey.currentState?.validate() ?? false) {
      final nuevoInstrumento = Instrumento(
        nombre: _nombreController.text.trim(),
        id: DateTime.now().millisecondsSinceEpoch,
        descripcion: _descripcionController.text.trim(),
        cantidad: int.parse(_cantidadController.text.trim()),
        tipo: _tipo,
        capacidadMaximaKg: _tipo == 'Almacenamiento' ? double.tryParse(_capacidadMaximaController.text.trim().replaceAll(',', '.')) : null,
      );

      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

      try {
        await instrumentosProvider.addInstrumento(nuevoInstrumento);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Instrumento guardado con éxito!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar instrumento: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Instrumento'),
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
                  labelText: 'Nombre del instrumento',
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
              const SizedBox(height: 20),
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
              if (_tipo == 'Almacenamiento') ...[
                const SizedBox(height: 20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: _saveInstrumento,
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