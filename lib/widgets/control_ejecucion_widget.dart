import 'package:flutter/material.dart';
import '../back/system/sistema_ejecucion.dart';

class ControlEjecucionWidget extends StatefulWidget {
  final SistemaEjecucion sistemaEjecucion;

  const ControlEjecucionWidget({
    super.key,
    required this.sistemaEjecucion,
  });

  @override
  State<ControlEjecucionWidget> createState() => _ControlEjecucionWidgetState();
}

class _ControlEjecucionWidgetState extends State<ControlEjecucionWidget> {
  @override
  void initState() {
    super.initState();
    widget.sistemaEjecucion.addListener(_onEstadoChanged);
  }

  @override
  void dispose() {
    widget.sistemaEjecucion.removeListener(_onEstadoChanged);
    super.dispose();
  }

  void _onEstadoChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final sistema = widget.sistemaEjecucion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.play_circle,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Control de Ejecución',
              style: textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Estado actual
        Card(
          color: _getColorEstado(sistema.estado, colorScheme),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _getIconoEstado(sistema.estado),
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _getTextoEstado(sistema.estado),
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sistema.formatearTiempoTranscurrido()} / ${sistema.formatearTiempoTotal()}',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),

        // Barra de progreso
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Progreso General', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: sistema.progreso,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(sistema.progreso * 100).toStringAsFixed(1)}%',
                  style: textTheme.bodyMedium,
                ),
                Text(
                  'Restante: ${sistema.formatearTiempoRestante()}',
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Controles
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Botón Iniciar/Pausar
            FilledButton.icon(
              onPressed: () {
                if (sistema.estado == EstadoEjecucion.detenido ||
                    sistema.estado == EstadoEjecucion.pausado) {
                  sistema.iniciar();
                } else if (sistema.estado == EstadoEjecucion.ejecutando) {
                  sistema.pausar();
                }
              },
              icon: Icon(
                sistema.estado == EstadoEjecucion.ejecutando
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              label: Text(
                sistema.estado == EstadoEjecucion.ejecutando
                    ? 'Pausar'
                    : 'Iniciar',
              ),
            ),

            // Botón Detener
            OutlinedButton.icon(
              onPressed: sistema.estado != EstadoEjecucion.detenido
                  ? () => sistema.detener()
                  : null,
              icon: const Icon(Icons.stop),
              label: const Text('Detener'),
            ),

            // Botón Reiniciar
            OutlinedButton.icon(
              onPressed: () => sistema.reiniciar(),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reiniciar'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Información de tareas actuales
        if (sistema.tareasEnEjecucion.isNotEmpty) ...[
          Text('Tareas en Ejecución', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...sistema.tareasEnEjecucion.map((entrada) => Card(
            color: colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.play_circle_filled),
              title: Text(entrada.paso.descripcion),
              subtitle: Text(
                '${entrada.recetaNombre} (${entrada.recetaInstancia}) • '
                'Trabajadores: ${entrada.paso.trabajadores.join(', ')}',
              ),
              trailing: Text(
                'Termina en ${_formatearTiempo(entrada.tiempoFin - sistema.tiempoTranscurrido)}',
                style: textTheme.bodySmall,
              ),
            ),
          )),
        ],

        // Próximas tareas
        if (sistema.proximasTareas.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Próximas Tareas', style: textTheme.titleMedium),
          const SizedBox(height: 8),
          ...sistema.proximasTareas.take(3).map((entrada) => Card(
            child: ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(entrada.paso.descripcion),
              subtitle: Text(
                '${entrada.recetaNombre} (${entrada.recetaInstancia}) • '
                'Trabajadores: ${entrada.paso.trabajadores.join(', ')}',
              ),
              trailing: Text(
                'En ${_formatearTiempo(entrada.tiempoInicio - sistema.tiempoTranscurrido)}',
                style: textTheme.bodySmall,
              ),
            ),
          )),
        ],
      ],
    );
  }

  Color _getColorEstado(EstadoEjecucion estado, ColorScheme colorScheme) {
    switch (estado) {
      case EstadoEjecucion.detenido:
        return Colors.grey;
      case EstadoEjecucion.ejecutando:
        return Colors.green;
      case EstadoEjecucion.pausado:
        return Colors.orange;
      case EstadoEjecucion.completado:
        return Colors.blue;
    }
  }

  IconData _getIconoEstado(EstadoEjecucion estado) {
    switch (estado) {
      case EstadoEjecucion.detenido:
        return Icons.stop_circle;
      case EstadoEjecucion.ejecutando:
        return Icons.play_circle_filled;
      case EstadoEjecucion.pausado:
        return Icons.pause_circle_filled;
      case EstadoEjecucion.completado:
        return Icons.check_circle;
    }
  }

  String _getTextoEstado(EstadoEjecucion estado) {
    switch (estado) {
      case EstadoEjecucion.detenido:
        return 'DETENIDO';
      case EstadoEjecucion.ejecutando:
        return 'EJECUTANDO';
      case EstadoEjecucion.pausado:
        return 'PAUSADO';
      case EstadoEjecucion.completado:
        return 'COMPLETADO';
    }
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final seg = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }
}
