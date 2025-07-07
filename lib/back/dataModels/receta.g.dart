// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecetaAdapter extends TypeAdapter<Receta> {
  @override
  final int typeId = 4;

  @override
  Receta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receta(
      nombre: fields[0] as String,
      descripcion: fields[1] as String,
      cantidadPorciones: fields[2] as int,
      categoria: fields[3] as String,
      etiquetas: (fields[4] as List).cast<String>(),
      duracionEstimadaMinutos: fields[5] as int,
      imagenPath: fields[6] as String?,
      pasosIds: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Receta obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.nombre)
      ..writeByte(1)
      ..write(obj.descripcion)
      ..writeByte(2)
      ..write(obj.cantidadPorciones)
      ..writeByte(3)
      ..write(obj.categoria)
      ..writeByte(4)
      ..write(obj.etiquetas)
      ..writeByte(5)
      ..write(obj.duracionEstimadaMinutos)
      ..writeByte(6)
      ..write(obj.imagenPath)
      ..writeByte(7)
      ..write(obj.pasosIds);
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
