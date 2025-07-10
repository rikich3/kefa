// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'estado_scheduling.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
