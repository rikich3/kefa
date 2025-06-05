import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importar Provider
// Importar el modelo Ingredientes y el Provider
import 'back/dataModels/ingredientes.dart'; // Asegúrate de que esta ruta sea correcta
import 'front/state/ingredientes_provider.dart'; // Asegúrate de que esta ruta sea correcta


class CrearIngredientePage extends StatefulWidget {
  const CrearIngredientePage({super.key});

  @override
  State<CrearIngredientePage> createState() => _CrearIngredientePageState();
}

class _CrearIngredientePageState extends State<CrearIngredientePage> {
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario

  // Controladores para capturar el texto de cada campo
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _unidadMedidaController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  @override
  void dispose() {
    // Limpiar los controladores cuando el widget se elimine
    _nameController.dispose();
    _descripcionController.dispose();
    _unidadMedidaController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  // Función para guardar el ingrediente
  void _saveIngrediente() async { // Marcamos como async porque Provider.addIngredient es async
    // Validar el formulario
    if (_formKey.currentState?.validate() ?? false) {
      // No necesitamos _formKey.currentState?.save() si usamos TextEditingControllers directamente

      // Crear una instancia del modelo Ingredientes con los datos del formulario
      // Asegúrate de parsear cantidad y precio a sus tipos correctos (int y double)
      // Considera usar .tryParse y manejar errores si la validación es menos estricta
      // La validación ya verifica si son números válidos, así que parse es seguro aquí
      final nuevoIngrediente = Ingredientes( // Usando el nombre de clase Ingredientes
        name: _nameController.text.trim(), // .trim() elimina espacios en blanco al inicio/fin
        descripcion: _descripcionController.text.trim(),
        unidadMedida: _unidadMedidaController.text.trim(),
        cantidad: int.parse(_cantidadController.text.trim()),
        precio: double.parse(_precioController.text.trim()),
      );

      // Obtener la instancia del IngredientProvider sin escuchar cambios (listen: false)
      // Asegúrate de que el nombre del Provider sea el correcto si usas uno diferente
      final ingredientProvider = Provider.of<IngredientesProvider>(context, listen: false);

      // Llamar al método addIngredient del Provider
      try {
        // Esperar a que la operación de guardar (en Hive) se complete
        await ingredientProvider.addIngredient(nuevoIngrediente);

        // Si llegamos aquí, la operación fue exitosa
        print('Ingrediente guardado con éxito: ${nuevoIngrediente.name}');

        // Opcional: Mostrar un mensaje de confirmación al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingrediente guardado con éxito!')),
        );

        // Volver a la pantalla anterior (el modal o la pantalla ManageTab)
        // Nota: El modal de la lista se actualizará automáticamente
        // porque el Provider notificará a sus listeners (el Consumer en el modal).
        Navigator.pop(context);

      } catch (e) {
        // Si ocurre un error durante la operación de guardar
        print('Error al guardar ingrediente: $e');
        // Mostrar un mensaje de error al usuario
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar ingrediente: ${e.toString()}')),
        );
        // No hacemos pop si hay un error, permitimos al usuario corregir o cancelar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Ingrediente'),
        // El botón de volver ya está presente usando leading: IconButton y Navigator.pop
        // No necesitas un onPressed en el icono de back si usas el comportamiento por defecto
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back),
        //   onPressed: () => Navigator.pop(context),
        //   tooltip: 'Volver',
        // ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey, // Asociar la clave al formulario
          child: ListView( // Usamos ListView para que el formulario sea scrollable si es largo
            // mainAxisSize: MainAxisSize.min, // No necesario en ListView
            // crossAxisAlignment: CrossAxisAlignment.stretch, // No necesario en ListView, se estira por defecto
            children: [
              // --- Campo Nombre ---
              TextFormField(
                controller: _nameController, // Usar controlador
                decoration: const InputDecoration(
                  labelText: 'Nombre del ingrediente',
                  border: OutlineInputBorder(), // Estilo M3
                ),
                // onSaved: (value) => _nombre = value ?? '', // Ya no necesario con controlador
                validator: (value) => (value == null || value.isEmpty) ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 20), // Espacio entre campos

              // --- Campo Descripción ---
              TextFormField(
                 controller: _descripcionController, // Usar controlador
                 decoration: const InputDecoration(
                   labelText: 'Descripción (opcional)',
                   border: OutlineInputBorder(),
                 ),
                 // validator: ... (si la descripción es obligatoria, añade validador)
              ),
              const SizedBox(height: 20),

              // --- Campo Unidad de Medida ---
              TextFormField(
                controller: _unidadMedidaController, // Usar controlador
                decoration: const InputDecoration(
                  labelText: 'Unidad de Medida (ej: gramos, ml, unidad)',
                  border: OutlineInputBorder(),
                ),
                 validator: (value) => (value == null || value.isEmpty) ? 'Ingrese una unidad de medida' : null, // Asumiendo que es obligatorio
              ),
              const SizedBox(height: 20),

              // --- Campo Cantidad ---
              TextFormField(
                controller: _cantidadController, // Usar controlador
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number, // Mostrar teclado numérico
                 validator: (value) { // Validar que sea un número entero
                    if (value == null || value.isEmpty) return 'Ingrese una cantidad';
                    if (int.tryParse(value.trim()) == null) return 'Debe ser un número entero válido';
                    if (int.parse(value.trim()) < 0) return 'La cantidad no puede ser negativa'; // Opcional: validación de valor
                    return null; // Validación exitosa
                 },
                // onSaved: (value) => _cantidad = value ?? '', // Ya no necesario
              ),
              const SizedBox(height: 20),

              // --- Campo Precio ---
               TextFormField(
                controller: _precioController, // Usar controlador
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                  prefixText: '\$', // Opcional: Añadir un prefijo de moneda
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true), // Permitir decimales
                 validator: (value) { // Validar que sea un número con decimales
                    if (value == null || value.isEmpty) return 'Ingrese un precio';
                     // Reemplazar coma por punto si se usa coma como separador decimal
                    final cleanedValue = value.trim().replaceAll(',', '.');
                    if (double.tryParse(cleanedValue) == null) return 'Debe ser un número válido';
                    if (double.parse(cleanedValue) < 0) return 'El precio no puede ser negativo'; // Opcional: validación de valor
                    return null; // Validación exitosa
                 },
               ),
               const SizedBox(height: 30), // Espacio antes de los botones

              // --- Botones ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Guardar (Principal)
                  Expanded( // Usar Expanded para que los botones compartan el espacio
                    child: FilledButton.icon( // Usamos FilledButton para alta prominencia M3
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                      onPressed: _saveIngrediente, // Llama a la función async _saveIngrediente
                    ),
                  ),
                  const SizedBox(width: 16), // Espacio entre botones
                  // Botón Cancelar (Secundario)
                  Expanded( // Usar Expanded
                    child: OutlinedButton.icon( // Usamos OutlinedButton para menor prominencia M3
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancelar'),
                      onPressed: () => Navigator.pop(context), // Volver sin guardar
                    ),
                  ),
                ],
              ),
               const SizedBox(height: 24), // Espacio al final
            ],
          ),
        ),
      ),
    );
  }
}