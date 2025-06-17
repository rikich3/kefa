import 'package:flutter/material.dart';

class PlatoEnPreparacion {
  final String nombre;
  final Duration tiempoEstimado;
  Duration tiempoTranscurrido;
  bool alerta;

  PlatoEnPreparacion({
    required this.nombre,
    required this.tiempoEstimado,
    this.tiempoTranscurrido = Duration.zero,
    this.alerta = false,
  });
}

class ControlTiemposPage extends StatefulWidget {
  const ControlTiemposPage({Key? key}) : super(key: key);

  @override
  State<ControlTiemposPage> createState() => _ControlTiemposPageState();
}

class _ControlTiemposPageState extends State<ControlTiemposPage> {
  final List<PlatoEnPreparacion> _platos = [
    PlatoEnPreparacion(nombre: 'Lomo Saltado', tiempoEstimado: Duration(minutes: 15)),
    PlatoEnPreparacion(nombre: 'Ceviche', tiempoEstimado: Duration(minutes: 10)),
    PlatoEnPreparacion(nombre: 'Aji de Gallina', tiempoEstimado: Duration(minutes: 20)),
  ];

  @override
  void initState() {
    super.initState();
    // Simula el avance del tiempo
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        for (var plato in _platos) {
          plato.tiempoTranscurrido += const Duration(seconds: 1);
          plato.alerta = plato.tiempoTranscurrido > plato.tiempoEstimado;
        }
      });
      return mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Tiempos de Preparación')),
      body: ListView.builder(
        itemCount: _platos.length,
        itemBuilder: (context, index) {
          final plato = _platos[index];
          return Card(
            color: plato.alerta ? Colors.red[100] : null,
            child: ListTile(
              title: Text(plato.nombre),
              subtitle: Text(
                'Estimado: ${plato.tiempoEstimado.inMinutes} min\nTranscurrido: ${plato.tiempoTranscurrido.inMinutes} min ${plato.tiempoTranscurrido.inSeconds % 60} seg',
              ),
              trailing: plato.alerta
                  ? const Icon(Icons.warning, color: Colors.red)
                  : const Icon(Icons.timer, color: Colors.green),
            ),
          );
        },
      ),
    );
  }
}
