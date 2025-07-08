import 'dart:math';

import '../dataModels/estado_scheduling.dart';
import '../dataModels/paso_scheduling.dart';
import '../dataModels/cocinero_scheduling.dart';
import '../dataModels/utensilio_scheduling.dart';
import '../dataModels/horario_item.dart';



/// Algoritmo de scheduling dinámico OPTIMIZADO con detección de camino crítico
class SchedulingDinamicoAlgorithmOptimizado {
  EstadoScheduling? _estadoActual;
  bool _debugMode = true;
  List<String> _logEventos = [];
  
  // NUEVAS ESTRUCTURAS PARA OPTIMIZACIÓN
  Map<String, List<String>> _caminosCriticos = {};
  Map<String, double> _impactoEnMakespan = {};
  Set<String> _pasosEnCaminoCritico = {};

  /// Getter para acceder al estado actual
  EstadoScheduling? get estadoActual => _estadoActual;

  /// Debug logging
  void _log(String mensaje) {
    if (_debugMode) {
      print(mensaje);
      _logEventos.add(mensaje);
    }
  }

  /// Inicializar el algoritmo con pasos, cocineros y utensilios
  void inicializar({
    required List<PasoScheduling> pasos,
    required List<CocineroScheduling> cocineros,
    required List<UtensilioScheduling> utensilios,
  }) {    
    // Convertir pasos básicos a dinámicos y marcar disponibles los que no tienen dependencias
    final pasosDinamicos = pasos.map((p) {
      final dinamico = PasoSchedulingDinamico.fromPasoScheduling(p);
      if (dinamico.dependenciasPendientes.isEmpty) {
        dinamico.estado = EstadoPaso.disponible;
      }
      return dinamico;
    }).toList();
    
    // Reiniciar recursos
    for (var cocinero in cocineros) {
      cocinero.horario.clear();
      cocinero.ori = 0;
    }
    for (var utensilio in utensilios) {
      utensilio.horario.clear();
    }

    // Crear estado inicial
    _estadoActual = EstadoScheduling()
      ..tiempoActual = 0
      ..todosPasos = pasosDinamicos
      ..cocineros = cocineros
      ..utensilios = utensilios;
    
    // Calcular caminos críticos y prioridades
    _calcularCaminosCriticos(pasosDinamicos);
    
    // Mostrar pasos disponibles inicialmente
    final disponibles = pasosDinamicos.where((p) => p.estado == EstadoPaso.disponible).toList();
  }

  /// Calcula los caminos críticos del proyecto
  void _calcularCaminosCriticos(List<PasoSchedulingDinamico> pasos) {
    _caminosCriticos.clear();
    _impactoEnMakespan.clear();
    _pasosEnCaminoCritico.clear();

    // Para cada paso, calcular el camino crítico hacia atrás
    for (final paso in pasos) {
      if (!_impactoEnMakespan.containsKey(paso.id)) {
        _calcularCaminoCriticoHaciaAtras(paso, pasos);
      }
    }

    // Normalizar impactos relativos
    double maxImpacto = _impactoEnMakespan.values.fold(0, max);
    for (var pasoId in _impactoEnMakespan.keys) {
      _impactoEnMakespan[pasoId] = _impactoEnMakespan[pasoId]! / maxImpacto;
    }

    // Identificar caminos críticos
    for (final paso in pasos) {
      if ((_impactoEnMakespan[paso.id] ?? 0) > 0.8) { // 80% del impacto máximo
        _pasosEnCaminoCritico.add(paso.id);
      }
    }
  }

  void _calcularCaminoCriticoHaciaAtras(PasoSchedulingDinamico paso, List<PasoSchedulingDinamico> todosPasos) {
    if (_impactoEnMakespan.containsKey(paso.id)) return;

    // Calcular impacto inicial del paso
    double impacto = paso.duracion.toDouble();
    List<String> camino = [paso.id];

    // Si tiene dependencias, recursivamente calcular sus impactos
    if (paso.dependenciasOriginales.isNotEmpty) {
      double maxDependenciaImpacto = 0;
      String? dependenciaCritica;

      for (final depId in paso.dependenciasOriginales) {
        final dependencia = todosPasos.firstWhere((p) => p.id == depId);
        _calcularCaminoCriticoHaciaAtras(dependencia, todosPasos);

        final impactoDependencia = _impactoEnMakespan[depId]!;
        if (impactoDependencia > maxDependenciaImpacto) {
          maxDependenciaImpacto = impactoDependencia;
          dependenciaCritica = depId;
        }
      }

      if (dependenciaCritica != null) {
        impacto += maxDependenciaImpacto;
        camino.insertAll(0, _caminosCriticos[dependenciaCritica]!);
      }
    }

    _impactoEnMakespan[paso.id] = impacto;
    _caminosCriticos[paso.id] = camino;
    
    // Si el impacto es alto, marcar como crítico
    if (impacto > 600) { // Umbral para considerar un paso como crítico
      _pasosEnCaminoCritico.add(paso.id);
    }
  }

  /// Ejecuta el algoritmo de scheduling
  List<String> ejecutarCompleto() {
    if (_estadoActual == null) {
      throw StateError('Debe inicializar el algoritmo primero');
    }

    // Bucle principal de scheduling
    bool hayTrabajoRestante = true;
    int iteraciones = 0;
    const maxIteraciones = 1000;

    while (hayTrabajoRestante && iteraciones < maxIteraciones) {
      iteraciones++;

      // 1. Procesar pasos que terminan
      List<PasoSchedulingDinamico> pasosActivos = _estadoActual!.todosPasos
          .where((p) => p.estado == EstadoPaso.enProceso)
          .toList();
      _procesarPasosCompletados(pasosActivos);

      // 2. Asignar nuevos recursos
      int nuevosAsignados = _asignarRecursos();

      // 3. Verificar si hay trabajo restante
      pasosActivos = _estadoActual!.todosPasos
          .where((p) => p.estado == EstadoPaso.enProceso)
          .toList();
      
      final pasosNoCompletados = _estadoActual!.todosPasos
          .where((p) => p.estado != EstadoPaso.completado)
          .length;

      if (pasosNoCompletados == 0) {
        hayTrabajoRestante = false;
        _log('✅ Todos los pasos completados');
      } else if (nuevosAsignados == 0 && pasosActivos.isEmpty) {
        hayTrabajoRestante = false;
      } else {
        // 4. Avanzar al siguiente tiempo relevante
        int siguienteTiempo = _calcularSiguienteTiempo(pasosActivos);
        _avanzarTiempo(siguienteTiempo);
      }
    }

    // Verificar resultado
    final pasosCompletados = _estadoActual!.todosPasos
        .where((p) => p.estado == EstadoPaso.completado)
        .length;
    final totalPasos = _estadoActual!.todosPasos.length;

    return _logEventos;
  }

  /// Verifica si un recurso está disponible
  bool _estaDisponible(dynamic recurso, int tiempo) {
    return recurso.horario.every((HorarioItem item) => 
      (item.tiempoInicio + item.duracion) <= tiempo || item.tiempoInicio > tiempo);
  }

  /// Avanzar el tiempo del sistema
  void _avanzarTiempo(int nuevoTiempo) {
    if (_estadoActual != null) {
      _estadoActual!.tiempoActual = nuevoTiempo;
    }
  }

  /// Calcula el siguiente tiempo relevante para avanzar
  int _calcularSiguienteTiempo(List<PasoSchedulingDinamico> pasosActivos) {
    if (pasosActivos.isEmpty) return _estadoActual!.tiempoActual + 1;

    int siguienteTiempo = pasosActivos
        .map((p) => p.tiempoFin ?? _estadoActual!.tiempoActual + 1)
        .reduce(min);

    return siguienteTiempo;
  }

  /// Procesa los pasos que finalizan en el tiempo actual
  void _procesarPasosCompletados(List<PasoSchedulingDinamico> pasosActivos) {
    for (final paso in pasosActivos) {
      if (paso.tiempoFin == _estadoActual!.tiempoActual) {
        paso.estado = EstadoPaso.completado;

        // Actualizar dependientes
        for (final otroPaso in _estadoActual!.todosPasos) {
          if (otroPaso.dependenciasPendientes.contains(paso.id)) {
            otroPaso.dependenciasPendientes.remove(paso.id);
            if (otroPaso.dependenciasPendientes.isEmpty) {
              otroPaso.estado = EstadoPaso.disponible;
            }
          }
        }
      }
    }
  }

  /// Intenta asignar recursos a pasos disponibles
  int _asignarRecursos() {
    int asignados = 0;
    final pasosDisponibles = _estadoActual!.todosPasos
        .where((p) => p.estado == EstadoPaso.disponible)
        .toList();

    // Calcular prioridad de cada paso
    final prioridades = <String, double>{};
    for (final paso in pasosDisponibles) {
      double prioridad = _impactoEnMakespan[paso.id] ?? 0;
      
      // Bonus por estar en camino crítico
      if (_pasosEnCaminoCritico.contains(paso.id)) {
        prioridad *= 2;
      }
      
      // Bonus por tener dependientes esperando
      final numDependientes = _estadoActual!.todosPasos
          .where((p) => p.dependenciasPendientes.contains(paso.id))
          .length;
      prioridad += numDependientes * 0.5;
      
      // Penalización por recursos ocupados
      final cocineroDisponible = _estadoActual!.cocineros
          .where((c) => c.tipo == paso.tipoCocinero)
          .any((c) => _estaDisponible(c, _estadoActual!.tiempoActual));
          
      final utensilioDisponible = _estadoActual!.utensilios
          .where((u) => u.tipo == paso.tipoUtensilio)
          .any((u) => _estaDisponible(u, _estadoActual!.tiempoActual));
          
      if (!cocineroDisponible || !utensilioDisponible) {
        prioridad *= 0.5;
      }

      prioridades[paso.id] = prioridad;
    }

    // Ordenar pasos por prioridad
    pasosDisponibles.sort((a, b) {
      if (_pasosEnCaminoCritico.contains(a.id) != _pasosEnCaminoCritico.contains(b.id)) {
        return _pasosEnCaminoCritico.contains(a.id) ? -1 : 1;
      }
      if ((prioridades[b.id] ?? 0) != (prioridades[a.id] ?? 0)) {
        return (prioridades[b.id] ?? 0).compareTo(prioridades[a.id] ?? 0);
      }
      return b.duracion.compareTo(a.duracion); // Priorizar pasos más largos
    });

    // Intentar asignar recursos en orden de prioridad
    for (final paso in pasosDisponibles) {
      if (paso.estado == EstadoPaso.disponible) {
        bool asignado = _intentarAsignarRecursos(paso);
        if (asignado) {
          asignados++;
        }
      }
    }

    return asignados;
  }

  /// Intenta asignar recursos específicos a un paso
  bool _intentarAsignarRecursos(PasoSchedulingDinamico paso) {
    // Buscar cocinero disponible
    final cocineroDisponible = _estadoActual!.cocineros
        .where((c) => c.tipo == paso.tipoCocinero)
        .where((c) => _estaDisponible(c, _estadoActual!.tiempoActual))
        .firstOrNull;

    if (cocineroDisponible == null) return false;

    // Buscar utensilio disponible
    final utensilioDisponible = _estadoActual!.utensilios
        .where((u) => u.tipo == paso.tipoUtensilio)
        .where((u) => _estaDisponible(u, _estadoActual!.tiempoActual))
        .firstOrNull;

    if (utensilioDisponible == null) return false;

    // Asignar recursos
    final tiempoInicio = _estadoActual!.tiempoActual;
    final horarioItem = HorarioItem(
      pasoId: paso.id,
      tiempoInicio: tiempoInicio,
      duracion: paso.duracion,
    );

    cocineroDisponible.horario.add(horarioItem);
    utensilioDisponible.horario.add(horarioItem);

    paso.estado = EstadoPaso.enProceso;
    paso.tiempoInicio = tiempoInicio;
    paso.tiempoFin = tiempoInicio + paso.duracion;
    paso.cocineroAsignado = cocineroDisponible.id;
    paso.utensilioAsignado = utensilioDisponible.id;

    return true;
  }
}
