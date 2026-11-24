import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ParentalControlProvider extends ChangeNotifier {
  String _pin = '0000';
  List<String> _lockedCategories = [];

  String get pin => _pin;
  List<String> get lockedCategories => _lockedCategories;

  ParentalControlProvider() {
    init();
  }

  Future<void> init() async {
    _pin = await StorageService.getPin();
    _lockedCategories = await StorageService.getLockedCategories();
    notifyListeners();
  }

  Future<bool> validatePin(String inputPin) async {
    return inputPin == _pin;
  }

  Future<void> updatePin(String newPin) async {
    _pin = newPin;
    await StorageService.setPin(newPin);
    notifyListeners();
  }

  bool isCategoryLocked(String categoryName) {
    return _lockedCategories.contains(categoryName);
  }

  Future<void> toggleCategoryLock(String categoryName) async {
    await StorageService.toggleCategoryLock(categoryName);
    _lockedCategories = await StorageService.getLockedCategories();
    notifyListeners();
  }
}
