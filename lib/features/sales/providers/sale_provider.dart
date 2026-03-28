import 'package:flutter/material.dart';
import '../models/sale_model.dart';
import '../services/sale_service.dart';

class SaleProvider with ChangeNotifier {
  final SaleService _service = SaleService();
  
  List<SaleModel> _sales = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SaleModel> get sales => _sales;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSales({int? customerId, String? startDate, String? endDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sales = await _service.getSales(
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSale(SaleModel sale) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newSale = await _service.createSale(sale);
      _sales.insert(0, newSale); // Agregar al inicio (más reciente)
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SaleModel?> getSaleDetails(int id) async {
    try {
      return await _service.getSaleDetails(id);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateSaleStatus(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedSale = await _service.updateSale(id, data);
      
      // Actualizar en la lista local
      final index = _sales.indexWhere((s) => s.id == id);
      if (index != -1) {
        _sales[index] = updatedSale;
      }
      
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
