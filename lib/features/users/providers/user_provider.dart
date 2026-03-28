import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../../auth/models/user_model.dart';

class UserProvider with ChangeNotifier {
  final UserService _service = UserService();

  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _service.getUsers();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUser(Map<String, dynamic> userData) async {
    try {
      final newUser = await _service.createUser(userData);
      _users.add(newUser);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    try {
      final updatedUser = await _service.updateUser(id, userData);
      final index = _users.indexWhere((u) => u.id == id);
      if (index != -1) {
        _users[index] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _service.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> changeMyPassword(String current, String newPwd, String confirm) async {
    try {
      await _service.changePassword(current, newPwd, confirm);
    } catch (e) {
      rethrow;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
