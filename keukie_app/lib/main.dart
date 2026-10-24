import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/web_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WebAuthService.registerWindowsProtocol();
  WebAuthService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keukie',
      debugShowCheckedModeBanner: false,
      navigatorKey: WebAuthService.instance.navigatorKey,
      scaffoldMessengerKey: WebAuthService.instance.messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(primary: const Color(0xFF00ffcc)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}