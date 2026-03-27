import 'package:flutter/material.dart';
import '../models/product_size_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  List<ProductSizeModel> _sizes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductSizeModel> get sizes => _sizes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSizes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _productService.getProductSizes();
      _sizes = data.map((e) => ProductSizeModel.fromJson(e)).toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updatePrices(int id, double unit, double carton, double box) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _productService.updatePrice(id, unit, carton, box);
      await fetchSizes();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSize(String name, double unit, double carton, double box) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _productService.createSize(name, unit, carton, box);
      await fetchSizes();
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
