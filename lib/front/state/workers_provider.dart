import 'package:flutter/material.dart';
import '../../back/dataModels/worker.dart';
import '../../back/repositories/worker_repository.dart';
import '../../back/repositories/workers_repository_impl.dart';

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
      final workerEntries = await (_workerRepository as WorkersRepositoryImpl).getAllWorkersWithKeys();
      _workerEntries = workerEntries;
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
    print('🔥 Provider: Iniciando eliminación de worker con key: $key (tipo: ${key.runtimeType})');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _workerRepository.deleteWorker(key);
      print('🔥 Provider: Eliminación exitosa, recargando lista...');
      await loadWorkers();
      print('🔥 Provider: Lista recargada exitosamente');
    } catch (e) {
      print('🔥 Provider: Error durante eliminación: $e');
      _errorMessage = 'Error al eliminar worker: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}