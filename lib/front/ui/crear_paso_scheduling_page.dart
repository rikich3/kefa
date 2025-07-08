import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/paso.dart';
import '../../back/dataModels/instrumentos.dart';
import '../state/paso_provider.dart';
import '../state/ingredientes_provider.dart';
import '../state/instrumentos_provider.dart';

class CrearPasoSchedulingDialog extends StatefulWidget {
  final String recetaId;
  final int orden;
  final Paso? pasoParaEditar;

  const CrearPasoSchedulingDialog({
    super.key,
    required this.recetaId,
    required this.orden,
    this.pasoParaEditar,
  });

  @override
  State<CrearPasoSchedulingDialog> createState() => _CrearPasoSchedulingDialogState();
}

class _CrearPasoSchedulingDialogState extends State<CrearPasoSchedulingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _tiempoController = TextEditingController();

  // Campos para scheduling
  String _tipoCocineroSeleccionado = 'cocinero';
  String? _tipoUtensilioSeleccionado; // Cambiar a String? para permitir null inicialmente
  List<String> _dependenciasSeleccionadas = [];
  List<IngredienteRequerido> _ingredientesRequeridos = [];

  final List<String> _tiposCocinero = ['cocinero', 'olla'];

  bool get _esEdicion => widget.pasoParaEditar != null;

  @override
  void initState() {
    super.initState();
    
    // Cargar los pasos de la receta actual para el selector de dependencias
    // Lo hacemos inmediatamente para asegurar que los datos estén disponibles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PasoProvider>(context, listen: false).loadPasosByRecetaId(widget.recetaId);
    });
    
    if (_esEdicion) {
      final paso = widget.pasoParaEditar!;
      _nombreController.text = paso.nombrePaso;
      _descripcionController.text = paso.contenidoAccion;
      _tiempoController.text = paso.tiempoCoccionSegundos.toString();
      _tipoCocineroSeleccionado = paso.tipoCocinero ?? 'cocinero';
      _tipoUtensilioSeleccionado = paso.tipoUtensilio; // Puede ser null
      _dependenciasSeleccionadas = List<String>.from(paso.dependencias ?? []);
      _ingredientesRequeridos = List.from(paso.ingredientesRequeridos);
      
      print('🔧 Editando paso: ${paso.nombrePaso} (ID: ${paso.id})');
      print('   Dependencias actuales: $_dependenciasSeleccionadas');
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _tiempoController.dispose();
    super.dispose();
  }

  void _mostrarSelectorIngredientes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Seleccionar Ingredientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<IngredientesProvider>(
                      builder: (context, provider, child) {
                        return ListView.builder(
                          itemCount: provider.ingredientesEntries.length,
                          itemBuilder: (context, index) {
                            final ingrediente = provider.ingredientesEntries[index].value;
                            final key = provider.ingredientesEntries[index].key.toString();
                            
                            final ingredientesEncontrados = _ingredientesRequeridos
                                .where((req) => req.ingredienteId == key);
                            final existingIngredient = ingredientesEncontrados.isNotEmpty ? 
                                ingredientesEncontrados.first : null;
                            
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: existingIngredient != null,
                                          onChanged: (bool? value) {
                                            setModalState(() {
                                              if (value == true) {
                                                _ingredientesRequeridos.add(
                                                  IngredienteRequerido(
                                                    ingredienteId: key,
                                                    cantidad: 1.0,
                                                    unidadMedida: 'gr',
                                                  ),
                                                );
                                              } else {
                                                _ingredientesRequeridos
                                                    .removeWhere((req) => req.ingredienteId == key);
                                              }
                                            });
                                          },
                                        ),
                                        Expanded(
                                          child: Text(
                                            ingrediente.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (existingIngredient != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: TextFormField(
                                              initialValue: existingIngredient.cantidad.toString(),
                                              decoration: const InputDecoration(
                                                labelText: 'Cantidad',
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (value) {
                                                final cantidad = double.tryParse(value) ?? 1.0;
                                                final index = _ingredientesRequeridos
                                                    .indexWhere((req) => req.ingredienteId == key);
                                                if (index >= 0) {
                                                  _ingredientesRequeridos[index] = IngredienteRequerido(
                                                    ingredienteId: key,
                                                    cantidad: cantidad,
                                                    unidadMedida: _ingredientesRequeridos[index].unidadMedida,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 100,
                                            child: DropdownButtonFormField<String>(
                                              value: existingIngredient.unidadMedida,
                                              decoration: const InputDecoration(
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              ),
                                              items: ['gr', 'ml', 'cc', 'taza', 'cuchara', 'cucharita']
                                                  .map((unidad) => DropdownMenuItem(
                                                        value: unidad,
                                                        child: Text(unidad),
                                                      ))
                                                  .toList(),
                                              onChanged: (String? newValue) {
                                                if (newValue != null) {
                                                  final index = _ingredientesRequeridos
                                                      .indexWhere((req) => req.ingredienteId == key);
                                                  if (index >= 0) {
                                                    setModalState(() {
                                                      _ingredientesRequeridos[index] = IngredienteRequerido(
                                                        ingredienteId: key,
                                                        cantidad: _ingredientesRequeridos[index].cantidad,
                                                        unidadMedida: newValue,
                                                      );
                                                    });
                                                  }
                                                }
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {});
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarSelectorDependencias() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seleccionar Dependencias'),
                  IconButton(
                    onPressed: () {
                      // Recargar pasos manualmente
                      Provider.of<PasoProvider>(context, listen: false).loadPasosByRecetaId(widget.recetaId);
                      setDialogState(() {});
                    },
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refrescar pasos',
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Seleccione los pasos de los que depende este paso:'),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Consumer<PasoProvider>(
                        builder: (context, pasoProvider, child) {
                          print('🔍 Depuración Selector Dependencias:');
                          print('   Receta ID actual: ${widget.recetaId}');
                          print('   Cantidad pasos en provider: ${pasoProvider.pasosCurrentReceta.length}');
                          print('   Pasos disponibles: ${pasoProvider.pasosCurrentReceta.map((e) => '${e.value.id}-${e.value.nombrePaso}').toList()}');
                          
                          final pasosDisponibles = pasoProvider.pasosCurrentReceta
                              .where((entry) {
                                final paso = entry.value;
                                // Excluir el paso actual si estamos editando
                                if (_esEdicion && paso.id == widget.pasoParaEditar!.id) {
                                  return false;
                                }
                                return true;
                              }).toList();

                          if (pasosDisponibles.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline, size: 48),
                                  const SizedBox(height: 16),
                                  Text(
                                    pasoProvider.pasosCurrentReceta.isEmpty 
                                      ? 'No hay pasos cargados para esta receta.\nPresione el botón de refrescar.'
                                      : 'No hay otros pasos disponibles en esta receta',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: pasosDisponibles.length,
                            itemBuilder: (context, index) {
                              final pasoEntry = pasosDisponibles[index];
                              final paso = pasoEntry.value;
                              final estaSeleccionado = _dependenciasSeleccionadas.contains(paso.id);

                              return CheckboxListTile(
                                title: Text(paso.nombrePaso),
                                subtitle: Text('ID: ${paso.id}'),
                                value: estaSeleccionado,
                                onChanged: (bool? selected) {
                                  setDialogState(() {
                                    if (selected == true) {
                                      if (!_dependenciasSeleccionadas.contains(paso.id)) {
                                        _dependenciasSeleccionadas.add(paso.id);
                                      }
                                    } else {
                                      _dependenciasSeleccionadas.remove(paso.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {});
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _guardarPaso() async {
    if (_formKey.currentState!.validate()) {
      final paso = Paso(
        id: _esEdicion ? widget.pasoParaEditar!.id : DateTime.now().millisecondsSinceEpoch.toString(),
        recetaId: widget.recetaId,
        nombrePaso: _nombreController.text,
        contenidoAccion: _descripcionController.text,
        recursosCocinasRequeridos: [],
        ingredientesRequeridos: List.from(_ingredientesRequeridos),
        recursoAlmacenamiento: [],
        tiempoCoccionSegundos: int.tryParse(_tiempoController.text) ?? 0,
        tiempoPreparacionSegundos: 0,
        tipoCoccion: 'general',
        tipoAlmacenamiento: 'general',
        tareasAnterioresDirectas: [],
        orden: widget.orden,
        // Campos para scheduling
        tipoCocinero: _tipoCocineroSeleccionado,
        tipoUtensilio: _tipoUtensilioSeleccionado,
        dependencias: List.from(_dependenciasSeleccionadas),
      );

      try {
        if (_esEdicion) {
          final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
          
          // Asegurar que tenemos los datos más actualizados
          await pasoProvider.loadPasos();
          
          // Buscar la key del paso en la lista general (que tiene las keys reales de Hive)
          dynamic pasoKey;
          try {
            final entryGeneral = pasoProvider.pasoEntries
                .firstWhere((entry) => entry.value.id == widget.pasoParaEditar!.id);
            pasoKey = entryGeneral.key;
            
            print('🔧 Editando paso con ID: ${widget.pasoParaEditar!.id}, key encontrada: $pasoKey');
          } catch (e) {
            throw Exception('No se pudo encontrar el paso para editar. ID: ${widget.pasoParaEditar!.id}. Error: $e');
          }
          
          await pasoProvider.updatePaso(pasoKey, paso);
        } else {
          print('🆕 Creando nuevo paso con ID: ${paso.id}');
          await Provider.of<PasoProvider>(context, listen: false).addPaso(paso);
        }
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        print('❌ Error al guardar paso: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar paso: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Título
              Text(
                _esEdicion ? 'Editar Paso' : 'Crear Nuevo Paso',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Nombre del paso
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del paso',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_alt),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del paso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del paso',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la descripción del paso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tiempo del paso
              TextFormField(
                controller: _tiempoController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo del paso (segundos)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el tiempo del paso';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Configuración de Scheduling
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración para Algoritmo de Scheduling',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tipo de Cocinero
                      DropdownButtonFormField<String>(
                        value: _tipoCocineroSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Cocinero/Cocina',
                          border: OutlineInputBorder(),
                          helperText: 'Cocinero: persona / Olla: cocina automática',
                        ),
                        items: _tiposCocinero.map((String tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Row(
                              children: [
                                Icon(tipo == 'cocinero' ? Icons.person : Icons.kitchen),
                                const SizedBox(width: 8),
                                Text(tipo == 'cocinero' ? 'Cocinero (Persona)' : 'Olla (Cocina)'),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _tipoCocineroSeleccionado = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tipo de Utensilio (Instrumentos)
                      Consumer<InstrumentosProvider>(
                        builder: (context, instrumentosProvider, child) {
                          final instrumentos = instrumentosProvider.instrumentos;
                          
                          return DropdownButtonFormField<String>(
                            value: _tipoUtensilioSeleccionado,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Utensilio',
                              border: OutlineInputBorder(),
                              helperText: 'Selecciona el tipo de utensilio requerido',
                            ),
                            items: instrumentos.map((Instrumento instrumento) {
                              return DropdownMenuItem<String>(
                                value: instrumento.nombre,
                                child: Text('${instrumento.nombre} (${instrumento.cantidad} disponibles)'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _tipoUtensilioSeleccionado = newValue;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Debe seleccionar un tipo de utensilio';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dependencias
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dependencias',
                                  style: textTheme.labelLarge,
                                ),
                                FilledButton.icon(
                                  onPressed: _mostrarSelectorDependencias,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Consumer<PasoProvider>(
                              builder: (context, pasoProvider, child) {
                                if (_dependenciasSeleccionadas.isEmpty) {
                                  return Text(
                                    'Sin dependencias',
                                    style: textTheme.bodyMedium,
                                  );
                                }
                                
                                // Buscar los nombres de los pasos seleccionados
                                final nombresDependencias = _dependenciasSeleccionadas.map((pasoId) {
                                  // Buscar el paso por ID en la lista de pasos actuales
                                  try {
                                    final pasoEncontrado = pasoProvider.pasosCurrentReceta
                                        .firstWhere((entry) => entry.value.id == pasoId);
                                    return pasoEncontrado.value.nombrePaso;
                                  } catch (e) {
                                    return 'Paso no encontrado ($pasoId)';
                                  }
                                }).join(', ');

                                return Text(
                                  'Depende de: $nombresDependencias',
                                  style: textTheme.bodyMedium,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ingredientes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ingredientes Requeridos',
                            style: textTheme.titleMedium,
                          ),
                          FilledButton.icon(
                            onPressed: _mostrarSelectorIngredientes,
                            icon: const Icon(Icons.add),
                            label: const Text('Seleccionar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_ingredientesRequeridos.isNotEmpty) ...[
                        for (var req in _ingredientesRequeridos)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('• ${req.cantidad} ${req.unidadMedida}'),
                          ),
                      ] else
                        const Text('Ningún ingrediente seleccionado'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _guardarPaso,
                      icon: Icon(_esEdicion ? Icons.save : Icons.add_task),
                      label: Text(_esEdicion ? 'Actualizar' : 'Crear Paso'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
