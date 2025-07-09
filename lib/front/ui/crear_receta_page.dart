import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/receta.dart';
import '../../back/dataModels/paso.dart';
import '../state/recetas_provider.dart';
import '../state/workers_provider.dart';
import '../state/instrumentos_provider.dart';

class CrearRecetaPage extends StatefulWidget {
  const CrearRecetaPage({super.key});

  @override
  State<CrearRecetaPage> createState() => _CrearRecetaPageState();
}

class _CrearRecetaPageState extends State<CrearRecetaPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  
  List<Paso> _pasos = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  void _addPaso() {
    showDialog(
      context: context,
      builder: (context) => _PasoDialog(
        onSave: (paso) {
          setState(() {
            _pasos.add(paso);
          });
        },
      ),
    );
  }

  void _editPaso(int index) {
    showDialog(
      context: context,
      builder: (context) => _PasoDialog(
        paso: _pasos[index],
        onSave: (paso) {
          setState(() {
            _pasos[index] = paso;
          });
        },
      ),
    );
  }

  void _deletePaso(int index) {
    setState(() {
      _pasos.removeAt(index);
    });
  }

  void _saveReceta() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_pasos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe agregar al menos un paso a la receta')),
        );
        return;
      }

      final nuevaReceta = Receta(
        id: 0, // Se asignará automáticamente
        nombre: _nombreController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        pasos: _pasos,
        tiempoTotalSegundos: 0, // Se calculará automáticamente
        fechaCreacion: DateTime.now(),
      );

      final recetasProvider = Provider.of<RecetasProvider>(context, listen: false);

      try {
        await recetasProvider.addReceta(nuevaReceta);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receta guardada con éxito!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar receta: ${e.toString()}')),
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
        title: const Text('Crear Nueva Receta'),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información General', style: textTheme.titleLarge),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Receta',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese el nombre de la receta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pasos de la Receta', style: textTheme.titleLarge),
                  FilledButton.icon(
                    onPressed: _addPaso,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar Paso'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_pasos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No hay pasos agregados',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Agrega pasos para completar la receta',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pasos.length,
                  itemBuilder: (context, index) {
                    final paso = _pasos[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(paso.descripcion),
                        subtitle: Text(
                          'Tiempo: ${paso.tiempoSegundos ~/ 60}:${(paso.tiempoSegundos % 60).toString().padLeft(2, '0')} • '
                          'Trabajadores: ${paso.trabajadores.join(', ')} • '
                          'Utensilios: ${paso.utensilioTipos.join(', ')}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _editPaso(index),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () => _deletePaso(index),
                              icon: const Icon(Icons.delete),
                              color: colorScheme.error,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saveReceta,
                  child: const Text('Guardar Receta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasoDialog extends StatefulWidget {
  final Paso? paso;
  final Function(Paso) onSave;

  const _PasoDialog({
    this.paso,
    required this.onSave,
  });

  @override
  State<_PasoDialog> createState() => _PasoDialogState();
}

class _PasoDialogState extends State<_PasoDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _tiempoController = TextEditingController();
  
  List<String> _selectedTrabajadores = [];
  List<String> _selectedUtensilios = [];
  List<int> _cantidadesUtensilios = [];

  @override
  void initState() {
    super.initState();
    if (widget.paso != null) {
      _descripcionController.text = widget.paso!.descripcion;
      _tiempoController.text = widget.paso!.tiempoSegundos.toString();
      _selectedTrabajadores = List.from(widget.paso!.trabajadores);
      _selectedUtensilios = List.from(widget.paso!.utensilioTipos);
      _cantidadesUtensilios = List.from(widget.paso!.utensilioCantidades);
    }
  }

  @override
  void dispose() {
    _descripcionController.dispose();
    _tiempoController.dispose();
    super.dispose();
  }

  void _savePaso() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedTrabajadores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe seleccionar al menos un trabajador')),
        );
        return;
      }

      if (_selectedUtensilios.length != _cantidadesUtensilios.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debe especificar cantidades para todos los utensilios')),
        );
        return;
      }

      final paso = Paso(
        descripcion: _descripcionController.text.trim(),
        tiempoSegundos: int.parse(_tiempoController.text),
        trabajadores: _selectedTrabajadores,
        utensilioTipos: _selectedUtensilios,
        utensilioCantidades: _cantidadesUtensilios,
      );

      widget.onSave(paso);
      Navigator.pop(context);
    }
  }

  List<FilterChip> functionsToFilterChip(List<String> functions){
    List<FilterChip> chips = [];
    for(var i in functions){
      chips.add(FilterChip(
        label: Text(i),
        selected: _selectedTrabajadores.contains(i),
        onSelected: (selected) {
          setState(() {
            if (selected) {
              _selectedTrabajadores.add(i);
            } else {
              _selectedTrabajadores.remove(i);
            }
          });
        },
      ));
    }
    return chips;
  }

  List<String> listToSet(List<String> functions) {
    return functions.toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.paso == null ? 'Agregar Paso' : 'Editar Paso',
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción del Paso',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese la descripción del paso';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _tiempoController,
                  decoration: const InputDecoration(
                    labelText: 'Tiempo en segundos',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor ingrese el tiempo';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Por favor ingrese un tiempo válido mayor a 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                Text('Trabajadores Necesarios', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Consumer<WorkersProvider>(
                  builder: (context, workersProvider, child) {
                    return Wrap(
                      spacing: 8,
                        children: functionsToFilterChip(
                        listToSet(
                          workersProvider.workers.map((w) => w.funcion).toList()
                        )
                        )
                      //functionsToFilterChips(workersTochipsFunctions(workersProvider.workers))
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                Text('Utensilios Necesarios', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                Consumer<InstrumentosProvider>(
                  builder: (context, instrumentosProvider, child) {
                    return Column(
                      children: instrumentosProvider.instrumentos.map((instrumento) {
                        final index = _selectedUtensilios.indexOf(instrumento.nombre);
                        final isSelected = index != -1;
                        
                        return CheckboxListTile(
                          title: Text(instrumento.nombre),
                          value: isSelected,
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedUtensilios.add(instrumento.nombre);
                                _cantidadesUtensilios.add(1);
                              } else {
                                final removeIndex = _selectedUtensilios.indexOf(instrumento.nombre);
                                if (removeIndex != -1) {
                                  _selectedUtensilios.removeAt(removeIndex);
                                  _cantidadesUtensilios.removeAt(removeIndex);
                                }
                              }
                            });
                          },
                          secondary: isSelected 
                            ? SizedBox(
                                width: 60,
                                child: TextFormField(
                                  initialValue: _cantidadesUtensilios[index].toString(),
                                  decoration: const InputDecoration(
                                    labelText: 'Cant.',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    final cantidad = int.tryParse(value) ?? 1;
                                    _cantidadesUtensilios[index] = cantidad;
                                  },
                                ),
                              )
                            : null,
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _savePaso,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
