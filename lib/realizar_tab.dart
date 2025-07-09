import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'front/state/workers_provider.dart';
import 'front/state/instrumentos_provider.dart';
import 'back/dataModels/receta.dart';
import 'back/system/sistema_preprocesamiento.dart';
import 'back/system/sistema_ejecucion.dart';
import 'widgets/seleccion_recetas_widget.dart';
import 'widgets/vista_agendas_widget.dart';
import 'widgets/control_ejecucion_widget.dart';

class RealizarTab extends StatefulWidget {
  const RealizarTab({super.key});

  @override
  State<RealizarTab> createState() => _RealizarTabState();
}

class _RealizarTabState extends State<RealizarTab> {
  final List<RecetaConCantidad> _recetasSeleccionadas = [];
  SistemaPreprocesamiento? _sistemaPreprocesamiento;
  SistemaEjecucion? _sistemaEjecucion;
  bool _preprocesado = false;
  
  @override
  void dispose() {
    _sistemaEjecucion?.dispose();
    super.dispose();
  }
  
  /// Agrega una receta a la selección
  void _agregarReceta(Receta receta, int cantidad) {
    setState(() {
      _recetasSeleccionadas.add(RecetaConCantidad(
        receta: receta,
        cantidad: cantidad,
      ));
    });
  }
  
  /// Elimina una receta de la selección
  void _eliminarReceta(int index) {
    setState(() {
      _recetasSeleccionadas.removeAt(index);
      _preprocesado = false;
      _sistemaEjecucion?.dispose();
      _sistemaEjecucion = null;
    });
  }
  
  /// Ejecuta el preprocesamiento
  void _ejecutarPreprocesamiento() {
    if (_recetasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar al menos una receta para procesar'),
        ),
      );
      return;
    }
    
    final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
    final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);
    
    if (workersProvider.workers.isEmpty) {
      // Utiliza debugPrint para logging en Flutter
      debugPrint('Trabajadores disponibles: ${workersProvider.workers}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay trabajadores disponibles en la base de datos'),
        ),
      );
      return;
    }
    
    if (instrumentosProvider.instrumentos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay instrumentos disponibles en la base de datos'),
        ),
      );
      return;
    }
    debugPrint('Trabajadores disponibles: ${workersProvider.workers.length}');
    debugPrint('Instrumentos disponibles: ${instrumentosProvider.instrumentos.length}');
    setState(() {
      _sistemaPreprocesamiento = SistemaPreprocesamiento(
        trabajadoresDisponibles: workersProvider.workers,
        utensiliosDisponibles: instrumentosProvider.instrumentos,
      );
      
      _sistemaPreprocesamiento!.preprocesar(_recetasSeleccionadas);
      
      final agendasCombinadas = _sistemaPreprocesamiento!.obtenerAgendasCombinadas();
      
      _sistemaEjecucion?.dispose();
      _sistemaEjecucion = SistemaEjecucion(
        agendasCombinadas: agendasCombinadas,
        onNotificacionAudio: _manejarNotificacionAudio,
      );
      
      _preprocesado = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preprocesamiento completado. Tiempo estimado: ${_formatearTiempo(_sistemaPreprocesamiento!.tiempoTotalEstimado)}'
        ),
      ),
    );
  }
  
  /// Maneja las notificaciones de audio
  void _manejarNotificacionAudio(String mensaje) {
    // En una implementación real, aquí se reproduciría audio
    // Por ahora, mostraremos un snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  /// Formatea tiempo en segundos a mm:ss
  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final seg = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Realizar Recetas',
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Sección de selección de recetas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Seleccionar Recetas',
                          style: textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Widget de selección de recetas
                    SeleccionRecetasWidget(
                      recetasSeleccionadas: _recetasSeleccionadas,
                      onAgregarReceta: _agregarReceta,
                      onEliminarReceta: _eliminarReceta,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botón de preprocesamiento
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _recetasSeleccionadas.isNotEmpty 
                            ? _ejecutarPreprocesamiento 
                            : null,
                        icon: const Icon(Icons.settings_suggest),
                        label: const Text('Ejecutar Preprocesamiento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_preprocesado) ...[
              const SizedBox(height: 24),
              
              // Sección de control de ejecución
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ControlEjecucionWidget(
                    sistemaEjecucion: _sistemaEjecucion!,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección de vista de agendas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: VistaAgendasWidget(
                    sistemaEjecucion: _sistemaEjecucion!,
                    sistemaPreprocesamiento: _sistemaPreprocesamiento!,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
