import 'package:flutter/material.dart';
import 'trabajador_model.dart';
import 'dart:async';

class TrabajadoresMenu extends StatefulWidget {
  const TrabajadoresMenu({super.key});

  @override
  State<TrabajadoresMenu> createState() => _TrabajadoresMenuState();
}

class _TrabajadoresMenuState extends State<TrabajadoresMenu> {
  late List<Trabajador> trabajadores;
  final _tareaController = TextEditingController();
  final _duracionController = TextEditingController();
  String? _especialidadSeleccionada;

  @override
  void initState() {
    super.initState();
    trabajadores = defaultTrabajadores();
  }

  void _asignarTarea(int index) {
    _tareaController.text = '';
    _duracionController.text = '';
    _especialidadSeleccionada = null;
    final especialidades = trabajadores[index].especialidades;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 120),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Asignar tarea a ${trabajadores[index].nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (especialidades.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _especialidadSeleccionada,
                  items: especialidades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => _especialidadSeleccionada = value),
                  decoration: const InputDecoration(labelText: 'Especialidad para la tarea', border: OutlineInputBorder()),
                ),
              if (especialidades.isNotEmpty) const SizedBox(height: 16),
              TextField(
                controller: _tareaController,
                decoration: InputDecoration(
                  labelText: 'Tarea',
                  border: const OutlineInputBorder(),
                  hintText: especialidades.isNotEmpty && _especialidadSeleccionada != null
                    ? 'Ej: ${_especialidadSeleccionada!}'
                    : 'Ej: Limpieza, General...'
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _duracionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duración (minutos)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final tarea = _tareaController.text.trim();
                      final duracionMin = int.tryParse(_duracionController.text.trim()) ?? 0;
                      if ((especialidades.isNotEmpty && _especialidadSeleccionada == null) || tarea.isEmpty || duracionMin <= 0) return;
                      setState(() {
                        trabajadores[index].tareaAsignada = tarea;
                        trabajadores[index].tareaAsignadaInicio = DateTime.now();
                        trabajadores[index].duracionTarea = Duration(minutes: duracionMin);
                        trabajadores[index].tiempoRestante = Duration(minutes: duracionMin);
                        trabajadores[index].timer?.cancel();
                        trabajadores[index].timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                          final restante = trabajadores[index].duracionTarea! - DateTime.now().difference(trabajadores[index].tareaAsignadaInicio!);
                          setState(() {
                            trabajadores[index].tiempoRestante = restante > Duration.zero ? restante : Duration.zero;
                          });
                          if (trabajadores[index].tiempoRestante == Duration.zero) {
                            timer.cancel();
                          }
                        });
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Asignar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var t in trabajadores) {
      t.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Trabajadores', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: ListView.builder(
              itemCount: trabajadores.length,
              itemBuilder: (context, index) {
                final t = trabajadores[index];
                final asignado = t.tareaAsignada != null && t.tareaAsignada!.isNotEmpty && t.tiempoRestante > Duration.zero;
                return Card(
                  child: ListTile(
                    title: Text(t.nombre),
                    subtitle: Text('Rol: ${t.rol}\nEspecialidades: ${t.especialidades.join(', ')}\nTarea: ${t.tareaAsignada ?? "Sin asignar"}${asignado ? "\nRestante: ${t.tiempoRestante.inMinutes}:${(t.tiempoRestante.inSeconds % 60).toString().padLeft(2, '0')}" : ""}'),
                    isThreeLine: true,
                    trailing: asignado
                      ? const Icon(Icons.assignment_turned_in, color: Colors.green)
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.assignment_ind),
                          label: const Text('Asignar'),
                          onPressed: () => _asignarTarea(index),
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
