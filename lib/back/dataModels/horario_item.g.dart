// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'horario_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HorarioItemAdapter extends TypeAdapter<HorarioItem> {
  @override
  final int typeId = 10;

  @override
  HorarioItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HorarioItem(
      tiempoInicio: fields[0] as int,
      duracion: fields[1] as int,
      pasoId: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, HorarioItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.tiempoInicio)
      ..writeByte(1)
      ..write(obj.duracion)
      ..writeByte(2)
      ..write(obj.pasoId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HorarioItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
