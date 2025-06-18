import 'package:flutter/material.dart';

class Insumo {
  String nombre;
  double cantidad;
  String unidad;
  Insumo({required this.nombre, required this.cantidad, required this.unidad});
}

class IngredientesMenu extends StatefulWidget {
  const IngredientesMenu({super.key});

  @override
  State<IngredientesMenu> createState() => _IngredientesMenuState();
}

class _IngredientesMenuState extends State<IngredientesMenu> {
  List<Insumo> insumos = [
    Insumo(nombre: 'Harina', cantidad: 5, unidad: 'kg'),
    Insumo(nombre: 'Tomate', cantidad: 10, unidad: 'unidades'),
    Insumo(nombre: 'Aceite vegetal', cantidad: 2, unidad: 'l'),
  ];

  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController();
  String _unidadSeleccionada = 'kg';
  final List<String> _unidades = ['kg', 'g', 'l', 'ml', 'unidades', 'tazas', 'cucharadas'];

  void _mostrarDialogoAgregar({Insumo? insumo, int? index}) {
    if (insumo != null) {
      _nombreController.text = insumo.nombre;
      _cantidadController.text = insumo.cantidad.toString();
      _unidadSeleccionada = insumo.unidad;
    } else {
      _nombreController.clear();
      _cantidadController.clear();
      _unidadSeleccionada = 'kg';
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(insumo == null ? 'Agregar Ingrediente' : 'Editar Ingrediente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unidadSeleccionada,
                      items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _unidadSeleccionada = value);
                      },
                      decoration: const InputDecoration(labelText: 'Unidad'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = _nombreController.text.trim();
                final cantidad = double.tryParse(_cantidadController.text.trim()) ?? 0;
                if (nombre.isEmpty || cantidad <= 0) return;
                setState(() {
                  if (insumo == null) {
                    insumos.add(Insumo(nombre: nombre, cantidad: cantidad, unidad: _unidadSeleccionada));
                  } else if (index != null) {
                    insumos[index] = Insumo(nombre: nombre, cantidad: cantidad, unidad: _unidadSeleccionada);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(insumo == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarInsumo(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ingrediente'),
        content: const Text('¿Estás seguro de eliminar este ingrediente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                insumos.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
                onPressed: () => _mostrarDialogoAgregar(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 350,
            child: ListView.builder(
              itemCount: insumos.length,
              itemBuilder: (context, index) {
                final insumo = insumos[index];
                return Card(
                  child: ListTile(
                    title: Text(insumo.nombre),
                    subtitle: Text('Cantidad: ${insumo.cantidad} ${insumo.unidad}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editar',
                          onPressed: () => _mostrarDialogoAgregar(insumo: insumo, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarInsumo(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Mover a features/ingredientes/ingredientes_menu.dart
