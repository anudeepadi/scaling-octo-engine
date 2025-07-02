import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class NetworkUtils {
  /// Test network connectivity to Firebase services
  static Future<bool> testFirebaseConnectivity() async {
    final testUrls = [
      'https://firebase.googleapis.com',
      'https://identitytoolkit.googleapis.com',
      'https://securetoken.googleapis.com',
      'https://www.googleapis.com',
    ];

    bool allConnected = true;
    
    for (String url in testUrls) {
      try {
        developer.log('Testing connectivity to: $url', name: 'NetworkUtils');
        final response = await http.get(
          Uri.parse(url),
          headers: {'User-Agent': 'QuitTXT-Network-Test'},
        ).timeout(const Duration(seconds: 10));
        
        developer.log('$url: ${response.statusCode}', name: 'NetworkUtils');
        
        if (response.statusCode >= 400) {
          allConnected = false;
        }
      } catch (e) {
        developer.log('Failed to connect to $url: $e', name: 'NetworkUtils');
        allConnected = false;
      }
    }

    return allConnected;
  }

  /// Test if running on Android emulator
  static bool isAndroidEmulator() {
    if (!Platform.isAndroid) return false;
    
    // Check common emulator identifiers
    final brand = Platform.environment['ro.product.brand'] ?? '';
    final model = Platform.environment['ro.product.model'] ?? '';
    final device = Platform.environment['ro.product.device'] ?? '';
    
    return brand.toLowerCase().contains('generic') ||
           model.toLowerCase().contains('emulator') ||
           device.toLowerCase().contains('emulator') ||
           model.toLowerCase().contains('sdk');
  }

  /// Get network information for debugging
  static Map<String, dynamic> getNetworkInfo() {
    return {
      'platform': Platform.operatingSystem,
      'isAndroid': Platform.isAndroid,
      'isEmulator': isAndroidEmulator(),
      'locale': Platform.localeName,
      'version': Platform.operatingSystemVersion,
      'environment': Platform.environment.keys.take(5).toList(),
    };
  }

  /// Test DNS resolution
  static Future<bool> testDnsResolution() async {
    try {
      final addresses = await InternetAddress.lookup('firebase.googleapis.com');
      developer.log('DNS resolution successful: ${addresses.length} addresses found', name: 'NetworkUtils');
      return addresses.isNotEmpty;
    } catch (e) {
      developer.log('DNS resolution failed: $e', name: 'NetworkUtils');
      return false;
    }
  }

  /// Comprehensive network diagnostics
  static Future<Map<String, dynamic>> runNetworkDiagnostics() async {
    developer.log('Running network diagnostics...', name: 'NetworkUtils');
    
    final results = <String, dynamic>{};
    
    // Basic network info
    results['networkInfo'] = getNetworkInfo();
    
    // DNS test
    results['dnsResolution'] = await testDnsResolution();
    
    // Firebase connectivity
    results['firebaseConnectivity'] = await testFirebaseConnectivity();
    
    // Test basic HTTP
    try {
      final response = await http.get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 10));
      results['basicHttp'] = response.statusCode == 200;
    } catch (e) {
      results['basicHttp'] = false;
      results['basicHttpError'] = e.toString();
    }
    
    developer.log('Network diagnostics completed: $results', name: 'NetworkUtils');
    return results;
  }
} 