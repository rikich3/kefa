// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paso_scheduling.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasoSchedulingAdapter extends TypeAdapter<PasoScheduling> {
  @override
  final int typeId = 12;

  @override
  PasoScheduling read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PasoScheduling(
      id: fields[0] as String,
      nombre: fields[1] as String,
      tipoCocinero: fields[2] as String,
      tipoUtensilio: fields[3] as String,
      duracion: fields[4] as int,
      dependencias: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PasoScheduling obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.dependencias);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasoSchedulingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
