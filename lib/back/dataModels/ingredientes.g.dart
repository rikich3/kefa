// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredientes.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredientesAdapter extends TypeAdapter<Ingredientes> {
  @override
  final int typeId = 1;

  @override
  Ingredientes read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ingredientes(
      name: fields[0] as String,
      descripcion: fields[1] as String,
      unidadMedida: fields[2] as String,
      cantidad: fields[3] as int,
      precio: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Ingredientes obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.descripcion)
      ..writeByte(2)
      ..write(obj.unidadMedida)
      ..writeByte(3)
      ..write(obj.cantidad)
      ..writeByte(4)
      ..write(obj.precio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
