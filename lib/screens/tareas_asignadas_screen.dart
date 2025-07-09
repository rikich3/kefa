import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../front/state/workers_provider.dart';
import '../front/state/tarea_asignada_provider.dart';
import 'agenda_cocinero_screen.dart';

class TareasAsignadasScreen extends StatefulWidget {
  const TareasAsignadasScreen({super.key});

  @override
  State<TareasAsignadasScreen> createState() => _TareasAsignadasScreenState();
}

class _TareasAsignadasScreenState extends State<TareasAsignadasScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar tareas al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TareaAsignadaProvider>(context, listen: false).cargarTareas();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tareas Asignadas a Cocineros'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          Consumer<TareaAsignadaProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.hayTareasAsignadas
                    ? () => _mostrarDialogoBorrarTodas(context)
                    : null,
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Borrar todas las agendas',
              );
            },
          ),
        ],
      ),
      body: Consumer2<WorkersProvider, TareaAsignadaProvider>(
        builder: (context, workersProvider, tareasProvider, child) {
          if (tareasProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (tareasProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar tareas',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tareasProvider.errorMessage!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => tareasProvider.cargarTareas(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final workers = workersProvider.workers;

          if (workers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay cocineros disponibles',
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vaya a la pestaña "Gestionar" para agregar cocineros',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información general
                Card(
                  color: colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Resumen de Tareas',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total de cocineros: ${workers.length} • '
                                'Tareas asignadas: ${tareasProvider.totalTareas}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Lista de cocineros
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      final cocineroId = worker.nombre;
                      final cantidadTareas = tareasProvider.contarTareasCocinero(cocineroId);
                      final tieneTareas = tareasProvider.cocineroTieneTareas(cocineroId);

                      return Card(
                        elevation: tieneTareas ? 4 : 1,
                        color: tieneTareas 
                            ? colorScheme.surfaceVariant 
                            : colorScheme.surface,
                        child: InkWell(
                          onTap: () => _navegarAAgendaCocinero(context, cocineroId, worker.nombre),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: tieneTareas 
                                      ? colorScheme.primary 
                                      : colorScheme.outline,
                                  foregroundColor: tieneTareas 
                                      ? colorScheme.onPrimary 
                                      : colorScheme.onSurface,
                                  child: Text(
                                    worker.nombre[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  worker.nombre,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tieneTareas 
                                        ? colorScheme.primary 
                                        : colorScheme.outline,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    tieneTareas 
                                        ? '$cantidadTareas tareas' 
                                        : 'Sin tareas',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: tieneTareas 
                                          ? colorScheme.onPrimary 
                                          : colorScheme.onSurface,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                FilledButton.icon(
                                  onPressed: () => _navegarAAgendaCocinero(context, cocineroId, worker.nombre),
                                  icon: const Icon(Icons.calendar_today, size: 16),
                                  label: const Text('Ver Agenda'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navegarAAgendaCocinero(BuildContext context, String cocineroId, String cocineroNombre) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AgendaCocieroScreen(
          cocineroId: cocineroId,
          cocineroNombre: cocineroNombre,
        ),
      ),
    );
  }

  void _mostrarDialogoBorrarTodas(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text(
            '¿Está seguro que desea borrar TODAS las agendas de TODOS los cocineros?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<TareaAsignadaProvider>(context, listen: false)
                    .borrarTodasLasTareas();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todas las agendas han sido borradas'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Borrar Todas'),
            ),
          ],
        );
      },
    );
  }
}
