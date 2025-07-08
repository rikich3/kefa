import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'front/state/receta_provider.dart';
import 'front/state/paso_provider.dart';
import 'front/state/workers_provider.dart';
import 'front/state/instrumentos_provider.dart';
import 'back/dataModels/paso.dart';
import 'back/dataModels/worker.dart';
import 'back/dataModels/instrumentos.dart';
import 'back/dataModels/cocinero_scheduling.dart';
import 'back/dataModels/utensilio_scheduling.dart';
import 'back/dataModels/paso_scheduling.dart';
import 'back/algorithms/kitchen_scheduling_algorithm.dart';

class WorkTab extends StatefulWidget {
  const WorkTab({super.key});

  @override
  State<WorkTab> createState() => _WorkTabState();
}

class _WorkTabState extends State<WorkTab> {
  final Map<String, int> _recetasSeleccionadas = {};
  bool _ejecutandoAlgoritmo = false;
  bool _usarAlgoritmoOptimizado = true; // Nueva opción
  String? _resultadoPlan;
  List<String> _logsProceso = [];

  @override
  void initState() {
    super.initState();
    // Cargar datos al inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() async {
    final recetaProvider = Provider.of<RecetaProvider>(context, listen: false);
    final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
    final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
    final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

    await Future.wait([
      recetaProvider.loadRecetas(),
      pasoProvider.loadPasos(),
      workersProvider.loadWorkers(),
      instrumentosProvider.loadInstrumentos(),
    ]);

    setState(() {});
  }

  List<CocineroScheduling> _convertirWorkersACocineros(List<Worker> workers) {
    final cocineros = <CocineroScheduling>[];
    
    for (final worker in workers) {
      cocineros.add(CocineroScheduling(
        id: worker.nombre,
        nombre: worker.nombre,
        tipo: 'cocinero', // Los workers son cocineros reales
        ori: 0,
      ));
    }

    // Agregar ollas (asumiendo 2 ollas disponibles)
    cocineros.add(CocineroScheduling(
      id: 'olla1',
      nombre: 'Olla 1',
      tipo: 'olla',
      ori: 0,
    ));
    cocineros.add(CocineroScheduling(
      id: 'olla2',
      nombre: 'Olla 2',
      tipo: 'olla',
      ori: 30, // B2 empieza en 30s como en el ejemplo
    ));

    return cocineros;
  }

  List<UtensilioScheduling> _convertirInstrumentosAUtensilios(List<Instrumento> instrumentos) {
    final utensilios = <UtensilioScheduling>[];
    
    for (final instrumento in instrumentos) {
      // Crear una instancia por cada cantidad disponible
      for (int i = 1; i <= instrumento.cantidad; i++) {
        utensilios.add(UtensilioScheduling(
          id: '${instrumento.nombre}_$i',
          nombre: '${instrumento.nombre} $i',
          tipo: instrumento.nombre,
          ori: 0,
        ));
      }
    }

    return utensilios;
  }

  List<PasoScheduling> _convertirPasosAScheduling(List<Paso> pasos, Map<String, int> recetasCantidades) {
    final pasosScheduling = <PasoScheduling>[];
    
    print('🔍 CONVERSION DE PASOS - DEBUG:');
    print('   Recetas y cantidades: $recetasCantidades');
    print('   Total pasos disponibles: ${pasos.length}');
    
    for (final entry in recetasCantidades.entries) {
      final recetaNombre = entry.key;
      final cantidad = entry.value;
      
      print('   Procesando receta: "$recetaNombre" x$cantidad');
      
      // Obtener pasos de esta receta
      final pasosReceta = pasos.where((p) => p.recetaId == recetaNombre).toList();
      pasosReceta.sort((a, b) => a.orden.compareTo(b.orden));
      
      print('   Pasos encontrados para "$recetaNombre": ${pasosReceta.length}');
      for (final paso in pasosReceta) {
        print('     - Paso: "${paso.nombrePaso}" (ID: ${paso.id}, Orden: ${paso.orden})');
        print('       Tipo cocinero: ${paso.tipoCocinero}, Tipo utensilio: ${paso.tipoUtensilio}');
        print('       Duracion: ${paso.tiempoCoccionSegundos + paso.tiempoPreparacionSegundos}s');
        print('       Dependencias: ${paso.dependencias}');
      }
      
      // Crear instancias para cada plato
      for (int i = 0; i < cantidad; i++) {
        for (final paso in pasosReceta) {
          // Crear ID único para cada instancia: nombrePaso_instancia
          final idUnico = '${paso.nombrePaso}_plato${i + 1}';
          
          pasosScheduling.add(PasoScheduling(
            id: idUnico, // Usar ID más descriptivo
            nombre: '${paso.nombrePaso} (Plato ${i + 1})',
            tipoCocinero: paso.tipoCocinero ?? 'cocinero',
            tipoUtensilio: paso.tipoUtensilio ?? 'A', // Default a 'A' si no está definido
            duracion: paso.tiempoCoccionSegundos + paso.tiempoPreparacionSegundos,
            dependencias: _convertirDependencias(paso.dependencias ?? [], pasosReceta, i),
          ));
          
          print('     Agregado: $idUnico');
        }
      }
    }
    
    print('🔍 PASOS FINALES PARA SCHEDULING: ${pasosScheduling.length}');
    for (final paso in pasosScheduling) {
      print('   - ${paso.toString()}');
    }
    
    return pasosScheduling;
  }

  List<String> _convertirDependencias(List<String> dependenciasOriginales, List<Paso> pasosReceta, int numeroPlato) {
    final dependenciasConvertidas = <String>[];
    
    print('     🔗 Convirtiendo dependencias: $dependenciasOriginales');
    
    for (final depId in dependenciasOriginales) {
      try {
        // Buscar el paso correspondiente en la receta por ID
        Paso? pasoDependendiente = pasosReceta.where((p) => p.id == depId).firstOrNull;
        
        // Si no se encuentra por ID, buscar por nombre
        if (pasoDependendiente == null) {
          pasoDependendiente = pasosReceta.where((p) => p.nombrePaso == depId).firstOrNull;
        }
        
        if (pasoDependendiente != null) {
          // Crear la dependencia para el mismo plato
          final depConvertida = '${pasoDependendiente.nombrePaso}_plato${numeroPlato + 1}';
          dependenciasConvertidas.add(depConvertida);
          print('       ✅ Dependencia convertida: $depId -> $depConvertida');
        } else {
          print('       ⚠️ Dependencia no encontrada: $depId (se omite)');
        }
      } catch (e) {
        print('       ❌ Error al convertir dependencia $depId: $e');
      }
    }
    
    print('     🔗 Dependencias finales: $dependenciasConvertidas');
    return dependenciasConvertidas;
  }

  void _ejecutarAlgoritmo() async {
    if (_recetasSeleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos una receta')),
      );
      return;
    }

    setState(() {
      _ejecutandoAlgoritmo = true;
      _resultadoPlan = null;
      _logsProceso = [];
    });

    try {
      print('🚀 INICIANDO ALGORITMO DE SCHEDULING');
      print('=' * 50);
      
      _logsProceso.add('🚀 Iniciando algoritmo de scheduling...');
      _logsProceso.add('📋 Recetas seleccionadas: ${_recetasSeleccionadas.toString()}');

      // Obtener datos de providers
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      final workersProvider = Provider.of<WorkersProvider>(context, listen: false);
      final instrumentosProvider = Provider.of<InstrumentosProvider>(context, listen: false);

      // Convertir datos a formato de scheduling
      final cocineros = _convertirWorkersACocineros(workersProvider.workers);
      final utensilios = _convertirInstrumentosAUtensilios(instrumentosProvider.instrumentos);
      final pasos = _convertirPasosAScheduling(pasoProvider.pasoEntries.map((e) => e.value).toList(), _recetasSeleccionadas);

      print('👨‍🍳 Cocineros disponibles:');
      for (final cocinero in cocineros) {
        print('   - ${cocinero.toString()}');
      }

      print('🔧 Utensilios disponibles:');
      for (final utensilio in utensilios) {
        print('   - ${utensilio.toString()}');
      }

      print('📝 Pasos a ejecutar:');
      for (final paso in pasos) {
        print('   - ${paso.toString()}');
      }

      _logsProceso.add('👨‍🍳 Cocineros: ${cocineros.length}');
      _logsProceso.add('🔧 Utensilios: ${utensilios.length}');
      _logsProceso.add('📝 Pasos totales: ${pasos.length}');

      // Crear y ejecutar algoritmo
      final algoritmo = KitchenSchedulingAlgorithm();
      
      algoritmo.inicializarRecursos(
        listaCocineros: cocineros,
        listaUtensilios: utensilios,
        listaPasos: pasos,
      );

      _logsProceso.add('⚙️ Recursos inicializados');

      // Ejecutar algoritmo (usando el primer paso como raíz por simplicidad)
      if (pasos.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500)); // Simular procesamiento
        // Ejecutar algoritmo según configuración
        if (_usarAlgoritmoOptimizado) {
          algoritmo.ejecutarAlgoritmoOptimizado(pasos.first.id, _recetasSeleccionadas.values.reduce((a, b) => a + b));
        } else {
          algoritmo.ejecutarAlgoritmo(pasos.first.id, _recetasSeleccionadas.values.reduce((a, b) => a + b));
        }
        
        _logsProceso.add('✅ Algoritmo ejecutado exitosamente');
        
        // Generar resultado visual
        _resultadoPlan = _generarPlanVisual(algoritmo);
        
        print('✅ ALGORITMO COMPLETADO');
        print('=' * 50);
      }

    } catch (e) {
      print('❌ Error en algoritmo: $e');
      _logsProceso.add('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al ejecutar algoritmo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _ejecutandoAlgoritmo = false;
        });
      }
    }
  }

  String _generarPlanVisual(KitchenSchedulingAlgorithm algoritmo) {
    final buffer = StringBuffer();
    
    buffer.writeln('📊 PLAN DE COCINA GENERADO');
    buffer.writeln('=' * 40);
    buffer.writeln();
    
    buffer.writeln('👨‍🍳 COCINEROS Y OLLAS:');
    for (final cocinero in algoritmo.cocineros) {
      buffer.writeln('${cocinero.nombre} (${cocinero.tipo}):');
      if (cocinero.horario.isEmpty) {
        buffer.writeln('  Sin tareas asignadas');
      } else {
        for (final item in cocinero.horario) {
          final paso = algoritmo.pasos[item.pasoId];
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln('  Tiempo total ocupado: ${cocinero.ori}s');
      buffer.writeln();
    }
    
    buffer.writeln('🔧 UTENSILIOS:');
    for (final utensilio in algoritmo.utensilios) {
      buffer.writeln('${utensilio.nombre} (${utensilio.tipo}):');
      if (utensilio.horario.isEmpty) {
        buffer.writeln('  Sin uso asignado');
      } else {
        for (final item in utensilio.horario) {
          final paso = algoritmo.pasos[item.pasoId];
          buffer.writeln('  ${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso?.nombre ?? 'Paso desconocido'}');
        }
      }
      buffer.writeln('  Tiempo total ocupado: ${utensilio.ori}s');
      buffer.writeln();
    }
    
    final tiempoTotal = algoritmo.cocineros.map((c) => c.ori).reduce((a, b) => a > b ? a : b);
    buffer.writeln('⏱️ TIEMPO TOTAL DE COCINA: ${tiempoTotal}s (${(tiempoTotal / 60).toStringAsFixed(1)} minutos)');
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Consumer4<RecetaProvider, PasoProvider, WorkersProvider, InstrumentosProvider>(
        builder: (context, recetaProvider, pasoProvider, workersProvider, instrumentosProvider, child) {
          return ListView(
            children: [
              // Título
              Text(
                'Realizar Cocina',
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Selecciona las recetas y cantidades para generar el plan de cocina optimizado',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Estado de recursos
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recursos Disponibles',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRecursoInfo('👨‍🍳 Cocineros', workersProvider.workers.length.toString(), colorScheme),
                          _buildRecursoInfo('🔧 Utensilios', instrumentosProvider.instrumentos.fold<int>(0, (sum, i) => sum + i.cantidad).toString(), colorScheme),
                          _buildRecursoInfo('📖 Recetas', recetaProvider.recetaEntries.length.toString(), colorScheme),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Selección de recetas
              Text(
                'Seleccionar Recetas y Cantidades',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (recetaProvider.recetaEntries.isEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_menu_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay recetas disponibles',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vaya a la pestaña "Gestionar" para crear recetas',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ...recetaProvider.recetaEntries.map((entry) {
                  final receta = entry.value;
                  final cantidad = _recetasSeleccionadas[receta.nombre] ?? 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        child: Text(receta.categoria[0].toUpperCase()),
                      ),
                      title: Text(receta.nombre),
                      subtitle: Text('${receta.descripcion}\n${receta.duracionEstimadaMinutos} min • ${receta.cantidadPorciones} porciones'),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: cantidad > 0 ? () {
                              setState(() {
                                if (cantidad == 1) {
                                  _recetasSeleccionadas.remove(receta.nombre);
                                } else {
                                  _recetasSeleccionadas[receta.nombre] = cantidad - 1;
                                }
                              });
                            } : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Container(
                            width: 40,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.outline),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Center(
                              child: Text(
                                cantidad.toString(),
                                style: textTheme.titleMedium,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _recetasSeleccionadas[receta.nombre] = cantidad + 1;
                              });
                            },
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
              
              const SizedBox(height: 24),

              // Configuración de algoritmo
              if (_recetasSeleccionadas.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración del Algoritmo',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Usar Algoritmo Optimizado'),
                          subtitle: Text(_usarAlgoritmoOptimizado 
                            ? 'Mejor paralelización y balance de recursos'
                            : 'Algoritmo original secuencial'),
                          value: _usarAlgoritmoOptimizado,
                          onChanged: (value) {
                            setState(() {
                              _usarAlgoritmoOptimizado = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botón ejecutar
              if (_recetasSeleccionadas.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: _ejecutandoAlgoritmo ? null : _ejecutarAlgoritmo,
                  icon: _ejecutandoAlgoritmo 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                  label: Text(_ejecutandoAlgoritmo ? 'Generando Plan...' : 'Generar Plan de Cocina'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Logs del proceso
              if (_logsProceso.isNotEmpty) ...[
                Text(
                  'Proceso de Ejecución',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _logsProceso.map((log) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Resultado del plan
              if (_resultadoPlan != null) ...[
                Text(
                  'Plan Generado',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
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
                              'Plan de Cocina Optimizado',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colorScheme.outline),
                          ),
                          child: Text(
                            _resultadoPlan!,
                            style: textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecursoInfo(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onPrimaryContainer.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

class WorkTabPlaceholder extends StatelessWidget {
  const WorkTabPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkTab();
  }
}