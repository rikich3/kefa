import 'package:flutter/material.dart';

class Utensilio {
  String nombre;
  int cantidad;
  int disponibles;
  int enUso;
  int enLavadero;
  List<String> usuariosEnUso;
  Utensilio({
    required this.nombre,
    required this.cantidad,
    this.disponibles = 0,
    this.enUso = 0,
    this.enLavadero = 0,
    List<String>? usuariosEnUso,
  }) : usuariosEnUso = usuariosEnUso ?? [];
}

class UtensiliosMenu extends StatefulWidget {
  const UtensiliosMenu({super.key});

  @override
  State<UtensiliosMenu> createState() => _UtensiliosMenuState();
}

class _UtensiliosMenuState extends State<UtensiliosMenu> {
  List<Utensilio> utensilios = [
    Utensilio(nombre: 'Sartén', cantidad: 3, disponibles: 2, enUso: 1, usuariosEnUso: ['Juan']),
    Utensilio(nombre: 'Olla', cantidad: 5, disponibles: 3, enUso: 2, usuariosEnUso: ['Ana', 'Luis']),
    Utensilio(nombre: 'Cuchillo', cantidad: 10, disponibles: 8, enUso: 2, usuariosEnUso: ['Pedro', 'María']),
  ];

  final _nombreController = TextEditingController();
  final _cantidadController = TextEditingController();
  final _disponiblesController = TextEditingController();
  final _enUsoController = TextEditingController();
  final _enLavaderoController = TextEditingController();
  final _usuariosController = TextEditingController();

  void _mostrarDialogoAgregar({Utensilio? utensilio, int? index}) {
    if (utensilio != null) {
      _nombreController.text = utensilio.nombre;
      _cantidadController.text = utensilio.cantidad.toString();
      _disponiblesController.text = utensilio.disponibles.toString();
      _enUsoController.text = utensilio.enUso.toString();
      _enLavaderoController.text = utensilio.enLavadero.toString();
      _usuariosController.text = utensilio.usuariosEnUso.join(', ');
    } else {
      _nombreController.clear();
      _cantidadController.clear();
      _disponiblesController.clear();
      _enUsoController.clear();
      _enLavaderoController.clear();
      _usuariosController.clear();
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(utensilio == null ? 'Agregar Utensilio' : 'Editar Utensilio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cantidad total'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _disponiblesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Disponibles'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _enUsoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'En uso'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _enLavaderoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'En lavadero'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usuariosController,
                  decoration: const InputDecoration(labelText: 'Usuarios en uso (separados por coma)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final nombre = _nombreController.text.trim();
                final cantidad = int.tryParse(_cantidadController.text.trim()) ?? 0;
                final disponibles = int.tryParse(_disponiblesController.text.trim()) ?? 0;
                final enUso = int.tryParse(_enUsoController.text.trim()) ?? 0;
                final enLavadero = int.tryParse(_enLavaderoController.text.trim()) ?? 0;
                final usuarios = _usuariosController.text.split(',').map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
                if (nombre.isEmpty || cantidad <= 0) return;
                setState(() {
                  if (utensilio == null) {
                    utensilios.add(Utensilio(
                      nombre: nombre,
                      cantidad: cantidad,
                      disponibles: disponibles,
                      enUso: enUso,
                      enLavadero: enLavadero,
                      usuariosEnUso: usuarios,
                    ));
                  } else if (index != null) {
                    utensilios[index] = Utensilio(
                      nombre: nombre,
                      cantidad: cantidad,
                      disponibles: disponibles,
                      enUso: enUso,
                      enLavadero: enLavadero,
                      usuariosEnUso: usuarios,
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: Text(utensilio == null ? 'Agregar' : 'Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarUtensilio(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar utensilio'),
        content: const Text('¿Estás seguro de eliminar este utensilio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                utensilios.removeAt(index);
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
              itemCount: utensilios.length,
              itemBuilder: (context, index) {
                final u = utensilios[index];
                return Card(
                  child: ListTile(
                    title: Text(u.nombre),
                    subtitle: Text('Total: ${u.cantidad} | Disponibles: ${u.disponibles} | En uso: ${u.enUso} | Lavadero: ${u.enLavadero}\nUsuarios: ${u.usuariosEnUso.isNotEmpty ? u.usuariosEnUso.join(", ") : "-"}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Editar',
                          onPressed: () => _mostrarDialogoAgregar(utensilio: u, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarUtensilio(index),
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
