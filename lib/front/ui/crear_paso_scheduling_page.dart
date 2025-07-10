import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/paso.dart';
import '../../back/dataModels/instrumentos.dart';
import '../../back/dataModels/ingredientes.dart';
import '../state/paso_provider.dart';
import '../state/instrumentos_provider.dart';
import '../state/ingredientes_provider.dart';

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
  final Map<String, TextEditingController> _cantidadControllers = {};

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
                            final unidadIngrediente = ingrediente.unidadMedida;
                            final ingredientesEncontrados = _ingredientesRequeridos
                                .where((req) => req.ingredienteId == key);
                            final existingIngredient = ingredientesEncontrados.isNotEmpty ? 
                                ingredientesEncontrados.first : null;
                            if (existingIngredient != null && !_cantidadControllers.containsKey(key)) {
                              _cantidadControllers[key] = TextEditingController(text: existingIngredient.cantidad.toString());
                            }
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
                                                    unidadMedida: unidadIngrediente,
                                                  ),
                                                );
                                                _cantidadControllers[key] = TextEditingController(text: '1.0');
                                              } else {
                                                _ingredientesRequeridos.removeWhere((req) => req.ingredienteId == key);
                                                _cantidadControllers.remove(key);
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
                                          IconButton(
                                            icon: const Icon(Icons.arrow_drop_down, color: Colors.redAccent),
                                            onPressed: () {
                                              setModalState(() {
                                                final index = _ingredientesRequeridos.indexWhere((req) => req.ingredienteId == key);
                                                if (index >= 0) {
                                                  final current = _ingredientesRequeridos[index];
                                                  final newCantidad = (current.cantidad - 1).clamp(0, double.infinity).toDouble();
                                                  _ingredientesRequeridos[index] = IngredienteRequerido(
                                                    ingredienteId: key,
                                                    cantidad: newCantidad,
                                                    unidadMedida: current.unidadMedida,
                                                  );
                                                  _cantidadControllers[key]?.text = newCantidad.toString();
                                                }
                                              });
                                            },
                                            tooltip: 'Reducir cantidad',
                                          ),
                                          SizedBox(
                                            width: 60,
                                            child: TextFormField(
                                              controller: _cantidadControllers[key],
                                              textAlign: TextAlign.center,
                                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                contentPadding: EdgeInsets.symmetric(vertical: 4),
                                                border: OutlineInputBorder(),
                                              ),
                                              onChanged: (value) {
                                                final parsed = double.tryParse(value.replaceAll(',', '.'));
                                                if (parsed != null && parsed >= 0) {
                                                  setModalState(() {
                                                    final idx = _ingredientesRequeridos.indexWhere((req) => req.ingredienteId == key);
                                                    if (idx >= 0) {
                                                      _ingredientesRequeridos[idx] = IngredienteRequerido(
                                                        ingredienteId: key,
                                                        cantidad: parsed,
                                                        unidadMedida: existingIngredient.unidadMedida,
                                                      );
                                                    }
                                                  });
                                                }
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.arrow_drop_up, color: Colors.green),
                                            onPressed: () {
                                              setModalState(() {
                                                final index = _ingredientesRequeridos.indexWhere((req) => req.ingredienteId == key);
                                                if (index >= 0) {
                                                  final current = _ingredientesRequeridos[index];
                                                  final newCantidad = current.cantidad + 1;
                                                  _ingredientesRequeridos[index] = IngredienteRequerido(
                                                    ingredienteId: key,
                                                    cantidad: newCantidad,
                                                    unidadMedida: current.unidadMedida,
                                                  );
                                                  _cantidadControllers[key]?.text = newCantidad.toString();
                                                }
                                              });
                                            },
                                            tooltip: 'Aumentar cantidad',
                                          ),
                                          const SizedBox(width: 8),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            child: Text(existingIngredient.unidadMedida, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () {
                                              setModalState(() {
                                                _ingredientesRequeridos.removeWhere((req) => req.ingredienteId == key);
                                                _cantidadControllers.remove(key);
                                              });
                                            },
                                            tooltip: 'Quitar ingrediente',
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
                          int? selectedId;
                          if (_tipoUtensilioSeleccionado != null && instrumentos.isNotEmpty) {
                            final found = instrumentos.firstWhere(
                              (i) => i.id.toString() == _tipoUtensilioSeleccionado,
                              orElse: () => instrumentos.first,
                            );
                            selectedId = found.id;
                          } else {
                            selectedId = null;
                          }
                          return DropdownButtonFormField<int?>(
                            value: selectedId,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Utensilio',
                              border: OutlineInputBorder(),
                              helperText: 'Selecciona el tipo de utensilio requerido',
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Ninguno'),
                              ),
                              ...instrumentos.map((Instrumento instrumento) {
                                return DropdownMenuItem<int>(
                                  value: instrumento.id,
                                  child: Text(instrumento.nombre),
                                );
                              }).toList(),
                            ],
                            onChanged: (int? newId) {
                              setState(() {
                                _tipoUtensilioSeleccionado = newId?.toString();
                              });
                            },
                            validator: (value) {
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
                                const Text('Dependencias', style: TextStyle(fontWeight: FontWeight.bold)),
                                TextButton.icon(
                                  onPressed: _mostrarSelectorDependencias,
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Editar'),
                                ),
                              ],
                            ),
                            if (_dependenciasSeleccionadas.isEmpty)
                              const Text('Ninguna dependencia seleccionada'),
                            if (_dependenciasSeleccionadas.isNotEmpty)
                              Consumer<PasoProvider>(
                                builder: (context, pasoProvider, child) {
                                  return Wrap(
                                    spacing: 8,
                                    children: _dependenciasSeleccionadas.map((depId) {
                                      final paso = pasoProvider.pasoEntries.firstWhere(
                                        (e) => e.value.id == depId,
                                        orElse: () => MapEntry(depId, Paso(
                                          id: depId,
                                          recetaId: '',
                                          nombrePaso: depId,
                                          contenidoAccion: '',
                                          recursosCocinasRequeridos: [],
                                          ingredientesRequeridos: [],
                                          recursoAlmacenamiento: [],
                                          tiempoCoccionSegundos: 0,
                                          tiempoPreparacionSegundos: 0,
                                          tipoCoccion: '',
                                          tipoAlmacenamiento: '',
                                          tareasAnterioresDirectas: [],
                                          orden: 0,
                                        )),
                                      ).value;
                                      return Chip(label: Text(paso.nombrePaso));
                                    }).toList(),
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
                          const Text('Ingredientes requeridos', style: TextStyle(fontWeight: FontWeight.bold)),
                          FilledButton.icon(
                            onPressed: _mostrarSelectorIngredientes,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_ingredientesRequeridos.isEmpty)
                        const Text('No hay ingredientes seleccionados'),
                      if (_ingredientesRequeridos.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _ingredientesRequeridos.length,
                          itemBuilder: (context, index) {
                            final req = _ingredientesRequeridos[index];
                            final ingrediente = Provider.of<IngredientesProvider>(context, listen: false)
                                .ingredientesEntries
                                .firstWhere(
                                  (e) => e.key.toString() == req.ingredienteId,
                                  orElse: () => MapEntry(
                                    req.ingredienteId,
                                    Ingredientes(
                                      name: req.ingredienteId,
                                      descripcion: '',
                                      unidadMedida: req.unidadMedida,
                                      cantidad: 0,
                                      precio: 0.0,
                                    ),
                                  ),
                                )
                                .value;
                            _cantidadControllers[req.ingredienteId] ??= TextEditingController(text: req.cantidad.toString());
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        ingrediente.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(() {
                                          final newCantidad = (req.cantidad - 1).clamp(0, double.infinity).toDouble();
                                          _ingredientesRequeridos[index] = IngredienteRequerido(
                                            ingredienteId: req.ingredienteId,
                                            cantidad: newCantidad,
                                            unidadMedida: req.unidadMedida,
                                          );
                                          _cantidadControllers[req.ingredienteId]?.text = newCantidad.toString();
                                        });
                                      },
                                      tooltip: 'Reducir cantidad',
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: TextFormField(
                                        controller: _cantidadControllers[req.ingredienteId],
                                        textAlign: TextAlign.center,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) {
                                          final parsed = double.tryParse(value.replaceAll(',', '.'));
                                          if (parsed != null && parsed >= 0) {
                                            setState(() {
                                              _ingredientesRequeridos[index] = IngredienteRequerido(
                                                ingredienteId: req.ingredienteId,
                                                cantidad: parsed,
                                                unidadMedida: req.unidadMedida,
                                              );
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, color: Colors.green),
                                      onPressed: () {
                                        setState(() {
                                          final newCantidad = req.cantidad + 1;
                                          _ingredientesRequeridos[index] = IngredienteRequerido(
                                            ingredienteId: req.ingredienteId,
                                            cantidad: newCantidad,
                                            unidadMedida: req.unidadMedida,
                                          );
                                          _cantidadControllers[req.ingredienteId]?.text = newCantidad.toString();
                                        });
                                      },
                                      tooltip: 'Aumentar cantidad',
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Text(req.unidadMedida, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _ingredientesRequeridos.removeAt(index);
                                          _cantidadControllers.remove(req.ingredienteId);
                                        });
                                      },
                                      tooltip: 'Quitar ingrediente',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: _guardarPaso,
                    child: Text(_esEdicion ? 'Guardar Cambios' : 'Crear Paso'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ), // Cierre de Container
    ); // Cierre de Dialog
  } // Cierre de build
} // Cierre de clase
