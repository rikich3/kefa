import 'package:flutter/material.dart';
import '../../back/dataModels/worker.dart';
import '../../back/repositories/worker_repository.dart';

class WorkersProvider extends ChangeNotifier {
  final WorkerRepository _workerRepository;

  List<MapEntry<dynamic, Worker>> _workerEntries = [];
  bool _isLoading = false;
  String? _errorMessage;

  WorkersProvider({required WorkerRepository workerRepository})
      : _workerRepository = workerRepository {
    loadWorkers();
  }

  List<MapEntry<dynamic, Worker>> get workerEntries => _workerEntries;
  List<Worker> get workers => _workerEntries.map((e) => e.value).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadWorkers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Adaptación: getAllWorkers devuelve List<Worker>, así que generamos MapEntry con el índice como key
      final allWorkers = await _workerRepository.getAllWorkers();
      _workerEntries = allWorkers.asMap().entries.map((e) => MapEntry(e.key, e.value)).toList();
    } catch (e) {
      _errorMessage = 'Error al cargar trabajadores: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addWorker(Worker worker) async {
    if (worker.nombre.isEmpty) {
      _errorMessage = 'El nombre del trabajador no puede estar vacío';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _workerRepository.addWorker(worker);
      await loadWorkers();
    } catch (e) {
      _errorMessage = 'Error al añadir trabajador: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWorker(dynamic key, Worker worker) async {
    await _workerRepository.updateWorker(key, worker);
    await loadWorkers();
  }

  Future<void> deleteWorker(dynamic key) async {
    await _workerRepository.deleteWorker(key);
    await loadWorkers();
  }
}