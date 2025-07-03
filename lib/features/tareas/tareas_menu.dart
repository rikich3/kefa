import 'package:flutter/material.dart';
import '../trabajadores/trabajador_model.dart';
import 'tarea_model.dart';
import 'asignador_tareas.dart';

class TareasMenu extends StatefulWidget {
  final List<Tarea> tareas;
  final List<Trabajador> trabajadores;
  final void Function(List<Tarea>)? onTareasActualizadas;

  const TareasMenu({
    Key? key,
    required this.tareas,
    required this.trabajadores,
    this.onTareasActualizadas,
  }) : super(key: key);

  @override
  State<TareasMenu> createState() => _TareasMenuState();
}

class _TareasMenuState extends State<TareasMenu> {
  late List<Tarea> _tareas;

  @override
  void initState() {
    super.initState();
    _tareas = List<Tarea>.from(widget.tareas);
  }

  void _asignarAutomaticamente() {
    setState(() {
      _tareas = AsignadorTareas.asignarTareas(
        tareas: _tareas,
        trabajadores: widget.trabajadores,
      );
      widget.onTareasActualizadas?.call(_tareas);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Asignar automáticamente',
            onPressed: _asignarAutomaticamente,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _tareas.length,
        itemBuilder: (context, index) {
          final tarea = _tareas[index];
          final trabajador = widget.trabajadores.firstWhere(
            (w) => w.id == tarea.trabajadorId,
            orElse: () => Trabajador(id: '', nombre: 'Sin asignar', rol: ''),
          );
          return ListTile(
            title: Text(tarea.nombre),
            subtitle: Text('Estado: ${tarea.estado}\nAsignado a: ${trabajador.nombre}'),
            trailing: Text('Prioridad: ${tarea.prioridad}'),
          );
        },
      ),
    );
  }
}
