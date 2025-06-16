import 'package:flutter/material.dart';
import '../../back/dataModels/instrumentos.dart';
import '../../back/repositories/instrumentos_repository.dart';

class InstrumentosProvider extends ChangeNotifier {
  final InstrumentosRepository _instrumentosRepository;

  List<MapEntry<dynamic, Instrumento>> _instrumentosEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  InstrumentosProvider({required InstrumentosRepository instrumentosRepository})
      : _instrumentosRepository = instrumentosRepository {
    loadInstrumentos();
  }

  List<MapEntry<dynamic, Instrumento>> get instrumentosEntries => _instrumentosEntries;
  List<Instrumento> get instrumentos => _instrumentosEntries.map((e) => e.value).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadInstrumentos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final allInstrumentos = await _instrumentosRepository.getAllInstrumentos();
      // Si el repo devuelve List<Instrumento>, generamos MapEntry con el índice como key
      _instrumentosEntries = allInstrumentos.asMap().entries.map((e) => MapEntry(e.key, e.value)).toList();
    } catch (e) {
      _errorMessage = 'Error al cargar instrumentos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addInstrumento(Instrumento instrumento) async {
    if (instrumento.nombre.isEmpty) {
      _errorMessage = 'El nombre del instrumento no puede estar vacío';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _instrumentosRepository.addInstrumento(instrumento);
      await loadInstrumentos();
    } catch (e) {
      _errorMessage = 'Error al añadir instrumento: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInstrumento(dynamic key, Instrumento instrumento) async {
    await _instrumentosRepository.updateInstrumento(key, instrumento);
    await loadInstrumentos();
  }

  Future<void> deleteInstrumento(dynamic key) async {
    await _instrumentosRepository.deleteInstrumento(key);
    await loadInstrumentos();
  }
}