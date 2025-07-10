import 'ingredientes.dart';
import 'instrumentos.dart';
import 'paso.dart';
import 'receta.dart';

/// Clase utilitaria para calcular el loteo óptimo de pasos que usan utensilios de almacenamiento.
class LoteoOptimizer {
  /// Calcula la cantidad total de cada paso/ingrediente requerido para la producción final.
  /// Divide los pasos que usan utensilios de almacenamiento en lotes óptimos según la capacidad del utensilio.
  /// Devuelve un mapa con los pasos loteados y sus asignaciones.
  static List<LoteoPasoResult> optimizarLoteo({
    required Receta receta,
    required List<Paso> pasos,
    required List<Instrumento> utensilios,
    required double cantidadFinal, // Cambiado a double
  }) {
    // 1. Construir un mapa de pasos por ID para acceso rápido
    final pasosPorId = {for (var p in pasos) p.id: p};
    // 2. Calcular requerimientos totales recursivamente
    final requerimientos = _calcularRequerimientosPaso(
      receta,
      pasosPorId,
      receta.pasosIds.last, // Suponemos que el último paso es el final
      cantidadFinal,
      {},
    );
    // 3. Loteo de pasos con utensilios de almacenamiento
    final loteos = <LoteoPasoResult>[];
    for (final pasoId in requerimientos.keys) {
      final paso = pasosPorId[pasoId]!;
      final cantidad = requerimientos[pasoId]!;
      final utensilioId = paso.recursoAlmacenamiento.isNotEmpty ? paso.recursoAlmacenamiento.first : null;
      if (utensilioId != null) {
        final utensilio = utensilios.firstWhere(
          (u) => u.id.toString() == utensilioId,
          orElse: () => Instrumento(nombre: '', id: 0, descripcion: '', cantidad: 0, tipo: 'Normal', capacidadMaximaKg: null),
        );
        // Solo si el utensilio es de almacenamiento se aplica la lógica de capacidad máxima
        if (utensilio.tipo == 'Almacenamiento' && utensilio.capacidadMaximaKg != null && utensilio.capacidadMaximaKg! > 0) {
          final capacidad = utensilio.capacidadMaximaKg!;
          final lotes = (cantidad / capacidad).ceil();
          for (int i = 0; i < lotes; i++) {
            final cantidadLote = (i == lotes - 1) ? (cantidad - capacidad * (lotes - 1)) : capacidad;
            loteos.add(LoteoPasoResult(
              paso: paso,
              cantidad: cantidadLote,
              utensilio: utensilio,
              lote: i + 1,
              totalLotes: lotes,
            ));
          }
        } else {
          // Si no es de almacenamiento, no se hace batching
          loteos.add(LoteoPasoResult(
            paso: paso,
            cantidad: cantidad,
            utensilio: utensilio,
            lote: 1,
            totalLotes: 1,
          ));
        }
      } else {
        loteos.add(LoteoPasoResult(
          paso: paso,
          cantidad: cantidad,
          utensilio: null,
          lote: 1,
          totalLotes: 1,
        ));
      }
    }
    return loteos;
  }

  /// Recursivamente calcula la cantidad total requerida de cada paso.
  static Map<String, double> _calcularRequerimientosPaso(
    Receta receta,
    Map<String, Paso> pasosPorId,
    String pasoId,
    double cantidadNecesaria,
    Map<String, double> acumulado,
  ) {
    acumulado[pasoId] = (acumulado[pasoId] ?? 0) + cantidadNecesaria;
    final paso = pasosPorId[pasoId]!;
    // Ingredientes requeridos (no recursivo)
    // Dependencias de pasos (recursivo)
    for (final depId in paso.tareasAnterioresDirectas) {
      _calcularRequerimientosPaso(receta, pasosPorId, depId, cantidadNecesaria, acumulado);
    }
    return acumulado;
  }
}

class LoteoPasoResult {
  final Paso paso;
  final double cantidad;
  final Instrumento? utensilio;
  final int lote;
  final int totalLotes;

  LoteoPasoResult({
    required this.paso,
    required this.cantidad,
    required this.utensilio,
    required this.lote,
    required this.totalLotes,
  });
}
