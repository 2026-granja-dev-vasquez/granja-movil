import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerService _service = CustomerService();
  
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerModel> get customers => _customers;
  List<CustomerModel> get activeCustomers => _customers.where((c) => c.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customers = await _service.getCustomers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newCustomer = await _service.createCustomer(customer);
      _customers.add(newCustomer);
      _customers.sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _service.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _customers[index] = updated;
      }
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _service.deleteCustomer(id);
      final index = _customers.indexWhere((c) => c.id == id);
      if (index != -1) {
        // En lugar de remover, marcamos como inactivo si la API lo hizo así
        _customers[index] = CustomerModel(
          id: _customers[index].id,
          name: _customers[index].name,
          phone: _customers[index].phone,
          address: _customers[index].address,
          isActive: false,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }
}
