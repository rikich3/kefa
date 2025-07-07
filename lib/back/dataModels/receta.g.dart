// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecetaAdapter extends TypeAdapter<Receta> {
  @override
  final int typeId = 5;

  @override
  Receta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receta(
      nombre: fields[0] as String,
      descripcion: fields[1] as String,
      pasos: (fields[2] as List).cast<Paso>(),
      tiempoTotalSegundos: fields[3] as int,
      fechaCreacion: fields[4] as DateTime,
      id: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Receta obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.descripcion)
      ..writeByte(2)
      ..write(obj.pasos)
      ..writeByte(3)
      ..write(obj.tiempoTotalSegundos)
      ..writeByte(4)
      ..write(obj.fechaCreacion)
      ..writeByte(5)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
