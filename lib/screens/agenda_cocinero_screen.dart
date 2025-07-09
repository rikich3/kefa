import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../front/state/tarea_asignada_provider.dart';
import '../back/dataModels/tarea_asignada.dart';

class AgendaCocineroScreen extends StatefulWidget {
  final String cocineroId;
  final String cocineroNombre;

  const AgendaCocineroScreen({
    super.key,
    required this.cocineroId,
    required this.cocineroNombre,
  });

  @override
  State<AgendaCocineroScreen> createState() => _AgendaCocineroScreenState();
}

class _AgendaCocineroScreenState extends State<AgendaCocineroScreen> {
  int _selectedTaskIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TareaAsignadaProvider>().cargarTareas();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Agenda - ${widget.cocineroNombre}'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            onPressed: _mostrarDialogoBorrarAgenda,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Borrar agenda',
          ),
        ],
      ),
      body: Consumer<TareaAsignadaProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final tareas = provider.getTareasCocinero(widget.cocineroId);

          if (tareas.isEmpty) {
            return _buildEmptyState(colorScheme);
          }

          // Asegurar que el índice seleccionado esté dentro del rango
          if (_selectedTaskIndex >= tareas.length) {
            _selectedTaskIndex = 0;
          }

          return Column(
            children: [
              // Barra horizontal de tareas
              _buildTaskBar(tareas, colorScheme),
              
              // Contenido principal con navegación
              Expanded(
                child: _buildTaskContent(tareas, colorScheme),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tareas asignadas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Este cocinero no tiene tareas en su agenda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskDurationIndicator(int durationSeconds, ColorScheme colorScheme, bool isSelected) {
    // Calculate width based on duration (max 10 minutes = full width)
    final widthPercentage = (durationSeconds / 600).clamp(0.2, 1.0);
    
    return Container(
      width: 40 * widthPercentage,
      height: 3,
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: isSelected 
          ? colorScheme.onPrimary.withOpacity(0.8)
          : colorScheme.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTaskBar(List<TareaAsignada> tareas, ColorScheme colorScheme) {
    // Ordenar tareas por tiempo de inicio
    final tareasOrdenadas = List<TareaAsignada>.from(tareas)
      ..sort((a, b) => a.tiempoInicioSegundos.compareTo(b.tiempoInicioSegundos));

    return Container(
      height: 90,  // Increased height to accommodate duration indicator
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: tareasOrdenadas.length,
        itemBuilder: (context, index) {
          final tarea = tareasOrdenadas[index];
          final isSelected = index == _selectedTaskIndex;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _selectTask(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                decoration: BoxDecoration(
                  color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected 
                      ? colorScheme.primary 
                      : colorScheme.outline.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'T${tarea.orden}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected 
                          ? colorScheme.onPrimary 
                          : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tarea.tiempoInicioFormateado,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected 
                          ? colorScheme.onPrimary.withOpacity(0.8)
                          : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    _buildTaskDurationIndicator(tarea.duracionSegundos, colorScheme, isSelected),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskContent(List<TareaAsignada> tareas, ColorScheme colorScheme) {
    return Column(
      children: [
        // Navegación
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filled(
                onPressed: _selectedTaskIndex > 0 ? _previousTask : null,
                icon: const Icon(Icons.keyboard_arrow_left),
                style: IconButton.styleFrom(
                  backgroundColor: _selectedTaskIndex > 0 
                    ? colorScheme.primaryContainer 
                    : colorScheme.surfaceVariant,
                ),
              ),
              
              Text(
                'Tarea ${_selectedTaskIndex + 1} de ${tareas.length}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              IconButton.filled(
                onPressed: _selectedTaskIndex < tareas.length - 1 ? _nextTask : null,
                icon: const Icon(Icons.keyboard_arrow_right),
                style: IconButton.styleFrom(
                  backgroundColor: _selectedTaskIndex < tareas.length - 1 
                    ? colorScheme.primaryContainer 
                    : colorScheme.surfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Contenido de la tarea
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedTaskIndex = index;
              });
            },
            itemCount: tareas.length,
            itemBuilder: (context, index) {
              return _buildTaskDetails(tareas[index], colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskDetails(TareaAsignada tarea, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y ID
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'T${tarea.orden}',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tarea.nombreTarea,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (tarea.descripcion.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      tarea.descripcion,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información de tiempo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Horario',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTimeInfo('Inicio', tarea.tiempoInicioFormateado, Icons.play_arrow, colorScheme),
                  const SizedBox(height: 8),
                  _buildTimeInfo('Duración', tarea.duracionFormateada, Icons.timer, colorScheme),
                  const SizedBox(height: 8),
                  _buildTimeInfo('Fin', _formatearTiempo(tarea.tiempoFinSegundos), Icons.stop, colorScheme),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Utensilios requeridos
          if (tarea.utensiliosRequeridos.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.kitchen, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Utensilios Requeridos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tarea.utensiliosRequeridos.map((utensilio) {
                        return Chip(
                          label: Text(utensilio),
                          backgroundColor: colorScheme.secondaryContainer,
                          labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Información adicional
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Información',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('ID de Tarea', tarea.id, colorScheme),
                  _buildInfoRow('Asignado el', _formatearFecha(tarea.fechaAsignacion), colorScheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String value, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectTask(int index) {
    setState(() {
      _selectedTaskIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousTask() {
    if (_selectedTaskIndex > 0) {
      _selectTask(_selectedTaskIndex - 1);
    }
  }

  void _nextTask() {
    final tareas = context.read<TareaAsignadaProvider>().getTareasCocinero(widget.cocineroId);
    if (_selectedTaskIndex < tareas.length - 1) {
      _selectTask(_selectedTaskIndex + 1);
    }
  }

  void _mostrarDialogoBorrarAgenda() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text('¿Está seguro que desea borrar la agenda de ${widget.cocineroNombre}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _borrarAgendaCocinero();
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Borrar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarError(String mensaje) {
    if (!mounted) return;
    
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onError),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: colorScheme.onError,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _borrarAgendaCocinero() async {
    try {
      await context.read<TareaAsignadaProvider>().borrarTareasCocinero(widget.cocineroId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Agenda de ${widget.cocineroNombre} borrada exitosamente'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Si no quedan tareas, volver a la pantalla anterior
        final provider = context.read<TareaAsignadaProvider>();
        if (!provider.cocineroTieneTareas(widget.cocineroId)) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      _mostrarError('Error al borrar agenda: $e');
    }
  }

  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final secs = segundos % 60;
    return '${minutos}m ${secs}s';
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}
