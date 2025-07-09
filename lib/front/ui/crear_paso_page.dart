import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/paso.dart';
// import '../../back/dataModels/ingredientes.dart'; // Unused
// import '../../back/dataModels/worker.dart'; // Unused
// import '../../back/dataModels/instrumentos.dart'; // Unused
import '../../front/state/paso_provider.dart';
import '../../front/state/ingredientes_provider.dart';
import '../../front/state/workers_provider.dart';
import '../../front/state/instrumentos_provider.dart';

class CrearPasoPage extends StatefulWidget {
  final String recetaId;
  final int orden;

  const CrearPasoPage({
    super.key,
    required this.recetaId,
    required this.orden,
  });

  @override
  State<CrearPasoPage> createState() => _CrearPasoPageState();
}

class _CrearPasoPageState extends State<CrearPasoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _contenidoController = TextEditingController();
  final _tiempoCoccionController = TextEditingController();
  final _tiempoPreparacionController = TextEditingController();

  String _tipoCoccionSeleccionado = 'carnes';
  String _tipoAlmacenamientoSeleccionado = 'carnes';

  // Campos para scheduling
  String _tipoCocineroSeleccionado = 'cocinero';
  String _tipoUtensilioSeleccionado = 'A';
  List<String> _dependenciasSeleccionadas = [];

  final List<String> _tiposCocinero = ['cocinero', 'olla'];
  final List<String> _tiposUtensilio = ['A', 'B', 'C', 'D']; // Tipos de utensilios para scheduling

  final List<String> _tiposCoccion = [
    'carnes',
    'vegetales',
    'pescados y mariscos',
    'alimentos cocidos',
    'pan o productos secos',
    'postres o massa dulces',
    'otro'
  ];

  List<String> _recursosSeleccionados = [];
  List<IngredienteRequerido> _ingredientesRequeridos = [];
  List<String> _almacenamientoSeleccionado = [];
  List<String> _tareasAnteriores = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _contenidoController.dispose();
    _tiempoCoccionController.dispose();
    _tiempoPreparacionController.dispose();
    super.dispose();
  }

  void _mostrarSelectorRecursos() {
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
                  const Text('Seleccionar Recursos de Cocina',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Utensilios'),
                              Tab(text: 'Trabajadores'),
                            ],
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Tab de Utensilios
                                Consumer<InstrumentosProvider>(
                                  builder: (context, provider, child) {
                                    return ListView.builder(
                                      itemCount: provider.instrumentosEntries.length,
                                      itemBuilder: (context, index) {
                                        final instrumento = provider.instrumentosEntries[index].value;
                                        final key = provider.instrumentosEntries[index].key.toString();
                                        return CheckboxListTile(
                                          title: Text(instrumento.nombre),
                                          subtitle: Text(instrumento.descripcion),
                                          value: _recursosSeleccionados.contains(key),
                                          onChanged: (bool? value) {
                                            setModalState(() {
                                              if (value == true) {
                                                _recursosSeleccionados.add(key);
                                              } else {
                                                _recursosSeleccionados.remove(key);
                                              }
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                                // Tab de Trabajadores
                                Consumer<WorkersProvider>(
                                  builder: (context, provider, child) {
                                    return ListView.builder(
                                      itemCount: provider.workerEntries.length,
                                      itemBuilder: (context, index) {
                                        final worker = provider.workerEntries[index].value;
                                        final key = provider.workerEntries[index].key.toString();
                                        return CheckboxListTile(
                                          title: Text(worker.nombre),
                                          subtitle: Text(worker.funcion),
                                          value: _recursosSeleccionados.contains(key),
                                          onChanged: (bool? value) {
                                            setModalState(() {
                                              if (value == true) {
                                                _recursosSeleccionados.add(key);
                                              } else {
                                                _recursosSeleccionados.remove(key);
                                              }
                                            });
                                          },
                                        );
                                      },
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
                          setState(() {}); // Actualizar UI principal
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
                  const Text('Seleccionar Ingredientes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Consumer<IngredientesProvider>(
                      builder: (context, provider, child) {
                        return ListView.builder(
                          itemCount: provider.ingredientesEntries.length,
                          itemBuilder: (context, index) {
                            final ingrediente = provider.ingredientesEntries[index].value;
                            final key = provider.ingredientesEntries[index].key.toString();
                            
                            // Buscar si ya está seleccionado
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
                          setState(() {}); // Actualizar UI principal
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
              title: const Text('Seleccionar Dependencias'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Ingrese los nombres de los pasos de los que depende este paso:'),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Nombre del paso dependiente',
                        border: OutlineInputBorder(),
                        helperText: 'Ej: A, B, C, etc.',
                      ),
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty && !_dependenciasSeleccionadas.contains(value)) {
                          setDialogState(() {
                            _dependenciasSeleccionadas.add(value);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _dependenciasSeleccionadas.length,
                        itemBuilder: (context, index) {
                          final dependencia = _dependenciasSeleccionadas[index];
                          return ListTile(
                            title: Text(dependencia),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                setDialogState(() {
                                  _dependenciasSeleccionadas.removeAt(index);
                                });
                              },
                            ),
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
                    setState(() {}); // Actualizar UI principal
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
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        recetaId: widget.recetaId,
        nombrePaso: _nombreController.text,
        contenidoAccion: _contenidoController.text,
        recursosCocinasRequeridos: List.from(_recursosSeleccionados),
        ingredientesRequeridos: List.from(_ingredientesRequeridos),
        recursoAlmacenamiento: List.from(_almacenamientoSeleccionado),
        tiempoCoccionSegundos: int.tryParse(_tiempoCoccionController.text) ?? 0,
        tiempoPreparacionSegundos: int.tryParse(_tiempoPreparacionController.text) ?? 0,
        tipoCoccion: _tipoCoccionSeleccionado,
        tipoAlmacenamiento: _tipoAlmacenamientoSeleccionado,
        tareasAnterioresDirectas: List.from(_tareasAnteriores),
        orden: widget.orden,
        // Campos de scheduling
        tipoCocinero: _tipoCocineroSeleccionado,
        tipoUtensilio: _tipoUtensilioSeleccionado,
        dependencias: List.from(_dependenciasSeleccionadas),
      );

      try {
        await Provider.of<PasoProvider>(context, listen: false).addPaso(paso);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paso guardado exitosamente')),
          );
          Navigator.pop(context, true); // Retornar true para indicar éxito
        }
      } catch (e) {
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

    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Paso', style: textTheme.headlineSmall),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre del paso
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del paso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del paso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contenido/Acción
              TextFormField(
                controller: _contenidoController,
                decoration: const InputDecoration(
                  labelText: 'Contenido/Acción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el contenido del paso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Recursos de cocina
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recursos de cocina requeridos',
                              style: textTheme.titleMedium),
                          FilledButton.icon(
                            onPressed: _mostrarSelectorRecursos,
                            icon: const Icon(Icons.add),
                            label: const Text('Seleccionar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Seleccionados: ${_recursosSeleccionados.length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ingredientes requeridos
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ingredientes requeridos',
                              style: textTheme.titleMedium),
                          FilledButton.icon(
                            onPressed: _mostrarSelectorIngredientes,
                            icon: const Icon(Icons.add),
                            label: const Text('Seleccionar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_ingredientesRequeridos.isNotEmpty) ...[
                        for (var req in _ingredientesRequeridos) Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• ${req.cantidad} ${req.unidadMedida}'),
                            ),
                      ] else
                        const Text('Ningún ingrediente seleccionado'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tiempo de cocción
              TextFormField(
                controller: _tiempoCoccionController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de cocción (segundos)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Tiempo de preparación
              TextFormField(
                controller: _tiempoPreparacionController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo de preparación (segundos)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Tipo de cocción
              DropdownButtonFormField<String>(
                value: _tipoCoccionSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cocción',
                  border: OutlineInputBorder(),
                ),
                items: _tiposCoccion.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _tipoCoccionSeleccionado = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Tipo de almacenamiento
              DropdownButtonFormField<String>(
                value: _tipoAlmacenamientoSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de almacenamiento',
                  border: OutlineInputBorder(),
                ),
                items: _tiposCoccion.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _tipoAlmacenamientoSeleccionado = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // CAMPOS DE SCHEDULING
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuración de Scheduling',
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
                          labelText: 'Tipo de Cocinero',
                          border: OutlineInputBorder(),
                          helperText: 'Tipo de recurso humano requerido',
                        ),
                        items: _tiposCocinero.map((String tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text(tipo),
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

                      // Tipo de Utensilio
                      DropdownButtonFormField<String>(
                        value: _tipoUtensilioSeleccionado,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de Utensilio',
                          border: OutlineInputBorder(),
                          helperText: 'Tipo de utensilio requerido (A, B, C, D)',
                        ),
                        items: _tiposUtensilio.map((String tipo) {
                          return DropdownMenuItem<String>(
                            value: tipo,
                            child: Text('Tipo $tipo'),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _tipoUtensilioSeleccionado = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dependencias
                      Text(
                        'Dependencias',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _dependenciasSeleccionadas.isEmpty
                                        ? 'Sin dependencias'
                                        : 'Depende de: ${_dependenciasSeleccionadas.join(", ")}',
                                    style: textTheme.bodyMedium,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _mostrarSelectorDependencias,
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Editar dependencias',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _guardarPaso,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Paso'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _guardarPaso();
                        // Después de guardar, limpiar el formulario para otro paso
                        _nombreController.clear();
                        _contenidoController.clear();
                        _tiempoCoccionController.clear();
                        _tiempoPreparacionController.clear();
                        setState(() {
                          _recursosSeleccionados.clear();
                          _ingredientesRequeridos.clear();
                          _almacenamientoSeleccionado.clear();
                          _tareasAnteriores.clear();
                          // Limpiar campos de scheduling
                          _tipoCocineroSeleccionado = 'cocinero';
                          _tipoUtensilioSeleccionado = 'A';
                          _dependenciasSeleccionadas.clear();
                        });
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text('Agregar Otro'),
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
