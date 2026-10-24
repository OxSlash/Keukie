import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../screens/dashboard_screen.dart';

class WebAuthService {
  WebAuthService._();
  static final WebAuthService instance = WebAuthService._();

  static const String scheme = 'keukie';

  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  StreamSubscription<Uri>? _sub;
  String? _lastCode;

  static Future<void> registerWindowsProtocol() async {
    if (!Platform.isWindows) return;

    final exe = Platform.resolvedExecutable;
    const key = r'HKCU\Software\Classes\keukie';

    await Process.run('reg', ['add', key, '/ve', '/d', 'URL:Keukie', '/f']);
    await Process.run('reg', [
      'add',
      key,
      '/v',
      'URL Protocol',
      '/d',
      '',
      '/f',
    ]);
    await Process.run('reg', [
      'add',
      '$key\\shell\\open\\command',
      '/ve',
      '/d',
      '"$exe" "%1"',
      '/f',
    ]);
  }

  void init() {
    _sub ??= AppLinks().uriLinkStream.listen(_onUri);
  }

  String _newVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<String> _newChallenge() async {
    final verifier = _newVerifier();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_verifier', verifier);

    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<String?> startGoogle() async {
    final challenge = await _newChallenge();
    final uri = Uri.parse(
      '${ApiConfig.serverUrl}/auth/google/redirect',
    ).replace(queryParameters: {'challenge': challenge});

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    return ok ? null : 'Tidak bisa membuka browser';
  }

  Future<Map<String, dynamic>> requestEmailLink(String email) async {
    final challenge = await _newChallenge();
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/email-link'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'challenge': challenge}),
    );

    final data = jsonDecode(response.body);
    return {'statusCode': response.statusCode, ...data};
  }

  Future<void> _onUri(Uri uri) async {
    if (uri.scheme != scheme || uri.host != 'auth') return;

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty || code == _lastCode) return;
    _lastCode = code;

    final prefs = await SharedPreferences.getInstance();
    final verifier = prefs.getString('auth_verifier');

    if (verifier == null) {
      _toast('Sesi login tidak ditemukan. Mulai login dari aplikasi ini.');
      return;
    }
    await prefs.remove('auth_verifier');

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'code': code, 'verifier': verifier}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await prefs.setString('token', data['token']);
        await _openDashboard();
      } else {
        _toast(data['message'] ?? 'Login gagal');
      }
    } catch (_) {
      _toast('Tidak dapat terhubung ke server');
    }
  }

  Future<void> _openDashboard() async {
    for (var i = 0; i < 20 && navigatorKey.currentState == null; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  void _toast(String message) {
    messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }
}