// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paso.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IngredienteRequeridoAdapter extends TypeAdapter<IngredienteRequerido> {
  @override
  final int typeId = 5;

  @override
  IngredienteRequerido read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredienteRequerido(
      ingredienteId: fields[0] as String,
      cantidad: fields[1] as double,
      unidadMedida: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, IngredienteRequerido obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.ingredienteId)
      ..writeByte(1)
      ..write(obj.cantidad)
      ..writeByte(2)
      ..write(obj.unidadMedida);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredienteRequeridoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PasoAdapter extends TypeAdapter<Paso> {
  @override
  final int typeId = 6;

  @override
  Paso read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Paso(
      id: fields[0] as String,
      recetaId: fields[1] as String,
      nombrePaso: fields[2] as String,
      contenidoAccion: fields[3] as String,
      recursosCocinasRequeridos: (fields[4] as List).cast<String>(),
      ingredientesRequeridos: (fields[5] as List).cast<IngredienteRequerido>(),
      recursoAlmacenamiento: (fields[6] as List).cast<String>(),
      tiempoCoccionSegundos: fields[7] as int,
      tiempoPreparacionSegundos: fields[8] as int,
      tipoCoccion: fields[9] as String,
      tipoAlmacenamiento: fields[10] as String,
      tareasAnterioresDirectas: (fields[11] as List).cast<String>(),
      orden: fields[12] as int,
      tipoCocinero: fields[13] as String?,
      tipoUtensilio: fields[14] as String?,
      dependencias: (fields[15] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Paso obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.recetaId)
      ..writeByte(2)
      ..write(obj.nombrePaso)
      ..writeByte(3)
      ..write(obj.contenidoAccion)
      ..writeByte(4)
      ..write(obj.recursosCocinasRequeridos)
      ..writeByte(5)
      ..write(obj.ingredientesRequeridos)
      ..writeByte(6)
      ..write(obj.recursoAlmacenamiento)
      ..writeByte(7)
      ..write(obj.tiempoCoccionSegundos)
      ..writeByte(8)
      ..write(obj.tiempoPreparacionSegundos)
      ..writeByte(9)
      ..write(obj.tipoCoccion)
      ..writeByte(10)
      ..write(obj.tipoAlmacenamiento)
      ..writeByte(11)
      ..write(obj.tareasAnterioresDirectas)
      ..writeByte(12)
      ..write(obj.orden)
      ..writeByte(13)
      ..write(obj.tipoCocinero)
      ..writeByte(14)
      ..write(obj.tipoUtensilio)
      ..writeByte(15)
      ..write(obj.dependencias);
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
