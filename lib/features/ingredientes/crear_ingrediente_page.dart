import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CrearIngredientePage extends StatefulWidget {
  const CrearIngredientePage({super.key});

  @override
  State<CrearIngredientePage> createState() => _CrearIngredientePageState();
}

class _CrearIngredientePageState extends State<CrearIngredientePage> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _cantidad = '';
  String _unidad = 'g';

  final List<String> _unidades = [
    'g', 'kg', 'ml', 'l', 'unidades', 'cucharadas', 'tazas'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Ingrediente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nombre del ingrediente',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => _nombre = value ?? '',
                validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+([.,][0-9]*)?'))],
                      onSaved: (value) => _cantidad = value ?? '',
                      validator: (value) => (value == null || value.isEmpty) ? 'Ingrese una cantidad' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _unidad,
                      items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _unidad = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Unidad',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        print('Ingrediente: $_nombre, Cantidad: $_cantidad $_unidad');
                        Navigator.pop(context);
                      }
                    },
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
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
