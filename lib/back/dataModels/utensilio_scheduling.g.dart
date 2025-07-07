// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'utensilio_scheduling.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UtensilioSchedulingAdapter extends TypeAdapter<UtensilioScheduling> {
  @override
  final int typeId = 12;

  @override
  UtensilioScheduling read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UtensilioScheduling(
      id: fields[0] as String,
      nombre: fields[1] as String,
      tipo: fields[2] as String,
      horario: (fields[3] as List?)?.cast<HorarioItem>(),
      ori: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UtensilioScheduling obj) {
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
      other is UtensilioSchedulingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
