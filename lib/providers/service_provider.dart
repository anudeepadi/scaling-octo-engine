import 'package:flutter/material.dart';
import '../services/service_manager.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceManager _serviceManager = ServiceManager();
  
  MessagingService get currentService => _serviceManager.currentService;
  String get serviceDisplayName => _serviceManager.serviceDisplayName;
  
  ServiceProvider() {
    // Listen for changes in the service manager
    _serviceManager.addListener(_onServiceChanged);
  }
  
  void _onServiceChanged() {
    notifyListeners();
  }
  
  Future<void> useGemini() async {
    await _serviceManager.useGemini();
  }
  
  Future<void> useDash() async {
    await _serviceManager.useDash();
  }
  
  Future<void> toggleService() async {
    await _serviceManager.toggleService();
  }
  
  @override
  void dispose() {
    _serviceManager.removeListener(_onServiceChanged);
    super.dispose();
  }
}