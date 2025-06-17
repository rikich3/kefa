import 'package:flutter/material.dart';
import 'receta_model.dart';

class RealizarRecetaPage extends StatefulWidget {
  final Receta receta;
  const RealizarRecetaPage({Key? key, required this.receta}) : super(key: key);

  @override
  State<RealizarRecetaPage> createState() => _RealizarRecetaPageState();
}

class _RealizarRecetaPageState extends State<RealizarRecetaPage> {
  int _pasoActual = 0;
  late Stopwatch _stopwatch;
  late Duration _tiempoEstimado;
  bool _alertaTiempo = false;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    // Suma de tiempos estimados por paso (puedes ajustar esto si tienes tiempos por paso)
    _tiempoEstimado = Duration(minutes: widget.receta.pasos.length * 5); // Ejemplo: 5 min por paso
    _tick();
  }

  void _tick() async {
    while (mounted && _stopwatch.isRunning) {
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _alertaTiempo = _stopwatch.elapsed > _tiempoEstimado;
      });
    }
  }

  void _completarPaso() {
    if (_pasoActual < widget.receta.pasos.length - 1) {
      setState(() {
        _pasoActual++;
      });
    } else {
      _stopwatch.stop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¡Receta completada!'),
          content: Text('Tiempo total: ${_stopwatch.elapsed.inMinutes} min ${_stopwatch.elapsed.inSeconds % 60} seg'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paso = widget.receta.pasos[_pasoActual];
    return Scaffold(
      appBar: AppBar(title: Text('Realizar: ${widget.receta.nombre}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paso ${_pasoActual + 1} de ${widget.receta.pasos.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(paso, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            Text('Tiempo estimado: ${_tiempoEstimado.inMinutes} min'),
            Text('Tiempo transcurrido: ${_stopwatch.elapsed.inMinutes} min ${_stopwatch.elapsed.inSeconds % 60} seg',
                style: TextStyle(color: _alertaTiempo ? Colors.red : Colors.black)),
            if (_alertaTiempo)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('¡Alerta! Tiempo excedido', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(_pasoActual < widget.receta.pasos.length - 1 ? 'Siguiente paso' : 'Finalizar'),
              onPressed: _completarPaso,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }
}
