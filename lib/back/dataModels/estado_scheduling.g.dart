// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estado_scheduling.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasoSchedulingDinamicoAdapter
    extends TypeAdapter<PasoSchedulingDinamico> {
  @override
  final int typeId = 15;

  @override
  PasoSchedulingDinamico read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasoSchedulingDinamico(
      id: fields[0] as String,
      nombre: fields[1] as String,
      tipoCocinero: fields[2] as String,
      tipoUtensilio: fields[3] as String,
      duracion: fields[4] as int,
      dependenciasOriginales: (fields[5] as List?)?.cast<String>(),
      estado: fields[7] as EstadoPaso,
      tiempoInicio: fields[8] as int?,
      tiempoFin: fields[9] as int?,
      cocineroAsignado: fields[10] as String?,
      utensilioAsignado: fields[11] as String?,
      prioridad: fields[12] as int,
    )..dependenciasPendientes = (fields[6] as List).cast<String>();
  }

  @override
  void write(BinaryWriter writer, PasoSchedulingDinamico obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.tipoCocinero)
      ..writeByte(3)
      ..write(obj.tipoUtensilio)
      ..writeByte(4)
      ..write(obj.duracion)
      ..writeByte(5)
      ..write(obj.dependenciasOriginales)
      ..writeByte(6)
      ..write(obj.dependenciasPendientes)
      ..writeByte(7)
      ..write(obj.estado)
      ..writeByte(8)
      ..write(obj.tiempoInicio)
      ..writeByte(9)
      ..write(obj.tiempoFin)
      ..writeByte(10)
      ..write(obj.cocineroAsignado)
      ..writeByte(11)
      ..write(obj.utensilioAsignado)
      ..writeByte(12)
      ..write(obj.prioridad);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasoSchedulingDinamicoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EstadoSchedulingAdapter extends TypeAdapter<EstadoScheduling> {
  @override
  final int typeId = 16;

  @override
  EstadoScheduling read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EstadoScheduling(
      tiempoActual: fields[0] as int,
      todosPasos: (fields[1] as List?)?.cast<PasoSchedulingDinamico>(),
      cocineros: (fields[2] as List?)?.cast<CocineroScheduling>(),
      utensilios: (fields[3] as List?)?.cast<UtensilioScheduling>(),
      logEventos: (fields[4] as List?)?.cast<String>(),
      completado: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, EstadoScheduling obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.tiempoActual)
      ..writeByte(1)
      ..write(obj.todosPasos)
      ..writeByte(2)
      ..write(obj.cocineros)
      ..writeByte(3)
      ..write(obj.utensilios)
      ..writeByte(4)
      ..write(obj.logEventos)
      ..writeByte(5)
      ..write(obj.completado);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadoSchedulingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EstadoPasoAdapter extends TypeAdapter<EstadoPaso> {
  @override
  final int typeId = 14;

  @override
  EstadoPaso read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EstadoPaso.pendiente;
      case 1:
        return EstadoPaso.disponible;
      case 2:
        return EstadoPaso.enProceso;
      case 3:
        return EstadoPaso.completado;
      default:
        return EstadoPaso.pendiente;
    }
  }

  @override
  void write(BinaryWriter writer, EstadoPaso obj) {
    switch (obj) {
      case EstadoPaso.pendiente:
        writer.writeByte(0);
        break;
      case EstadoPaso.disponible:
        writer.writeByte(1);
        break;
      case EstadoPaso.enProceso:
        writer.writeByte(2);
        break;
      case EstadoPaso.completado:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstadoPasoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
