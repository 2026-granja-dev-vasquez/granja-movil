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

  Future<void> fetchSales() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sales = await _service.getSales();
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
}
