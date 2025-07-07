import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/receta.dart';
import '../../back/dataModels/paso.dart';
import '../state/receta_provider.dart';
import '../state/paso_provider.dart';
import 'crear_paso_scheduling_page.dart';

class CrearRecetaNuevaPage extends StatefulWidget {
  final Receta? recetaParaEditar;
  final dynamic recetaKey;

  const CrearRecetaNuevaPage({
    super.key,
    this.recetaParaEditar,
    this.recetaKey,
  });

  @override
  State<CrearRecetaNuevaPage> createState() => _CrearRecetaNuevaPageState();
}

class _CrearRecetaNuevaPageState extends State<CrearRecetaNuevaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _porcionesController = TextEditingController();

  String _categoriaSeleccionada = 'entrada';
  final List<String> _categorias = ['entrada', 'fondo', 'postre'];

  Receta? _recetaCreada;
  List<Paso> _pasos = [];
  int _duracionTotalCalculada = 0;
  bool _cargandoPasos = false; // Indicador de carga

  bool get _esEdicion => widget.recetaParaEditar != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      _nombreController.text = widget.recetaParaEditar!.nombre;
      _descripcionController.text = widget.recetaParaEditar!.descripcion;
      _porcionesController.text = widget.recetaParaEditar!.cantidadPorciones.toString();
      _categoriaSeleccionada = widget.recetaParaEditar!.categoria;
      _recetaCreada = widget.recetaParaEditar;
      
      // Cargar pasos después de que se construya el widget
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarPasos();
      });
    }
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
      
      print('🔍 _cargarPasos: Cargando pasos para receta: "${_recetaCreada!.nombre}"');
      
      // Primero cargar específicamente los pasos de esta receta desde la BD
      await pasoProvider.loadPasosByRecetaId(_recetaCreada!.nombre);
      
      // Usar los pasos específicos de la receta actual desde el provider
      _pasos = pasoProvider.pasosCurrentReceta
          .map((entry) => entry.value)
          .where((paso) => paso.recetaId == _recetaCreada!.nombre)
          .toList();
      
      // Ordenar los pasos por orden
      _pasos.sort((a, b) => a.orden.compareTo(b.orden));
      
      print('🔍 _cargarPasos: Encontrados ${_pasos.length} pasos para receta "${_recetaCreada!.nombre}"');
      for (var paso in _pasos) {
        print('   - Paso ${paso.orden}: ${paso.nombrePaso} (ID: ${paso.id})');
      }
      
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

  void _guardarReceta() async {
    if (_formKey.currentState!.validate()) {
      final receta = Receta(
        nombre: _nombreController.text,
        descripcion: _descripcionController.text,
        cantidadPorciones: int.parse(_porcionesController.text),
        categoria: _categoriaSeleccionada,
        etiquetas: [],
        duracionEstimadaMinutos: (_duracionTotalCalculada / 60).ceil(),
        pasosIds: _pasos.map((p) => p.id).toList(),
      );

      try {
        if (_esEdicion) {
          await Provider.of<RecetaProvider>(context, listen: false)
              .updateReceta(widget.recetaKey, receta);
        } else {
          // Al crear una nueva receta, limpiar cualquier paso residual
          final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
          print('🧹 Limpiando pasos residuales para nueva receta: ${receta.nombre}');
          await pasoProvider.deletePasosByRecetaId(receta.nombre);
          
          await Provider.of<RecetaProvider>(context, listen: false)
              .addReceta(receta);
        }
        
        if (mounted) {
          setState(() {
            _recetaCreada = receta;
            // Limpiar lista de pasos al crear nueva receta
            if (!_esEdicion) {
              _pasos = [];
              _duracionTotalCalculada = 0;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_esEdicion 
                ? 'Receta actualizada exitosamente' 
                : 'Receta guardada exitosamente. Ahora puede agregar pasos.'
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar receta: $e')),
          );
        }
      }
    }
  }

  void _agregarPaso() async {
    if (_recetaCreada != null) {
      // Asegurar que los pasos estén cargados antes de abrir el diálogo
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
          // Recargar todos los pasos después de agregar uno nuevo
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
    // Asegurar que los pasos estén cargados antes de abrir el diálogo
    final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
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
        // Recargar todos los pasos después de editar
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
        content: Text('¿Está seguro que desea eliminar el paso "${paso.nombrePaso}"?'),
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
        final pasoKey = pasoProvider.pasoEntries
            .firstWhere((entry) => entry.value.id == paso.id)
            .key;
        await pasoProvider.deletePaso(pasoKey);
        
        // Recargar todos los pasos después de eliminar
        _cargarPasos();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paso eliminado exitosamente')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar paso: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Receta' : 'Crear Nueva Receta',
          style: textTheme.headlineSmall,
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre de la receta
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

              // Descripción
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

              // Cantidad de porciones
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

              // Categoría
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

              // Imagen (placeholder)
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

              // Duración estimada (calculada automáticamente)
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

              // Botones de guardar receta
              if (_recetaCreada == null) ...[
                FilledButton.icon(
                  onPressed: _guardarReceta,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Receta'),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _guardarReceta,
                        icon: const Icon(Icons.save),
                        label: const Text('Actualizar Receta'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _agregarPaso,
                        icon: const Icon(Icons.add_task),
                        label: const Text('Agregar Paso'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Lista de pasos
              if (_recetaCreada != null) ...[
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
                  // Grilla de pasos
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      childAspectRatio: 8, // Aumentado de 6 a 8 para hacer las cards aún más bajas
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 6, // Reducido el espaciado entre cards
                    ),
                    itemCount: _pasos.length,
                    itemBuilder: (context, index) {
                      final paso = _pasos[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(6), // Reducido de 8 a 6 para más compacto
                          child: Row(
                            children: [
                              // Número del paso
                              CircleAvatar(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                radius: 14, // Reducido de 16 a 14
                                child: Text(
                                  '${paso.orden}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11, // Reducido de 12 a 11
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10), // Reducido de 12 a 10
                              
                              // Información del paso
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
                                          size: 10, // Reducido de 12 a 10
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 3), // Reducido de 4 a 3
                                        Text(
                                          '${((paso.tiempoCoccionSegundos + paso.tiempoPreparacionSegundos) / 60).ceil()} min',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Botones de acción
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    onPressed: () => _editarPaso(paso),
                                    icon: const Icon(Icons.edit),
                                    iconSize: 16, // Reducido de 18 a 16
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    onPressed: () => _eliminarPaso(paso),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    iconSize: 16, // Reducido de 18 a 16
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

              // Botón finalizar (solo si hay receta creada)
              if (_recetaCreada != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Finalizar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
