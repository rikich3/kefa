// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tarea_asignada.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TareaAsignadaAdapter extends TypeAdapter<TareaAsignada> {
  @override
  final int typeId = 17;

  @override
  TareaAsignada read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TareaAsignada(
      id: fields[0] as String,
      cocineroId: fields[1] as String,
      nombreTarea: fields[2] as String,
      descripcion: fields[3] as String,
      utensiliosRequeridos: (fields[4] as List).cast<String>(),
      tiempoInicioSegundos: fields[5] as int,
      duracionSegundos: fields[6] as int,
      orden: fields[7] as int,
      fechaAsignacion: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TareaAsignada obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.cocineroId)
      ..writeByte(2)
      ..write(obj.nombreTarea)
      ..writeByte(3)
      ..write(obj.descripcion)
      ..writeByte(4)
      ..write(obj.utensiliosRequeridos)
      ..writeByte(5)
      ..write(obj.tiempoInicioSegundos)
      ..writeByte(6)
      ..write(obj.duracionSegundos)
      ..writeByte(7)
      ..write(obj.orden)
      ..writeByte(8)
      ..write(obj.fechaAsignacion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TareaAsignadaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
