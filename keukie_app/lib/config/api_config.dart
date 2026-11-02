import 'dart:io';

class ApiConfig {
  static const String? publicUrl = 
  'https://carefully-thesaurus-wax-soil.trycloudflare.com';

  static String get serverUrl {
    if (publicUrl != null) return publicUrl!;
    return Platform.isAndroid
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  static String get baseUrl => '$serverUrl/api';
}