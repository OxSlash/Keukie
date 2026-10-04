import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class TransaksiService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getTransaksi({
    String? jenis,
    String? metode,
    String? dari,
    String? sampai,
    String? cari,
  }) async {
    final queryParams = <String, String>{};
    if (jenis != null && jenis.isNotEmpty) queryParams['jenis'] = jenis;
    if (metode != null && metode.isNotEmpty) queryParams['metode'] = metode;
    if (dari != null && dari.isNotEmpty) queryParams['dari'] = dari;
    if (sampai != null && sampai.isNotEmpty) queryParams['sampai'] = sampai;
    if (cari != null && cari.isNotEmpty) queryParams['cari'] = cari;

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/transaksi',
    ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return {'statusCode': 200, 'data': data};
    }

    return {
      'statusCode': response.statusCode,
      'message': jsonDecode(response.body)['message'] ?? 'Gagal mengambil data',
    };
  }

  Future<Map<String, dynamic>> store({
    required String jenis,
    required double nominal,
    required String metode,
    required String tanggal,
    String? catatan,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/transaksi'),
      headers: await _headers(),
      body: jsonEncode({
        'jenis': jenis,
        'nominal': nominal,
        'metode': metode,
        'tanggal': tanggal,
        'catatan': catatan,
      }),
    );

    final data = jsonDecode(response.body);
    return {'statusCode': response.statusCode, ...data};
  }

  Future<Map<String, dynamic>> update(
    int id, {
    String? jenis,
    double? nominal,
    String? metode,
    String? tanggal,
    String? catatan,
  }) async {
    final body = <String, dynamic>{};
    if (jenis != null) body['jenis'] = jenis;
    if (nominal != null) body['nominal'] = nominal;
    if (metode != null) body['metode'] = metode;
    if (tanggal != null) body['tanggal'] = tanggal;
    if (catatan != null) body['catatan'] = catatan;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/transaksi/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    return {'statusCode': response.statusCode, ...data};
  }

  Future<Map<String, dynamic>> destroy(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/transaksi/$id'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);
    return {'statusCode': response.statusCode, ...data};
  }
}