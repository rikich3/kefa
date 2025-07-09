import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../back/dataModels/paso.dart';
// import '../../back/dataModels/ingredientes.dart'; // Unused
// import '../../back/dataModels/worker.dart'; // Unused
// import '../../back/dataModels/instrumentos.dart'; // Unused
import '../state/paso_provider.dart';
// import '../state/ingredientes_provider.dart'; // Unused
// import '../state/workers_provider.dart'; // Unused
// import '../state/instrumentos_provider.dart'; // Unused

class EditarPasoPage extends StatefulWidget {
  final dynamic pasoKey;
  final Paso paso;

  const EditarPasoPage({
    super.key,
    required this.pasoKey,
    required this.paso,
  });

  @override
  State<EditarPasoPage> createState() => _EditarPasoPageState();
}

class _EditarPasoPageState extends State<EditarPasoPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para los campos del formulario
  late TextEditingController _nombrePasoController;
  late TextEditingController _contenidoAccionController;
  late TextEditingController _tipoCoccionController;
  late TextEditingController _tipoAlmacenamientoController;
  
  // Variables para tiempos
  late int _tiempoCoccionSegundos;
  late int _tiempoPreparacionSegundos;
  late int _orden;
  
  // Listas para selecciones múltiples
  late List<String> _recursosCocinasSeleccionados;
  late List<String> _recursoAlmacenamientoSeleccionados;
  late List<String> _tareasAnterioresSeleccionadas;
  late List<IngredienteRequerido> _ingredientesRequeridos;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controladores con los datos del paso
    _nombrePasoController = TextEditingController(text: widget.paso.nombrePaso);
    _contenidoAccionController = TextEditingController(text: widget.paso.contenidoAccion);
    _tipoCoccionController = TextEditingController(text: widget.paso.tipoCoccion);
    _tipoAlmacenamientoController = TextEditingController(text: widget.paso.tipoAlmacenamiento);
    
    // Inicializar valores numéricos
    _tiempoCoccionSegundos = widget.paso.tiempoCoccionSegundos;
    _tiempoPreparacionSegundos = widget.paso.tiempoPreparacionSegundos;
    _orden = widget.paso.orden;
    
    // Inicializar listas (crear copias para evitar modificar el original)
    _recursosCocinasSeleccionados = List.from(widget.paso.recursosCocinasRequeridos);
    _recursoAlmacenamientoSeleccionados = List.from(widget.paso.recursoAlmacenamiento);
    _tareasAnterioresSeleccionadas = List.from(widget.paso.tareasAnterioresDirectas);
    _ingredientesRequeridos = List.from(widget.paso.ingredientesRequeridos);
  }

  @override
  void dispose() {
    _nombrePasoController.dispose();
    _contenidoAccionController.dispose();
    _tipoCoccionController.dispose();
    _tipoAlmacenamientoController.dispose();
    super.dispose();
  }

  void _guardarCambios() async {
    if (_formKey.currentState!.validate()) {
      final pasoProvider = Provider.of<PasoProvider>(context, listen: false);
      
      // Crear paso actualizado
      final pasoActualizado = Paso(
        id: widget.paso.id,
        recetaId: widget.paso.recetaId,
        nombrePaso: _nombrePasoController.text,
        contenidoAccion: _contenidoAccionController.text,
        recursosCocinasRequeridos: _recursosCocinasSeleccionados,
        ingredientesRequeridos: _ingredientesRequeridos,
        recursoAlmacenamiento: _recursoAlmacenamientoSeleccionados,
        tiempoCoccionSegundos: _tiempoCoccionSegundos,
        tiempoPreparacionSegundos: _tiempoPreparacionSegundos,
        tipoCoccion: _tipoCoccionController.text,
        tipoAlmacenamiento: _tipoAlmacenamientoController.text,
        tareasAnterioresDirectas: _tareasAnterioresSeleccionadas,
        orden: _orden,
      );

      try {
        await pasoProvider.updatePaso(widget.pasoKey, pasoActualizado);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paso actualizado exitosamente')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar el paso: $e')),
          );
        }
      }
    }
  }

  Widget _buildTimeInput(String label, int seconds, Function(int) onChanged) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: minutes.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutos',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final newMinutes = int.tryParse(value) ?? 0;
                  onChanged(newMinutes * 60 + remainingSeconds);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: remainingSeconds.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Segundos',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final newSeconds = int.tryParse(value) ?? 0;
                  onChanged(minutes * 60 + newSeconds);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Paso'),
        actions: [
          TextButton(
            onPressed: _guardarCambios,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nombre del paso
              TextFormField(
                controller: _nombrePasoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Paso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese un nombre para el paso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contenido de la acción
              TextFormField(
                controller: _contenidoAccionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción/Instrucciones',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese las instrucciones del paso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Orden
              TextFormField(
                initialValue: _orden.toString(),
                decoration: const InputDecoration(
                  labelText: 'Orden del Paso',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el orden del paso';
                  }
                  final orden = int.tryParse(value);
                  if (orden == null || orden < 1) {
                    return 'El orden debe ser un número mayor a 0';
                  }
                  return null;
                },
                onChanged: (value) {
                  _orden = int.tryParse(value) ?? 1;
                },
              ),
              const SizedBox(height: 16),

              // Tiempos
              _buildTimeInput('Tiempo de Preparación', _tiempoPreparacionSegundos, (value) {
                setState(() {
                  _tiempoPreparacionSegundos = value;
                });
              }),
              const SizedBox(height: 16),

              _buildTimeInput('Tiempo de Cocción', _tiempoCoccionSegundos, (value) {
                setState(() {
                  _tiempoCoccionSegundos = value;
                });
              }),
              const SizedBox(height: 16),

              // Tipo de cocción
              TextFormField(
                controller: _tipoCoccionController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Cocción',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: carnes, vegetales, pescados y mariscos',
                ),
              ),
              const SizedBox(height: 16),

              // Tipo de almacenamiento
              TextFormField(
                controller: _tipoAlmacenamientoController,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Almacenamiento',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: refrigerado, congelado, temperatura ambiente',
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    onPressed: _guardarCambios,
                    child: const Text('Guardar Cambios'),
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
