import 'package:flutter/material.dart';
import '../back/system/sistema_ejecucion.dart';
import '../back/system/sistema_preprocesamiento.dart';
import '../back/system/agenda_models.dart';

class VistaAgendasWidget extends StatefulWidget {
  final SistemaEjecucion sistemaEjecucion;
  final SistemaPreprocesamiento sistemaPreprocesamiento;

  const VistaAgendasWidget({
    super.key,
    required this.sistemaEjecucion,
    required this.sistemaPreprocesamiento,
  });

  @override
  State<VistaAgendasWidget> createState() => _VistaAgendasWidgetState();
}

class _VistaAgendasWidgetState extends State<VistaAgendasWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    widget.sistemaEjecucion.addListener(_onEstadoChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Vista de Agendas',
              style: textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cronología General'),
            Tab(text: 'Trabajadores'),
            Tab(text: 'Utensilios'),
          ],
        ),

        const SizedBox(height: 16),

        // Contenido de tabs
        SizedBox(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCronologiaGeneral(),
              _buildVistaAgendas(
                widget.sistemaPreprocesamiento.agendasTrabajadores,
                TipoRequisito.trabajador,
              ),
              _buildVistaAgendas(
                widget.sistemaPreprocesamiento.agendasUtensilios,
                TipoRequisito.utensilio,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCronologiaGeneral() {
    final agendasCombinadas = widget.sistemaPreprocesamiento.obtenerAgendasCombinadas();
    final tiempoActual = widget.sistemaEjecucion.tiempoTranscurrido;

    if (agendasCombinadas.isEmpty) {
      return const Center(
        child: Text('No hay tareas programadas'),
      );
    }

    return ListView.builder(
      itemCount: agendasCombinadas.length,
      itemBuilder: (context, index) {
        final entrada = agendasCombinadas[index];
        final yaEjecutada = entrada.tiempoFin <= tiempoActual;
        final enEjecucion = entrada.tiempoInicio <= tiempoActual && 
                           entrada.tiempoFin > tiempoActual;

        return Card(
          color: yaEjecutada
              ? Colors.grey[100]
              : enEjecucion
                  ? Colors.green[100]
                  : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: yaEjecutada
                  ? Colors.grey
                  : enEjecucion
                      ? Colors.green
                      : Colors.blue,
              child: Icon(
                yaEjecutada
                    ? Icons.check
                    : enEjecucion
                        ? Icons.play_arrow
                        : Icons.schedule,
                color: Colors.white,
              ),
            ),
            title: Text(
              entrada.paso.descripcion,
              style: TextStyle(
                decoration: yaEjecutada ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entrada.recetaNombre} (instancia ${entrada.recetaInstancia})'),
                Text('Trabajadores: ${entrada.paso.trabajadores.join(', ')}'),
                if (entrada.paso.utensilioTipos.isNotEmpty)
                  Text('Utensilios: ${entrada.paso.utensilioTipos.join(', ')}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatearTiempo(entrada.tiempoInicio),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Duración: ${_formatearTiempo(entrada.paso.tiempoSegundos)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVistaAgendas(Map<String, Agenda> agendas, TipoRequisito tipo) {
    if (agendas.isEmpty) {
      return Center(
        child: Text('No hay ${tipo == TipoRequisito.trabajador ? 'trabajadores' : 'utensilios'} disponibles'),
      );
    }

    return ListView.builder(
      itemCount: agendas.length,
      itemBuilder: (context, index) {
        final agenda = agendas.values.elementAt(index);
        return _buildAgendaCard(agenda);
      },
    );
  }

  Widget _buildAgendaCard(Agenda agenda) {
    final tiempoActual = widget.sistemaEjecucion.tiempoTranscurrido;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: agenda.tipo == TipoRequisito.trabajador
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
          child: Icon(
            agenda.tipo == TipoRequisito.trabajador
                ? Icons.person
                : Icons.build,
            color: agenda.tipo == TipoRequisito.trabajador
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(agenda.requisitoNombre),
        subtitle: Text(
          '${agenda.entradas.length} tareas • Ocupado hasta: ${_formatearTiempo(agenda.origen)}',
        ),
        children: agenda.entradas.map((entrada) {
          final yaEjecutada = entrada.tiempoFin <= tiempoActual;
          final enEjecucion = entrada.tiempoInicio <= tiempoActual && 
                             entrada.tiempoFin > tiempoActual;

          return ListTile(
            leading: Icon(
              yaEjecutada
                  ? Icons.check_circle
                  : enEjecucion
                      ? Icons.play_circle_filled
                      : Icons.schedule,
              color: yaEjecutada
                  ? Colors.grey
                  : enEjecucion
                      ? Colors.green
                      : Colors.blue,
            ),
            title: Text(
              entrada.paso.descripcion,
              style: TextStyle(
                decoration: yaEjecutada ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              '${entrada.recetaNombre} (${entrada.recetaInstancia}) • '
              '${_formatearTiempo(entrada.tiempoInicio)} - ${_formatearTiempo(entrada.tiempoFin)}',
            ),
            trailing: Text(
              _formatearTiempo(entrada.paso.tiempoSegundos),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final seg = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }
}
