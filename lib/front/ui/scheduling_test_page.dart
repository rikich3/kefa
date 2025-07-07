import 'package:flutter/material.dart';
import '../../back/algorithms/kitchen_scheduling_algorithm.dart';
import '../../back/dataModels/cocinero_scheduling.dart';
import '../../back/dataModels/utensilio_scheduling.dart';
import '../../back/dataModels/paso_scheduling.dart';

class SchedulingTestPage extends StatefulWidget {
  const SchedulingTestPage({super.key});

  @override
  State<SchedulingTestPage> createState() => _SchedulingTestPageState();
}

class _SchedulingTestPageState extends State<SchedulingTestPage> {
  final KitchenSchedulingAlgorithm algoritmo = KitchenSchedulingAlgorithm();
  bool _ejecutado = false;
  
  @override
  void initState() {
    super.initState();
    _configurarEjemploDelUsuario();
  }

  void _configurarEjemploDelUsuario() {
    // Configurar el ejemplo exacto que describió el usuario
    // Cocineros 1a, 2a
    List<CocineroScheduling> cocineros = [
      CocineroScheduling(id: '1a', nombre: '1a', tipo: 'cocinero'),
      CocineroScheduling(id: '2a', nombre: '2a', tipo: 'cocinero'),
    ];

    // Ollas 1b
    List<CocineroScheduling> ollas = [
      CocineroScheduling(id: '1b', nombre: '1b', tipo: 'olla'),
    ];

    // Utensilios A1, B1, B2 (B2 empieza a los 30s)
    List<UtensilioScheduling> utensilios = [
      UtensilioScheduling(id: 'A1', nombre: 'A1', tipo: 'A'),
      UtensilioScheduling(id: 'B1', nombre: 'B1', tipo: 'B'),
      UtensilioScheduling(id: 'B2', nombre: 'B2', tipo: 'B', ori: 30), // B2 empieza a los 30s
    ];

    // Pasos del ejemplo
    // A: cocinero, A, 10
    // B: cocinero, B, 10  
    // C: cocinero, B, 10
    List<PasoScheduling> pasos = [
      PasoScheduling(
        id: 'A',
        nombre: 'Paso A',
        tipoCocinero: 'cocinero',
        tipoUtensilio: 'A',
        duracion: 10,
        dependencias: [], // hoja
      ),
      PasoScheduling(
        id: 'B',
        nombre: 'Paso B',
        tipoCocinero: 'cocinero',
        tipoUtensilio: 'B',
        duracion: 10,
        dependencias: [], // hoja
      ),
      PasoScheduling(
        id: 'C',
        nombre: 'Paso C',
        tipoCocinero: 'cocinero',
        tipoUtensilio: 'B',
        duracion: 10,
        dependencias: [], // hoja
      ),
      PasoScheduling(
        id: 'D',
        nombre: 'Paso D',
        tipoCocinero: 'cocinero',
        tipoUtensilio: 'A',
        duracion: 15,
        dependencias: ['A', 'B', 'C'], // requiere A, B, C
      ),
      PasoScheduling(
        id: 'F',
        nombre: 'Paso F',
        tipoCocinero: 'cocinero',
        tipoUtensilio: 'B',
        duracion: 12,
        dependencias: [], // hoja independiente
      ),
      PasoScheduling(
        id: 'E',
        nombre: 'Paso E (Plato Final)',
        tipoCocinero: 'cocinero',
        tipoUtensilio: 'A',
        duracion: 20,
        dependencias: ['D', 'F'], // requiere D y F
      ),
    ];

    // Inicializar el algoritmo
    List<CocineroScheduling> todosCocineros = [...cocineros, ...ollas];
    algoritmo.inicializarRecursos(
      listaCocineros: todosCocineros,
      listaUtensilios: utensilios,
      listaPasos: pasos,
    );
  }

  void _ejecutarAlgoritmo() {
    setState(() {
      // Reinicializar para nueva ejecución
      _configurarEjemploDelUsuario();
      
      // Ejecutar algoritmo para 3 platos como en el ejemplo
      algoritmo.ejecutarAlgoritmo('E', 3);
      _ejecutado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Algoritmo de Scheduling'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Algoritmo de Scheduling de Cocina',
              style: textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuración del Ejemplo:',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('• Cocineros: 1a, 2a', style: textTheme.bodyMedium),
                    Text('• Ollas: 1b', style: textTheme.bodyMedium),
                    Text('• Utensilios: A1, B1, B2', style: textTheme.bodyMedium),
                    Text('• Pasos: A, B, C (hojas) → D → E', style: textTheme.bodyMedium),
                    Text('• Cantidad de platos: 3', style: textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            FilledButton.icon(
              onPressed: _ejecutarAlgoritmo,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Ejecutar Algoritmo'),
            ),
            
            const SizedBox(height: 20),
            
            if (_ejecutado) ...[
              Text(
                'Resultado del Scheduling:',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSeccionResultados('Cocineros y Ollas', algoritmo.cocineros, colorScheme),
                          const SizedBox(height: 20),
                          _buildSeccionResultadosUtensilios('Utensilios', algoritmo.utensilios, colorScheme),
                          const SizedBox(height: 20),
                          _buildResumenTiempos(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionResultados(String titulo, List<CocineroScheduling> recursos, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recursos.map((recurso) => _buildRecursoCard(recurso)).toList(),
      ],
    );
  }

  Widget _buildSeccionResultadosUtensilios(String titulo, List<UtensilioScheduling> recursos, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...recursos.map((recurso) => _buildUtensilioCard(recurso)).toList(),
      ],
    );
  }

  Widget _buildRecursoCard(CocineroScheduling recurso) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${recurso.nombre} (${recurso.tipo})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (recurso.horario.isEmpty)
              Text(
                'Sin tareas asignadas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...recurso.horario.map((item) {
                final paso = algoritmo.pasos[item.pasoId]!;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Text(
                    '${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso.nombre}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
            Text(
              'Tiempo total ocupado: ${recurso.ori}s',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtensilioCard(UtensilioScheduling utensilio) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${utensilio.nombre} (${utensilio.tipo})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (utensilio.horario.isEmpty)
              Text(
                'Sin tareas asignadas',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...utensilio.horario.map((item) {
                final paso = algoritmo.pasos[item.pasoId]!;
                return Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                  child: Text(
                    '${item.tiempoInicio}s - ${item.tiempoInicio + item.duracion}s: ${paso.nombre}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }).toList(),
            Text(
              'Tiempo total ocupado: ${utensilio.ori}s',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenTiempos() {
    if (!_ejecutado) return const SizedBox.shrink();
    
    int tiempoMaximo = 0;
    if (algoritmo.cocineros.isNotEmpty) {
      tiempoMaximo = algoritmo.cocineros.map((c) => c.ori).reduce((a, b) => a > b ? a : b);
    }
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.timer,
              size: 40,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'Tiempo Total de Cocina',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Text(
              '${tiempoMaximo}s',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
