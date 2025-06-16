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
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _dimensionesController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _pesoController.dispose();
    _dimensionesController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

  void _saveInstrumento() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Parsear dimensiones: se espera una lista de números separados por coma o espacio
      List<double> dimensiones = [];
      try {
        dimensiones = _dimensionesController.text
            .split(RegExp(r'[ ,xX]+'))
            .where((s) => s.trim().isNotEmpty)
            .map((s) => double.parse(s.trim().replaceAll(',', '.')))
            .toList();
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dimensiones inválidas. Use números separados por espacio, coma o "x".')),
        );
        return;
      }

      final nuevoInstrumento = Instrumento(
        nombre: _nombreController.text.trim(),
        id: DateTime.now().millisecondsSinceEpoch,
        descripcion: _descripcionController.text.trim(),
        peso: double.parse(_pesoController.text.trim().replaceAll(',', '.')),
        dimensiones: dimensiones,
        cantidad: int.parse(_cantidadController.text.trim()),
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
          SnackBar(content: Text('Error al guardar instrumento: ${e.toString()}')),
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
                controller: _pesoController,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese el peso';
                  final cleaned = value.trim().replaceAll(',', '.');
                  if (double.tryParse(cleaned) == null) return 'Debe ser un número válido';
                  if (double.parse(cleaned) < 0) return 'El peso no puede ser negativo';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _dimensionesController,
                decoration: const InputDecoration(
                  labelText: 'Dimensiones (ej: 10 20 30 o 10x20x30 en cm)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingrese las dimensiones';
                  final parts = value.split(RegExp(r'[ ,xX]+')).where((s) => s.trim().isNotEmpty);
                  if (parts.isEmpty) return 'Ingrese al menos una dimensión';
                  for (final part in parts) {
                    final cleaned = part.trim().replaceAll(',', '.');
                    if (double.tryParse(cleaned) == null) return 'Dimensión inválida: $part';
                    if (double.parse(cleaned) < 0) return 'Las dimensiones no pueden ser negativas';
                  }
                  return null;
                },
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