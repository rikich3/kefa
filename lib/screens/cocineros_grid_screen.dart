import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../front/state/workers_provider.dart';
import '../front/state/tarea_asignada_provider.dart';
import 'agenda_cocinero_screen.dart';

class CocinerosGridScreen extends StatefulWidget {
  const CocinerosGridScreen({super.key});

  @override
  State<CocinerosGridScreen> createState() => _CocinerosGridScreenState();
}

class _CocinerosGridScreenState extends State<CocinerosGridScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() async {
    final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
    final tareasProvider = Provider.of<TareaAsignadaProvider>(context, listen: false);

    await Future.wait([
      workersProvider.loadWorkers(),
      tareasProvider.cargarTareas(),
    ]);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        title: Text(
          'Cocineros Disponibles',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        elevation: 0,
      ),
      body: Consumer2<WorkersProvider, TareaAsignadaProvider>(
        builder: (context, workersProvider, tareasProvider, child) {
          // Obtener todos los cocineros (incluir workers y ollas)
          final workers = workersProvider.workers;
          final cocineros = <Map<String, dynamic>>[];
          
          // Agregar workers como cocineros
          for (final worker in workers) {
            final tareasDelCocinero = tareasProvider.getTareasCocinero(worker.nombre).length;
                
            cocineros.add({
              'id': worker.nombre,
              'nombre': worker.nombre,
              'tipo': 'Cocinero',
              'icono': Icons.person_outline,
              'color': Colors.blue,
              'cantidadTareas': tareasDelCocinero,
            });
          }
          
          // Agregar ollas (asumiendo que tenemos 2 ollas)
          for (int i = 1; i <= 2; i++) {
            final ollaId = 'olla$i';
            final tareasDeOlla = tareasProvider.getTareasCocinero(ollaId).length;
                
            cocineros.add({
              'id': ollaId,
              'nombre': 'Olla $i',
              'tipo': 'Olla',
              'icono': Icons.soup_kitchen_outlined,
              'color': Colors.orange,
              'cantidadTareas': tareasDeOlla,
            });
          }

          if (cocineros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay cocineros disponibles',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vaya a la pestaña "Gestionar" para agregar trabajadores',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
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
                          child: Text(
                            'Seleccione un cocinero para ver su agenda de tareas asignadas',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título de la grilla
                Text(
                  'Cocineros y Equipos (${cocineros.length})',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Grilla de cocineros
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: cocineros.length,
                    itemBuilder: (context, index) {
                      final cocinero = cocineros[index];
                      return _buildCocineroCard(
                        context,
                        cocinero,
                        colorScheme,
                        textTheme,
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

  Widget _buildCocineroCard(
    BuildContext context,
    Map<String, dynamic> cocinero,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navegarAAgendaCocinero(cocinero['id'], cocinero['nombre']),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (cocinero['color'] as Color).withOpacity(0.1),
                (cocinero['color'] as Color).withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono del cocinero
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cocinero['color'],
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    cocinero['icono'],
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Nombre del cocinero
                Text(
                  cocinero['nombre'],
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Tipo
                Text(
                  cocinero['tipo'],
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Cantidad de tareas
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cocinero['cantidadTareas'] > 0 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cocinero['cantidadTareas']} tareas',
                    style: textTheme.bodySmall?.copyWith(
                      color: cocinero['cantidadTareas'] > 0 
                          ? Colors.green[800]
                          : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Botón de acción
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _navegarAAgendaCocinero(cocinero['id'], cocinero['nombre']),
                    icon: const Icon(Icons.calendar_view_day, size: 16),
                    label: const Text('Ver Agenda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cocinero['color'],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      textStyle: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navegarAAgendaCocinero(String cocineroId, String cocineroNombre) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AgendaCocineroScreen(
          cocineroId: cocineroId,
          cocineroNombre: cocineroNombre,
        ),
      ),
    );
  }
}
