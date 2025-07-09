import 'dart:async';
import 'package:flutter/material.dart';
import 'agenda_models.dart';

/// Estados del sistema de ejecución
enum EstadoEjecucion {
  detenido,
  ejecutando,
  pausado,
  completado,
}

/// Maneja la ejecución en tiempo real de las agendas
class SistemaEjecucion extends ChangeNotifier {
  final List<EntradaAgenda> _agendasCombinadas;
  
  EstadoEjecucion _estado = EstadoEjecucion.detenido;
  Timer? _cronometro;
  int _tiempoTranscurrido = 0; // en segundos
  
  // Callbacks para notificaciones de audio
  final Function(String mensaje)? onNotificacionAudio;
  
  SistemaEjecucion({
    required List<EntradaAgenda> agendasCombinadas,
    this.onNotificacionAudio,
  }) : _agendasCombinadas = List.from(agendasCombinadas);
  
  // Getters
  EstadoEjecucion get estado => _estado;
  int get tiempoTranscurrido => _tiempoTranscurrido;
  int get tiempoTotal => _agendasCombinadas.isNotEmpty 
      ? _agendasCombinadas.last.tiempoFin 
      : 0;
  double get progreso => tiempoTotal > 0 
      ? _tiempoTranscurrido / tiempoTotal 
      : 0.0;
  
  /// Obtiene las próximas tareas a ejecutar
  List<EntradaAgenda> get proximasTareas {
    return _agendasCombinadas
        .where((entrada) => entrada.tiempoInicio >= _tiempoTranscurrido)
        .take(5)
        .toList();
  }
  
  /// Obtiene las tareas actualmente en ejecución
  List<EntradaAgenda> get tareasEnEjecucion {
    return _agendasCombinadas
        .where((entrada) => 
            entrada.tiempoInicio <= _tiempoTranscurrido && 
            entrada.tiempoFin > _tiempoTranscurrido)
        .toList();
  }
  
  /// Obtiene las tareas completadas
  List<EntradaAgenda> get tareasCompletadas {
    return _agendasCombinadas
        .where((entrada) => entrada.tiempoFin <= _tiempoTranscurrido)
        .toList();
  }
  
  /// Inicia la ejecución
  void iniciar() {
    if (_estado == EstadoEjecucion.detenido || _estado == EstadoEjecucion.pausado) {
      _estado = EstadoEjecucion.ejecutando;
      _iniciarCronometro();
      notifyListeners();
    }
  }
  
  /// Pausa la ejecución
  void pausar() {
    if (_estado == EstadoEjecucion.ejecutando) {
      _estado = EstadoEjecucion.pausado;
      _cronometro?.cancel();
      notifyListeners();
    }
  }
  
  /// Detiene la ejecución
  void detener() {
    _estado = EstadoEjecucion.detenido;
    _cronometro?.cancel();
    _tiempoTranscurrido = 0;
    notifyListeners();
  }
  
  /// Reinicia la ejecución
  void reiniciar() {
    detener();
    iniciar();
  }
  
  /// Inicia el cronómetro interno
  void _iniciarCronometro() {
    _cronometro = Timer.periodic(const Duration(seconds: 1), (timer) {
      _tiempoTranscurrido++;
      _verificarNotificaciones();
      _verificarComplecion();
      notifyListeners();
    });
  }
  
  /// Verifica si hay tareas que deben notificarse
  void _verificarNotificaciones() {
    // Buscar tareas que empiezan en este momento
    for (final entrada in _agendasCombinadas) {
      if (entrada.tiempoInicio == _tiempoTranscurrido) {
        _notificarInicioDeTarea(entrada);
      }
    }
  }
  
  /// Notifica el inicio de una tarea
  void _notificarInicioDeTarea(EntradaAgenda entrada) {
    final mensaje = _generarMensajeNotificacion(entrada);
    onNotificacionAudio?.call(mensaje);
  }
  
  /// Genera el mensaje de notificación para una tarea
  String _generarMensajeNotificacion(EntradaAgenda entrada) {
    // Encontrar los trabajadores involucrados en esta tarea
    final trabajadores = <String>[];
    
    // Esto es una simplificación. En una implementación real,
    // necesitarías mapear las agendas a los trabajadores específicos
    for (final tipoTrabajador in entrada.paso.trabajadores) {
      trabajadores.add(tipoTrabajador);
    }
    
    final trabajadoresTexto = trabajadores.join(', ');
    final duracion = _formatearTiempo(entrada.paso.tiempoSegundos);
    
    return '$trabajadoresTexto: Inicien ${entrada.paso.descripcion} '
           'para ${entrada.recetaNombre} (instancia ${entrada.recetaInstancia}). '
           'Duración estimada: $duracion.';
  }
  
  /// Verifica si la ejecución se ha completado
  void _verificarComplecion() {
    if (_tiempoTranscurrido >= tiempoTotal) {
      _estado = EstadoEjecucion.completado;
      _cronometro?.cancel();
      onNotificacionAudio?.call('¡Ejecución completada! Todas las recetas han sido terminadas.');
    }
  }
  
  /// Formatea el tiempo en formato mm:ss
  String formatearTiempoTranscurrido() {
    return _formatearTiempo(_tiempoTranscurrido);
  }
  
  /// Formatea el tiempo total en formato mm:ss
  String formatearTiempoTotal() {
    return _formatearTiempo(tiempoTotal);
  }
  
  /// Formatea un tiempo en segundos a formato mm:ss
  String _formatearTiempo(int segundos) {
    final minutos = segundos ~/ 60;
    final segundosRestantes = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundosRestantes.toString().padLeft(2, '0')}';
  }
  
  /// Obtiene el tiempo restante en segundos
  int get tiempoRestante => tiempoTotal - _tiempoTranscurrido;
  
  /// Formatea el tiempo restante
  String formatearTiempoRestante() {
    return _formatearTiempo(tiempoRestante);
  }
  
  @override
  void dispose() {
    _cronometro?.cancel();
    super.dispose();
  }
}
