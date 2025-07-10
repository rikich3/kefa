import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/receta.dart';
import '../../back/dataModels/paso.dart';
import '../state/receta_provider.dart';
import '../state/paso_provider.dart';
import 'crear_paso_scheduling_page.dart';

class EditarRecetaPage extends StatefulWidget {
  final Receta recetaParaEditar;
  final dynamic recetaKey;

  const EditarRecetaPage({
    super.key,
    required this.recetaParaEditar,
    required this.recetaKey,
  });

  @override
  State<EditarRecetaPage> createState() => _EditarRecetaPageState();
}

class _EditarRecetaPageState extends State<EditarRecetaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _porcionesController = TextEditingController();

  String _categoriaSeleccionada = 'entrada';
  final List<String> _categorias = ['entrada', 'fondo', 'postre'];

  Receta? _recetaCreada;
  List<Paso> _pasos = [];
  int _duracionTotalCalculada = 0;
  bool _cargandoPasos = false;

  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.recetaParaEditar.nombre;
    _descripcionController.text = widget.recetaParaEditar.descripcion;
    _porcionesController.text = widget.recetaParaEditar.cantidadPorciones.toString();
    _categoriaSeleccionada = widget.recetaParaEditar.categoria;
    _recetaCreada = widget.recetaParaEditar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPasos();
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _porcionesController.dispose();
    super.dispose();
  }

  void _cargarPasos() async {
    if (_recetaCreada != null) {
      setState(() {
        _cargandoPasos = true;
      });
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      await pasoProvider.loadPasosByRecetaId(_recetaCreada!.nombre);
      _pasos = pasoProvider.pasosCurrentReceta
          .map((entry) => entry.value)
          .where((paso) => paso.recetaId == _recetaCreada!.nombre)
          .toList();
      _pasos.sort((a, b) => a.orden.compareTo(b.orden));
      _calcularDuracionTotal();
      if (mounted) {
        setState(() {
          _cargandoPasos = false;
        });
      }
    }
  }

  void _calcularDuracionTotal() {
    _duracionTotalCalculada = _pasos.fold(0, (total, paso) {
      return total + paso.tiempoCoccionSegundos + paso.tiempoPreparacionSegundos;
    });
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final receta = Receta(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        cantidadPorciones: int.parse(_porcionesController.text),
        categoria: _categoriaSeleccionada,
        etiquetas: widget.recetaParaEditar.etiquetas,
        duracionEstimadaMinutos: (_duracionTotalCalculada / 60).ceil(),
        pasosIds: _pasos.map((p) => p.id).toList(),
      );
      try {
        await Provider.of<RecetaProvider>(context, listen: false)
            .updateReceta(widget.recetaKey, receta);
        if (mounted) {
          setState(() {
            _recetaCreada = receta;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receta actualizada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar receta: $e')),
          );
        }
      }
    }
  }

  void _agregarPaso() async {
    if (_recetaCreada != null) {
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      await pasoProvider.loadPasosByRecetaId(_recetaCreada!.nombre);
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => CrearPasoSchedulingDialog(
            recetaId: _recetaCreada!.nombre,
            orden: _pasos.length + 1,
          ),
        );
        if (result == true && mounted) {
          _cargarPasos();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Paso agregado exitosamente')),
            );
          }
        }
      }
    }
  }

  void _editarPaso(Paso paso) async {
    final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
    await pasoProvider.loadPasos();
    await pasoProvider.loadPasosByRecetaId(_recetaCreada!.nombre);
    if (mounted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => CrearPasoSchedulingDialog(
          recetaId: _recetaCreada!.nombre,
          orden: paso.orden,
          pasoParaEditar: paso,
        ),
      );
      if (result == true && mounted) {
        _cargarPasos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paso actualizado exitosamente')),
          );
        }
      }
    }
  }

  void _eliminarPaso(Paso paso) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Está seguro que desea eliminar el paso "${paso.nombrePaso}"?'),
            const SizedBox(height: 8),
            Text(
              'Esta acción también actualizará las dependencias de otros pasos que dependan de este.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
        await pasoProvider.loadPasos();
        dynamic pasoKey;
        try {
          final entryGeneral = pasoProvider.pasoEntries
              .firstWhere((entry) => entry.value.id == paso.id);
          pasoKey = entryGeneral.key;
        } catch (e) {
          throw Exception('No se pudo encontrar el paso para eliminar. ID: ${paso.id}. Error: $e');
        }
        final todosLosPasos = pasoProvider.pasoEntries
            .map((entry) => entry.value)
            .where((p) => p.recetaId == _recetaCreada!.nombre && p.id != paso.id)
            .toList();
        for (var otroPaso in todosLosPasos) {
          if (otroPaso.dependencias != null && otroPaso.dependencias!.contains(paso.id)) {
            final nuevasDependencias = List<String>.from(otroPaso.dependencias!)..remove(paso.id);
            final pasoActualizado = Paso(
              id: otroPaso.id,
              recetaId: otroPaso.recetaId,
              nombrePaso: otroPaso.nombrePaso,
              contenidoAccion: otroPaso.contenidoAccion,
              recursosCocinasRequeridos: otroPaso.recursosCocinasRequeridos,
              ingredientesRequeridos: otroPaso.ingredientesRequeridos,
              recursoAlmacenamiento: otroPaso.recursoAlmacenamiento,
              tiempoCoccionSegundos: otroPaso.tiempoCoccionSegundos,
              tiempoPreparacionSegundos: otroPaso.tiempoPreparacionSegundos,
              tipoCoccion: otroPaso.tipoCoccion,
              tipoAlmacenamiento: otroPaso.tipoAlmacenamiento,
              tareasAnterioresDirectas: otroPaso.tareasAnterioresDirectas,
              orden: otroPaso.orden,
              tipoCocinero: otroPaso.tipoCocinero,
              tipoUtensilio: otroPaso.tipoUtensilio,
              dependencias: nuevasDependencias,
            );
            try {
              final otroEntry = pasoProvider.pasoEntries
                  .firstWhere((entry) => entry.value.id == otroPaso.id);
              await pasoProvider.updatePaso(otroEntry.key, pasoActualizado);
            } catch (e) {}
          }
        }
        await pasoProvider.deletePaso(pasoKey);
        _cargarPasos();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paso eliminado exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar paso: $e')),
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
        title: Text('Editar Receta', style: textTheme.headlineSmall),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la receta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant_menu),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
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
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese una descripción';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _porcionesController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad de porciones',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese la cantidad de porciones';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Por favor ingrese un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias.map((String categoria) {
                  return DropdownMenuItem<String>(
                    value: categoria,
                    child: Text(categoria.toUpperCase()),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _categoriaSeleccionada = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Imagen de la receta\n(Próximamente)',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duración estimada (autocalculada)',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${(_duracionTotalCalculada / 60).ceil()} minutos',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context, false),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Cambios'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _agregarPaso,
                icon: const Icon(Icons.add_task),
                label: const Text('Agregar Paso'),
              ),
              const SizedBox(height: 16),
              Text(
                'Pasos de la Receta',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (_cargandoPasos) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando pasos...'),
                      ],
                    ),
                  ),
                ),
              ] else if (_pasos.isEmpty) ...[
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_outlined,
                          size: 48,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No hay pasos agregados\nComience agregando el primer paso',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _pasos.length,
                  itemBuilder: (context, index) {
                    final paso = _pasos[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              radius: 14,
                              child: Text(
                                '${paso.orden}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    paso.nombrePaso,
                                    style: textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    paso.contenidoAccion,
                                    style: textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer,
                                        size: 10,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${((paso.tiempoCoccionSegundos + paso.tiempoPreparacionSegundos) / 60).ceil()} min',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (paso.ingredientesRequeridos.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ingredientes:',
                                      style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    ...paso.ingredientesRequeridos.map<Widget>((ing) => Padding(
                                      padding: const EdgeInsets.only(left: 8, top: 2),
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '${ing.cantidad} ${ing.unidadMedida}',
                                              style: textTheme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () => _editarPaso(paso),
                                  icon: const Icon(Icons.edit),
                                  iconSize: 16,
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  onPressed: () => _eliminarPaso(paso),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  iconSize: 16,
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
