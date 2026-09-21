import 'package:flutter/material.dart';

class SettingProfilModal extends StatelessWidget {
  const SettingProfilModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      child: Container(
        width: 500,
        height: 350,
        padding: const EdgeInsets.all(20),
        child: const Center(
          child: Text(
            'Setting Profil - Segera Hadir',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
