// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrumentos.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InstrumentoAdapter extends TypeAdapter<Instrumento> {
  @override
  final int typeId = 2;

  @override
  Instrumento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Instrumento(
      nombre: fields[0] as String,
      id: fields[1] as int,
      descripcion: fields[2] as String,
      cantidad: fields[3] as int,
      tipo: fields[4] as String,
      capacidadMaximaKg: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Instrumento obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.descripcion)
      ..writeByte(3)
      ..write(obj.cantidad)
      ..writeByte(4)
      ..write(obj.tipo)
      ..writeByte(5)
      ..write(obj.capacidadMaximaKg);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InstrumentoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
