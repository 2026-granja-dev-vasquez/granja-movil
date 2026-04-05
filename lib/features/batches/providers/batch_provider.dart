import 'package:flutter/material.dart';
import '../models/batch_model.dart';
import '../services/batch_service.dart';

class BatchProvider with ChangeNotifier {
  final BatchService _batchService = BatchService();
  List<BatchModel> _batches = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BatchModel> get batches => _batches;
  List<BatchModel> get activeBatches => _batches.where((b) => b.status == 'active').toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBatches() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _batchService.getBatches();
      _batches = data.map((e) => BatchModel.fromJson(e)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addBatch(String name, int initialQuantity, DateTime acquisitionDate) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _batchService.createBatch({
        'name': name,
        'initial_quantity': initialQuantity,
        'acquisition_date': acquisitionDate.toIso8601String().split('T')[0],
      });
      await fetchBatches();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerMortality(int batchId, int quantity, DateTime date, String? reason) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _batchService.registerMortality(
        batchId,
        quantity,
        date.toIso8601String().split('T')[0],
        reason,
      );
      await fetchBatches();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<BatchModel?> getBatchDetailed(int id) async {
    try {
      final data = await _batchService.getBatch(id);
      return BatchModel.fromJson(data);
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    }
  }

  Future<bool> closeBatch(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _batchService.updateBatch(id, {'status': 'depleted'});
      await fetchBatches();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addAdjustment(int batchId, int quantity, DateTime date, String reason) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _batchService.registerAdjustment(
        batchId,
        quantity,
        date.toIso8601String().split('T')[0],
        reason,
      );
      await fetchBatches();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
