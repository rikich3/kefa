// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cocinero_scheduling.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CocineroSchedulingAdapter extends TypeAdapter<CocineroScheduling> {
  @override
  final int typeId = 11;

  @override
  CocineroScheduling read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CocineroScheduling(
      id: fields[0] as String,
      nombre: fields[1] as String,
      tipo: fields[2] as String,
      horario: (fields[3] as List?)?.cast<HorarioItem>(),
      ori: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CocineroScheduling obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nombre)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.horario)
      ..writeByte(4)
      ..write(obj.ori);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CocineroSchedulingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
