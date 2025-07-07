// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paso.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PasoAdapter extends TypeAdapter<Paso> {
  @override
  final int typeId = 4;

  @override
  Paso read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Paso(
      trabajadores: (fields[0] as List).cast<String>(),
      utensilioTipos: (fields[1] as List).cast<String>(),
      utensilioCantidades: (fields[2] as List).cast<int>(),
      tiempoSegundos: fields[3] as int,
      descripcion: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Paso obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.trabajadores)
      ..writeByte(1)
      ..write(obj.utensilioTipos)
      ..writeByte(2)
      ..write(obj.utensilioCantidades)
      ..writeByte(3)
      ..write(obj.tiempoSegundos)
      ..writeByte(4)
      ..write(obj.descripcion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PasoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
