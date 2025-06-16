import 'package:flutter/material.dart';

class Trabajador {
  final String nombre;
  final String asignacion;
  final String fotoUrl;
  final bool esSuperusuario;
  bool bloqueado;

  Trabajador({
    required this.nombre,
    required this.asignacion,
    required this.fotoUrl,
    this.esSuperusuario = false,
    this.bloqueado = false,
  });
}

class TrabajadoresPage extends StatefulWidget {
  final bool esSuperusuario;
  const TrabajadoresPage({super.key, this.esSuperusuario = true});

  @override
  State<TrabajadoresPage> createState() => _TrabajadoresPageState();
}

class _TrabajadoresPageState extends State<TrabajadoresPage> {
  late List<Trabajador> trabajadores;

  @override
  void initState() {
    super.initState();
    trabajadores = [
      Trabajador(nombre: 'Ana López', asignacion: 'Chef', fotoUrl: 'https://randomuser.me/api/portraits/women/1.jpg', esSuperusuario: false),
      Trabajador(nombre: 'Carlos Pérez', asignacion: 'Ayudante', fotoUrl: 'https://randomuser.me/api/portraits/men/2.jpg', esSuperusuario: false),
      Trabajador(nombre: 'Lucía Gómez', asignacion: 'Repostera', fotoUrl: 'https://randomuser.me/api/portraits/women/3.jpg', esSuperusuario: false),
      Trabajador(nombre: 'Miguel Torres', asignacion: 'Limpieza', fotoUrl: 'https://randomuser.me/api/portraits/men/4.jpg', esSuperusuario: false),
      Trabajador(nombre: 'Sofía Ramírez', asignacion: 'Cocinera', fotoUrl: 'https://randomuser.me/api/portraits/women/5.jpg', esSuperusuario: false),
    ];
  }

  void _eliminarTrabajador(int index) {
    setState(() {
      trabajadores.removeAt(index);
    });
  }

  void _agregarTrabajador() {
    showDialog(
      context: context,
      builder: (ctx) {
        String nombre = '';
        String asignacion = '';
        String fotoUrl = '';
        return AlertDialog(
          title: const Text('Añadir trabajador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onChanged: (v) => nombre = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Asignación'),
                onChanged: (v) => asignacion = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'URL de foto (opcional)'),
                onChanged: (v) => fotoUrl = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nombre.isNotEmpty && asignacion.isNotEmpty) {
                  setState(() {
                    trabajadores.add(Trabajador(
                      nombre: nombre,
                      asignacion: asignacion,
                      fotoUrl: fotoUrl.isNotEmpty ? fotoUrl : 'https://randomuser.me/api/portraits/lego/1.jpg',
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _toggleBloqueo(int index) {
    if (widget.esSuperusuario) {
      setState(() {
        trabajadores[index].bloqueado = !trabajadores[index].bloqueado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trabajadores de la cocina'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Añadir trabajador',
            onPressed: _agregarTrabajador,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: trabajadores.length,
        itemBuilder: (context, index) {
          final t = trabajadores[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(t.fotoUrl),
                radius: 28,
              ),
              title: Text(t.nombre),
              subtitle: Text(t.asignacion),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      t.bloqueado ? Icons.lock : Icons.lock_open,
                      color: t.bloqueado ? Colors.red : Colors.green,
                    ),
                    tooltip: t.bloqueado ? 'Desbloquear edición' : 'Bloquear edición',
                    onPressed: widget.esSuperusuario ? () => _toggleBloqueo(index) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'Retirar de la cocina',
                    onPressed: widget.esSuperusuario && !t.bloqueado ? () => _eliminarTrabajador(index) : null,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
