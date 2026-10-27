import 'dart:io';

class ApiConfig {
  // Isi dengan alamat tunnel/server https saat menguji login Google dan
  // email link, mis. 'https://abc.trycloudflare.com'. Kosongkan (null)
  // untuk memakai alamat lokal.
  static const String? publicUrl =
      'https://restricted-dui-personality-fur.trycloudflare.com';

  static String get serverUrl {
    if (publicUrl != null) return publicUrl!;
    return Platform.isAndroid
        ? 'http://10.0.2.2:8000'
        : 'http://127.0.0.1:8000';
  }

  static String get baseUrl => '$serverUrl/api';
}
